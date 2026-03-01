import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// Community sender key service (Signal-style Sender Keys).
///
/// - Maintains a per-community shared 32-byte AES key (sender key).
/// - Distributes that key via Signal-encrypted shares (rare, not per message).
/// - Stores the key locally in secure storage for offline-first operation.
class CommunitySenderKeyService {
  static const String _logName = 'CommunitySenderKeyService';
  static const String _storagePrefix = 'community_sender_key_v1_';
  static const int _maxLocalKeysPerCommunity = 8;

  final FlutterSecureStorage _secureStorage;
  final SupabaseService _supabase;
  final AgentIdService _agentIdService;
  final MessageEncryptionService _encryptionService;

  CommunitySenderKeyService({
    required FlutterSecureStorage secureStorage,
    required SupabaseService supabase,
    required AgentIdService agentIdService,
    required MessageEncryptionService encryptionService,
  })  : _secureStorage = secureStorage,
        _supabase = supabase,
        _agentIdService = agentIdService,
        _encryptionService = encryptionService;

  /// Returns the locally cached *active* sender key for this community (if any).
  ///
  /// Backwards compatible with the legacy single-key format written by older builds.
  Future<CommunitySenderKey?> getLocalKey(String communityId) async {
    try {
      final raw = await _secureStorage.read(key: '$_storagePrefix$communityId');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // New format:
      // {
      //   "active_key_id": "<uuid>",
      //   "keys": { "<uuid>": "<base64>" }
      // }
      final activeKeyId = decoded['active_key_id'] as String?;
      final keys = decoded['keys'];
      if (activeKeyId != null && keys is Map<String, dynamic>) {
        final keyBase64 = keys[activeKeyId] as String?;
        if (keyBase64 == null || keyBase64.isEmpty) return null;
        return CommunitySenderKey(
          communityId: communityId,
          keyId: activeKeyId,
          keyBytes32: Uint8List.fromList(base64Decode(keyBase64)),
        );
      }

      // Legacy format:
      // { "key_id": "...", "key_base64": "..." }
      final keyId = decoded['key_id'] as String?;
      final keyBase64 = decoded['key_base64'] as String?;
      if (keyId == null || keyBase64 == null) return null;
      return CommunitySenderKey(
        communityId: communityId,
        keyId: keyId,
        keyBytes32: Uint8List.fromList(base64Decode(keyBase64)),
      );
    } catch (e, st) {
      developer.log('Failed to read local community sender key',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  /// Returns a locally cached sender key by key id (if present).
  Future<CommunitySenderKey?> getLocalKeyById({
    required String communityId,
    required String keyId,
  }) async {
    try {
      final raw = await _secureStorage.read(key: '$_storagePrefix$communityId');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final keys = decoded['keys'];
      if (keys is! Map<String, dynamic>) return null;
      final keyBase64 = keys[keyId] as String?;
      if (keyBase64 == null || keyBase64.isEmpty) return null;
      return CommunitySenderKey(
        communityId: communityId,
        keyId: keyId,
        keyBytes32: Uint8List.fromList(base64Decode(keyBase64)),
      );
    } catch (e, st) {
      developer.log('Failed to read local community sender key by id',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  /// Ensures the client has the *current* sender key and is eligible for
  /// RLS-gated `community_stream:<communityId>` subscriptions.
  ///
  /// This is the **silent refresh** primitive used when a sender key rotates:
  /// the client fetches/decrypts the active key share (if needed) and upserts
  /// `community_memberships.key_id` without any user-visible "rejoin" UX.
  Future<CommunitySenderKey> ensureCurrentKeyAndMembership({
    required String communityId,
    required String currentUserId,
  }) async {
    if (!_supabase.isAvailable) {
      // Offline: best effort. We can still decrypt if we have local keys, but
      // we cannot guarantee stream subscription eligibility.
      final local = await getLocalKey(communityId);
      if (local != null) return local;
      final generated = _generateKey(communityId);
      await _persistLocalKey(generated, setActive: true);
      return generated;
    }

    final serverKeyId = await _fetchServerActiveKeyId(communityId);
    if (serverKeyId == null) {
      // No state yet: fall back to normal creation path (may create + share).
      return getOrEstablishKey(
        communityId: communityId,
        currentUserId: currentUserId,
        memberUserIds: const <String>[],
      );
    }

    final localForServer = await getLocalKeyById(
      communityId: communityId,
      keyId: serverKeyId,
    );
    if (localForServer != null) {
      await _persistLocalKey(localForServer, setActive: true);
      await _upsertMembershipBestEffort(
        communityId: communityId,
        userId: currentUserId,
        keyId: localForServer.keyId,
      );
      return localForServer;
    }

    // Backwards-compat: legacy single-key format may not be addressable by id.
    final legacyOrActive = await getLocalKey(communityId);
    if (legacyOrActive != null && legacyOrActive.keyId == serverKeyId) {
      await _persistLocalKey(legacyOrActive, setActive: true);
      await _upsertMembershipBestEffort(
        communityId: communityId,
        userId: currentUserId,
        keyId: legacyOrActive.keyId,
      );
      return legacyOrActive;
    }

    final share = await _fetchShareForKey(
      communityId: communityId,
      toUserId: currentUserId,
      keyId: serverKeyId,
    );
    if (share == null) {
      throw Exception('No sender-key share available for rotated key');
    }
    final decrypted = await _decryptShare(share);
    await _persistLocalKey(decrypted, setActive: true);
    await _upsertMembershipBestEffort(
      communityId: communityId,
      userId: currentUserId,
      keyId: decrypted.keyId,
    );
    return decrypted;
  }

  /// Gets the sender key required to decrypt a specific message blob.
  ///
  /// If the key is not cached locally, will try to fetch+decrypt the Signal
  /// share for that key (rejoin).
  Future<CommunitySenderKey> getKeyForMessage({
    required String communityId,
    required String currentUserId,
    required String keyId,
  }) async {
    final local = await getLocalKeyById(communityId: communityId, keyId: keyId);
    if (local != null) return local;

    if (!_supabase.isAvailable) {
      throw Exception('Missing sender key locally and Supabase unavailable');
    }

    final share = await _fetchShareForKey(
      communityId: communityId,
      toUserId: currentUserId,
      keyId: keyId,
    );
    if (share == null) {
      throw Exception('No sender-key share available for required key');
    }
    final decrypted = await _decryptShare(share);
    await _persistLocalKey(decrypted, setActive: false);

    // If this key is now the server active key, update membership best-effort.
    final serverKeyId = await _fetchServerActiveKeyId(communityId);
    if (serverKeyId != null && serverKeyId == decrypted.keyId) {
      await _persistLocalKey(decrypted, setActive: true);
      await _upsertMembershipBestEffort(
        communityId: communityId,
        userId: currentUserId,
        keyId: decrypted.keyId,
      );
    }
    return decrypted;
  }

  /// Rotates the community sender key, updates state, and re-shares to members.
  ///
  /// **Security note:** Requires Supabase and Signal encryption for distribution.
  Future<CommunitySenderKey> rotateKey({
    required String communityId,
    required String currentUserId,
    required List<String> memberUserIds,
    Duration graceDuration = const Duration(days: 7),
    bool hardRotation = false,
  }) async {
    if (!_supabase.isAvailable) {
      throw Exception('Cannot rotate sender key without Supabase');
    }

    final previousKeyId = await _fetchServerActiveKeyId(communityId);
    final newKey = _generateKey(communityId);
    final nowUtc = DateTime.now().toUtc();
    final graceExpiresAt =
        hardRotation ? null : nowUtc.add(graceDuration).toIso8601String();

    // Update active key state (requires an UPDATE RLS policy).
    await _supabase.client
        .from('community_sender_key_state')
        .update({
          'key_id': newKey.keyId,
          'previous_key_id': previousKeyId,
          'grace_expires_at': graceExpiresAt,
          'updated_at': nowUtc.toIso8601String(),
        })
        .eq('community_id', communityId)
        .eq('created_by', currentUserId);

    // Share to all members (including self).
    await _shareKeyToMembers(
      key: newKey,
      fromUserId: currentUserId,
      memberUserIds: memberUserIds,
    );

    await _persistLocalKey(newKey, setActive: true);
    await _upsertMembershipBestEffort(
      communityId: communityId,
      userId: currentUserId,
      keyId: newKey.keyId,
    );
    return newKey;
  }

  /// Ensure we have a sender key for this community.
  ///
  /// Behavior:
  /// - If present locally -> returns immediately (no Signal required).
  /// - Else try to fetch and decrypt a share from Supabase (requires Signal).
  /// - Else attempt to create key state + share to members (requires Supabase + Signal).
  Future<CommunitySenderKey> getOrEstablishKey({
    required String communityId,
    required String currentUserId,
    required List<String> memberUserIds,
  }) async {
    // If online, prefer the server-active key id to avoid using stale local keys
    // after rotation. If we don't have the active key yet, fetch+decrypt its share.
    if (_supabase.isAvailable) {
      final serverKeyId = await _fetchServerActiveKeyId(communityId);
      if (serverKeyId != null) {
        final localForServer = await getLocalKeyById(
          communityId: communityId,
          keyId: serverKeyId,
        );
        if (localForServer != null) {
          await _persistLocalKey(localForServer, setActive: true);
          await _upsertMembershipBestEffort(
            communityId: communityId,
            userId: currentUserId,
            keyId: localForServer.keyId,
          );
          return localForServer;
        }

        // Backwards-compat: legacy single-key format may not be addressable by id.
        final legacyOrActive = await getLocalKey(communityId);
        if (legacyOrActive != null && legacyOrActive.keyId == serverKeyId) {
          await _persistLocalKey(legacyOrActive, setActive: true);
          await _upsertMembershipBestEffort(
            communityId: communityId,
            userId: currentUserId,
            keyId: legacyOrActive.keyId,
          );
          return legacyOrActive;
        }

        // Do NOT fall back to a stale local key when the server has rotated.
        // Instead, fetch and decrypt the active key share.
        final share = await _fetchShareForKey(
          communityId: communityId,
          toUserId: currentUserId,
          keyId: serverKeyId,
        );
        if (share == null) {
          throw Exception('No sender-key share available for active key');
        }

        final decrypted = await _decryptShare(share);
        await _persistLocalKey(decrypted, setActive: true);
        await _upsertMembershipBestEffort(
          communityId: communityId,
          userId: currentUserId,
          keyId: decrypted.keyId,
        );
        return decrypted;
      }
    }

    final local = await getLocalKey(communityId);
    if (local != null) return local;

    if (!_supabase.isAvailable) {
      // Offline mode: generate local key; cannot share until online.
      final generated = _generateKey(communityId);
      await _persistLocalKey(generated, setActive: true);
      return generated;
    }

    // 1) If a share exists for us, use it.
    final share = await _fetchLatestShare(
      communityId: communityId,
      toUserId: currentUserId,
    );
    if (share != null) {
      final decrypted = await _decryptShare(share);
      await _persistLocalKey(decrypted, setActive: true);
      await _upsertMembershipBestEffort(
        communityId: communityId,
        userId: currentUserId,
        keyId: decrypted.keyId,
      );
      return decrypted;
    }

    // 2) Otherwise, attempt to become key creator.
    final key = _generateKey(communityId);
    final created = await _tryCreateKeyState(
      communityId: communityId,
      keyId: key.keyId,
      createdBy: currentUserId,
    );

    if (!created) {
      // Someone else likely created; re-attempt share fetch.
      final serverKeyId = await _fetchServerActiveKeyId(communityId);
      final retryShare = serverKeyId == null
          ? await _fetchLatestShare(
              communityId: communityId,
              toUserId: currentUserId,
            )
          : await _fetchShareForKey(
              communityId: communityId,
              toUserId: currentUserId,
              keyId: serverKeyId,
            );
      if (retryShare != null) {
        final decrypted = await _decryptShare(retryShare);
        await _persistLocalKey(decrypted, setActive: true);
        return decrypted;
      }
      throw Exception(
        'Community sender key exists but no share is available for this user yet.',
      );
    }

    // Share to all members (including self for robustness).
    await _shareKeyToMembers(
      key: key,
      fromUserId: currentUserId,
      memberUserIds: memberUserIds,
    );

    await _persistLocalKey(key, setActive: true);
    await _upsertMembershipBestEffort(
      communityId: communityId,
      userId: currentUserId,
      keyId: key.keyId,
    );
    return key;
  }

  Future<bool> _tryCreateKeyState({
    required String communityId,
    required String keyId,
    required String createdBy,
  }) async {
    try {
      await _supabase.client.from('community_sender_key_state').insert({
        'community_id': communityId,
        'key_id': keyId,
        'created_by': createdBy,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<_CommunitySenderKeyShare?> _fetchLatestShare({
    required String communityId,
    required String toUserId,
  }) async {
    try {
      final row = await _supabase.client
          .from('community_sender_key_shares')
          .select()
          .eq('community_id', communityId)
          .eq('to_user_id', toUserId)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (row == null) return null;
      return _CommunitySenderKeyShare.fromJson(row);
    } catch (e, st) {
      developer.log('Failed to fetch community sender key share',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  Future<_CommunitySenderKeyShare?> _fetchShareForKey({
    required String communityId,
    required String toUserId,
    required String keyId,
  }) async {
    try {
      final row = await _supabase.client
          .from('community_sender_key_shares')
          .select()
          .eq('community_id', communityId)
          .eq('to_user_id', toUserId)
          .eq('key_id', keyId)
          .maybeSingle();
      if (row == null) return null;
      return _CommunitySenderKeyShare.fromJson(row);
    } catch (e, st) {
      developer.log('Failed to fetch community sender key share for key',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> _fetchServerActiveKeyId(String communityId) async {
    if (!_supabase.isAvailable) return null;
    try {
      final row = await _supabase.client
          .from('community_sender_key_state')
          .select('key_id')
          .eq('community_id', communityId)
          .maybeSingle();
      return row?['key_id']?.toString();
    } catch (e, st) {
      developer.log('Failed to fetch community sender key state',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  Future<CommunitySenderKey> _decryptShare(
      _CommunitySenderKeyShare share) async {
    final encryptionType = EncryptionType.values.firstWhere(
      (e) => e.name == share.encryptionType,
      orElse: () => EncryptionType.aes256gcm,
    );
    final encrypted =
        EncryptedMessage.fromBase64(share.encryptedKeyBase64, encryptionType);

    if (encrypted.encryptionType != EncryptionType.signalProtocol) {
      throw Exception('Community sender key shares must be Signal-encrypted');
    }

    // Signal sender keys are tied to the Signal "address" used for DM/share transport.
    //
    // For long-term correctness (and to avoid depending on the AgentId secure mapping),
    // we treat the sender's **auth user id** as the Signal address for user-to-user messaging.
    final plaintext =
        await _encryptionService.decrypt(encrypted, share.fromUserId);
    final decoded = jsonDecode(plaintext) as Map<String, dynamic>;
    final keyId = decoded['key_id'] as String;
    final keyBase64 = decoded['key_base64'] as String;
    final bytes = base64Decode(keyBase64);

    return CommunitySenderKey(
      communityId: share.communityId,
      keyId: keyId,
      keyBytes32: Uint8List.fromList(bytes),
    );
  }

  Future<void> _shareKeyToMembers({
    required CommunitySenderKey key,
    required String fromUserId,
    required List<String> memberUserIds,
  }) async {
    final senderAgentId = await _agentIdService.getUserAgentId(fromUserId);
    final payloadJson = jsonEncode({
      'key_id': key.keyId,
      'key_base64': base64Encode(key.keyBytes32),
    });

    for (final memberUserId in memberUserIds) {
      final encrypted =
          await _encryptionService.encrypt(payloadJson, memberUserId);
      if (encrypted.encryptionType != EncryptionType.signalProtocol) {
        throw Exception(
            'Signal Protocol is required to distribute community sender keys');
      }

      try {
        await _supabase.client.from('community_sender_key_shares').insert({
          'community_id': key.communityId,
          'key_id': key.keyId,
          'to_user_id': memberUserId,
          'from_user_id': fromUserId,
          'sender_agent_id': senderAgentId,
          'encryption_type': encrypted.encryptionType.name,
          'encrypted_key_base64': encrypted.toBase64(),
        });
      } catch (_) {
        // Likely duplicate (already shared). Best-effort.
      }
    }
  }

  CommunitySenderKey _generateKey(String communityId) {
    final keyId = const Uuid().v4();
    final random = math.Random.secure();
    final keyBytes = Uint8List(32);
    for (var i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return CommunitySenderKey(
      communityId: communityId,
      keyId: keyId,
      keyBytes32: keyBytes,
    );
  }

  Future<void> _persistLocalKey(
    CommunitySenderKey key, {
    required bool setActive,
  }) async {
    final storageKey = '$_storagePrefix${key.communityId}';
    Map<String, dynamic> decoded = <String, dynamic>{};
    try {
      final existing = await _secureStorage.read(key: storageKey);
      if (existing != null && existing.isNotEmpty) {
        decoded = jsonDecode(existing) as Map<String, dynamic>;
      }
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    // Normalize legacy -> new.
    final keys = <String, String>{};
    final existingKeys = decoded['keys'];
    if (existingKeys is Map<String, dynamic>) {
      for (final entry in existingKeys.entries) {
        final v = entry.value;
        if (v is String && v.isNotEmpty) keys[entry.key] = v;
      }
    } else {
      final legacyKeyId = decoded['key_id'] as String?;
      final legacyKeyBase64 = decoded['key_base64'] as String?;
      if (legacyKeyId != null &&
          legacyKeyBase64 != null &&
          legacyKeyId.isNotEmpty &&
          legacyKeyBase64.isNotEmpty) {
        keys[legacyKeyId] = legacyKeyBase64;
      }
    }

    keys[key.keyId] = base64Encode(key.keyBytes32);

    // Trim to a bounded number of keys per community (keep newest by insertion).
    if (keys.length > _maxLocalKeysPerCommunity) {
      final toRemove =
          keys.keys.take(keys.length - _maxLocalKeysPerCommunity).toList();
      for (final k in toRemove) {
        if (k != key.keyId) keys.remove(k);
      }
    }

    final next = <String, dynamic>{
      'version': 1,
      'active_key_id':
          setActive ? key.keyId : (decoded['active_key_id'] ?? key.keyId),
      'keys': keys,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _secureStorage.write(key: storageKey, value: jsonEncode(next));
  }

  Future<void> _upsertMembershipBestEffort({
    required String communityId,
    required String userId,
    required String keyId,
  }) async {
    if (!_supabase.isAvailable) return;
    try {
      // Best-effort upsert; enables RLS-gated community stream delivery.
      await _supabase.client.from('community_memberships').upsert({
        'community_id': communityId,
        'user_id': userId,
        'key_id': keyId,
      });
    } catch (e, st) {
      developer.log(
        'Warning: failed to upsert community membership (best-effort)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}

class CommunitySenderKey {
  final String communityId;
  final String keyId;
  final Uint8List keyBytes32;

  const CommunitySenderKey({
    required this.communityId,
    required this.keyId,
    required this.keyBytes32,
  });
}

class _CommunitySenderKeyShare {
  final String communityId;
  final String keyId;
  final String toUserId;
  final String fromUserId;
  final String senderAgentId;
  final String encryptionType;
  final String encryptedKeyBase64;

  const _CommunitySenderKeyShare({
    required this.communityId,
    required this.keyId,
    required this.toUserId,
    required this.fromUserId,
    required this.senderAgentId,
    required this.encryptionType,
    required this.encryptedKeyBase64,
  });

  factory _CommunitySenderKeyShare.fromJson(Map<String, dynamic> json) {
    return _CommunitySenderKeyShare(
      communityId: json['community_id'] as String,
      keyId: json['key_id'] as String,
      toUserId: json['to_user_id'] as String,
      fromUserId: json['from_user_id'] as String,
      senderAgentId: json['sender_agent_id'] as String,
      encryptionType: json['encryption_type'] as String,
      encryptedKeyBase64: json['encrypted_key_base64'] as String,
    );
  }
}

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:avrai_runtime_os/data/database/app_database.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Secure Vault Sync Service
///
/// Responsible for End-to-End Encrypted (E2EE) cloud backup and restore of
/// critical user AI state: Pheromones (KnowledgeVectors), DNA (PersonalityKnot),
/// and Soul (LearnedArchetypes).
///
/// **Privacy & Security Philosophy:**
/// - Local-First: Data primarily lives on the device.
/// - Zero-Knowledge Cloud: The server only sees encrypted BLOBs.
/// - E2EE: Uses AES-256-GCM encrypted with a key derived from a user recovery phrase or password.
class SecureVaultSyncService {
  static const String _logName = 'SecureVaultSyncService';
  static const String _vaultTable = 'user_encrypted_vaults';

  final AppDatabase _db;
  final SupabaseService _supabase;

  SecureVaultSyncService({
    required AppDatabase db,
    required SupabaseService supabase,
  })  : _db = db,
        _supabase = supabase;

  /// Backs up the local state to the cloud encrypted with the given passphrase.
  Future<void> backupVault(String passphrase) async {
    developer.log('Starting secure vault backup...', name: _logName);
    
    final currentUser = _supabase.currentUser;
    if (currentUser == null) {
      throw StateError('Cannot backup vault: No authenticated user.');
    }

    try {
      // 1. Gather all state from the database
      final dwellEvents = await _db.getAllDwellEvents();
      final pheromones = await _db.getPheromonesByQueue('inbox'); // Backup only what's needed or both
      final outboxPheromones = await _db.getPheromonesByQueue('outbox');
      final archetypes = await _db.getAllArchetypes();
      final knot = await _db.getPersonalityKnot(currentUser.id);

      // 2. Serialize to JSON
      final stateMap = {
        'dwells': dwellEvents.map((e) => {
          'id': e.id,
          'startTime': e.startTime.toIso8601String(),
          'endTime': e.endTime.toIso8601String(),
          'latitude': e.latitude,
          'longitude': e.longitude,
          'encounteredAgentIds': e.encounteredAgentIds,
        }).toList(),
        'pheromones': [...pheromones, ...outboxPheromones].map((p) => {
          'id': p.id,
          'senderAgentId': p.senderAgentId,
          'insightWeights': p.insightWeights,
          'contextCategory': p.contextCategory,
          'timestamp': p.timestamp.toIso8601String(),
          'queueType': p.queueType,
        }).toList(),
        'archetypes': archetypes.map((a) => {
          'id': a.id,
          'name': a.name,
          'stateJson': a.stateJson,
          'lastUpdatedAt': a.lastUpdatedAt.toIso8601String(),
        }).toList(),
        'knot': knot != null ? {
          'userId': knot.userId,
          'dnaPayload': base64Encode(knot.dnaPayload),
          'lastUpdatedAt': knot.lastUpdatedAt.toIso8601String(),
        } : null,
      };

      final plaintext = jsonEncode(stateMap);

      // 3. Derive key and encrypt
      final salt = _generateRandomBytes(16);
      final key = _deriveKey(passphrase, salt);
      final encryptedBlob = _encryptAES256GCM(plaintext, key);
      
      final payload = {
        'encrypted_data': encryptedBlob,
        'salt': base64Encode(salt),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 4. Upload to Supabase
      await _supabase.client.from(_vaultTable).upsert({
        'user_id': currentUser.id,
        'vault_data': payload,
      });

      developer.log('Secure vault backup completed successfully.', name: _logName);
    } catch (e, st) {
      developer.log('Failed to backup vault', error: e, stackTrace: st, name: _logName);
      rethrow;
    }
  }

  /// Restores the local state from the cloud using the given passphrase.
  Future<void> restoreVault(String passphrase) async {
    developer.log('Starting secure vault restore...', name: _logName);
    
    final currentUser = _supabase.currentUser;
    if (currentUser == null) {
      throw StateError('Cannot restore vault: No authenticated user.');
    }

    try {
      // 1. Fetch encrypted vault from Supabase
      final response = await _supabase.client
          .from(_vaultTable)
          .select('vault_data')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null || response['vault_data'] == null) {
        developer.log('No vault found for user.', name: _logName);
        return;
      }

      final vaultData = response['vault_data'] as Map<String, dynamic>;
      final encryptedBlob = vaultData['encrypted_data'] as String;
      final salt = base64Decode(vaultData['salt'] as String);

      // 2. Derive key and decrypt
      final key = _deriveKey(passphrase, salt);
      final plaintext = _decryptAES256GCM(encryptedBlob, key);

      // 3. Deserialize JSON
      final stateMap = jsonDecode(plaintext) as Map<String, dynamic>;

      // 4. Insert back into the database
      // Clear old data to prevent duplication conflicts? Or just upsert.
      // Upserting is safer.
      
      final dwellsList = (stateMap['dwells'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final d in dwellsList) {
        await _db.upsertDwellEvent(DwellEventsCompanion.insert(
          id: d['id'],
          startTime: DateTime.parse(d['startTime']),
          endTime: DateTime.parse(d['endTime']),
          latitude: d['latitude'],
          longitude: d['longitude'],
          encounteredAgentIds: d['encounteredAgentIds'],
        ));
      }

      final pheromonesList = (stateMap['pheromones'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final p in pheromonesList) {
        await _db.upsertPheromone(PheromonesCompanion.insert(
          id: p['id'],
          senderAgentId: p['senderAgentId'],
          insightWeights: p['insightWeights'],
          contextCategory: p['contextCategory'],
          timestamp: DateTime.parse(p['timestamp']),
        ));
      }

      final archetypesList = (stateMap['archetypes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final a in archetypesList) {
        await _db.upsertArchetype(ArchetypesCompanion.insert(
          id: a['id'],
          name: a['name'],
          stateJson: a['stateJson'],
          lastUpdatedAt: DateTime.parse(a['lastUpdatedAt']),
        ));
      }

      final knotData = stateMap['knot'] as Map<String, dynamic>?;
      if (knotData != null) {
        await _db.upsertPersonalityKnot(PersonalityKnotsCompanion.insert(
          userId: knotData['userId'],
          dnaPayload: base64Decode(knotData['dnaPayload']),
          lastUpdatedAt: DateTime.parse(knotData['lastUpdatedAt']),
        ));
      }

      developer.log('Secure vault restore completed successfully.', name: _logName);
    } catch (e, st) {
      developer.log('Failed to restore vault', error: e, stackTrace: st, name: _logName);
      rethrow;
    }
  }

  // --- Cryptography Helpers --- //

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (i) => random.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  /// Derives an AES-256 key from a passphrase using PBKDF2 (HMAC-SHA256)
  Uint8List _deriveKey(String passphrase, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 100000, 32)); // 100k iterations, 32 bytes (256 bits)
    return pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  String _encryptAES256GCM(String plaintext, Uint8List key) {
    final iv = _generateRandomBytes(12);
    
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final ciphertextWithTag = cipher.process(plaintextBytes);

    final combined = Uint8List(iv.length + ciphertextWithTag.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, ciphertextWithTag);

    return 'vault_v1:${base64Encode(combined)}';
  }

  String _decryptAES256GCM(String encrypted, Uint8List key) {
    if (!encrypted.startsWith('vault_v1:')) {
      throw Exception('Invalid vault format');
    }

    final base64Data = encrypted.substring('vault_v1:'.length);
    final bytes = base64Decode(base64Data);
    
    if (bytes.length < 12 + 16) {
      throw Exception('Invalid vault data length');
    }

    final iv = bytes.sublist(0, 12);
    final ciphertextWithTag = bytes.sublist(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final decryptedBytes = cipher.process(ciphertextWithTag);
    return utf8.decode(decryptedBytes);
  }
}

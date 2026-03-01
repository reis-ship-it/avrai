import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai2ai/models/community_chat_message.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_runtime_os/crypto/aes256gcm_fixed_key_codec.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_sender_key_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:uuid/uuid.dart';

/// CommunityChatService
///
/// Encrypted group chats for communities/clubs using:
/// - **Sender Keys (AES-256-GCM)**: encrypt once per message with a shared 32-byte key
/// - **Signal-encrypted key shares**: distribute/rotate sender keys rarely (not per message)
/// - **Payloadless realtime**: `community_stream:<communityId>` emits only `messageId`
///   via `public.community_message_events` (RLS-gated).
///
/// **Offline-first:**
/// - Messages are stored locally before network send.
/// - Sender keys are cached in secure storage and can decrypt historical messages across rotations.
///
/// Philosophy: "Doors, not badges" - secure, authentic community connections.
class CommunityChatService {
  static const String _logName = 'CommunityChatService';
  static const String _chatStoreName = 'community_chat_messages';
  static const String _chatIdPrefix = 'community_chat_';
  static const String _communityStreamChannelPrefix = 'community_stream:';

  final MessageEncryptionService _encryptionService;
  final AgentIdService? _agentIdService;
  final RealtimeBackend? _realtimeBackend;
  final AtomicClockService? _atomicClock;
  final DmMessageStore? _dmStore;
  final CommunitySenderKeyService? _senderKeyService;
  final CommunityMessageStore? _communityMessageStore;

  CommunityChatService({
    MessageEncryptionService? encryptionService,
    AgentIdService? agentIdService,
    RealtimeBackend? realtimeBackend,
    AtomicClockService? atomicClock,
    DmMessageStore? dmStore,
    CommunitySenderKeyService? senderKeyService,
    CommunityMessageStore? communityMessageStore,
  })  : _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _agentIdService = agentIdService,
        _realtimeBackend = realtimeBackend,
        _atomicClock = atomicClock,
        _dmStore = dmStore,
        _senderKeyService = senderKeyService,
        _communityMessageStore = communityMessageStore;

  /// Send an encrypted group message
  ///
  /// [userId] - Sender's user ID
  /// [communityId] - Community/club ID
  /// [message] - Plaintext message to send
  ///
  /// Returns the created CommunityChatMessage
  ///
  /// Throws Exception if user is not a member of the community
  Future<CommunityChatMessage> sendGroupMessage(
    String userId,
    String communityId,
    String message, {
    required Community community, // Pass community to verify membership
  }) async {
    try {
      // Verify user is a member
      if (!community.isMember(userId)) {
        throw Exception('User is not a member of this community');
      }

      developer.log(
          'Sending group message from $userId to community $communityId',
          name: _logName);

      final chatId = _generateChatId(communityId);

      // Encrypt message with group key
      final encrypted = await _encryptGroupMessage(message, communityId);

      // Create message
      final chatMessage = CommunityChatMessage(
        messageId: const Uuid().v4(),
        chatId: chatId,
        communityId: communityId,
        senderId: userId,
        encryptedContent: encrypted,
        timestamp: DateTime.now(),
      );

      // Store message
      await _saveMessage(chatMessage);

      developer.log('✅ Group message sent and saved: ${chatMessage.messageId}',
          name: _logName);
      return chatMessage;
    } catch (e, stackTrace) {
      developer.log(
        'Error sending group message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Send a group/community message and broadcast it over realtime using Signal Protocol (fanout).
  ///
  /// **Transport encryption:** Signal Protocol per-recipient (fanout).
  /// **At-rest encryption:** Stored locally using the existing group-key scheme.
  ///
  /// This avoids implementing Sender Keys for MVP, while still providing E2EE in transit.
  Future<CommunityChatMessage> sendGroupMessageOverNetwork({
    required String userId,
    required String communityId,
    required String message,
    required Community community,
  }) async {
    // Store locally first
    final stored = await sendGroupMessage(
      userId,
      communityId,
      message,
      community: community,
    );

    await _broadcastGroupMessageSenderKey(
      senderUserId: userId,
      community: community,
      plaintext: message,
      messageId: stored.messageId,
    );

    return stored;
  }

  /// Subscribe to incoming community messages for a user (optionally scoped to one community).
  ///
  /// Decrypts using Signal Protocol and stores the message locally (group-key at rest).
  Stream<CommunityChatMessage> subscribeToIncomingCommunityMessages({
    required String userId,
    String? communityId,
  }) async* {
    final realtime = _realtimeBackend;
    final dmStore = _dmStore;
    final senderKeyService = _senderKeyService;
    final messageStore = _communityMessageStore;
    if (realtime == null) {
      developer.log(
        'Realtime community subscription unavailable (missing RealtimeBackend)',
        name: _logName,
      );
      return;
    }
    if (senderKeyService == null || messageStore == null) {
      developer.log(
        'Realtime community subscription unavailable (missing sender key services)',
        name: _logName,
      );
      return;
    }

    await realtime.connect();
    final cid = communityId;
    if (cid == null || cid.isEmpty) {
      developer.log(
        'Community stream subscription requires communityId',
        name: _logName,
      );
      return;
    }

    // Ensure the user is eligible for the RLS-gated stream:
    // - fetch/decrypt the active sender key share (if rotated)
    // - upsert community_memberships with the current key_id
    try {
      await senderKeyService.ensureCurrentKeyAndMembership(
        communityId: cid,
        currentUserId: userId,
      );
    } catch (e, st) {
      developer.log(
        'Unable to ensure current sender key/membership for community stream',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return;
    }

    // Keep stream eligibility fresh so members stay in seamlessly across rotations.
    // This avoids "silent stalls" if a rotation happened long ago and the grace window expires
    // before any post-rotation message arrives to trigger a key fetch.
    final refreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
      unawaited(() async {
        try {
          await senderKeyService.ensureCurrentKeyAndMembership(
            communityId: cid,
            currentUserId: userId,
          );
        } catch (e, st) {
          developer.log(
            'Background key/membership refresh failed',
            name: _logName,
            error: e,
            stackTrace: st,
          );
        }
      }());
    });

    final inboxChannel = '$_communityStreamChannelPrefix$cid';

    try {
      await for (final msg in realtime.subscribeToMessages(inboxChannel)) {
        try {
          // Payloadless notify: messageId in msg.id or msg.content.
          final messageId = msg.id.isNotEmpty ? msg.id : msg.content;
          if (messageId.isEmpty) continue;

          final blob = await messageStore.getMessageBlob(messageId);
          if (blob == null) continue;
          if (blob.communityId != cid) continue;

          // Ignore DM notifications if misrouted here.
          if (dmStore != null) {
            final dmBlob = await dmStore.getDmBlob(messageId);
            if (dmBlob != null) continue;
          }

          // Ensure we have the exact key required for this message (supports rotations and history).
          // If a rotation just happened and the share is racing, try a one-time refresh + retry.
          CommunitySenderKey key;
          try {
            key = await senderKeyService.getKeyForMessage(
              communityId: blob.communityId,
              currentUserId: userId,
              keyId: blob.keyId,
            );
          } catch (_) {
            await senderKeyService.ensureCurrentKeyAndMembership(
              communityId: cid,
              currentUserId: userId,
            );
            key = await senderKeyService.getKeyForMessage(
              communityId: blob.communityId,
              currentUserId: userId,
              keyId: blob.keyId,
            );
          }

          final plaintext = Aes256GcmFixedKeyCodec.decryptBase64ToString(
            key32: key.keyBytes32,
            ciphertextBase64: blob.ciphertextBase64,
          );

          final stored = await _storeReceivedGroupMessage(
            messageId: blob.messageId,
            communityId: blob.communityId,
            senderUserId: blob.senderUserId,
            plaintext: plaintext,
            sentAtIso: blob.sentAt.toIso8601String(),
          );
          if (stored != null) yield stored;
        } catch (e, st) {
          developer.log(
            'Error processing incoming community message: $e',
            name: _logName,
            error: e,
            stackTrace: st,
          );
        }
      }
    } finally {
      refreshTimer.cancel();
    }
  }

  /// Get group chat history
  ///
  /// [communityId] - Community/club ID
  ///
  /// Returns list of decrypted messages, most recent first
  Future<List<CommunityChatMessage>> getGroupChatHistory(
      String communityId) async {
    try {
      final chatId = _generateChatId(communityId);
      final box = GetStorage(_chatStoreName);
      final List<dynamic> raw =
          box.read<List<dynamic>>('community_chat_$chatId') ?? [];

      final messages = raw
          .map((e) => CommunityChatMessage.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();

      // Sort most recent first
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting group chat history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get user's community chats list
  ///
  /// [userId] - User's ID
  /// [communities] - List of communities user is a member of
  ///
  /// Returns list of chat previews, sorted by most recent message
  Future<List<CommunityChatPreview>> getUserCommunitiesChatList(
    String userId,
    List<Community> communities,
  ) async {
    try {
      final previews = <CommunityChatPreview>[];

      for (final community in communities) {
        final history = await getGroupChatHistory(community.id);

        if (history.isEmpty) {
          // No messages yet, still include in list
          previews.add(CommunityChatPreview(
            communityId: community.id,
            communityName: community.name,
            communityDescription: community.description,
            memberCount: community.memberCount,
            isClub: false, // Would need to check if it's a Club
          ));
          continue;
        }

        // Get last message
        final lastMessage = history.first;

        // Decrypt last message for preview (first 50 chars)
        String? preview;
        try {
          final decrypted =
              await getDecryptedMessage(lastMessage, community.id);
          preview = decrypted.length > 50
              ? '${decrypted.substring(0, 50)}...'
              : decrypted;
        } catch (e) {
          preview = '[Encrypted message]';
        }

        previews.add(CommunityChatPreview(
          communityId: community.id,
          communityName: community.name,
          communityDescription: community.description,
          lastMessagePreview: preview,
          lastMessageTime: lastMessage.timestamp,
          lastSenderName:
              lastMessage.senderId, // Would need to lookup user name
          memberCount: community.memberCount,
          isClub: false, // Would need to check if it's a Club
        ));
      }

      // Sort by most recent message
      previews.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return previews;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user communities chat list: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Add member to chat (when they join community)
  ///
  /// [communityId] - Community/club ID
  /// [userId] - User ID to add
  ///
  /// Note: In Option A (Shared Group Key), all members automatically have access
  /// since they all use the same key. This method is for future compatibility.
  Future<void> addMemberToChat(String communityId, String userId) async {
    try {
      developer.log('Adding member $userId to community chat $communityId',
          name: _logName);

      // In Option A, members automatically have access via shared key
      // This method is a placeholder for future upgrade options
      // where individual key management might be needed

      developer.log('✅ Member added (shared key access)', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error adding member to chat: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Remove member from chat (when they leave community)
  ///
  /// [communityId] - Community/club ID
  /// [userId] - User ID to remove
  ///
  /// Note: In Option A (Shared Group Key), removing a member doesn't revoke access
  /// since they still have the key. This method is for future compatibility.
  Future<void> removeMemberFromChat(String communityId, String userId) async {
    try {
      developer.log('Removing member $userId from community chat $communityId',
          name: _logName);

      // In Option A, members retain access via shared key
      // This method is a placeholder for future upgrade options
      // where individual key revocation might be needed

      developer.log(
          '✅ Member removed (note: shared key access retained in Option A)',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error removing member from chat: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get decrypted message content
  ///
  /// [message] - Encrypted message
  /// [communityId] - Community ID (for key lookup)
  ///
  /// Returns decrypted message text
  Future<String> getDecryptedMessage(
    CommunityChatMessage message,
    String communityId,
  ) async {
    try {
      return await _decryptGroupMessage(message.encryptedContent, communityId);
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return '[Message decryption failed]';
    }
  }

  // ========================================================================
  // PRIVATE METHODS - ENCRYPTION
  // ========================================================================

  // Note: For Option A (Shared Group Key), we use communityId as recipientId
  // in the encryption service. This ensures all members use the same key.
  // The encryption service manages the key internally.

  /// Encrypt group message with shared group key
  ///
  /// Uses communityId as recipientId in encryption service.
  /// All members use the same communityId, ensuring shared key access.
  Future<EncryptedMessage> _encryptGroupMessage(
    String message,
    String communityId,
  ) async {
    try {
      // Use communityId as recipientId - encryption service will use same key for all
      // This achieves Option A (Shared Group Key) behavior
      return await _encryptionService.encrypt(message, 'group_$communityId');
    } catch (e, stackTrace) {
      developer.log(
        'Error encrypting group message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Decrypt group message with shared group key
  ///
  /// Uses communityId as recipientId in encryption service.
  /// All members use the same communityId, ensuring shared key access.
  Future<String> _decryptGroupMessage(
    EncryptedMessage encrypted,
    String communityId,
  ) async {
    try {
      // Use communityId as recipientId - same approach as encryption
      return await _encryptionService.decrypt(encrypted, 'group_$communityId');
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting group message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ========================================================================
  // PRIVATE METHODS - STORAGE
  // ========================================================================

  /// Generate chat ID from community ID
  String _generateChatId(String communityId) {
    return '$_chatIdPrefix$communityId';
  }

  /// Save message to storage
  Future<void> _saveMessage(CommunityChatMessage message) async {
    try {
      final box = GetStorage(_chatStoreName);
      final key = 'community_chat_${message.chatId}';
      final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];
      existing.add(message.toJson());
      await box.write(key, existing);
    } catch (e, stackTrace) {
      developer.log(
        'Error saving message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Legacy fanout path (Signal-per-recipient) removed in favor of sender keys.

  Future<void> _broadcastGroupMessageSenderKey({
    required String senderUserId,
    required Community community,
    required String plaintext,
    required String messageId,
  }) async {
    final realtime = _realtimeBackend;
    final atomicClock = _atomicClock;
    final agentIdService = _agentIdService;
    final senderKeyService = _senderKeyService;
    final store = _communityMessageStore;

    if (realtime == null ||
        atomicClock == null ||
        agentIdService == null ||
        senderKeyService == null ||
        store == null) {
      throw Exception('Community sender-key transport not available');
    }

    if (!community.isMember(senderUserId)) {
      throw Exception('User is not a member of this community');
    }

    final senderAgentId = await agentIdService.getUserAgentId(senderUserId);
    final atomicTimestamp = await atomicClock.getAtomicTimestamp();

    // Ensure sender key exists / is distributed (Signal shares are rare).
    final key = await senderKeyService.getOrEstablishKey(
      communityId: community.id,
      currentUserId: senderUserId,
      memberUserIds: community.memberIds,
    );

    final ciphertextBase64 = Aes256GcmFixedKeyCodec.encryptStringToBase64(
      key32: key.keyBytes32,
      plaintext: plaintext,
    );

    await store.putMessageBlob(
      messageId: messageId,
      communityId: community.id,
      senderUserId: senderUserId,
      senderAgentId: senderAgentId,
      keyId: key.keyId,
      algorithm: 'sender_key_aes256gcm_v1',
      ciphertextBase64: ciphertextBase64,
      sentAt: atomicTimestamp.serverTime,
    );

    await realtime.connect();

    // Single-stream event (one insert). Members receive via RLS-gated subscription.
    await realtime.sendMessage(
      '$_communityStreamChannelPrefix${community.id}',
      RealtimeMessage(
        id: messageId,
        senderId: senderUserId,
        content: messageId,
        type: 'community_event',
        timestamp: atomicTimestamp.serverTime,
        metadata: <String, dynamic>{
          'kind': 'community_event_v1',
          'sender_user_id': senderUserId,
        },
      ),
    );
  }

  Future<CommunityChatMessage?> _storeReceivedGroupMessage({
    required String messageId,
    required String communityId,
    required String senderUserId,
    required String plaintext,
    String? sentAtIso,
  }) async {
    try {
      final chatId = _generateChatId(communityId);
      final box = GetStorage(_chatStoreName);
      final key = 'community_chat_$chatId';
      final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];

      // De-dupe: if we already stored this message ID, do nothing.
      final alreadyExists =
          existing.any((e) => (e as Map)['messageId'] == messageId);
      if (alreadyExists) return null;

      final timestamp = sentAtIso != null
          ? DateTime.tryParse(sentAtIso) ?? DateTime.now()
          : DateTime.now();

      final encryptedAtRest =
          await _encryptGroupMessage(plaintext, communityId);

      final chatMessage = CommunityChatMessage(
        messageId: messageId,
        chatId: chatId,
        communityId: communityId,
        senderId: senderUserId,
        encryptedContent: encryptedAtRest,
        timestamp: timestamp,
      );

      existing.add(chatMessage.toJson());
      await box.write(key, existing);
      return chatMessage;
    } catch (e, st) {
      developer.log(
        'Error storing received community message: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

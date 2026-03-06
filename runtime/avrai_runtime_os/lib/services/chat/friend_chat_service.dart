import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai2ai/models/friend_chat_message.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:uuid/uuid.dart';

/// FriendChatService
///
/// Service for 1-on-1 encrypted friend chats.
/// All messages are encrypted with AES-256-GCM before storage.
///
/// Philosophy: "Doors, not badges" - Authentic connections through secure communication.
/// Privacy: All messages encrypted on-device, never transmitted unencrypted.
///
/// Phase 2.2: Friend Chat Service
class FriendChatService {
  static const String _logName = 'FriendChatService';
  static const String _chatStoreName = 'friend_chat_messages';
  static const String _chatIdPrefix = 'friend_chat_';
  static const String _dmMailboxChannelPrefix = 'dm_mailbox:';
  static const String _outboxStoreName = 'friend_chat_outbox';

  final MessageEncryptionService _encryptionService;
  final AgentIdService? _agentIdService;
  final RealtimeBackend? _realtimeBackend;
  final AtomicClockService? _atomicClock;
  final DmMessageStore? _dmStore;

  FriendChatService({
    MessageEncryptionService? encryptionService,
    AgentIdService? agentIdService,
    RealtimeBackend? realtimeBackend,
    AtomicClockService? atomicClock,
    DmMessageStore? dmStore,
  })  : _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _agentIdService = agentIdService,
        _realtimeBackend = realtimeBackend,
        _atomicClock = atomicClock,
        _dmStore = dmStore;

  /// Send an encrypted message to a friend
  ///
  /// [userId] - Sender's user ID
  /// [friendId] - Recipient's user ID
  /// [message] - Plaintext message to send
  ///
  /// Returns the created FriendChatMessage
  Future<FriendChatMessage> sendMessage(
    String userId,
    String friendId,
    String message,
  ) async {
    try {
      developer.log('Sending message from $userId to $friendId',
          name: _logName);

      // Generate consistent chat ID (sorted IDs for bidirectional chats)
      final chatId = _generateChatId(userId, friendId);

      // Encrypt message
      final encrypted = await _encryptionService.encrypt(message, chatId);

      // Create message
      final chatMessage = FriendChatMessage(
        messageId: const Uuid().v4(),
        chatId: chatId,
        senderId: userId,
        recipientId: friendId,
        encryptedContent: encrypted,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Store message
      await _saveMessage(chatMessage);

      developer.log('✅ Message sent and saved: ${chatMessage.messageId}',
          name: _logName);
      return chatMessage;
    } catch (e, stackTrace) {
      developer.log(
        'Error sending message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Send a direct message and broadcast it over realtime using Signal Protocol.
  ///
  /// This is the "real" user-to-user DM transport:
  /// - Locally: stores message encrypted-at-rest (Sembast, AES fallback).
  /// - In transit: encrypts with Signal Protocol (recipient agentId) and broadcasts
  ///   to the recipient's inbox channel via RealtimeBackend.
  ///
  /// Throws if realtime dependencies are not available or if Signal encryption
  /// cannot be used (we do NOT silently downgrade to AES for transport).
  Future<FriendChatMessage> sendMessageOverNetwork(
    String userId,
    String friendId,
    String message,
  ) async {
    // Always store locally first (so UI/history works offline).
    final stored = await sendMessage(userId, friendId, message);
    try {
      await _broadcastDirectMessage(
        userId: userId,
        friendId: friendId,
        message: message,
        messageId: stored.messageId,
      );
    } catch (e, st) {
      developer.log(
        'Network send failed; queueing DM for retry: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _enqueueOutbox(
        messageId: stored.messageId,
        userId: userId,
        friendId: friendId,
      );
    }
    return stored;
  }

  /// Subscribe to incoming direct messages for a user (optionally filtered to one friend).
  ///
  /// Decrypts using Signal Protocol and stores the plaintext locally (encrypted-at-rest).
  Stream<FriendChatMessage> subscribeToIncomingMessages({
    required String userId,
    String? friendId,
  }) async* {
    final realtime = _realtimeBackend;
    final dmStore = _dmStore;
    if (realtime == null) {
      developer.log(
        'Realtime DM subscription unavailable (missing RealtimeBackend)',
        name: _logName,
      );
      return;
    }
    if (dmStore == null) {
      developer.log(
        'DM mailbox subscription unavailable (missing DmMessageStore)',
        name: _logName,
      );
      return;
    }

    await realtime.connect();
    await _flushOutboxBestEffort();

    final inboxChannel = '$_dmMailboxChannelPrefix$userId';

    await for (final msg in realtime.subscribeToMessages(inboxChannel)) {
      try {
        // Payloadless notify: messageId is in msg.id (and msg.content for safety).
        final messageId = msg.id.isNotEmpty ? msg.id : msg.content;
        if (messageId.isEmpty) continue;

        final blob = await dmStore.getDmBlob(messageId);
        if (blob == null) continue;
        if (blob.toUserId != userId) continue;
        if (friendId != null && blob.fromUserId != friendId) continue;

        // Require Signal Protocol for DM transport.
        if (blob.encryptionType != EncryptionType.signalProtocol) {
          developer.log(
            'Rejected incoming DM (non-Signal encryption): ${blob.encryptionType}',
            name: _logName,
          );
          continue;
        }

        final plaintext = await _encryptionService.decrypt(
          blob.toEncryptedMessage(),
          blob.fromUserId,
        );

        final stored = await _storeReceivedMessage(
          messageId: messageId,
          senderUserId: blob.fromUserId,
          recipientUserId: userId,
          plaintext: plaintext,
          sentAtIso: blob.sentAt.toIso8601String(),
        );

        if (stored != null) {
          yield stored;
        }
      } catch (e, st) {
        developer.log(
          'Error processing incoming DM: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Get conversation history between two users
  ///
  /// [userId] - Current user's ID
  /// [friendId] - Friend's user ID
  ///
  /// Returns list of messages, most recent first
  Future<List<FriendChatMessage>> getConversationHistory(
    String userId,
    String friendId,
  ) async {
    try {
      final chatId = _generateChatId(userId, friendId);
      final box = GetStorage(_chatStoreName);
      final List<dynamic> raw =
          box.read<List<dynamic>>('friend_chat_$chatId') ?? [];

      final messages = raw
          .map((e) =>
              FriendChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // Sort most recent first
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting conversation history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get list of friend conversations for a user
  ///
  /// [userId] - User's ID
  /// [friendIds] - List of friend IDs to get conversations for
  ///
  /// Returns list of chat previews, sorted by most recent message
  Future<List<FriendChatPreview>> getFriendsChatList(
    String userId,
    List<String> friendIds, {
    Map<String, String>? friendNames,
    Map<String, String>? friendPhotoUrls,
    Map<String, bool>? friendOnlineStatus,
  }) async {
    try {
      final previews = <FriendChatPreview>[];

      for (final friendId in friendIds) {
        final history = await getConversationHistory(userId, friendId);

        if (history.isEmpty) {
          // No conversation yet, skip
          continue;
        }

        // Get last message
        final lastMessage = history.first;

        // Decrypt last message for preview (first 50 chars)
        String? preview;
        try {
          final decrypted =
              await getDecryptedMessage(lastMessage, userId, friendId);
          preview = decrypted.length > 50
              ? '${decrypted.substring(0, 50)}...'
              : decrypted;
        } catch (e) {
          preview = '[Encrypted message]';
        }

        // Count unread messages
        final unreadCount = history
            .where((msg) => !msg.isRead && msg.recipientId == userId)
            .length;

        previews.add(FriendChatPreview(
          friendId: friendId,
          friendName: friendNames?[friendId] ?? friendId,
          friendPhotoUrl: friendPhotoUrls?[friendId],
          lastMessagePreview: preview,
          lastMessageTime: lastMessage.timestamp,
          unreadCount: unreadCount,
          isOnline: friendOnlineStatus?[friendId] ?? false,
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
        'Error getting friends chat list: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Mark messages as read
  ///
  /// [userId] - User who read the messages
  /// [friendId] - Friend whose messages were read
  ///
  /// Returns number of messages marked as read
  Future<int> markAsRead(String userId, String friendId) async {
    try {
      final chatId = _generateChatId(userId, friendId);
      final box = GetStorage(_chatStoreName);
      final key = 'friend_chat_$chatId';
      final List<dynamic> raw = box.read<List<dynamic>>(key) ?? [];

      int markedCount = 0;
      final updated = raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        if (map['senderId'] == friendId &&
            map['recipientId'] == userId &&
            map['isRead'] == false) {
          map['isRead'] = true;
          markedCount++;
        }
        return map;
      }).toList();

      if (markedCount > 0) {
        await box.write(key, updated);
      }

      developer.log('✅ Marked $markedCount messages as read', name: _logName);
      return markedCount;
    } catch (e, stackTrace) {
      developer.log(
        'Error marking messages as read: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Get decrypted message content
  ///
  /// [message] - Encrypted message
  /// [userId] - Current user's ID (for chat ID generation)
  /// [friendId] - Friend's ID (for chat ID generation)
  ///
  /// Returns decrypted message text
  Future<String> getDecryptedMessage(
    FriendChatMessage message,
    String userId,
    String friendId,
  ) async {
    try {
      final chatId = _generateChatId(userId, friendId);
      return await _encryptionService.decrypt(message.encryptedContent, chatId);
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

  /// Get total unread count across all friend chats
  ///
  /// [userId] - User's ID
  /// [friendIds] - List of friend IDs
  ///
  /// Returns total number of unread messages
  Future<int> getTotalUnreadCount(String userId, List<String> friendIds) async {
    try {
      int totalUnread = 0;

      for (final friendId in friendIds) {
        final history = await getConversationHistory(userId, friendId);
        totalUnread += history
            .where((msg) => !msg.isRead && msg.recipientId == userId)
            .length;
      }

      return totalUnread;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting total unread count: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  // ========================================================================
  // PRIVATE METHODS
  // ========================================================================

  /// Generate consistent chat ID from two user IDs
  /// Sorts IDs to ensure same chat ID regardless of order
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '$_chatIdPrefix${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Save message to storage
  Future<void> _saveMessage(FriendChatMessage message) async {
    try {
      final box = GetStorage(_chatStoreName);
      final key = 'friend_chat_${message.chatId}';
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

  Future<void> _broadcastDirectMessage({
    required String userId,
    required String friendId,
    required String message,
    required String messageId,
  }) async {
    final agentIdService = _agentIdService;
    final atomicClock = _atomicClock;
    final dmStore = _dmStore;

    if (agentIdService == null || atomicClock == null || dmStore == null) {
      throw Exception(
        'Direct message transport not available (missing AgentIdService/AtomicClockService/DmMessageStore)',
      );
    }

    final senderAgentId = await agentIdService.getUserAgentId(userId);
    final recipientAgentId = await agentIdService.getUserAgentId(friendId);

    // Signal transport address for user-to-user messaging is the recipient's auth user id.
    final encrypted = await _encryptionService.encrypt(message, friendId);
    if (encrypted.encryptionType != EncryptionType.signalProtocol) {
      throw Exception(
        'Signal Protocol is required for DM transport. Got ${encrypted.encryptionType.name}. '
        'Make sure Signal is initialized and recipient has published a prekey bundle.',
      );
    }

    final atomicTimestamp = await atomicClock.getAtomicTimestamp();

    // 1) Server-authoritative enqueue: writes blob + notification atomically.
    await dmStore.enqueueDm(
      messageId: messageId,
      fromUserId: userId,
      toUserId: friendId,
      senderAgentId: senderAgentId,
      recipientAgentId: recipientAgentId,
      encrypted: encrypted,
      sentAt: atomicTimestamp.serverTime,
    );
  }

  Future<void> _enqueueOutbox({
    required String messageId,
    required String userId,
    required String friendId,
  }) async {
    final box = GetStorage(_outboxStoreName);
    final List<dynamic> pending =
        box.read<List<dynamic>>('outbox_pending') ?? [];
    pending.add(<String, dynamic>{
      'messageId': messageId,
      'userId': userId,
      'friendId': friendId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await box.write('outbox_pending', pending);
  }

  Future<void> _flushOutboxBestEffort() async {
    final realtime = _realtimeBackend;
    if (realtime == null) return;

    try {
      final outboxBox = GetStorage(_outboxStoreName);
      final List<dynamic> pending =
          outboxBox.read<List<dynamic>>('outbox_pending') ?? [];
      if (pending.isEmpty) return;

      final chatBox = GetStorage(_chatStoreName);
      final remaining = <Map<String, dynamic>>[];

      for (final entry in pending) {
        final value = Map<String, dynamic>.from(entry as Map);
        final messageId = value['messageId'] as String?;
        final userId = value['userId'] as String?;
        final friendId = value['friendId'] as String?;
        if (userId == null || friendId == null || messageId == null) continue;

        // Load local message and re-decrypt plaintext for transport encryption.
        final chatId = _generateChatId(userId, friendId);
        final key = 'friend_chat_$chatId';
        final List<dynamic> messages = chatBox.read<List<dynamic>>(key) ?? [];
        final storedMap = messages
            .cast<Map>()
            .where((m) => m['messageId'] == messageId)
            .firstOrNull;

        if (storedMap == null) {
          // Message no longer exists, skip
          continue;
        }

        final msg =
            FriendChatMessage.fromJson(Map<String, dynamic>.from(storedMap));
        final plaintext = await getDecryptedMessage(msg, userId, friendId);

        try {
          await _broadcastDirectMessage(
            userId: userId,
            friendId: friendId,
            message: plaintext,
            messageId: messageId,
          );
        } catch (_) {
          remaining.add(value);
          continue;
        }
      }

      await outboxBox.write('outbox_pending', remaining);
    } catch (e, st) {
      developer.log(
        'Outbox flush failed (best-effort): $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<FriendChatMessage?> _storeReceivedMessage({
    required String messageId,
    required String senderUserId,
    required String recipientUserId,
    required String plaintext,
    String? sentAtIso,
  }) async {
    try {
      final chatId = _generateChatId(senderUserId, recipientUserId);
      final box = GetStorage(_chatStoreName);
      final key = 'friend_chat_$chatId';
      final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];

      // De-dupe: if we already stored this message ID, do nothing.
      final alreadyExists =
          existing.any((e) => (e as Map)['messageId'] == messageId);
      if (alreadyExists) return null;

      final timestamp = sentAtIso != null
          ? DateTime.tryParse(sentAtIso) ?? DateTime.now()
          : DateTime.now();

      // Encrypt-at-rest (chatId-scoped; Hybrid will fall back to AES here).
      final encryptedAtRest =
          await _encryptionService.encrypt(plaintext, chatId);

      final chatMessage = FriendChatMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: senderUserId,
        recipientId: recipientUserId,
        encryptedContent: encryptedAtRest,
        timestamp: timestamp,
        isRead: false,
      );

      existing.add(chatMessage.toJson());
      await box.write(key, existing);
      return chatMessage;
    } catch (e, st) {
      developer.log(
        'Error storing received DM: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai2ai/models/friend_chat_message.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_learning_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_route_planner.dart';
import 'package:avrai_runtime_os/services/messaging/bham_transport_policy.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
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
  static const String _dmReceiptChannelPrefix = 'dm_receipts:';
  static const String _outboxStoreName = 'friend_chat_outbox';
  static const String _routeReceiptMetadataKey = 'transport_route_receipt';

  final MessageEncryptionService _encryptionService;
  final AgentIdService? _agentIdService;
  final RealtimeBackend? _realtimeBackend;
  final AtomicClockService? _atomicClock;
  final DmMessageStore? _dmStore;
  final HeadlessAvraiOsHost? _headlessOsHost;
  final BhamRoutePlanner? _routePlanner;
  final BhamRouteLearningService? _routeLearningService;
  final BhamTransportPolicy? _transportPolicy;
  final HumanLanguageBoundaryReviewLane _humanLanguageBoundaryReviewLane;
  final Ai2AiChatEventIntakeService? _ai2aiChatEventIntakeService;
  final Map<String, StreamSubscription<RealtimeMessage>> _receiptSubscriptions =
      <String, StreamSubscription<RealtimeMessage>>{};

  FriendChatService({
    MessageEncryptionService? encryptionService,
    AgentIdService? agentIdService,
    RealtimeBackend? realtimeBackend,
    AtomicClockService? atomicClock,
    DmMessageStore? dmStore,
    HeadlessAvraiOsHost? headlessOsHost,
    BhamRoutePlanner? routePlanner,
    BhamRouteLearningService? routeLearningService,
    BhamTransportPolicy? transportPolicy,
    HumanLanguageBoundaryReviewLane? humanLanguageBoundaryReviewLane,
    Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
  })  : _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _agentIdService = agentIdService,
        _realtimeBackend = realtimeBackend,
        _atomicClock = atomicClock,
        _dmStore = dmStore,
        _headlessOsHost = headlessOsHost,
        _routePlanner = routePlanner,
        _routeLearningService = routeLearningService,
        _transportPolicy = transportPolicy,
        _humanLanguageBoundaryReviewLane = humanLanguageBoundaryReviewLane ??
            HumanLanguageBoundaryReviewLane(),
        _ai2aiChatEventIntakeService = ai2aiChatEventIntakeService;

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

      final review = await _reviewDirectMessage(
        userId: userId,
        friendId: friendId,
        message: message,
        egressRequested: false,
      );
      if (!review.transcriptStorageAllowed) {
        throw HumanLanguageBoundaryViolationException(
          operation: 'friend_chat_local_store',
          decision: review.turn.boundary,
        );
      }

      final chatMessage = await _storeOutboundDirectMessage(
        userId: userId,
        friendId: friendId,
        plaintext: review.transcriptText,
        metadata: review.toMetadata(),
      );

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
    final result = await sendMessageOverNetworkWithKernelContext(
      userId,
      friendId,
      message,
    );
    return result.message;
  }

  Future<FriendChatSendResult> sendMessageOverNetworkWithKernelContext(
    String userId,
    String friendId,
    String message,
  ) async {
    final review = await _reviewDirectMessage(
      userId: userId,
      friendId: friendId,
      message: message,
      egressRequested: true,
    );
    if (!review.transcriptStorageAllowed || !review.egressAllowed) {
      throw HumanLanguageBoundaryViolationException(
        operation: 'friend_chat_network_send',
        decision: review.turn.boundary,
      );
    }

    final stored = await _storeOutboundDirectMessage(
      userId: userId,
      friendId: friendId,
      plaintext: review.transcriptText,
      metadata: await _buildOutboundDirectMessageMetadata(
        userId: userId,
        plaintext: review.transcriptText,
        review: review,
      ),
    );
    await _ensureReceiptSubscription(userId);
    final routeReceipt = await _planDirectMessageRouteReceipt(
      messageId: stored.messageId,
    );
    var effectiveRouteReceipt = routeReceipt;
    var effectiveStored = await _updateStoredMessageRouteReceipt(
          chatId: stored.chatId,
          messageId: stored.messageId,
          routeReceipt: routeReceipt,
        ) ??
        _messageWithRouteReceipt(stored, routeReceipt);
    try {
      await _broadcastDirectMessage(
        userId: userId,
        friendId: friendId,
        message: review.transportText,
        messageId: stored.messageId,
      );
      effectiveRouteReceipt = _markCustodyAccepted(routeReceipt);
      effectiveStored = await _updateStoredMessageRouteReceipt(
            chatId: stored.chatId,
            messageId: stored.messageId,
            routeReceipt: effectiveRouteReceipt,
          ) ??
          _messageWithRouteReceipt(effectiveStored, effectiveRouteReceipt);
      await _recordRouteOutcome(effectiveRouteReceipt, success: true);
      await _ingestDirectMessageForLearning(
        localUserId: userId,
        senderUserId: userId,
        counterpartUserId: friendId,
        messageId: effectiveStored.messageId,
        plaintext: review.transportText,
        occurredAt: effectiveStored.timestamp,
        direction: Ai2AiChatFlowDirection.outbound,
        metadata: effectiveStored.metadata,
        routeReceipt: effectiveRouteReceipt,
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
      await _recordRouteOutcome(routeReceipt, success: false);
    }
    final kernelResult = await _emitHeadlessDirectMessageLifecycle(
      userId: userId,
      friendId: friendId,
      message: review.transportText,
      storedMessage: stored,
      routeReceipt: effectiveRouteReceipt,
      boundaryReview: review,
    );
    return FriendChatSendResult(
      message: effectiveStored,
      realityKernelFusionInput: kernelResult?.realityKernelFusionInput,
      governanceReport: kernelResult?.governanceReport,
      routeReceipt: effectiveRouteReceipt,
    );
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

    await _ensureReceiptSubscription(userId);
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

        final storeResult = await _storeReceivedMessage(
          messageId: messageId,
          senderUserId: blob.fromUserId,
          recipientUserId: userId,
          plaintext: plaintext,
          sentAtIso: blob.sentAt.toIso8601String(),
          metadata: await _buildAi2AiLearningMetadata(
            localUserId: userId,
            sourceUserId: blob.fromUserId,
            plaintext: plaintext,
            chatType: 'friend',
            channel: 'friend_chat',
          ),
        );

        if (storeResult.shouldConsumeTransport) {
          unawaited(_consumeDmTransportBlobBestEffort(
            messageId: messageId,
            recipientUserId: userId,
          ));
        }

        final stored = storeResult.message;
        if (stored != null) {
          await _ingestDirectMessageForLearning(
            localUserId: userId,
            senderUserId: blob.fromUserId,
            counterpartUserId: blob.fromUserId,
            messageId: stored.messageId,
            plaintext: plaintext,
            occurredAt: stored.timestamp,
            direction: Ai2AiChatFlowDirection.inbound,
            metadata: stored.metadata,
          );
          await _sendDeliveryReceipt(
            messageId: messageId,
            senderUserId: blob.fromUserId,
            recipientUserId: userId,
            deliveredByUserId: userId,
          );
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
      final readMessageIds = <String>[];
      final updated = raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        if (map['senderId'] == friendId &&
            map['recipientId'] == userId &&
            map['isRead'] == false) {
          map['isRead'] = true;
          markedCount++;
          final messageId = map['messageId']?.toString();
          if (messageId != null && messageId.isNotEmpty) {
            readMessageIds.add(messageId);
          }
        }
        return map;
      }).toList();

      if (markedCount > 0) {
        await box.write(key, updated);
        for (final messageId in readMessageIds) {
          await _sendReadReceipt(
            messageId: messageId,
            senderUserId: friendId,
            recipientUserId: userId,
            readByUserId: userId,
          );
        }
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

  Future<FriendChatMessage> _storeOutboundDirectMessage({
    required String userId,
    required String friendId,
    required String plaintext,
    required Map<String, dynamic> metadata,
  }) async {
    final chatId = _generateChatId(userId, friendId);
    final encrypted = await _encryptionService.encrypt(plaintext, chatId);
    final chatMessage = FriendChatMessage(
      messageId: const Uuid().v4(),
      chatId: chatId,
      senderId: userId,
      recipientId: friendId,
      encryptedContent: encrypted,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: metadata,
    );
    await _saveMessage(chatMessage);
    return chatMessage;
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

  Future<FriendChatSendResult?> _emitHeadlessDirectMessageLifecycle({
    required String userId,
    required String friendId,
    required String message,
    required FriendChatMessage storedMessage,
    required TransportRouteReceipt routeReceipt,
    required HumanLanguageBoundaryReview boundaryReview,
  }) async {
    final host = _headlessOsHost;
    if (host == null) {
      return null;
    }

    try {
      await host.start();
      final now = DateTime.now().toUtc();
      final envelope = KernelEventEnvelope(
        eventId: 'friend_chat:$userId:$friendId:${now.microsecondsSinceEpoch}',
        userId: userId,
        agentId: await _resolveActorAgentId(userId),
        occurredAtUtc: now,
        sourceSystem: 'friend_chat_service',
        eventType: 'direct_message_sent',
        actionType: 'send_direct_message',
        entityId: friendId,
        entityType: 'friend_chat',
        routeReceipt: routeReceipt,
        context: <String, dynamic>{
          'message_id': storedMessage.messageId,
          'message_length': message.length,
          'language_intent':
              boundaryReview.turn.interpretation.intent.toWireValue(),
          'boundary_disposition':
              boundaryReview.turn.boundary.disposition.toWireValue(),
          'boundary_reason_codes': boundaryReview.turn.boundary.reasonCodes,
          'egress_purpose':
              boundaryReview.turn.boundary.egressPurpose.toWireValue(),
        },
        predictionContext: const <String, dynamic>{
          'transport': 'signal_protocol',
          'chat_scope': 'direct',
        },
        runtimeContext: const <String, dynamic>{
          'execution_path': 'friend_chat_service.sendMessageOverNetwork',
          'workflow_stage': 'direct_message_send',
        },
      );
      final runtimeBundle = await host.resolveRuntimeExecution(
        envelope: envelope,
      );
      final whyRequest = KernelWhyRequest(
        bundle: runtimeBundle.withoutWhy(),
        goal: 'deliver_direct_message',
        predictedOutcome: 'message_visible_to_friend',
        predictedConfidence: 0.76,
        actualOutcome: 'message_sent',
        actualOutcomeScore: 1.0,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'message_length',
            weight: (message.length / 120.0).clamp(0.0, 1.0),
            source: 'chat',
            durable: false,
          ),
        ],
        policySignals: const <WhySignal>[
          WhySignal(
            label: 'locality_in_where',
            weight: 0.4,
            source: 'policy',
            durable: true,
          ),
        ],
      );
      final modelTruth = await host.buildModelTruth(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      final governance = await host.inspectGovernance(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      return FriendChatSendResult(
        message: storedMessage,
        realityKernelFusionInput: modelTruth,
        governanceReport: governance,
      );
    } catch (e, st) {
      developer.log(
        'Headless OS direct chat lifecycle failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<String?> _resolveActorAgentId(String userId) async {
    final service = _agentIdService;
    if (service == null) {
      return null;
    }
    try {
      return await service.getUserAgentId(userId);
    } catch (_) {
      return null;
    }
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
          final updatedMessage = await _markStoredMessageCustodyAccepted(
            chatId: chatId,
            messageId: messageId,
          );
          final updatedReceipt = updatedMessage == null
              ? null
              : _routeReceiptFromMetadata(updatedMessage.metadata);
          if (updatedReceipt != null) {
            await _recordRouteOutcome(updatedReceipt, success: true);
          }
          await _ingestDirectMessageForLearning(
            localUserId: userId,
            senderUserId: userId,
            counterpartUserId: friendId,
            messageId: messageId,
            plaintext: plaintext,
            occurredAt: updatedMessage?.timestamp ?? msg.timestamp,
            direction: Ai2AiChatFlowDirection.outbound,
            metadata: updatedMessage?.metadata ?? msg.metadata,
            routeReceipt: updatedReceipt,
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

  Future<_StoredDirectMessageResult> _storeReceivedMessage({
    required String messageId,
    required String senderUserId,
    required String recipientUserId,
    required String plaintext,
    String? sentAtIso,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final chatId = _generateChatId(senderUserId, recipientUserId);
      final box = GetStorage(_chatStoreName);
      final key = 'friend_chat_$chatId';
      final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];

      // De-dupe: if we already stored this message ID, do nothing.
      final alreadyExists =
          existing.any((e) => (e as Map)['messageId'] == messageId);
      if (alreadyExists) {
        return const _StoredDirectMessageResult(
          status: _StoredMessageStatus.duplicate,
        );
      }

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
        metadata: metadata,
      );

      existing.add(chatMessage.toJson());
      await box.write(key, existing);
      return _StoredDirectMessageResult(
        status: _StoredMessageStatus.stored,
        message: chatMessage,
      );
    } catch (e, st) {
      developer.log(
        'Error storing received DM: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const _StoredDirectMessageResult(
        status: _StoredMessageStatus.failed,
      );
    }
  }

  Future<void> _consumeDmTransportBlobBestEffort({
    required String messageId,
    required String recipientUserId,
  }) async {
    final dmStore = _dmStore;
    if (dmStore == null) {
      return;
    }
    try {
      await dmStore.consumeDmBlob(
        messageId: messageId,
        toUserId: recipientUserId,
      );
    } catch (e, st) {
      developer.log(
        'Failed to consume DM transport blob after local persistence: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<TransportRouteReceipt> _planDirectMessageRouteReceipt({
    required String messageId,
  }) async {
    final planner = _routePlanner;
    if (planner == null) {
      return TransportRouteReceiptCompatibilityTranslator.buildQueuedFallback(
        channel: 'friend_chat',
        recordedAtUtc: DateTime.now().toUtc(),
      );
    }
    final ttl =
        _transportPolicy?.ttlForThreadKind(ChatThreadKind.matchedDirect) ??
            const Duration(hours: 24);
    final expiresAtUtc = DateTime.now().toUtc().add(ttl);
    final routePlan = await planner.planRoutes(
      messageId: messageId,
      threadKind: ChatThreadKind.matchedDirect,
      expiresAtUtc: expiresAtUtc,
      availability: <TransportMode, bool>{
        TransportMode.ble: true,
        TransportMode.localWifi: true,
        TransportMode.nearbyRelay: true,
        TransportMode.wormhole: true,
        TransportMode.cloudAssist: _realtimeBackend != null,
      },
      exploratory: true,
    );
    return planner.markReleased(
      receipt: planner.buildQueuedReceipt(
        routePlan: routePlan,
        channel: 'friend_chat',
        expiresAtUtc: expiresAtUtc,
      ),
      attemptedRoutes: routePlan.candidateRoutes.take(3).toList(),
    );
  }

  Future<HumanLanguageBoundaryReview> _reviewDirectMessage({
    required String userId,
    required String friendId,
    required String message,
    required bool egressRequested,
  }) async {
    final actorAgentId =
        await _resolveActorAgentId(userId) ?? 'agt_friend_chat_$userId';
    return _humanLanguageBoundaryReviewLane.reviewOutboundText(
      actorAgentId: actorAgentId,
      rawText: message,
      egressPurpose: BoundaryEgressPurpose.directMessage,
      egressRequested: egressRequested,
      userId: userId,
      chatType: 'friend',
      surface: 'chat',
      channel: 'friend_chat',
      privacyMode: BoundaryPrivacyMode.localSovereign,
    );
  }

  Future<Map<String, dynamic>> _buildOutboundDirectMessageMetadata({
    required String userId,
    required String plaintext,
    required HumanLanguageBoundaryReview review,
  }) async {
    return _mergeMetadata(
      review.toMetadata(),
      await _buildAi2AiLearningMetadata(
        localUserId: userId,
        sourceUserId: userId,
        plaintext: plaintext,
        chatType: 'friend',
        channel: 'friend_chat',
      ),
    );
  }

  Future<Map<String, dynamic>> _buildAi2AiLearningMetadata({
    required String localUserId,
    required String sourceUserId,
    required String plaintext,
    required String chatType,
    required String channel,
  }) async {
    final intake = _ai2aiChatEventIntakeService;
    if (intake == null) {
      return const <String, dynamic>{};
    }
    return intake.buildLearningMetadata(
      localUserId: localUserId,
      sourceUserId: sourceUserId,
      rawText: plaintext,
      chatType: chatType,
      channel: channel,
    );
  }

  Future<void> _ingestDirectMessageForLearning({
    required String localUserId,
    required String senderUserId,
    required String counterpartUserId,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    required Ai2AiChatFlowDirection direction,
    Map<String, dynamic>? metadata,
    TransportRouteReceipt? routeReceipt,
  }) async {
    final intake = _ai2aiChatEventIntakeService;
    if (intake == null) {
      return;
    }
    await intake.ingestDirectMessage(
      localUserId: localUserId,
      senderUserId: senderUserId,
      counterpartUserId: counterpartUserId,
      messageId: messageId,
      plaintext: plaintext,
      occurredAt: occurredAt,
      direction: direction,
      metadata: metadata,
      routeReceipt: routeReceipt,
    );
  }

  Map<String, dynamic> _mergeMetadata(
    Map<String, dynamic>? base,
    Map<String, dynamic>? additions,
  ) {
    final merged = Map<String, dynamic>.from(base ?? const <String, dynamic>{});
    if (additions != null) {
      merged.addAll(additions);
    }
    return merged;
  }

  TransportRouteReceipt _markCustodyAccepted(TransportRouteReceipt receipt) {
    final planner = _routePlanner;
    if (planner == null) {
      return receipt;
    }
    final winningRoute = receipt.attemptedRoutes.isNotEmpty
        ? receipt.attemptedRoutes.first
        : receipt.plannedRoutes.firstOrNull;
    if (winningRoute == null) {
      return receipt;
    }
    return planner.markCustodyAccepted(
      receipt: receipt,
      winningRoute: winningRoute,
      winningRouteReason: 'direct message accepted by transport',
      custodyAcceptedBy: winningRoute.metadata['peer_id']?.toString() ??
          winningRoute.mode.name,
    );
  }

  Future<void> _recordRouteOutcome(
    TransportRouteReceipt receipt, {
    required bool success,
  }) async {
    final learning = _routeLearningService;
    final winningRoute = receipt.winningRoute ??
        receipt.attemptedRoutes.firstOrNull ??
        receipt.plannedRoutes.firstOrNull;
    if (learning == null || winningRoute == null) {
      return;
    }
    await learning.recordSignal(
      RouteLearningSignal(
        messageId:
            receipt.metadata['message_id']?.toString() ?? receipt.receiptId,
        mode: winningRoute.mode,
        success: success,
        observedAtUtc: DateTime.now().toUtc(),
        latencyMs: winningRoute.estimatedLatencyMs,
      ),
    );
  }

  String _receiptChannelForUser(String userId) =>
      '$_dmReceiptChannelPrefix$userId';

  Future<void> _ensureReceiptSubscription(String userId) async {
    final realtime = _realtimeBackend;
    if (realtime == null || _receiptSubscriptions.containsKey(userId)) {
      return;
    }

    await realtime.connect();
    final subscription = realtime
        .subscribeToMessages(_receiptChannelForUser(userId))
        .listen((message) {
      unawaited(_handleReceiptMessage(currentUserId: userId, message: message));
    }, onError: (Object error, StackTrace stackTrace) {
      developer.log(
        'DM receipt subscription failed: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    });
    _receiptSubscriptions[userId] = subscription;
  }

  Future<void> _sendDeliveryReceipt({
    required String messageId,
    required String senderUserId,
    required String recipientUserId,
    required String deliveredByUserId,
  }) async {
    final realtime = _realtimeBackend;
    if (realtime == null) {
      return;
    }

    await realtime.connect();
    final timestamp = DateTime.now().toUtc();
    await realtime.sendMessage(
      _receiptChannelForUser(senderUserId),
      RealtimeMessage(
        id: messageId,
        senderId: deliveredByUserId,
        content: messageId,
        type: 'dm_receipt',
        timestamp: timestamp,
        metadata: <String, dynamic>{
          'kind': 'dm_delivery_receipt_v1',
          'message_id': messageId,
          'sender_user_id': senderUserId,
          'recipient_user_id': recipientUserId,
          'receipt_by_user_id': deliveredByUserId,
          'receipt_at_utc': timestamp.toIso8601String(),
        },
      ),
    );
  }

  Future<void> _sendReadReceipt({
    required String messageId,
    required String senderUserId,
    required String recipientUserId,
    required String readByUserId,
  }) async {
    final realtime = _realtimeBackend;
    if (realtime == null) {
      return;
    }

    await realtime.connect();
    final timestamp = DateTime.now().toUtc();
    await realtime.sendMessage(
      _receiptChannelForUser(senderUserId),
      RealtimeMessage(
        id: messageId,
        senderId: readByUserId,
        content: messageId,
        type: 'dm_receipt',
        timestamp: timestamp,
        metadata: <String, dynamic>{
          'kind': 'dm_read_receipt_v1',
          'message_id': messageId,
          'sender_user_id': senderUserId,
          'recipient_user_id': recipientUserId,
          'receipt_by_user_id': readByUserId,
          'receipt_at_utc': timestamp.toIso8601String(),
        },
      ),
    );
  }

  Future<void> _handleReceiptMessage({
    required String currentUserId,
    required RealtimeMessage message,
  }) async {
    final metadata = Map<String, dynamic>.from(message.metadata);
    final receiptKind = metadata['kind']?.toString();
    final messageId = metadata['message_id']?.toString() ??
        (message.id.isNotEmpty ? message.id : message.content);
    final senderUserId = metadata['sender_user_id']?.toString();
    final recipientUserId = metadata['recipient_user_id']?.toString();
    final receiptByUserId =
        metadata['receipt_by_user_id']?.toString() ?? message.senderId;
    if (receiptKind == null ||
        messageId.isEmpty ||
        senderUserId == null ||
        recipientUserId == null) {
      return;
    }

    final friendId =
        senderUserId == currentUserId ? recipientUserId : senderUserId;
    switch (receiptKind) {
      case 'dm_delivery_receipt_v1':
        await _advanceStoredOutgoingRouteReceipt(
          currentUserId: currentUserId,
          friendId: friendId,
          messageId: messageId,
          deliveredByUserId: receiptByUserId,
        );
        return;
      case 'dm_read_receipt_v1':
        await _advanceStoredOutgoingRouteReceipt(
          currentUserId: currentUserId,
          friendId: friendId,
          messageId: messageId,
          readByUserId: receiptByUserId,
        );
        return;
      default:
        return;
    }
  }

  Future<FriendChatMessage?> _advanceStoredOutgoingRouteReceipt({
    required String currentUserId,
    required String friendId,
    required String messageId,
    String? deliveredByUserId,
    String? readByUserId,
  }) {
    final chatId = _generateChatId(currentUserId, friendId);
    return _updateStoredMessage(
      chatId: chatId,
      messageId: messageId,
      transform: (message) {
        final routeReceipt = _routeReceiptFromMetadata(message.metadata);
        if (routeReceipt == null) {
          return message;
        }

        final updatedReceipt = readByUserId != null
            ? _markRead(routeReceipt, readByUserId: readByUserId)
            : _markDelivered(routeReceipt,
                deliveredByUserId: deliveredByUserId);
        return _messageWithRouteReceipt(
          message.copyWith(
              isRead: readByUserId != null ? true : message.isRead),
          updatedReceipt,
        );
      },
    );
  }

  Future<FriendChatMessage?> _markStoredMessageCustodyAccepted({
    required String chatId,
    required String messageId,
  }) {
    return _updateStoredMessage(
      chatId: chatId,
      messageId: messageId,
      transform: (message) {
        final routeReceipt = _routeReceiptFromMetadata(message.metadata);
        if (routeReceipt == null) {
          return message;
        }
        return _messageWithRouteReceipt(
          message,
          _markCustodyAccepted(routeReceipt),
        );
      },
    );
  }

  Future<FriendChatMessage?> _updateStoredMessageRouteReceipt({
    required String chatId,
    required String messageId,
    required TransportRouteReceipt routeReceipt,
  }) {
    return _updateStoredMessage(
      chatId: chatId,
      messageId: messageId,
      transform: (message) => _messageWithRouteReceipt(message, routeReceipt),
    );
  }

  Future<FriendChatMessage?> _updateStoredMessage({
    required String chatId,
    required String messageId,
    required FriendChatMessage Function(FriendChatMessage current) transform,
  }) async {
    final box = GetStorage(_chatStoreName);
    final key = 'friend_chat_$chatId';
    final List<dynamic> raw = box.read<List<dynamic>>(key) ?? [];
    if (raw.isEmpty) {
      return null;
    }

    FriendChatMessage? updatedMessage;
    final updated = raw.map((entry) {
      final current =
          FriendChatMessage.fromJson(Map<String, dynamic>.from(entry as Map));
      if (current.messageId != messageId) {
        return current.toJson();
      }
      updatedMessage = transform(current);
      return updatedMessage!.toJson();
    }).toList();

    if (updatedMessage == null) {
      return null;
    }

    await box.write(key, updated);
    return updatedMessage;
  }

  FriendChatMessage _messageWithRouteReceipt(
    FriendChatMessage message,
    TransportRouteReceipt routeReceipt,
  ) {
    return message.copyWith(
      metadata: _mergeRouteReceiptIntoMetadata(message.metadata, routeReceipt),
    );
  }

  Map<String, dynamic> _mergeRouteReceiptIntoMetadata(
    Map<String, dynamic>? metadata,
    TransportRouteReceipt routeReceipt,
  ) {
    final merged = Map<String, dynamic>.from(metadata ?? <String, dynamic>{});
    merged[_routeReceiptMetadataKey] = routeReceipt.toJson();
    return merged;
  }

  TransportRouteReceipt? _routeReceiptFromMetadata(
      Map<String, dynamic>? metadata) {
    final raw = metadata?[_routeReceiptMetadataKey];
    if (raw is! Map) {
      return null;
    }
    return TransportRouteReceipt.fromJson(Map<String, dynamic>.from(raw));
  }

  TransportRouteReceipt _markDelivered(
    TransportRouteReceipt receipt, {
    String? deliveredByUserId,
  }) {
    final planner = _routePlanner;
    final winningRoute = receipt.winningRoute ??
        receipt.attemptedRoutes.firstOrNull ??
        receipt.plannedRoutes.firstOrNull;
    if (planner != null && winningRoute != null) {
      return planner.markDelivered(
        receipt: receipt,
        winningRoute: winningRoute,
        winningRouteReason: 'delivery receipt received from recipient',
      );
    }
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'delivered',
      recordedAtUtc: now,
      winningRoute: winningRoute,
      winningRouteReason: 'delivery receipt received from recipient',
      custodyAcceptedAtUtc: receipt.custodyAcceptedAtUtc ?? now,
      custodyAcceptedBy: receipt.custodyAcceptedBy ?? deliveredByUserId,
      deliveredAtUtc: receipt.deliveredAtUtc ?? now,
    );
  }

  TransportRouteReceipt _markRead(
    TransportRouteReceipt receipt, {
    String? readByUserId,
  }) {
    final planner = _routePlanner;
    if (planner != null) {
      return planner.markRead(
        receipt: receipt,
        readBy: readByUserId,
      );
    }
    final now = DateTime.now().toUtc();
    return receipt.copyWith(
      status: 'read',
      recordedAtUtc: now,
      custodyAcceptedAtUtc: receipt.custodyAcceptedAtUtc ?? now,
      deliveredAtUtc: receipt.deliveredAtUtc ?? now,
      readAtUtc: receipt.readAtUtc ?? now,
      readBy: readByUserId,
    );
  }
}

class FriendChatSendResult {
  const FriendChatSendResult({
    required this.message,
    this.realityKernelFusionInput,
    this.governanceReport,
    this.routeReceipt,
  });

  final FriendChatMessage message;
  final RealityKernelFusionInput? realityKernelFusionInput;
  final KernelGovernanceReport? governanceReport;
  final TransportRouteReceipt? routeReceipt;

  String? get kernelEventId =>
      realityKernelFusionInput?.envelope.eventId ??
      governanceReport?.envelope.eventId;

  bool get modelTruthReady => realityKernelFusionInput != null;

  bool get localityContainedInWhere =>
      realityKernelFusionInput?.localityContainedInWhere ?? false;

  String? get governanceSummary => governanceReport?.projections.isEmpty ?? true
      ? null
      : governanceReport!.projections.first.summary;
}

enum _StoredMessageStatus {
  stored,
  duplicate,
  failed,
}

class _StoredDirectMessageResult {
  final _StoredMessageStatus status;
  final FriendChatMessage? message;

  const _StoredDirectMessageResult({
    required this.status,
    this.message,
  });

  bool get shouldConsumeTransport => status != _StoredMessageStatus.failed;
}

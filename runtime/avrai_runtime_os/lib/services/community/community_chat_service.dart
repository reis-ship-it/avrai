import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai2ai/models/community_chat_message.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/crypto/aes256gcm_fixed_key_codec.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_sender_key_service.dart';
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
  final HeadlessAvraiOsHost? _headlessOsHost;
  final BhamRoutePlanner? _routePlanner;
  final BhamRouteLearningService? _routeLearningService;
  final BhamTransportPolicy? _transportPolicy;
  final HumanLanguageBoundaryReviewLane _humanLanguageBoundaryReviewLane;
  final Ai2AiChatEventIntakeService? _ai2aiChatEventIntakeService;

  CommunityChatService({
    MessageEncryptionService? encryptionService,
    AgentIdService? agentIdService,
    RealtimeBackend? realtimeBackend,
    AtomicClockService? atomicClock,
    DmMessageStore? dmStore,
    CommunitySenderKeyService? senderKeyService,
    CommunityMessageStore? communityMessageStore,
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
        _senderKeyService = senderKeyService,
        _communityMessageStore = communityMessageStore,
        _headlessOsHost = headlessOsHost,
        _routePlanner = routePlanner,
        _routeLearningService = routeLearningService,
        _transportPolicy = transportPolicy,
        _humanLanguageBoundaryReviewLane = humanLanguageBoundaryReviewLane ??
            HumanLanguageBoundaryReviewLane(),
        _ai2aiChatEventIntakeService = ai2aiChatEventIntakeService;

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

      final review = await _reviewCommunityMessage(
        userId: userId,
        communityId: communityId,
        message: message,
        egressRequested: false,
      );
      if (!review.transcriptStorageAllowed) {
        throw HumanLanguageBoundaryViolationException(
          operation: 'community_chat_local_store',
          decision: review.turn.boundary,
        );
      }

      final chatMessage = await _storeOutboundGroupMessage(
        userId: userId,
        communityId: communityId,
        plaintext: review.transcriptText,
        metadata: review.toMetadata(),
      );

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
    final result = await sendGroupMessageOverNetworkWithKernelContext(
      userId: userId,
      communityId: communityId,
      message: message,
      community: community,
    );
    return result.message;
  }

  Future<CommunityChatSendResult> sendGroupMessageOverNetworkWithKernelContext({
    required String userId,
    required String communityId,
    required String message,
    required Community community,
  }) async {
    final review = await _reviewCommunityMessage(
      userId: userId,
      communityId: communityId,
      message: message,
      egressRequested: true,
    );
    if (!review.transcriptStorageAllowed || !review.egressAllowed) {
      throw HumanLanguageBoundaryViolationException(
        operation: 'community_chat_network_send',
        decision: review.turn.boundary,
      );
    }

    final stored = await _storeOutboundGroupMessage(
      userId: userId,
      communityId: communityId,
      plaintext: review.transcriptText,
      metadata: await _buildOutboundCommunityMessageMetadata(
        userId: userId,
        plaintext: review.transcriptText,
        review: review,
      ),
    );
    final routeReceipt = await _planGroupRouteReceipt(
      messageId: stored.messageId,
      communityId: communityId,
    );
    var effectiveRouteReceipt = routeReceipt;

    await _broadcastGroupMessageSenderKey(
      senderUserId: userId,
      community: community,
      plaintext: review.transportText,
      messageId: stored.messageId,
    );
    effectiveRouteReceipt = _markCustodyAccepted(routeReceipt);
    await _recordRouteOutcome(effectiveRouteReceipt, success: true);
    await _ingestCommunityMessageForLearning(
      localUserId: userId,
      senderUserId: userId,
      communityId: communityId,
      messageId: stored.messageId,
      plaintext: review.transportText,
      occurredAt: stored.timestamp,
      direction: Ai2AiChatFlowDirection.outbound,
      metadata: stored.metadata,
      routeReceipt: effectiveRouteReceipt,
      memberCount: community.memberCount,
    );

    final kernelResult = await _emitHeadlessCommunityChatLifecycle(
      userId: userId,
      communityId: communityId,
      message: review.transportText,
      community: community,
      storedMessage: stored,
      routeReceipt: effectiveRouteReceipt,
      boundaryReview: review,
    );

    return CommunityChatSendResult(
      message: stored,
      realityKernelFusionInput: kernelResult?.realityKernelFusionInput,
      governanceReport: kernelResult?.governanceReport,
      routeReceipt: effectiveRouteReceipt,
    );
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
            metadata: await _buildAi2AiLearningMetadata(
              localUserId: userId,
              sourceUserId: blob.senderUserId,
              plaintext: plaintext,
              chatType: 'community',
              channel: 'community_chat',
            ),
          );
          if (stored != null) {
            await _ingestCommunityMessageForLearning(
              localUserId: userId,
              senderUserId: blob.senderUserId,
              communityId: blob.communityId,
              messageId: stored.messageId,
              plaintext: plaintext,
              occurredAt: stored.timestamp,
              direction: Ai2AiChatFlowDirection.inbound,
              metadata: stored.metadata,
              memberCount: null,
            );
            yield stored;
          }
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

  Future<CommunityChatMessage> _storeOutboundGroupMessage({
    required String userId,
    required String communityId,
    required String plaintext,
    required Map<String, dynamic> metadata,
  }) async {
    final chatId = _generateChatId(communityId);
    final encrypted = await _encryptGroupMessage(plaintext, communityId);
    final chatMessage = CommunityChatMessage(
      messageId: const Uuid().v4(),
      chatId: chatId,
      communityId: communityId,
      senderId: userId,
      encryptedContent: encrypted,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    await _saveMessage(chatMessage);
    return chatMessage;
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
    Map<String, dynamic>? metadata,
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
        metadata: metadata,
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

  Future<CommunityChatSendResult?> _emitHeadlessCommunityChatLifecycle({
    required String userId,
    required String communityId,
    required String message,
    required Community community,
    required CommunityChatMessage storedMessage,
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
        eventId:
            'community_chat:$communityId:$userId:${now.microsecondsSinceEpoch}',
        userId: userId,
        agentId: await _resolveActorAgentId(userId),
        occurredAtUtc: now,
        sourceSystem: 'community_chat_service',
        eventType: 'community_message_sent',
        actionType: 'send_group_message',
        entityId: communityId,
        entityType: 'community_chat',
        routeReceipt: routeReceipt,
        context: <String, dynamic>{
          'message_id': storedMessage.messageId,
          'message_length': message.length,
          'member_count': community.memberCount,
          'language_intent':
              boundaryReview.turn.interpretation.intent.toWireValue(),
          'boundary_disposition':
              boundaryReview.turn.boundary.disposition.toWireValue(),
          'boundary_reason_codes': boundaryReview.turn.boundary.reasonCodes,
          'egress_purpose':
              boundaryReview.turn.boundary.egressPurpose.toWireValue(),
        },
        predictionContext: const <String, dynamic>{
          'transport': 'signal_protocol_sender_key',
          'chat_scope': 'community',
        },
        runtimeContext: const <String, dynamic>{
          'execution_path':
              'community_chat_service.sendGroupMessageOverNetwork',
          'workflow_stage': 'community_message_send',
        },
      );
      final runtimeBundle = await host.resolveRuntimeExecution(
        envelope: envelope,
      );
      final whyRequest = KernelWhyRequest(
        bundle: runtimeBundle.withoutWhy(),
        goal: 'deliver_community_message',
        predictedOutcome: 'message_visible_to_members',
        predictedConfidence: 0.79,
        actualOutcome: 'message_sent',
        actualOutcomeScore: 1.0,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'member_count',
            weight: (community.memberCount / 25.0).clamp(0.0, 1.0),
            source: 'community',
            durable: false,
          ),
          WhySignal(
            label: 'message_length',
            weight: (message.length / 120.0).clamp(0.0, 1.0),
            source: 'community',
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
      return CommunityChatSendResult(
        message: storedMessage,
        realityKernelFusionInput: modelTruth,
        governanceReport: governance,
      );
    } catch (e, st) {
      developer.log(
        'Headless OS community chat lifecycle failed',
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

  Future<TransportRouteReceipt> _planGroupRouteReceipt({
    required String messageId,
    required String communityId,
  }) async {
    final planner = _routePlanner;
    if (planner == null) {
      return TransportRouteReceiptCompatibilityTranslator.buildQueuedFallback(
        channel: 'community_chat',
        recordedAtUtc: DateTime.now().toUtc(),
      );
    }
    final ttl = _transportPolicy?.ttlForThreadKind(ChatThreadKind.community) ??
        const Duration(hours: 24);
    final expiresAtUtc = DateTime.now().toUtc().add(ttl);
    final routePlan = await planner.planRoutes(
      messageId: messageId,
      threadKind: ChatThreadKind.community,
      expiresAtUtc: expiresAtUtc,
      availability: <TransportMode, bool>{
        TransportMode.ble: true,
        TransportMode.localWifi: true,
        TransportMode.nearbyRelay: true,
        TransportMode.wormhole: true,
        TransportMode.cloudAssist: _realtimeBackend != null,
      },
      locality: communityId,
      exploratory: true,
    );
    return planner.markReleased(
      receipt: planner.buildQueuedReceipt(
        routePlan: routePlan,
        channel: 'community_chat',
        expiresAtUtc: expiresAtUtc,
      ),
      attemptedRoutes: routePlan.candidateRoutes.take(3).toList(),
    );
  }

  Future<HumanLanguageBoundaryReview> _reviewCommunityMessage({
    required String userId,
    required String communityId,
    required String message,
    required bool egressRequested,
  }) async {
    final actorAgentId =
        await _resolveActorAgentId(userId) ?? 'agt_community_chat_$userId';
    return _humanLanguageBoundaryReviewLane.reviewOutboundText(
      actorAgentId: actorAgentId,
      rawText: message,
      egressPurpose: BoundaryEgressPurpose.communityMessage,
      egressRequested: egressRequested,
      userId: userId,
      chatType: 'community',
      surface: 'chat',
      channel: 'community_chat:$communityId',
      privacyMode: BoundaryPrivacyMode.localSovereign,
    );
  }

  Future<Map<String, dynamic>> _buildOutboundCommunityMessageMetadata({
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
        chatType: 'community',
        channel: 'community_chat',
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

  Future<void> _ingestCommunityMessageForLearning({
    required String localUserId,
    required String senderUserId,
    required String communityId,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    required Ai2AiChatFlowDirection direction,
    Map<String, dynamic>? metadata,
    TransportRouteReceipt? routeReceipt,
    int? memberCount,
  }) async {
    final intake = _ai2aiChatEventIntakeService;
    if (intake == null) {
      return;
    }
    await intake.ingestCommunityMessage(
      localUserId: localUserId,
      senderUserId: senderUserId,
      communityId: communityId,
      messageId: messageId,
      plaintext: plaintext,
      occurredAt: occurredAt,
      direction: direction,
      metadata: metadata,
      routeReceipt: routeReceipt,
      memberCount: memberCount,
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
      winningRouteReason: 'group message accepted by transport',
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
}

class CommunityChatSendResult {
  const CommunityChatSendResult({
    required this.message,
    this.realityKernelFusionInput,
    this.governanceReport,
    this.routeReceipt,
  });

  final CommunityChatMessage message;
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

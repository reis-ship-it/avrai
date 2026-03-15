import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_core/models/business/business_expert_message.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/chat/conversation_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'package:get_storage/get_storage.dart';

/// Business-Expert Chat Service (AI2AI Network Routing)
///
/// Routes messages through ai2ai network while showing real business/expert identities.
/// Messages are encrypted in transit but participants see each other's real names.
/// All messages stored locally in Sembast for offline access.
class BusinessExpertChatServiceAI2AI {
  static const String _logName = 'BusinessExpertChatServiceAI2AI';
  final ConversationOrchestrationLane _conversationOrchestrationLane;
  final MessageEncryptionService _encryptionService;
  final PartnershipService? _partnershipService;
  final BusinessAccountService? _businessService;
  final AgentIdService _agentIdService;
  final HumanLanguageBoundaryReviewLane _humanLanguageBoundaryReviewLane;
  final Ai2AiChatEventIntakeService? _ai2aiChatEventIntakeService;
  final _uuid = const Uuid();

  // Local storage container names
  static const String _messagesStoreName = 'business_expert_messages';
  static const String _conversationsStoreName = 'business_expert_conversations';

  BusinessExpertChatServiceAI2AI({
    ConversationOrchestrationLane? conversationOrchestrationLane,
    MessageEncryptionService? encryptionService,
    PartnershipService? partnershipService,
    BusinessAccountService? businessService,
    AgentIdService? agentIdService,
    HumanLanguageBoundaryReviewLane? humanLanguageBoundaryReviewLane,
    Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
  })  : _conversationOrchestrationLane = conversationOrchestrationLane ??
            _resolveConversationOrchestrationLane(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _partnershipService = partnershipService,
        _businessService = businessService,
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _humanLanguageBoundaryReviewLane = humanLanguageBoundaryReviewLane ??
            HumanLanguageBoundaryReviewLane(),
        _ai2aiChatEventIntakeService = ai2aiChatEventIntakeService;

  static ConversationOrchestrationLane _resolveConversationOrchestrationLane() {
    if (GetIt.instance.isRegistered<ConversationOrchestrationLane>()) {
      return GetIt.instance<ConversationOrchestrationLane>();
    }
    throw ArgumentError(
      'ConversationOrchestrationLane must be provided or registered for '
      'BusinessExpertChatServiceAI2AI.',
    );
  }

  /// Send a message from business to expert or vice versa
  ///
  /// Messages are:
  /// 1. Encrypted with MessageEncryptionService
  /// 2. Routed through ai2ai network (encrypted in transit)
  /// 3. Stored locally in Sembast (for offline access)
  /// 4. Include participant identities (visible to participants)
  ///
  /// Agent IDs are automatically looked up if not provided.
  Future<BusinessExpertMessage> sendMessage({
    required String businessId,
    required String expertId,
    required String content,
    required MessageSenderType senderType,
    String? senderAgentId, // Optional: will be looked up if not provided
    String? recipientAgentId, // Optional: will be looked up if not provided
    MessageType messageType = MessageType.text,
    bool encrypt = true,
  }) async {
    try {
      // Get agent IDs if not provided
      final actualSenderAgentId = senderAgentId ??
          (senderType == MessageSenderType.business
              ? await _agentIdService.getBusinessAgentId(businessId)
              : await _agentIdService.getExpertAgentId(expertId));

      final actualRecipientAgentId = recipientAgentId ??
          (senderType == MessageSenderType.business
              ? await _agentIdService.getExpertAgentId(expertId)
              : await _agentIdService.getBusinessAgentId(businessId));

      developer.log(
        'Sending message via ai2ai: sender=${senderType.name}, senderAgent=$actualSenderAgentId, recipientAgent=$actualRecipientAgentId',
        name: _logName,
      );

      final localActorId =
          senderType == MessageSenderType.business ? businessId : expertId;
      final remoteActorId =
          senderType == MessageSenderType.business ? expertId : businessId;
      final review = await _reviewBusinessDirectMessage(
        actorAgentId: actualSenderAgentId,
        localActorId: localActorId,
        message: content,
      );
      if (!review.transcriptStorageAllowed || !review.egressAllowed) {
        throw HumanLanguageBoundaryViolationException(
          operation: 'business_expert_chat_network_send',
          decision: review.turn.boundary,
        );
      }

      // Get or create conversation
      final conversation = await _getOrCreateConversation(businessId, expertId);

      // Encrypt message content if requested
      Uint8List? encryptedContent;
      String encryptionType = 'aes256gcm';
      if (encrypt) {
        final encrypted = await _encryptionService.encrypt(
          review.transportText,
          actualRecipientAgentId,
        );
        encryptedContent = encrypted.encryptedContent;
        encryptionType = encrypted.encryptionType.name;
      }

      final metadata = await _buildOutboundBusinessExpertMessageMetadata(
        localActorId: localActorId,
        actorAgentId: actualSenderAgentId,
        plaintext: review.transcriptText,
        review: review,
      );

      // Create message with participant identities
      final message = BusinessExpertMessage(
        id: _uuid.v4(),
        conversationId: conversation['id'] as String,
        senderType: senderType,
        senderId:
            senderType == MessageSenderType.business ? businessId : expertId,
        recipientType: senderType == MessageSenderType.business
            ? MessageRecipientType.expert
            : MessageRecipientType.business,
        recipientId:
            senderType == MessageSenderType.business ? expertId : businessId,
        content: review.transcriptText,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata,
      );

      // Store message locally in Sembast
      await _saveMessageLocally(message);

      // Route message through ai2ai network
      // Payload includes participant identities (visible to participants, encrypted in transit)
      final ai2aiPayload = {
        'message_id': message.id,
        'conversation_id': message.conversationId,
        'sender_type': senderType.name,
        'sender_id': message.senderId,
        'sender_agent_id': actualSenderAgentId,
        'recipient_type': message.recipientType.name,
        'recipient_id': message.recipientId,
        'recipient_agent_id': actualRecipientAgentId,
        'content': review.transportText, // Will be encrypted by ai2ai protocol
        'encrypted_content':
            encryptedContent != null ? base64Encode(encryptedContent) : null,
        'encryption_type': encryptionType,
        'message_type': messageType.name,
        'created_at': message.createdAt.toIso8601String(),
        // Participant metadata (visible to participants)
        'business_id': businessId,
        'expert_id': expertId,
      };

      final payloadWithCategory = {
        ...ai2aiPayload,
        'message_category':
            'user_chat', // Optional: post-decryption validation/clarity
      };
      await _conversationOrchestrationLane.sendDirectMessagePayload(
        recipientAgentId: actualRecipientAgentId,
        payload: payloadWithCategory,
      );
      await _ingestBusinessExpertMessageForLearning(
        localActorId: localActorId,
        localActorAgentId: actualSenderAgentId,
        senderActorId: localActorId,
        senderActorAgentId: actualSenderAgentId,
        counterpartActorId: remoteActorId,
        counterpartActorAgentId: actualRecipientAgentId,
        messageId: message.id,
        plaintext: review.transportText,
        occurredAt: message.createdAt,
        metadata: message.metadata,
      );

      // Update conversation last_message_at
      await _updateConversationLastMessage(conversation['id'] as String);

      developer.log(
        'Message sent via ai2ai: ${message.id} (${senderType.name} -> ${message.recipientType.name})',
        name: _logName,
      );

      return message;
    } catch (e) {
      developer.log('Error sending message: $e', name: _logName);
      rethrow;
    }
  }

  /// Get conversation between business and expert
  Future<Map<String, dynamic>?> getConversation(
    String businessId,
    String expertId,
  ) async {
    try {
      final box = GetStorage(_conversationsStoreName);
      final conversationId = _generateConversationId(businessId, expertId);
      final data =
          box.read<Map<String, dynamic>>('conversation_$conversationId');
      return data;
    } catch (e) {
      developer.log('Error getting conversation: $e', name: _logName);
      return null;
    }
  }

  /// Get all conversations for a business
  Future<List<Map<String, dynamic>>> getBusinessConversations(
      String businessId) async {
    try {
      final box = GetStorage(_conversationsStoreName);
      final List<dynamic> allConvs =
          box.read<List<dynamic>>('all_conversations') ?? [];

      final filtered = allConvs
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((c) => c['business_id'] == businessId)
          .toList();

      // Sort by most recent first
      filtered.sort((a, b) => (b['last_message_at'] as String? ?? '')
          .compareTo(a['last_message_at'] as String? ?? ''));
      return filtered;
    } catch (e) {
      developer.log('Error getting business conversations: $e', name: _logName);
      return [];
    }
  }

  /// Get all conversations for an expert
  Future<List<Map<String, dynamic>>> getExpertConversations(
      String expertId) async {
    try {
      final box = GetStorage(_conversationsStoreName);
      final List<dynamic> allConvs =
          box.read<List<dynamic>>('all_conversations') ?? [];

      final filtered = allConvs
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((c) => c['expert_id'] == expertId)
          .toList();

      // Sort by most recent first
      filtered.sort((a, b) => (b['last_message_at'] as String? ?? '')
          .compareTo(a['last_message_at'] as String? ?? ''));
      return filtered;
    } catch (e) {
      developer.log('Error getting expert conversations: $e', name: _logName);
      return [];
    }
  }

  /// Get or create conversation
  Future<Map<String, dynamic>> _getOrCreateConversation(
    String businessId,
    String expertId,
  ) async {
    final existing = await getConversation(businessId, expertId);
    if (existing != null) {
      return existing;
    }

    // Calculate vibe compatibility if partnership service is available
    double? vibeScore;
    if (_partnershipService != null) {
      try {
        vibeScore = await _partnershipService.calculateVibeCompatibility(
          userId: expertId,
          businessId: businessId,
        );
      } catch (e) {
        developer.log('Error calculating vibe compatibility: $e',
            name: _logName);
      }
    }

    // Get business and expert names for display
    String? businessName;
    String? expertName;

    if (_businessService != null) {
      try {
        final business = await _businessService.getBusinessAccount(businessId);
        businessName = business?.name;
      } catch (e) {
        developer.log('Error getting business name: $e', name: _logName);
      }
    }

    // TODO: Get expert name from user service when available
    // For now, expert name will be null and can be populated later

    // Create new conversation
    final conversationId = _generateConversationId(businessId, expertId);
    final conversationData = {
      'id': conversationId,
      'business_id': businessId,
      'expert_id': expertId,
      'business_name': businessName,
      'expert_name': expertName,
      'vibe_compatibility_score': vibeScore,
      'connection_status': 'pending',
      'last_message_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final box = GetStorage(_conversationsStoreName);
    await box.write('conversation_$conversationId', conversationData);

    // Also maintain a list of all conversations for filtering
    final List<dynamic> allConvs =
        box.read<List<dynamic>>('all_conversations') ?? [];
    allConvs.add(conversationData);
    await box.write('all_conversations', allConvs);

    return conversationData;
  }

  /// Get message history for a conversation (from local GetStorage)
  Future<List<BusinessExpertMessage>> getMessageHistory(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final box = GetStorage(_messagesStoreName);
      final List<dynamic> raw =
          box.read<List<dynamic>>('messages_$conversationId') ?? [];

      final allMessages = raw
          .map((e) => BusinessExpertMessage.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();

      // Sort newest first
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination
      final messages = allMessages.skip(offset).take(limit).toList();

      // Decrypt messages if needed
      final decryptedMessages = <BusinessExpertMessage>[];
      for (final message in messages) {
        if (message.encryptedContent != null) {
          try {
            final encrypted = EncryptedMessage(
              encryptedContent: message.encryptedContent!,
              encryptionType: EncryptionType.values.firstWhere(
                  (e) => e.name == message.encryptionType,
                  orElse: () => EncryptionType.aes256gcm),
            );
            // Signal sessions are keyed by the remote *agentId* (not businessId/expertId).
            // For legacy AES (local-only), keep the existing senderId lookup behavior.
            final decryptKeyId = message.encryptionType ==
                    EncryptionType.signalProtocol.name
                ? (message.senderType == MessageSenderType.business
                    ? await _agentIdService.getBusinessAgentId(message.senderId)
                    : await _agentIdService.getExpertAgentId(message.senderId))
                : message.senderId;
            final decrypted = await _encryptionService.decrypt(
              encrypted,
              decryptKeyId,
            );
            decryptedMessages.add(message.copyWith(content: decrypted));
          } catch (e) {
            developer.log('Error decrypting message: $e', name: _logName);
            decryptedMessages.add(message);
          }
        } else {
          decryptedMessages.add(message);
        }
      }

      return decryptedMessages.reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      developer.log('Error getting message history: $e', name: _logName);
      return [];
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final box = GetStorage(_messagesStoreName);
      // We need to find which conversation this message belongs to
      // Iterate through known conversations
      final convBox = GetStorage(_conversationsStoreName);
      final List<dynamic> allConvs =
          convBox.read<List<dynamic>>('all_conversations') ?? [];

      for (final conv in allConvs) {
        final convId = (conv as Map)['id'] as String?;
        if (convId == null) continue;

        final key = 'messages_$convId';
        final List<dynamic> messages = box.read<List<dynamic>>(key) ?? [];
        bool found = false;
        final updated = messages.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          if (map['id'] == messageId) {
            map['is_read'] = true;
            map['read_at'] = DateTime.now().toIso8601String();
            map['updated_at'] = DateTime.now().toIso8601String();
            found = true;
          }
          return map;
        }).toList();

        if (found) {
          await box.write(key, updated);
          return;
        }
      }
    } catch (e) {
      developer.log('Error marking message as read: $e', name: _logName);
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(
      String businessIdOrExpertId, bool isBusiness) async {
    try {
      final box = GetStorage(_messagesStoreName);
      final convBox = GetStorage(_conversationsStoreName);
      final List<dynamic> allConvs =
          convBox.read<List<dynamic>>('all_conversations') ?? [];

      int count = 0;
      final recipientType = isBusiness ? 'business' : 'expert';

      for (final conv in allConvs) {
        final convId = (conv as Map)['id'] as String?;
        if (convId == null) continue;

        final List<dynamic> messages =
            box.read<List<dynamic>>('messages_$convId') ?? [];
        count += messages.where((e) {
          final map = e as Map;
          return map['is_read'] == false &&
              map['recipient_type'] == recipientType &&
              map['recipient_id'] == businessIdOrExpertId;
        }).length;
      }

      return count;
    } catch (e) {
      developer.log('Error getting unread count: $e', name: _logName);
      return 0;
    }
  }

  /// Subscribe to real-time messages from ai2ai network
  ///
  /// Listens for incoming messages routed through ai2ai network
  Stream<BusinessExpertMessage> subscribeToMessages(String conversationId) {
    final controller = StreamController<BusinessExpertMessage>.broadcast();

    // Poll for new messages from ai2ai network
    // In a real implementation, this would use ai2ai realtime subscriptions
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Check for new messages via ai2ai protocol
        // This is a simplified polling approach - in production, use realtime subscriptions
        final newMessages = await _checkForNewMessages(conversationId);
        for (final message in newMessages) {
          controller.add(message);
        }
      } catch (e) {
        developer.log('Error checking for new messages: $e', name: _logName);
      }
    });

    return controller.stream;
  }

  /// Check for new messages from ai2ai network
  Future<List<BusinessExpertMessage>> _checkForNewMessages(
      String conversationId) async {
    // This would integrate with ai2ai network to receive messages
    // For now, return empty list - real implementation would:
    // 1. Listen to ai2ai network for messages
    // 2. Decrypt and validate messages
    // 3. Store locally in Sembast
    // 4. Return new messages
    return [];
  }

  /// Save message locally in GetStorage
  Future<void> _saveMessageLocally(BusinessExpertMessage message) async {
    try {
      final box = GetStorage(_messagesStoreName);
      final key = 'messages_${message.conversationId}';
      final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];
      existing.add(message.toJson());
      await box.write(key, existing);
    } catch (e) {
      developer.log('Error saving message locally: $e', name: _logName);
      rethrow;
    }
  }

  /// Update conversation last message timestamp
  Future<void> _updateConversationLastMessage(String conversationId) async {
    try {
      final box = GetStorage(_conversationsStoreName);
      final data =
          box.read<Map<String, dynamic>>('conversation_$conversationId');
      if (data != null) {
        final updated = Map<String, dynamic>.from(data)
          ..['last_message_at'] = DateTime.now().toIso8601String()
          ..['updated_at'] = DateTime.now().toIso8601String();
        await box.write('conversation_$conversationId', updated);

        // Update in all_conversations list too
        final List<dynamic> allConvs =
            box.read<List<dynamic>>('all_conversations') ?? [];
        final idx =
            allConvs.indexWhere((c) => (c as Map)['id'] == conversationId);
        if (idx >= 0) {
          allConvs[idx] = updated;
          await box.write('all_conversations', allConvs);
        }
      }
    } catch (e) {
      developer.log('Error updating conversation: $e', name: _logName);
    }
  }

  /// Generate conversation ID from business and expert IDs
  String _generateConversationId(String businessId, String expertId) {
    // Deterministic ID generation (same conversation always gets same ID)
    final ids = [businessId, expertId]..sort();
    return 'conv_${ids.join('_')}';
  }

  Future<HumanLanguageBoundaryReview> _reviewBusinessDirectMessage({
    required String actorAgentId,
    required String localActorId,
    required String message,
  }) {
    return _humanLanguageBoundaryReviewLane.reviewOutboundText(
      actorAgentId: actorAgentId,
      rawText: message,
      egressPurpose: BoundaryEgressPurpose.directMessage,
      egressRequested: true,
      userId: localActorId,
      chatType: 'business_direct',
      surface: 'business_chat',
      channel: 'business_expert_chat',
    );
  }

  Future<Map<String, dynamic>> _buildOutboundBusinessExpertMessageMetadata({
    required String localActorId,
    required String actorAgentId,
    required String plaintext,
    required HumanLanguageBoundaryReview review,
  }) async {
    return _mergeMetadata(
      review.toMetadata(),
      await _buildAi2AiLearningMetadata(
        localActorId: localActorId,
        sourceActorId: localActorId,
        sourceAgentId: actorAgentId,
        plaintext: plaintext,
      ),
    );
  }

  Future<Map<String, dynamic>> _buildAi2AiLearningMetadata({
    required String localActorId,
    required String sourceActorId,
    required String sourceAgentId,
    required String plaintext,
  }) async {
    final intake = _ai2aiChatEventIntakeService;
    if (intake == null) {
      return const <String, dynamic>{};
    }
    return intake.buildLearningMetadata(
      localUserId: localActorId,
      sourceUserId: sourceActorId,
      sourceAgentId: sourceAgentId,
      rawText: plaintext,
      chatType: 'business_direct',
      channel: 'business_expert_chat',
      surface: 'business_chat',
    );
  }

  Future<void> _ingestBusinessExpertMessageForLearning({
    required String localActorId,
    required String localActorAgentId,
    required String senderActorId,
    required String senderActorAgentId,
    required String counterpartActorId,
    required String counterpartActorAgentId,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    Map<String, dynamic>? metadata,
  }) async {
    final intake = _ai2aiChatEventIntakeService;
    if (intake == null) {
      return;
    }
    await intake.ingestDirectMessage(
      localUserId: localActorId,
      localAgentId: localActorAgentId,
      senderUserId: senderActorId,
      senderAgentId: senderActorAgentId,
      counterpartUserId: counterpartActorId,
      counterpartAgentId: counterpartActorAgentId,
      messageId: messageId,
      plaintext: plaintext,
      occurredAt: occurredAt,
      direction: Ai2AiChatFlowDirection.outbound,
      metadata: metadata,
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
}

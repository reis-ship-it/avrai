import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:avrai/core/ai2ai/anonymous_communication.dart' as ai2ai;
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai/core/models/business/business_expert_message.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:uuid/uuid.dart';
import 'package:get_storage/get_storage.dart';

/// Business-Expert Chat Service (AI2AI Network Routing)
///
/// Routes messages through ai2ai network while showing real business/expert identities.
/// Messages are encrypted in transit but participants see each other's real names.
/// All messages stored locally in Sembast for offline access.
class BusinessExpertChatServiceAI2AI {
  static const String _logName = 'BusinessExpertChatServiceAI2AI';
  final ai2ai.AnonymousCommunicationProtocol _ai2aiProtocol;
  final MessageEncryptionService _encryptionService;
  final PartnershipService? _partnershipService;
  final BusinessAccountService? _businessService;
  final AgentIdService _agentIdService;
  final _uuid = const Uuid();

  // Local storage container names
  static const String _messagesStoreName = 'business_expert_messages';
  static const String _conversationsStoreName = 'business_expert_conversations';

  BusinessExpertChatServiceAI2AI({
    ai2ai.AnonymousCommunicationProtocol? ai2aiProtocol,
    MessageEncryptionService? encryptionService,
    PartnershipService? partnershipService,
    BusinessAccountService? businessService,
    AgentIdService? agentIdService,
  })  : _ai2aiProtocol = ai2aiProtocol ?? _createDefaultProtocol(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _partnershipService = partnershipService,
        _businessService = businessService,
        _agentIdService = agentIdService ?? di.sl<AgentIdService>();

  static ai2ai.AnonymousCommunicationProtocol _createDefaultProtocol() {
    // Try to get from DI - protocol must be registered
    if (di.sl.isRegistered<ai2ai.AnonymousCommunicationProtocol>()) {
      return di.sl<ai2ai.AnonymousCommunicationProtocol>();
    }

    // If not registered, throw error - protocol must be provided via DI
    throw ArgumentError(
        'AnonymousCommunicationProtocol must be registered in dependency injection. '
        'It requires encryptionService, supabase, atomicClock, and anonymizationService.');
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

      // Get or create conversation
      final conversation = await _getOrCreateConversation(businessId, expertId);

      // Encrypt message content if requested
      Uint8List? encryptedContent;
      EncryptionType encryptionType = EncryptionType.aes256gcm;
      if (encrypt) {
        final encrypted =
            await _encryptionService.encrypt(content, actualRecipientAgentId);
        encryptedContent = encrypted.encryptedContent;
        encryptionType = encrypted.encryptionType;
      }

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
        content: content,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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
        'recipient_type': message.recipientType.name,
        'recipient_id': message.recipientId,
        'content': content, // Will be encrypted by ai2ai protocol
        'encrypted_content':
            encryptedContent != null ? base64Encode(encryptedContent) : null,
        'encryption_type': encryptionType.name,
        'message_type': messageType.name,
        'created_at': message.createdAt.toIso8601String(),
        // Participant metadata (visible to participants)
        'business_id': businessId,
        'expert_id': expertId,
      };

      // Route through ai2ai network
      // Note: AnonymousCommunicationProtocol will encrypt the payload
      // but participants can see each other's identities in the chat UI
      // MessageType.userChat allows routing before decryption (unencrypted header)
      final payloadWithCategory = {
        ...ai2aiPayload,
        'message_category':
            'user_chat', // Optional: post-decryption validation/clarity
      };
      await _ai2aiProtocol.sendEncryptedMessage(
        actualRecipientAgentId,
        ai2ai.MessageType
            .userChat, // Protocol-level routing via unencrypted header (AnonymousCommunicationProtocol enum)
        payloadWithCategory,
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
      final data = box.read<Map<String, dynamic>>('conversation_$conversationId');
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
      final List<dynamic> allConvs = box.read<List<dynamic>>('all_conversations') ?? [];

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
      final List<dynamic> allConvs = box.read<List<dynamic>>('all_conversations') ?? [];

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
    final List<dynamic> allConvs = box.read<List<dynamic>>('all_conversations') ?? [];
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
      final List<dynamic> raw = box.read<List<dynamic>>('messages_$conversationId') ?? [];

      final allMessages = raw
          .map((e) => BusinessExpertMessage.fromJson(Map<String, dynamic>.from(e as Map)))
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
              encryptionType: message.encryptionType,
            );
            // Signal sessions are keyed by the remote *agentId* (not businessId/expertId).
            // For legacy AES (local-only), keep the existing senderId lookup behavior.
            final decryptKeyId = message.encryptionType ==
                    EncryptionType.signalProtocol
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
      final List<dynamic> allConvs = convBox.read<List<dynamic>>('all_conversations') ?? [];

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
      final List<dynamic> allConvs = convBox.read<List<dynamic>>('all_conversations') ?? [];

      int count = 0;
      final recipientType = isBusiness ? 'business' : 'expert';

      for (final conv in allConvs) {
        final convId = (conv as Map)['id'] as String?;
        if (convId == null) continue;

        final List<dynamic> messages = box.read<List<dynamic>>('messages_$convId') ?? [];
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
      final data = box.read<Map<String, dynamic>>('conversation_$conversationId');
      if (data != null) {
        final updated = Map<String, dynamic>.from(data)
          ..['last_message_at'] = DateTime.now().toIso8601String()
          ..['updated_at'] = DateTime.now().toIso8601String();
        await box.write('conversation_$conversationId', updated);

        // Update in all_conversations list too
        final List<dynamic> allConvs = box.read<List<dynamic>>('all_conversations') ?? [];
        final idx = allConvs.indexWhere((c) => (c as Map)['id'] == conversationId);
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
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:typed_data';

import 'package:avrai_runtime_os/ai2ai/chat/conversation_store_writer.dart';
import 'package:avrai_runtime_os/ai2ai/chat/incoming_chat_payload_helpers.dart';
import 'package:avrai_core/models/business/business_expert_message.dart'
    as chat_models;
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class IncomingBusinessExpertChatLane {
  const IncomingBusinessExpertChatLane._();

  static Future<void> handle({
    required Map<String, dynamic> payload,
    required AppLogger logger,
    required String logName,
    Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
  }) async {
    try {
      final String? messageId = payload['message_id'] as String?;
      final String? conversationId = payload['conversation_id'] as String?;
      final String? senderTypeStr = payload['sender_type'] as String?;
      final String? senderId = payload['sender_id'] as String?;
      final String? senderAgentId = payload['sender_agent_id'] as String?;
      final String? recipientTypeStr = payload['recipient_type'] as String?;
      final String? recipientId = payload['recipient_id'] as String?;
      final String? recipientAgentId = payload['recipient_agent_id'] as String?;
      final String? content = payload['content'] as String?;
      final String? encryptedContentStr =
          payload['encrypted_content'] as String?;
      final String? encryptionTypeStr = payload['encryption_type'] as String?;
      final String? messageTypeStr = payload['message_type'] as String?;
      final String? createdAtStr = payload['created_at'] as String?;

      if (IncomingChatPayloadHelpers.hasMissingRequiredFields(<Object?>[
        messageId,
        conversationId,
        senderTypeStr,
        senderId,
        recipientTypeStr,
        recipientId,
        content,
        createdAtStr,
      ])) {
        IncomingChatPayloadHelpers.warnIncompleteChatPayload(
          chatType: 'business-expert',
          logger: logger,
          logName: logName,
        );
        return;
      }

      final String resolvedMessageId = messageId!;
      final String resolvedConversationId = conversationId!;
      final String resolvedSenderTypeStr = senderTypeStr!;
      final String resolvedSenderId = senderId!;
      final String resolvedRecipientTypeStr = recipientTypeStr!;
      final String resolvedRecipientId = recipientId!;
      final String resolvedContent = content!;
      final String resolvedCreatedAtStr = createdAtStr!;

      final chat_models.MessageSenderType senderType =
          IncomingChatPayloadHelpers.parseEnumByName(
        values: chat_models.MessageSenderType.values,
        name: resolvedSenderTypeStr,
        fallback: chat_models.MessageSenderType.business,
      );
      final chat_models.MessageRecipientType recipientType =
          IncomingChatPayloadHelpers.parseEnumByName(
        values: chat_models.MessageRecipientType.values,
        name: resolvedRecipientTypeStr,
        fallback: chat_models.MessageRecipientType.expert,
      );
      final String encryptionType =
          ['none', 'aes256gcm'].contains(encryptionTypeStr)
              ? encryptionTypeStr!
              : 'aes256gcm';
      final chat_models.MessageType messageType =
          IncomingChatPayloadHelpers.parseEnumByName(
        values: chat_models.MessageType.values,
        name: messageTypeStr,
        fallback: chat_models.MessageType.text,
      );

      final Uint8List? encryptedContent =
          IncomingChatPayloadHelpers.decodeEncryptedContentOrNull(
        encryptedContentStr: encryptedContentStr,
        logger: logger,
        logName: logName,
      );

      final DateTime? createdAt =
          IncomingChatPayloadHelpers.parseCreatedAtOrNull(
        createdAtStr: resolvedCreatedAtStr,
        logger: logger,
        logName: logName,
      );
      if (createdAt == null) return;

      final metadata = await _buildInboundLearningMetadata(
        ai2aiChatEventIntakeService: ai2aiChatEventIntakeService,
        localActorId: resolvedRecipientId,
        sourceActorId: resolvedSenderId,
        sourceAgentId: senderAgentId,
        plaintext: resolvedContent,
      );

      final chat_models.BusinessExpertMessage chatMessage =
          chat_models.BusinessExpertMessage(
        id: resolvedMessageId,
        conversationId: resolvedConversationId,
        senderType: senderType,
        senderId: resolvedSenderId,
        recipientType: recipientType,
        recipientId: resolvedRecipientId,
        content: resolvedContent,
        encryptedContent: encryptedContent,
        encryptionType: encryptionType,
        type: messageType,
        isRead: false,
        readAt: null,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        metadata: metadata,
      );

      await ConversationStoreWriter.appendMessage(
        boxName: 'business_expert_messages',
        conversationId: chatMessage.conversationId,
        messageJson: chatMessage.toJson(),
      );
      await _ingestInboundMessageForLearning(
        ai2aiChatEventIntakeService: ai2aiChatEventIntakeService,
        localActorId: resolvedRecipientId,
        localAgentId: recipientAgentId,
        senderActorId: resolvedSenderId,
        senderAgentId: senderAgentId,
        messageId: resolvedMessageId,
        plaintext: resolvedContent,
        occurredAt: createdAt,
        metadata: metadata,
      );

      logger.debug(
        'Saved incoming business-expert chat message: $resolvedMessageId',
        tag: logName,
      );
    } catch (e, st) {
      logger.error(
        'Error handling incoming business-expert chat: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  static Future<Map<String, dynamic>> _buildInboundLearningMetadata({
    required Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
    required String localActorId,
    required String sourceActorId,
    required String? sourceAgentId,
    required String plaintext,
  }) async {
    if (ai2aiChatEventIntakeService == null) {
      return const <String, dynamic>{};
    }
    return ai2aiChatEventIntakeService.buildLearningMetadata(
      localUserId: localActorId,
      sourceUserId: sourceActorId,
      sourceAgentId: sourceAgentId,
      rawText: plaintext,
      chatType: 'business_direct',
      channel: 'business_expert_chat',
      surface: 'business_chat',
    );
  }

  static Future<void> _ingestInboundMessageForLearning({
    required Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
    required String localActorId,
    required String? localAgentId,
    required String senderActorId,
    required String? senderAgentId,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    required Map<String, dynamic> metadata,
  }) async {
    if (ai2aiChatEventIntakeService == null) {
      return;
    }
    await ai2aiChatEventIntakeService.ingestDirectMessage(
      localUserId: localActorId,
      localAgentId: localAgentId,
      senderUserId: senderActorId,
      senderAgentId: senderAgentId,
      counterpartUserId: senderActorId,
      counterpartAgentId: senderAgentId,
      messageId: messageId,
      plaintext: plaintext,
      occurredAt: occurredAt,
      direction: Ai2AiChatFlowDirection.inbound,
      metadata: metadata,
    );
  }
}

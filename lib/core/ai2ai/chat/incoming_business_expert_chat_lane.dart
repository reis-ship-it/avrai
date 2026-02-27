import 'dart:typed_data';

import 'package:avrai/core/ai2ai/chat/conversation_store_writer.dart';
import 'package:avrai/core/ai2ai/chat/incoming_chat_payload_helpers.dart';
import 'package:avrai/core/models/business/business_expert_message.dart'
    as chat_models;
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';

class IncomingBusinessExpertChatLane {
  const IncomingBusinessExpertChatLane._();

  static Future<void> handle({
    required Map<String, dynamic> payload,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final String? messageId = payload['message_id'] as String?;
      final String? conversationId = payload['conversation_id'] as String?;
      final String? senderTypeStr = payload['sender_type'] as String?;
      final String? senderId = payload['sender_id'] as String?;
      final String? recipientTypeStr = payload['recipient_type'] as String?;
      final String? recipientId = payload['recipient_id'] as String?;
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
      final EncryptionType encryptionType =
          IncomingChatPayloadHelpers.parseEnumByName(
        values: EncryptionType.values,
        name: encryptionTypeStr,
        fallback: EncryptionType.aes256gcm,
      );
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
      );

      await ConversationStoreWriter.appendMessage(
        boxName: 'business_expert_messages',
        conversationId: chatMessage.conversationId,
        messageJson: chatMessage.toJson(),
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
}

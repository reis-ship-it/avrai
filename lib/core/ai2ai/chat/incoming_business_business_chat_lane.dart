// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:typed_data';

import 'package:avrai/core/ai2ai/chat/conversation_store_writer.dart';
import 'package:avrai/core/ai2ai/chat/incoming_chat_payload_helpers.dart';
import 'package:avrai/core/models/business/business_business_message.dart'
    as chat_models;
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';

class IncomingBusinessBusinessChatLane {
  const IncomingBusinessBusinessChatLane._();

  static Future<void> handle({
    required Map<String, dynamic> payload,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final String? messageId = payload['message_id'] as String?;
      final String? conversationId = payload['conversation_id'] as String?;
      final String? senderBusinessId = payload['sender_business_id'] as String?;
      final String? recipientBusinessId =
          payload['recipient_business_id'] as String?;
      final String? content = payload['content'] as String?;
      final String? encryptedContentStr =
          payload['encrypted_content'] as String?;
      final String? encryptionTypeStr = payload['encryption_type'] as String?;
      final String? messageTypeStr = payload['message_type'] as String?;
      final String? createdAtStr = payload['created_at'] as String?;

      if (IncomingChatPayloadHelpers.hasMissingRequiredFields(<Object?>[
        messageId,
        conversationId,
        senderBusinessId,
        recipientBusinessId,
        content,
        createdAtStr,
      ])) {
        IncomingChatPayloadHelpers.warnIncompleteChatPayload(
          chatType: 'business-business',
          logger: logger,
          logName: logName,
        );
        return;
      }

      final String resolvedMessageId = messageId!;
      final String resolvedConversationId = conversationId!;
      final String resolvedSenderBusinessId = senderBusinessId!;
      final String resolvedRecipientBusinessId = recipientBusinessId!;
      final String resolvedContent = content!;
      final String resolvedCreatedAtStr = createdAtStr!;

      final EncryptionType encryptionType =
          IncomingChatPayloadHelpers.parseEnumByName(
        values: EncryptionType.values,
        name: encryptionTypeStr,
        fallback: EncryptionType.aes256gcm,
      );
      final chat_models.BusinessBusinessMessageType messageType =
          IncomingChatPayloadHelpers.parseEnumByName(
        values: chat_models.BusinessBusinessMessageType.values,
        name: messageTypeStr,
        fallback: chat_models.BusinessBusinessMessageType.text,
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

      final chat_models.BusinessBusinessMessage chatMessage =
          chat_models.BusinessBusinessMessage(
        id: resolvedMessageId,
        conversationId: resolvedConversationId,
        senderBusinessId: resolvedSenderBusinessId,
        recipientBusinessId: resolvedRecipientBusinessId,
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
        boxName: 'business_business_messages',
        conversationId: chatMessage.conversationId,
        messageJson: chatMessage.toJson(),
      );

      logger.debug(
        'Saved incoming business-business chat message: $resolvedMessageId',
        tag: logName,
      );
    } catch (e, st) {
      logger.error(
        'Error handling incoming business-business chat: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}

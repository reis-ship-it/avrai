import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart' as ai2ai;

class LegacyConversationTransportDispatch {
  const LegacyConversationTransportDispatch({
    required this.messageId,
    required this.timestamp,
    required this.messageCategory,
  });

  final String messageId;
  final DateTime timestamp;
  final String messageCategory;
}

class LegacyDeliveredAi2AiMessage {
  const LegacyDeliveredAi2AiMessage({
    required this.messageId,
    required this.messageTypeName,
    required this.decryptedPayload,
    required this.timestamp,
  });

  final String messageId;
  final String messageTypeName;
  final Map<String, dynamic> decryptedPayload;
  final DateTime timestamp;
}

abstract class LegacyConversationTransportAdapter {
  Future<LegacyConversationTransportDispatch> sendDirectMessagePayload({
    required String recipientAgentId,
    required Map<String, dynamic> payload,
    String messageCategory = 'user_chat',
  });

  Future<List<LegacyDeliveredAi2AiMessage>> getDeliveredMessages({
    required String senderAgentId,
    required String targetAgentId,
  });
}

class AnonymousConversationTransportAdapter
    implements LegacyConversationTransportAdapter {
  const AnonymousConversationTransportAdapter({
    required ai2ai.AnonymousCommunicationProtocol protocol,
  }) : _protocol = protocol;

  final ai2ai.AnonymousCommunicationProtocol _protocol;

  @override
  Future<LegacyConversationTransportDispatch> sendDirectMessagePayload({
    required String recipientAgentId,
    required Map<String, dynamic> payload,
    String messageCategory = 'user_chat',
  }) async {
    final message = await _protocol.sendEncryptedMessage(
      recipientAgentId,
      ai2ai.MessageType.userChat,
      <String, dynamic>{
        ...payload,
        'message_category': payload['message_category'] ?? messageCategory,
      },
    );
    return LegacyConversationTransportDispatch(
      messageId: message.messageId,
      timestamp: message.timestamp.toUtc(),
      messageCategory: messageCategory,
    );
  }

  @override
  Future<List<LegacyDeliveredAi2AiMessage>> getDeliveredMessages({
    required String senderAgentId,
    required String targetAgentId,
  }) async {
    final messages = await _protocol.getDeliveredMessages(
      senderAgentId: senderAgentId,
      targetAgentId: targetAgentId,
    );
    return messages
        .map(
          (message) => LegacyDeliveredAi2AiMessage(
            messageId: message.messageId,
            messageTypeName: message.messageType.name,
            decryptedPayload: Map<String, dynamic>.from(
              message.decryptedPayload,
            ),
            timestamp: message.timestamp,
          ),
        )
        .toList(growable: false);
  }
}

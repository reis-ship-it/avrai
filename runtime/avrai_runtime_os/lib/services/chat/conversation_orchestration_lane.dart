import 'package:avrai_runtime_os/services/transport/legacy/legacy_conversation_transport_adapter.dart';

/// Non-kernel seam for governed human chat transport.
///
/// This lane intentionally does not own transport truth. It exists to keep
/// human chat surfaces off legacy protocol types while the underlying delivery
/// path continues migrating behind mesh-owned execution.
class ConversationTransportDispatchResult {
  const ConversationTransportDispatchResult({
    required this.messageId,
    required this.timestamp,
    required this.messageCategory,
  });

  final String messageId;
  final DateTime timestamp;
  final String messageCategory;
}

class ConversationOrchestrationLane {
  ConversationOrchestrationLane({
    required LegacyConversationTransportAdapter transportAdapter,
  }) : _transportAdapter = transportAdapter;

  final LegacyConversationTransportAdapter _transportAdapter;

  Future<ConversationTransportDispatchResult> sendDirectMessagePayload({
    required String recipientAgentId,
    required Map<String, dynamic> payload,
    String messageCategory = 'user_chat',
  }) async {
    final message = await _transportAdapter.sendDirectMessagePayload(
      recipientAgentId: recipientAgentId,
      payload: payload,
      messageCategory: messageCategory,
    );
    return ConversationTransportDispatchResult(
      messageId: message.messageId,
      timestamp: message.timestamp,
      messageCategory: messageCategory,
    );
  }
}

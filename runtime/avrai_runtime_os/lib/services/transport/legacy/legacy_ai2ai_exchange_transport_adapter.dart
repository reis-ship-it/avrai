import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart' as ai2ai;
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';

abstract class LegacyAi2AiExchangeTransportAdapter {
  Future<void> dispatchExchange({
    required String peerId,
    required Ai2AiExchangeArtifactClass artifactClass,
    required Map<String, dynamic> payload,
    String? legacyMessageTypeName,
  });
}

class AnonymousAi2AiExchangeTransportAdapter
    implements LegacyAi2AiExchangeTransportAdapter {
  const AnonymousAi2AiExchangeTransportAdapter({
    required ai2ai.AnonymousCommunicationProtocol protocol,
  }) : _protocol = protocol;

  final ai2ai.AnonymousCommunicationProtocol _protocol;

  @override
  Future<void> dispatchExchange({
    required String peerId,
    required Ai2AiExchangeArtifactClass artifactClass,
    required Map<String, dynamic> payload,
    String? legacyMessageTypeName,
  }) async {
    await _protocol.sendEncryptedMessage(
      peerId,
      _legacyMessageTypeFor(
        artifactClass: artifactClass,
        legacyMessageTypeName: legacyMessageTypeName,
      ),
      payload,
    );
  }

  ai2ai.MessageType _legacyMessageTypeFor({
    required Ai2AiExchangeArtifactClass artifactClass,
    required String? legacyMessageTypeName,
  }) {
    if (legacyMessageTypeName != null && legacyMessageTypeName.isNotEmpty) {
      return ai2ai.MessageType.values.firstWhere(
        (value) => value.name == legacyMessageTypeName,
        orElse: () => ai2ai.MessageType.recommendationShare,
      );
    }
    return switch (artifactClass) {
      Ai2AiExchangeArtifactClass.probe => ai2ai.MessageType.discoverySync,
      Ai2AiExchangeArtifactClass.prekey => ai2ai.MessageType.trustVerification,
      Ai2AiExchangeArtifactClass.receipt => ai2ai.MessageType.reputationUpdate,
      Ai2AiExchangeArtifactClass.control =>
        ai2ai.MessageType.networkMaintenance,
      Ai2AiExchangeArtifactClass.learningDelta ||
      Ai2AiExchangeArtifactClass.dnaDelta ||
      Ai2AiExchangeArtifactClass.memoryArtifact =>
        ai2ai.MessageType.recommendationShare,
    };
  }
}

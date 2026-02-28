// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_packet_forwarder.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_network/avra_network.dart';

class LearningInsightMeshForwarder {
  const LearningInsightMeshForwarder._();

  static Future<void> forward({
    required List<String> candidatePeerIds,
    required MeshForwardingContext context,
    required String senderNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required Map<String, dynamic> payload,
    String? geographicScope,
    bool fireAndForgetSend = false,
    void Function(String peerId, String recipientId)? onForwarded,
    void Function(String peerId, String recipientId, Object error)?
        onForwardFailed,
  }) {
    return MeshPacketForwarder.forwardToCandidates(
      candidatePeerIds: candidatePeerIds,
      discovery: context.discovery,
      protocol: context.protocol,
      senderNodeId: senderNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      messageType: MessageType.learningInsight,
      payload: payload,
      geographicScope: geographicScope,
      fireAndForgetSend: fireAndForgetSend,
      onForwarded: onForwarded,
      onForwardFailed: onForwardFailed,
    );
  }
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/forwarded_payload_builder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class GossipLearningForwardingLane {
  const GossipLearningForwardingLane._();

  static Future<void> forward({
    required Map<String, dynamic> payload,
    required int hop,
    required String originId,
    required String receivedFromDeviceId,
    required Iterable<String> discoveredNodeIds,
    required MeshForwardingContext context,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    required String failureLabel,
    int maxCandidates = 2,
  }) async {
    final candidates =
        MeshForwardingTargetSelector.excludingReceivedFromAndOrigin(
      discoveredNodeIds: discoveredNodeIds,
      receivedFromDeviceId: receivedFromDeviceId,
      originId: originId,
      maxCandidates: maxCandidates,
    );

    if (candidates.isEmpty) return;

    try {
      final forwardedPayload = ForwardedPayloadBuilder.withHopAndOrigin(
        source: payload,
        hop: hop,
        originId: originId,
      );

      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: forwardedPayload,
      );
    } catch (e) {
      logger.debug('$failureLabel: $e', tag: logName);
    }
  }
}

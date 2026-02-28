// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/forwarded_payload_builder.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class LocalityAgentUpdateForwardingLane {
  const LocalityAgentUpdateForwardingLane._();

  static Future<void> forward({
    required Map<String, dynamic> message,
    required int hop,
    required String? originId,
    required Iterable<String> discoveredNodeIds,
    required MeshForwardingContext context,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    int maxCandidates = 2,
  }) async {
    final candidates = MeshForwardingTargetSelector.excludingOptionalOrigin(
      discoveredNodeIds: discoveredNodeIds,
      originId: originId,
      maxCandidates: maxCandidates,
    );

    if (candidates.isEmpty) return;

    try {
      final forwardedMessage = ForwardedPayloadBuilder.withHopAndOrigin(
        source: message,
        hop: hop,
        originId: originId,
      );

      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: forwardedMessage,
      );

      logger.debug('Forwarded locality agent update through mesh', tag: logName);
    } catch (e) {
      logger.debug('Locality agent update forward failed: $e', tag: logName);
    }
  }
}

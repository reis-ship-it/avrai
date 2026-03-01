// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class OrganicSpotDiscoveryForwardingLane {
  const OrganicSpotDiscoveryForwardingLane._();

  static Future<void> forward({
    required Map<String, dynamic> signal,
    required Iterable<String> discoveredNodeIds,
    required MeshForwardingContext context,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    int maxCandidates = 2,
  }) async {
    final candidates = MeshForwardingTargetSelector.select(
      discoveredNodeIds: discoveredNodeIds,
      maxCandidates: maxCandidates,
    );

    if (candidates.isEmpty) return;

    try {
      final payload = Map<String, dynamic>.from(signal);
      payload['origin_id'] = localNodeId;

      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: payload,
      );

      logger.debug(
        'Shared organic spot discovery through mesh: ${signal['geohash']}',
        tag: logName,
      );
    } catch (e) {
      logger.debug('Organic spot discovery forward failed: $e', tag: logName);
    }
  }
}

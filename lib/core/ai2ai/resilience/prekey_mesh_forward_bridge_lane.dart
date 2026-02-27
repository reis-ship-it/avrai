import 'package:avrai/core/ai2ai/routing/mesh_forwarding_context.dart';
import 'package:avrai/core/ai2ai/routing/prekey_bundle_mesh_forwarding_lane.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class PrekeyMeshForwardBridgeLane {
  const PrekeyMeshForwardBridgeLane._();

  static Future<void> forward({
    required bool allowBleSideEffects,
    required MeshForwardingContext? Function() tryCreateMeshForwardingContext,
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required AppLogger logger,
    required String logName,
  }) async {
    if (!allowBleSideEffects) return;

    final MeshForwardingContext? forwardingContext =
        tryCreateMeshForwardingContext();
    if (forwardingContext == null) return;

    await PrekeyBundleMeshForwardingLane.forward(
      bundle: bundle,
      recipientId: recipientId,
      discoveredNodeIds: discoveredNodeIds,
      context: forwardingContext,
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      adaptiveMeshService: adaptiveMeshService,
      logger: logger,
      logName: logName,
      maxCandidates: 2,
    );
  }
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_governance_orchestration_lane.dart';
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
    final payload = Map<String, dynamic>.from(signal);
    payload['origin_id'] = localNodeId;
    final selection = await MeshForwardingTargetSelector.selectWithContext(
      context: context,
      discoveredNodeIds: discoveredNodeIds,
      destinationId: signal['geohash']?.toString() ?? 'organic_spot_discovery',
      geographicScope: signal['geographic_scope']?.toString(),
      maxCandidates: maxCandidates,
    );
    final candidates = selection.peerIds;

    final governancePlan =
        await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
      context: context,
      candidatePeerIds: candidates,
      senderNodeId: localNodeId,
      destinationId: signal['geohash']?.toString() ?? 'organic_spot_discovery',
      payloadKind: 'organic_spot_discovery',
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      geographicScope: signal['geographic_scope']?.toString(),
      payloadContext: <String, dynamic>{
        if (signal['geohash'] != null) 'geohash': signal['geohash'],
      },
      logger: logger,
      logName: logName,
    );

    if (candidates.isEmpty) {
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId:
            signal['geohash']?.toString() ?? 'organic_spot_discovery',
        payloadKind: 'organic_spot_discovery',
        channel: 'mesh_ble_forward',
        payload: payload,
        payloadContext: <String, dynamic>{
          if (signal['geohash'] != null) 'geohash': signal['geohash'],
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: signal['geographic_scope']?.toString(),
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId:
            signal['geohash']?.toString() ?? 'organic_spot_discovery',
        payloadKind: 'organic_spot_discovery',
        forwardedPeerIds: const <String>[],
        failedPeerIds: const <String>[],
        failureReason: deferredEntry == null
            ? 'no_mesh_candidates_available'
            : 'waiting_for_viable_route',
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: signal['geographic_scope']?.toString(),
        payloadContext: <String, dynamic>{
          if (signal['geohash'] != null) 'geohash': signal['geohash'],
        },
        logger: logger,
        logName: logName,
      );
      return;
    }

    try {
      final forwardedPeerIds = <String>[];
      final failedPeerIds = <String>[];

      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: payload,
        onForwarded: (peerId, _) {
          forwardedPeerIds.add(peerId);
        },
        onForwardFailed: (peerId, _, __) {
          failedPeerIds.add(peerId);
        },
      );

      final deferredEntry = forwardedPeerIds.isEmpty
          ? await context.custodyOutbox?.enqueue(
              receiptId: governancePlan.routeReceipt.receiptId,
              destinationId:
                  signal['geohash']?.toString() ?? 'organic_spot_discovery',
              payloadKind: 'organic_spot_discovery',
              channel: 'mesh_ble_forward',
              payload: payload,
              payloadContext: <String, dynamic>{
                if (signal['geohash'] != null) 'geohash': signal['geohash'],
              },
              sourceRouteReceipt: governancePlan.routeReceipt,
              geographicScope: signal['geographic_scope']?.toString(),
            )
          : null;
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId:
            signal['geohash']?.toString() ?? 'organic_spot_discovery',
        payloadKind: 'organic_spot_discovery',
        forwardedPeerIds: forwardedPeerIds,
        failedPeerIds: failedPeerIds,
        failureReason:
            forwardedPeerIds.isEmpty ? 'all_mesh_candidates_failed' : null,
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: signal['geographic_scope']?.toString(),
        payloadContext: <String, dynamic>{
          if (signal['geohash'] != null) 'geohash': signal['geohash'],
        },
        logger: logger,
        logName: logName,
      );

      logger.debug(
        'Shared organic spot discovery through mesh: ${signal['geohash']}',
        tag: logName,
      );
    } catch (e) {
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId:
            signal['geohash']?.toString() ?? 'organic_spot_discovery',
        payloadKind: 'organic_spot_discovery',
        channel: 'mesh_ble_forward',
        payload: payload,
        payloadContext: <String, dynamic>{
          if (signal['geohash'] != null) 'geohash': signal['geohash'],
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: signal['geographic_scope']?.toString(),
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId:
            signal['geohash']?.toString() ?? 'organic_spot_discovery',
        payloadKind: 'organic_spot_discovery',
        forwardedPeerIds: const <String>[],
        failedPeerIds: candidates,
        failureReason: e.toString(),
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: signal['geographic_scope']?.toString(),
        payloadContext: <String, dynamic>{
          if (signal['geohash'] != null) 'geohash': signal['geohash'],
        },
        logger: logger,
        logName: logName,
      );
      logger.debug('Organic spot discovery forward failed: $e', tag: logName);
    }
  }
}

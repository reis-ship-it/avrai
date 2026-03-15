// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/forwarded_payload_builder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_governance_orchestration_lane.dart';
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
    final forwardedPayload = ForwardedPayloadBuilder.withHopAndOrigin(
      source: payload,
      hop: hop,
      originId: originId,
    );
    final candidates =
        await MeshForwardingTargetSelector.excludingReceivedFromAndOrigin(
      discoveredNodeIds: discoveredNodeIds,
      receivedFromDeviceId: receivedFromDeviceId,
      originId: originId,
      context: context,
      geographicScope: payload['scope']?.toString(),
      maxCandidates: maxCandidates,
    );

    final governancePlan =
        await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
      context: context,
      candidatePeerIds: candidates,
      senderNodeId: localNodeId,
      destinationId: originId,
      payloadKind: 'learning_insight_gossip',
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      geographicScope: payload['scope']?.toString(),
      payloadContext: <String, dynamic>{
        'hop': hop,
        'origin_id': originId,
        'received_from_device_id': receivedFromDeviceId,
      },
      logger: logger,
      logName: logName,
    );

    if (candidates.isEmpty) {
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId: originId,
        payloadKind: 'learning_insight_gossip',
        channel: 'mesh_ble_forward',
        payload: forwardedPayload,
        payloadContext: <String, dynamic>{
          'hop': hop,
          'origin_id': originId,
          'received_from_device_id': receivedFromDeviceId,
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: payload['scope']?.toString(),
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: originId,
        payloadKind: 'learning_insight_gossip',
        forwardedPeerIds: const <String>[],
        failedPeerIds: const <String>[],
        failureReason: deferredEntry == null
            ? 'no_mesh_candidates_available'
            : 'waiting_for_viable_route',
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: payload['scope']?.toString(),
        payloadContext: <String, dynamic>{
          'hop': hop,
          'origin_id': originId,
          'received_from_device_id': receivedFromDeviceId,
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
        payload: forwardedPayload,
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
              destinationId: originId,
              payloadKind: 'learning_insight_gossip',
              channel: 'mesh_ble_forward',
              payload: forwardedPayload,
              payloadContext: <String, dynamic>{
                'hop': hop,
                'origin_id': originId,
                'received_from_device_id': receivedFromDeviceId,
              },
              sourceRouteReceipt: governancePlan.routeReceipt,
              geographicScope: payload['scope']?.toString(),
            )
          : null;
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: originId,
        payloadKind: 'learning_insight_gossip',
        forwardedPeerIds: forwardedPeerIds,
        failedPeerIds: failedPeerIds,
        failureReason:
            forwardedPeerIds.isEmpty ? 'all_mesh_candidates_failed' : null,
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: payload['scope']?.toString(),
        payloadContext: <String, dynamic>{
          'hop': hop,
          'origin_id': originId,
          'received_from_device_id': receivedFromDeviceId,
        },
        logger: logger,
        logName: logName,
      );
    } catch (e) {
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId: originId,
        payloadKind: 'learning_insight_gossip',
        channel: 'mesh_ble_forward',
        payload: forwardedPayload,
        payloadContext: <String, dynamic>{
          'hop': hop,
          'origin_id': originId,
          'received_from_device_id': receivedFromDeviceId,
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: payload['scope']?.toString(),
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: originId,
        payloadKind: 'learning_insight_gossip',
        forwardedPeerIds: const <String>[],
        failedPeerIds: candidates,
        failureReason: e.toString(),
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: payload['scope']?.toString(),
        payloadContext: <String, dynamic>{
          'hop': hop,
          'origin_id': originId,
          'received_from_device_id': receivedFromDeviceId,
        },
        logger: logger,
        logName: logName,
      );
      logger.debug('$failureLabel: $e', tag: logName);
    }
  }
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/forwarded_payload_builder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_governance_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

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
    final forwardedMessage = ForwardedPayloadBuilder.withHopAndOrigin(
      source: message,
      hop: hop,
      originId: originId,
    );
    final candidates =
        await MeshForwardingTargetSelector.excludingOptionalOrigin(
      discoveredNodeIds: discoveredNodeIds,
      originId: originId,
      destinationId: originId ?? message['agent_id']?.toString() ?? localNodeId,
      context: context,
      geographicScope: message['scope']?.toString(),
      maxCandidates: maxCandidates,
    );

    final governancePlan =
        await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
      context: context,
      candidatePeerIds: candidates,
      senderNodeId: localNodeId,
      destinationId: originId ?? message['agent_id']?.toString() ?? localNodeId,
      payloadKind: 'locality_agent_update',
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      geographicScope: message['scope']?.toString(),
      payloadContext: <String, dynamic>{
        if (originId != null) 'origin_id': originId,
        'hop': hop,
      },
      logger: logger,
      logName: logName,
    );

    if (candidates.isEmpty) {
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId:
            originId ?? message['agent_id']?.toString() ?? localNodeId,
        payloadKind: 'locality_agent_update',
        channel: 'mesh_ble_forward',
        payload: forwardedMessage,
        payloadContext: <String, dynamic>{
          if (originId != null) 'origin_id': originId,
          'hop': hop,
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: message['scope']?.toString(),
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId:
            originId ?? message['agent_id']?.toString() ?? localNodeId,
        payloadKind: 'locality_agent_update',
        forwardedPeerIds: const <String>[],
        failedPeerIds: const <String>[],
        failureReason: deferredEntry == null
            ? 'no_mesh_candidates_available'
            : 'waiting_for_viable_route',
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: message['scope']?.toString(),
        payloadContext: <String, dynamic>{
          if (originId != null) 'origin_id': originId,
          'hop': hop,
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
        payload: forwardedMessage,
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
                  originId ?? message['agent_id']?.toString() ?? localNodeId,
              payloadKind: 'locality_agent_update',
              channel: 'mesh_ble_forward',
              payload: forwardedMessage,
              payloadContext: <String, dynamic>{
                if (originId != null) 'origin_id': originId,
                'hop': hop,
              },
              sourceRouteReceipt: governancePlan.routeReceipt,
              geographicScope: message['scope']?.toString(),
            )
          : null;
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId:
            originId ?? message['agent_id']?.toString() ?? localNodeId,
        payloadKind: 'locality_agent_update',
        forwardedPeerIds: forwardedPeerIds,
        failedPeerIds: failedPeerIds,
        failureReason:
            forwardedPeerIds.isEmpty ? 'all_mesh_candidates_failed' : null,
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: message['scope']?.toString(),
        payloadContext: <String, dynamic>{
          if (originId != null) 'origin_id': originId,
          'hop': hop,
        },
        logger: logger,
        logName: logName,
      );

      logger.debug('Forwarded locality agent update through mesh',
          tag: logName);
    } catch (e) {
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId:
            originId ?? message['agent_id']?.toString() ?? localNodeId,
        payloadKind: 'locality_agent_update',
        channel: 'mesh_ble_forward',
        payload: forwardedMessage,
        payloadContext: <String, dynamic>{
          if (originId != null) 'origin_id': originId,
          'hop': hop,
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: message['scope']?.toString(),
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId:
            originId ?? message['agent_id']?.toString() ?? localNodeId,
        payloadKind: 'locality_agent_update',
        forwardedPeerIds: const <String>[],
        failedPeerIds: candidates,
        failureReason: e.toString(),
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: message['scope']?.toString(),
        payloadContext: <String, dynamic>{
          if (originId != null) 'origin_id': originId,
          'hop': hop,
        },
        logger: logger,
        logName: logName,
      );
      logger.debug('Locality agent update forward failed: $e', tag: logName);
    }
  }
}

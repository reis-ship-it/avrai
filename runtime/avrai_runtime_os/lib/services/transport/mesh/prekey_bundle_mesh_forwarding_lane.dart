// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_governance_orchestration_lane.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class PrekeyBundleMeshForwardingLane {
  const PrekeyBundleMeshForwardingLane._();

  static Future<void> forward({
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required Iterable<String> discoveredNodeIds,
    required MeshForwardingContext context,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required AppLogger logger,
    required String logName,
    int maxCandidates = 2,
  }) async {
    MeshGovernanceForwardPlan? governancePlan;
    try {
      if (adaptiveMeshService == null) {
        return;
      }

      if (!adaptiveMeshService.shouldForwardMessage(
        currentHop: 0,
        priority: mesh_policy.MessagePriority.high,
        messageType: mesh_policy.MessageType.learningInsight,
        geographicScope: 'locality',
      )) {
        return;
      }

      final forwardPayload = <String, dynamic>{
        'kind': 'prekey_bundle_forward',
        'recipient_id': recipientId,
        'prekey_bundle': bundle.toJson(),
        'hop': 1,
        'origin_id': recipientId,
        'scope': 'locality',
      };
      final candidates =
          await MeshForwardingTargetSelector.excludingRecipientAndLocalNode(
        discoveredNodeIds: discoveredNodeIds,
        recipientId: recipientId,
        localNodeId: localNodeId,
        context: context,
        geographicScope: 'locality',
        maxCandidates: maxCandidates,
      );

      governancePlan =
          await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
        context: context,
        candidatePeerIds: candidates,
        senderNodeId: localNodeId,
        destinationId: recipientId,
        payloadKind: 'prekey_bundle_forward',
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        geographicScope: 'locality',
        payloadContext: const <String, dynamic>{
          'payload_class': 'prekey_bundle',
        },
        logger: logger,
        logName: logName,
      );

      if (candidates.isEmpty) {
        final deferredEntry = await context.custodyOutbox?.enqueue(
          receiptId: governancePlan.routeReceipt.receiptId,
          destinationId: recipientId,
          payloadKind: 'prekey_bundle_forward',
          channel: 'mesh_ble_forward',
          payload: forwardPayload,
          payloadContext: const <String, dynamic>{
            'payload_class': 'prekey_bundle',
          },
          sourceRouteReceipt: governancePlan.routeReceipt,
          geographicScope: 'locality',
        );
        await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
          context: context,
          plan: governancePlan,
          senderNodeId: localNodeId,
          destinationId: recipientId,
          payloadKind: 'prekey_bundle_forward',
          forwardedPeerIds: const <String>[],
          failedPeerIds: const <String>[],
          failureReason: deferredEntry == null
              ? 'no_mesh_candidates_available'
              : 'waiting_for_viable_route',
          deferredToCustody: deferredEntry != null,
          custodyOutboxEntryId: deferredEntry?.entryId,
          geographicScope: 'locality',
          payloadContext: const <String, dynamic>{
            'payload_class': 'prekey_bundle',
          },
          logger: logger,
          logName: logName,
        );
        return;
      }

      final forwardedPeerIds = <String>[];
      final failedPeerIds = <String>[];

      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: forwardPayload,
        geographicScope: 'locality',
        fireAndForgetSend: true,
        onForwarded: (peerId, peerRecipientId) {
          forwardedPeerIds.add(peerId);
          logger.debug(
            'Forwarded prekey bundle through mesh: $recipientId → $peerRecipientId',
            tag: logName,
          );
        },
        onForwardFailed: (peerId, peerRecipientId, error) {
          failedPeerIds.add(peerId);
          logger.debug(
            'Failed to forward prekey bundle to $peerRecipientId: $error',
            tag: logName,
          );
        },
      );

      final deferredEntry = forwardedPeerIds.isEmpty
          ? await context.custodyOutbox?.enqueue(
              receiptId: governancePlan.routeReceipt.receiptId,
              destinationId: recipientId,
              payloadKind: 'prekey_bundle_forward',
              channel: 'mesh_ble_forward',
              payload: forwardPayload,
              payloadContext: const <String, dynamic>{
                'payload_class': 'prekey_bundle',
              },
              sourceRouteReceipt: governancePlan.routeReceipt,
              geographicScope: 'locality',
            )
          : null;
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: recipientId,
        payloadKind: 'prekey_bundle_forward',
        forwardedPeerIds: forwardedPeerIds,
        failedPeerIds: failedPeerIds,
        failureReason:
            forwardedPeerIds.isEmpty ? 'all_mesh_candidates_failed' : null,
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: 'locality',
        payloadContext: const <String, dynamic>{
          'payload_class': 'prekey_bundle',
        },
        logger: logger,
        logName: logName,
      );
    } catch (e) {
      governancePlan ??=
          await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
        context: context,
        candidatePeerIds: const <String>[],
        senderNodeId: localNodeId,
        destinationId: recipientId,
        payloadKind: 'prekey_bundle_forward',
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        geographicScope: 'locality',
        payloadContext: const <String, dynamic>{
          'payload_class': 'prekey_bundle',
        },
        logger: logger,
        logName: logName,
      );
      final deferredEntry = await context.custodyOutbox?.enqueue(
        receiptId: governancePlan.routeReceipt.receiptId,
        destinationId: recipientId,
        payloadKind: 'prekey_bundle_forward',
        channel: 'mesh_ble_forward',
        payload: <String, dynamic>{
          'kind': 'prekey_bundle_forward',
          'recipient_id': recipientId,
          'prekey_bundle': bundle.toJson(),
          'hop': 1,
          'origin_id': recipientId,
          'scope': 'locality',
        },
        payloadContext: const <String, dynamic>{
          'payload_class': 'prekey_bundle',
        },
        sourceRouteReceipt: governancePlan.routeReceipt,
        geographicScope: 'locality',
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: recipientId,
        payloadKind: 'prekey_bundle_forward',
        forwardedPeerIds: const <String>[],
        failedPeerIds: const <String>[],
        failureReason: e.toString(),
        deferredToCustody: deferredEntry != null,
        custodyOutboxEntryId: deferredEntry?.entryId,
        geographicScope: 'locality',
        payloadContext: const <String, dynamic>{
          'payload_class': 'prekey_bundle',
        },
        logger: logger,
        logName: logName,
      );
      logger.debug('Error forwarding prekey bundle through mesh: $e',
          tag: logName);
    }
  }
}

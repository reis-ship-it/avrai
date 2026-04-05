import 'package:avrai_runtime_os/kernel/mesh/dart_mesh_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartMeshRuntimeKernel', () {
    late DateTime now;
    late InMemoryMeshRuntimeStateStore routeStore;
    late InMemoryMeshRuntimeStateStore custodyStore;
    late InMemoryMeshRuntimeStateStore announceStore;
    late MeshRouteLedger routeLedger;
    late MeshCustodyOutbox custodyOutbox;
    late MeshAnnounceLedger announceLedger;
    late MeshInterfaceRegistry interfaceRegistry;
    late DartMeshRuntimeKernel kernel;

    setUp(() {
      now = DateTime.utc(2026, 3, 12, 18);
      routeStore = InMemoryMeshRuntimeStateStore();
      custodyStore = InMemoryMeshRuntimeStateStore();
      announceStore = InMemoryMeshRuntimeStateStore();
      routeLedger = MeshRouteLedger(
        store: routeStore,
        nowUtc: () => now,
      );
      custodyOutbox = MeshCustodyOutbox(
        store: custodyStore,
        nowUtc: () => now,
        defaultRetryBackoff: const Duration(seconds: 30),
      );
      announceLedger = MeshAnnounceLedger(
        store: announceStore,
        nowUtc: () => now,
      );
      interfaceRegistry = MeshInterfaceRegistry(cloudInterfaceAvailable: true);
      kernel = DartMeshRuntimeKernel(
        routeLedger: routeLedger,
        custodyOutbox: custodyOutbox,
        announceLedger: announceLedger,
        interfaceRegistry: interfaceRegistry,
        nowUtc: () => now,
      );
    });

    test('planTransport queues delivery when no route exists and custody is allowed',
        () async {
      final plan = await kernel.planTransport(
        MeshRoutePlanningRequest(
          planningId: 'mesh-plan-queued',
          destinationId: 'peer-b',
          envelope: _envelope('mesh-plan-queued'),
          governanceBundle: _governanceBundle(),
        ),
      );

      expect(plan.allowed, isTrue);
      expect(plan.queued, isTrue);
      expect(plan.lifecycleState, MeshTransportLifecycleState.queued);
      expect(plan.reason, 'awaiting_custody_release');
      expect(kernel.snapshotTransport('mesh-plan-queued')?.lifecycleState,
          MeshTransportLifecycleState.queued);
    });

    test('commit observe replay recover and diagnose expose runtime truth',
        () async {
      final receipt = _routeReceipt(
        receiptId: 'mesh-route-1',
        destinationId: 'peer-c',
        status: 'forwarded',
        recordedAtUtc: now,
        deliveredAtUtc: now.add(const Duration(seconds: 2)),
      );
      await routeLedger.recordForwardOutcome(
        destinationId: 'peer-c',
        channel: 'mesh_ble_forward',
        payloadKind: 'user_chat',
        attemptedRoutes: receipt.plannedRoutes,
        winningRoute: receipt.winningRoute,
        occurredAtUtc: now,
        geographicScope: 'local',
      );
      await custodyOutbox.enqueue(
        receiptId: 'mesh-route-custody',
        destinationId: 'peer-c',
        payloadKind: 'learning_update',
        channel: 'mesh_ble_forward',
        payload: const <String, dynamic>{'kind': 'learning_update'},
        payloadContext: const <String, dynamic>{'proof': true},
        sourceRouteReceipt: receipt,
        geographicScope: 'local',
        nowUtc: now,
      );
      await announceLedger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'peer-c',
          nextHopPeerId: 'peer-c',
          nextHopNodeId: 'node-c',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.93,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: interfaceRegistry.resolveByInterfaceId(
          'ble',
          privacyMode: MeshTransportPrivacyMode.privateMesh,
        ),
        nowUtc: now,
      );

      final plan = await kernel.planTransport(
        MeshRoutePlanningRequest(
          planningId: 'mesh-plan-live',
          destinationId: 'peer-c',
          envelope: _envelope('mesh-plan-live', routeReceipt: receipt),
          governanceBundle: _governanceBundle(),
          routeReceipt: receipt,
        ),
      );
      final commit = await kernel.commitTransport(
        MeshTransportCommit(
          attemptId: 'mesh-commit-live',
          plan: plan,
          envelope: _envelope('mesh-commit-live', routeReceipt: receipt),
        ),
      );
      final observation = await kernel.observeTransport(
        MeshObservation(
          observationId: 'mesh-observation-live',
          subjectId: 'mesh-route-1',
          lifecycleState: MeshLifecycleState.delivered,
          observedAtUtc: now.add(const Duration(seconds: 2)),
          envelope: _envelope('mesh-observation-live', routeReceipt: receipt),
          governanceBundle: _governanceBundle(),
          routeReceipt: receipt,
        ),
      );
      final replay = await kernel.replayMesh(
        const KernelReplayRequest(subjectId: 'peer-c'),
      );
      final recovery = await kernel.recoverMesh(
        KernelRecoveryRequest(
          subjectId: 'mesh-restored',
          persistedEnvelope: const <String, dynamic>{
            'subject_id': 'mesh-restored',
            'destination_id': 'peer-z',
            'lifecycle_state': 'queued',
            'saved_at_utc': '2026-03-12T18:00:00.000Z',
            'queue_depth': 3,
          },
        ),
      );
      final health = await kernel.diagnoseMesh();

      expect(
        commit.lifecycleState,
        MeshTransportLifecycleState.transportDelivered,
      );
      expect(observation.accepted, isTrue);
      expect(replay, isNotEmpty);
      expect(recovery.restoredCount, 1);
      expect(kernel.snapshotTransport('mesh-restored')?.queueDepth, 3);
      expect(health.status, MeshHealthStatus.healthy);
      expect(health.diagnostics['route_receipt_truth_present'], isTrue);
      expect(health.diagnostics['snapshot_supported'], isTrue);
      expect(health.diagnostics['replay_supported'], isTrue);
      expect(health.diagnostics['pending_custody_count'], 1);
    });
  });
}

KernelEventEnvelope _envelope(
  String eventId, {
  TransportRouteReceipt? routeReceipt,
}) {
  return KernelEventEnvelope(
    eventId: eventId,
    occurredAtUtc: DateTime.utc(2026, 3, 12, 18),
    userId: 'local-user',
    agentId: 'agent-a',
    sourceSystem: 'test',
    eventType: 'mesh_test',
    actionType: 'validate',
    entityId: eventId,
    entityType: 'message',
    privacyMode: MeshTransportPrivacyMode.privateMesh,
    routeReceipt: routeReceipt,
  );
}

KernelContextBundle _governanceBundle() {
  return KernelContextBundle(
    who: const WhoKernelSnapshot(
      primaryActor: 'agent-a',
      affectedActor: 'peer-c',
      companionActors: <String>[],
      actorRoles: <String>['peer'],
      trustScope: 'private',
      cohortRefs: <String>[],
      identityConfidence: 0.92,
    ),
    what: const WhatKernelSnapshot(
      actionType: 'deliver',
      targetEntityType: 'message',
      targetEntityId: 'message-1',
      stateTransitionType: 'planned_to_delivered',
      outcomeType: 'delivery',
      semanticTags: <String>['mesh'],
      taxonomyConfidence: 0.88,
    ),
    when: WhenKernelSnapshot(
      observedAt: DateTime.utc(2026, 3, 12, 18),
      freshness: 0.9,
      recencyBucket: 'hot',
      timingConflictFlags: const <String>[],
      temporalConfidence: 0.9,
    ),
    where: const WhereKernelSnapshot(
      localityToken: 'where:bham:test',
      cityCode: 'bham',
      localityCode: 'test',
      projection: <String, dynamic>{'mode': 'local'},
      boundaryTension: 0.1,
      spatialConfidence: 0.87,
      travelFriction: 0.2,
      placeFitFlags: <String>['local'],
    ),
    how: const HowKernelSnapshot(
      executionPath: 'dart_mesh_runtime_kernel_test',
      workflowStage: 'validation',
      transportMode: 'mesh',
      plannerMode: 'governed',
      modelFamily: 'signal_reticulum',
      interventionChain: <String>['plan', 'commit', 'observe'],
      failureMechanism: 'none',
      mechanismConfidence: 0.9,
    ),
    why: WhyKernelSnapshot(
      goal: 'prove_runtime_kernel',
      summary: 'Validate live mesh runtime behavior.',
      rootCauseType: WhyRootCauseType.mechanism,
      confidence: 0.84,
      drivers: const <WhySignal>[WhySignal(label: 'test', weight: 1.0)],
      inhibitors: const <WhySignal>[],
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 12, 18),
    ),
  );
}

TransportRouteReceipt _routeReceipt({
  required String receiptId,
  required String destinationId,
  required String status,
  required DateTime recordedAtUtc,
  DateTime? deliveredAtUtc,
}) {
  const route = TransportRouteCandidate(
    routeId: 'ble:peer-c:node-c',
    mode: TransportMode.ble,
    confidence: 0.9,
    estimatedLatencyMs: 110,
    rationale: 'test_route',
    metadata: <String, dynamic>{
      'peer_id': 'peer-c',
      'peer_node_id': 'node-c',
      'mesh_interface_kind': 'ble',
    },
  );
  return TransportRouteReceipt(
    receiptId: receiptId,
    channel: 'mesh_ble_forward',
    status: status,
    recordedAtUtc: recordedAtUtc,
    plannedRoutes: const <TransportRouteCandidate>[route],
    attemptedRoutes: const <TransportRouteCandidate>[route],
    winningRoute: route,
    hopCount: 1,
    queuedAtUtc: recordedAtUtc,
    custodyAcceptedAtUtc: recordedAtUtc.add(const Duration(seconds: 1)),
    custodyAcceptedBy: 'node-c',
    deliveredAtUtc: deliveredAtUtc,
    metadata: <String, dynamic>{
      'destination_id': destinationId,
      'peer_id': destinationId,
      'privacy_mode': MeshTransportPrivacyMode.privateMesh,
      'mesh_route_resolution_mode': 'announce',
    },
  );
}

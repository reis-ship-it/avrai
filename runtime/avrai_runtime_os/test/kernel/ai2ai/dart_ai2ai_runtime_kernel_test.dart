import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/monitoring/ai2ai_network_activity_event.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartAi2AiRuntimeKernel', () {
    late DateTime now;
    late NetworkActivityMonitor monitor;
    late DartAi2AiRuntimeKernel kernel;

    setUp(() {
      now = DateTime.utc(2026, 3, 12, 18);
      monitor = NetworkActivityMonitor();
      kernel = DartAi2AiRuntimeKernel(
        networkActivityMonitor: monitor,
        nowUtc: () => now,
      );
    });

    test('planExchange commitExchange observeExchange build real lifecycle truth and replay records',
        () async {
      final receipt = _routeReceipt(
        receiptId: 'ai2ai-route-1',
        recordedAtUtc: now,
        deliveredAtUtc: now.add(const Duration(seconds: 1)),
        readAtUtc: now.add(const Duration(seconds: 2)),
        learningAppliedAtUtc: now.add(const Duration(seconds: 3)),
      );
      final candidate = _candidate(routeReceipt: receipt).toExchangeCandidate();

      final plan = await kernel.planExchange(candidate);
      final commit = await kernel.commitExchange(
        Ai2AiExchangeCommit(
          attemptId: 'ai2ai-commit-1',
          plan: plan,
          envelope: candidate.envelope,
        ),
      );
      await kernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId: 'ai2ai-observation-read-1',
          exchangeId: candidate.exchangeId,
          conversationId: candidate.conversationId,
          lifecycleState: Ai2AiExchangeLifecycleState.peerConsumed,
          observedAtUtc: now.add(const Duration(seconds: 2)),
          envelope: candidate.envelope,
          governanceBundle: candidate.governanceBundle,
          routeReceipt: receipt,
        ),
      );
      final observation = await kernel.observeExchange(
        Ai2AiExchangeObservation(
          observationId: 'ai2ai-observation-1',
          exchangeId: candidate.exchangeId,
          conversationId: candidate.conversationId,
          lifecycleState: Ai2AiExchangeLifecycleState.peerApplied,
          observedAtUtc: now.add(const Duration(seconds: 3)),
          envelope: candidate.envelope,
          governanceBundle: candidate.governanceBundle,
          routeReceipt: receipt,
        ),
      );
      final replay = await kernel.replayAi2Ai(
        const KernelReplayRequest(subjectId: 'message-1'),
      );
      final health = await kernel.diagnoseAi2Ai();

      expect(plan.lifecycleState, Ai2AiExchangeLifecycleState.peerApplied);
      expect(commit.lifecycleState, Ai2AiExchangeLifecycleState.committed);
      expect(observation.accepted, isTrue);
      expect(replay, isNotEmpty);
      expect(kernel.snapshotExchange('message-1')?.lifecycleState,
          Ai2AiExchangeLifecycleState.peerApplied);
      expect(health.status, Ai2AiHealthStatus.healthy);
      expect(health.diagnostics['delivery_truth_present'], isTrue);
      expect(health.diagnostics['learning_truth_present'], isTrue);
      expect(health.diagnostics['peer_received_count'], 0);
      expect(health.diagnostics['peer_applied_count'], 1);
      expect(health.diagnostics['snapshot_supported'], isTrue);
      expect(health.diagnostics['replay_supported'], isTrue);
    });

    test('recover restores persisted snapshot into runtime kernel', () async {
      final report = await kernel.recoverAi2Ai(
        const KernelRecoveryRequest(
          subjectId: 'message-restored',
          persistedEnvelope: <String, dynamic>{
            'subject_id': 'message-restored',
            'conversation_id': 'conversation-restored',
            'lifecycle_state': 'queued',
            'saved_at_utc': '2026-03-12T18:00:00.000Z',
            'payload_class': 'message',
          },
        ),
      );

      expect(report.restoredCount, 1);
      expect(
        kernel.snapshotAi2Ai('message-restored')?.conversationId,
        'conversation-restored',
      );
    });

    test('diagnose degrades when encryption failure is observed', () async {
      monitor.logEvent(
        AI2AINetworkActivityEvent(
          eventType: AI2AINetworkActivityEventType.encryptionFailure,
          occurredAt: now,
          connectionId: 'conversation-1',
        ),
      );

      final health = await kernel.diagnoseAi2Ai();

      expect(health.status, Ai2AiHealthStatus.degraded);
      expect(health.diagnostics['encryption_failure_count'], 1);
    });

    test('observeExchange tracks exact peer-truth lifecycle stages', () async {
      final candidate = _candidate(
        routeReceipt: _routeReceipt(
          receiptId: 'ai2ai-route-peer-truth',
          recordedAtUtc: now,
        ),
      ).toExchangeCandidate();
      final plan = await kernel.planExchange(candidate);
      await kernel.commitExchange(
        Ai2AiExchangeCommit(
          attemptId: 'ai2ai-peer-truth-commit',
          plan: plan,
          envelope: candidate.envelope,
        ),
      );

      for (final stage in const <Ai2AiExchangeLifecycleState>[
        Ai2AiExchangeLifecycleState.peerReceived,
        Ai2AiExchangeLifecycleState.peerValidated,
        Ai2AiExchangeLifecycleState.peerConsumed,
        Ai2AiExchangeLifecycleState.peerApplied,
      ]) {
        await kernel.observeExchange(
          Ai2AiExchangeObservation(
            observationId: 'obs-${stage.name}',
            exchangeId: candidate.exchangeId,
            conversationId: candidate.conversationId,
            lifecycleState: stage,
            observedAtUtc: now.add(const Duration(minutes: 1)),
            envelope: candidate.envelope,
            governanceBundle: candidate.governanceBundle,
            routeReceipt: candidate.routeReceipt,
          ),
        );
        expect(kernel.snapshotExchange(candidate.exchangeId)?.lifecycleState, stage);
      }

      final health = await kernel.diagnoseAi2Ai();
      expect(health.diagnostics['peer_received_count'], 1);
      expect(health.diagnostics['peer_validated_count'], 1);
      expect(health.diagnostics['peer_consumed_count'], 1);
      expect(health.diagnostics['peer_applied_count'], 1);
    });
  });
}

Ai2AiMessageCandidate _candidate({
  required TransportRouteReceipt routeReceipt,
}) {
  return Ai2AiMessageCandidate(
    messageId: 'message-1',
    conversationId: 'conversation-1',
    peerId: 'peer-b',
    payloadClass: Ai2AiPayloadClass.message,
    envelope: KernelEventEnvelope(
      eventId: 'message-1',
      occurredAtUtc: DateTime.utc(2026, 3, 12, 18),
      userId: 'local-user',
      agentId: 'agent-a',
      sourceSystem: 'test',
      eventType: 'ai2ai_message',
      actionType: 'deliver',
      entityId: 'message-1',
      entityType: 'chat_message',
      privacyMode: 'private_mesh',
      routeReceipt: routeReceipt,
      policyContext: const <String, dynamic>{'egress_allowed': true},
    ),
    governanceBundle: KernelContextBundle(
      who: const WhoKernelSnapshot(
        primaryActor: 'agent-a',
        affectedActor: 'peer-b',
        companionActors: <String>[],
        actorRoles: <String>['peer'],
        trustScope: 'private',
        cohortRefs: <String>[],
        identityConfidence: 0.9,
      ),
      what: const WhatKernelSnapshot(
        actionType: 'message',
        targetEntityType: 'conversation',
        targetEntityId: 'conversation-1',
        stateTransitionType: 'planned_to_learning_applied',
        outcomeType: 'learning_applied',
        semanticTags: <String>['ai2ai'],
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
        localityToken: 'where:test',
        cityCode: 'bham',
        localityCode: 'test',
        projection: <String, dynamic>{},
        boundaryTension: 0.0,
        spatialConfidence: 0.9,
        travelFriction: 0.0,
        placeFitFlags: <String>[],
      ),
      how: const HowKernelSnapshot(
        executionPath: 'dart_ai2ai_runtime_kernel_test',
        workflowStage: 'validation',
        transportMode: 'mesh',
        plannerMode: 'governed',
        modelFamily: 'signal_reticulum',
        interventionChain: <String>['plan', 'commit', 'observe'],
        failureMechanism: 'none',
        mechanismConfidence: 0.9,
      ),
      why: WhyKernelSnapshot(
        goal: 'prove_ai2ai_runtime_kernel',
        summary: 'Validate AI2AI delivery and learning truth.',
        rootCauseType: WhyRootCauseType.mechanism,
        confidence: 0.85,
        drivers: const <WhySignal>[WhySignal(label: 'test', weight: 1.0)],
        inhibitors: const <WhySignal>[],
        counterfactuals: const <WhyCounterfactual>[],
        createdAtUtc: DateTime.utc(2026, 3, 12, 18),
      ),
    ),
    routeReceipt: routeReceipt,
    requiresLearningReceipt: true,
  );
}

TransportRouteReceipt _routeReceipt({
  required String receiptId,
  required DateTime recordedAtUtc,
  DateTime? deliveredAtUtc,
  DateTime? readAtUtc,
  DateTime? learningAppliedAtUtc,
}) {
  const route = TransportRouteCandidate(
    routeId: 'ble:peer-b:node-b',
    mode: TransportMode.ble,
    confidence: 0.91,
    estimatedLatencyMs: 95,
    rationale: 'test_route',
    metadata: <String, dynamic>{
      'peer_id': 'peer-b',
      'peer_node_id': 'node-b',
    },
  );
  return TransportRouteReceipt(
    receiptId: receiptId,
    channel: 'mesh_ble_forward',
    status: learningAppliedAtUtc != null ? 'forwarded' : 'delivered',
    recordedAtUtc: recordedAtUtc,
    plannedRoutes: const <TransportRouteCandidate>[route],
    attemptedRoutes: const <TransportRouteCandidate>[route],
    winningRoute: route,
    hopCount: 1,
    queuedAtUtc: recordedAtUtc,
    custodyAcceptedAtUtc: recordedAtUtc.add(const Duration(milliseconds: 500)),
    custodyAcceptedBy: 'node-b',
    deliveredAtUtc: deliveredAtUtc,
    readAtUtc: readAtUtc,
    readBy: readAtUtc == null ? null : 'peer-b',
    learningAppliedAtUtc: learningAppliedAtUtc,
    learningAppliedBy: learningAppliedAtUtc == null ? null : 'local-user',
    metadata: const <String, dynamic>{
      'conversation_id': 'conversation-1',
      'peer_id': 'peer-b',
      'payload_class': 'message',
      'mesh_route_resolution_mode': 'announce',
    },
  );
}

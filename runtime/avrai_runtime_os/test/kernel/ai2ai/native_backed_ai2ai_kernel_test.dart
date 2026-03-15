import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_priority.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/native_backed_ai2ai_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NativeBackedAi2AiKernel', () {
    test('falls back when native bridge is unavailable', () async {
      final kernel = NativeBackedAi2AiKernel(
        nativeBridge: _UnavailableAi2AiBridge(),
        fallback: _FakeAi2AiFallback(),
        policy: const Ai2AiNativeExecutionPolicy(requireNative: false),
      );

      final plan = await kernel.planAi2Ai(_candidate());

      expect(plan.reason, 'fallback_plan');
    });

    test('throws when native is required and unavailable', () async {
      final kernel = NativeBackedAi2AiKernel(
        nativeBridge: _UnavailableAi2AiBridge(),
        fallback: _FakeAi2AiFallback(),
        policy: const Ai2AiNativeExecutionPolicy(requireNative: true),
      );

      expect(
        () => kernel.planAi2Ai(_candidate()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native AI2AI kernel is required'),
          ),
        ),
      );
    });

    test('consumes handled native lifecycle payload', () async {
      final audit = Ai2AiNativeFallbackAudit();
      final kernel = NativeBackedAi2AiKernel(
        nativeBridge: _DispatchingAi2AiBridge(
          <String, Map<String, dynamic>>{
            'plan_ai2ai': <String, dynamic>{
              'handled': true,
              'payload': <String, dynamic>{
                'plan_id': 'ai2ai-plan-native',
                'message_id': 'message-1',
                'lifecycle_state': 'delivered',
                'allowed': true,
                'planned_at_utc': '2026-03-12T18:00:00.000Z',
                'reason': 'native_plan',
                'context': const <String, dynamic>{'source': 'native'},
              },
            },
          },
        ),
        fallback: _FakeAi2AiFallback(),
        audit: audit,
      );

      final plan = await kernel.planAi2Ai(_candidate());

      expect(plan.reason, 'native_plan');
      expect(plan.lifecycleState, Ai2AiLifecycleState.delivered);
      expect(audit.nativeHandledCount, 1);
    });

    test('diagnose reports native-backed health when native handles syscall',
        () async {
      final audit = Ai2AiNativeFallbackAudit();
      final kernel = NativeBackedAi2AiKernel(
        nativeBridge: _DispatchingAi2AiBridge(
          <String, Map<String, dynamic>>{
            'diagnose_ai2ai_kernel': <String, dynamic>{
              'handled': true,
              'payload': const <String, dynamic>{
                'delivery_truth_present': true,
                'learning_truth_present': true,
                'snapshot_supported': true,
                'replay_supported': true,
              },
            },
          },
        ),
        fallback: _FakeAi2AiFallback(),
        audit: audit,
      );

      final health = await kernel.diagnoseAi2Ai();

      expect(health.nativeBacked, isTrue);
      expect(health.status, Ai2AiHealthStatus.healthy);
      expect(health.diagnostics['delivery_truth_present'], isTrue);
      expect(audit.nativeHandledCount, 1);
    });
  });
}

class _UnavailableAi2AiBridge implements Ai2AiNativeInvocationBridge {
  @override
  bool get isAvailable => false;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError();
  }
}

class _DispatchingAi2AiBridge implements Ai2AiNativeInvocationBridge {
  _DispatchingAi2AiBridge(this._responses);

  final Map<String, Map<String, dynamic>> _responses;

  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    return _responses[syscall] ?? const <String, dynamic>{'handled': false};
  }
}

class _FakeAi2AiFallback extends Ai2AiKernelFallbackSurface {
  @override
  Future<Ai2AiExchangeReceipt> commitExchange(Ai2AiExchangeCommit request) async {
    return Ai2AiExchangeReceipt(
      recordId: request.attemptId,
      exchangeId: request.plan.exchangeId,
      accepted: true,
      lifecycleState: Ai2AiExchangeLifecycleState.committed,
      recordedAtUtc: DateTime.utc(2026, 3, 12, 18),
    );
  }

  @override
  Future<Ai2AiExchangeReceipt> observeExchange(
    Ai2AiExchangeObservation observation,
  ) async {
    return Ai2AiExchangeReceipt(
      recordId: observation.observationId,
      exchangeId: observation.exchangeId,
      accepted: true,
      lifecycleState: observation.lifecycleState,
      recordedAtUtc: DateTime.utc(2026, 3, 12, 18),
    );
  }

  @override
  Future<Ai2AiExchangePlan> planExchange(Ai2AiExchangeCandidate candidate) async {
    return Ai2AiExchangePlan(
      planId: 'ai2ai-plan-fallback',
      exchangeId: candidate.exchangeId,
      lifecycleState: Ai2AiExchangeLifecycleState.peerReceived,
      allowed: true,
      plannedAtUtc: DateTime.utc(2026, 3, 12, 18),
      decision: candidate.decision,
      reason: 'fallback_plan',
    );
  }

  @override
  Ai2AiExchangeSnapshot? snapshotExchange(String subjectId) {
    return Ai2AiExchangeSnapshot(
      subjectId: subjectId,
      conversationId: 'conversation-1',
      lifecycleState: Ai2AiExchangeLifecycleState.committed,
      savedAtUtc: DateTime.utc(2026, 3, 12, 18),
      artifactClass: Ai2AiExchangeArtifactClass.memoryArtifact,
    );
  }
}

Ai2AiMessageCandidate _candidate() {
  return Ai2AiMessageCandidate(
    messageId: 'message-1',
    conversationId: 'conversation-1',
    peerId: 'peer-b',
    payloadClass: Ai2AiPayloadClass.message,
    envelope: KernelEventEnvelope(
      eventId: 'message-1',
      occurredAtUtc: DateTime.utc(2026, 3, 12, 18),
      agentId: 'agent-a',
      eventType: 'ai2ai_message',
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
        actionType: 'deliver',
        targetEntityType: 'message',
        targetEntityId: 'message-1',
        stateTransitionType: 'planned',
        outcomeType: 'pending',
        semanticTags: <String>['ai2ai'],
        taxonomyConfidence: 0.9,
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
        executionPath: 'test',
        workflowStage: 'validation',
        transportMode: 'mesh',
        plannerMode: 'governed',
        modelFamily: 'signal_reticulum',
        interventionChain: <String>[],
        failureMechanism: 'none',
        mechanismConfidence: 0.9,
      ),
      why: WhyKernelSnapshot(
        goal: 'test',
        summary: 'test',
        rootCauseType: WhyRootCauseType.mechanism,
        confidence: 0.9,
        drivers: const <WhySignal>[],
        inhibitors: const <WhySignal>[],
        counterfactuals: const <WhyCounterfactual>[],
        createdAtUtc: DateTime.utc(2026, 3, 12, 18),
      ),
    ),
  );
}

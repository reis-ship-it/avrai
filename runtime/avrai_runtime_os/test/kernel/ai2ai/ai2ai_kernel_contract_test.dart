import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ai2AiKernelContract', () {
    test('default replay and projection use snapshot truth', () async {
      final kernel = _FakeAi2AiKernel();

      final replay = await kernel.replayAi2Ai(
        const KernelReplayRequest(subjectId: 'message:1'),
      );
      final projection = await kernel.projectAi2AiForRealityModel(
        Ai2AiProjectionRequest(
          subjectId: 'message:1',
          whenSnapshot: WhenKernelSnapshot(
            observedAt: DateTime.utc(2026, 3, 11, 16),
            freshness: 0.76,
            recencyBucket: 'active',
            timingConflictFlags: const <String>['none'],
            temporalConfidence: 0.88,
          ),
        ),
      );
      final health = await kernel.diagnoseAi2Ai();

      expect(replay.single.summary, contains('conversation-1'));
      expect(projection.what.payload['conversation_id'], 'conversation-1');
      expect(projection.when.payload['projection_surface'], 'when');
      expect(projection.when.features['freshness'], 0.76);
      expect(projection.why.payload['projection_surface'], 'why');
      expect(health.kernelId, 'ai2ai_runtime_governance');
    });

    test('simulation request round-trips through json', () {
      final candidate = Ai2AiMessageCandidate(
        messageId: 'message-1',
        conversationId: 'conversation-1',
        peerId: 'peer-b',
        payloadClass: Ai2AiPayloadClass.message,
        envelope: KernelEventEnvelope(
          eventId: 'ai2ai-event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 11),
          agentId: 'agent-a',
          eventType: 'ai2ai_message_candidate',
        ),
        governanceBundle: _governanceBundle(),
      );
      final request = Ai2AiSimulationRequest(
        simulationId: 'ai2ai-sim-1',
        runContext: const MonteCarloRunContext(
          canonicalReplayYear: 2026,
          replayYear: 2026,
          branchId: 'branch-bham',
          runId: 'run-ai2ai-1',
          seed: 9,
          divergencePolicy: 'bounded',
        ),
        seedCandidates: <Ai2AiMessageCandidate>[candidate],
      );

      final decoded = Ai2AiSimulationRequest.fromJson(request.toJson());
      expect(decoded.simulationId, request.simulationId);
      expect(decoded.seedCandidates.single.messageId, 'message-1');
      expect(
        decoded.seedCandidates.single.governanceBundle.why?.goal,
        'deliver_message',
      );
    });

    test('default simulation echoes AI2AI runtime frame telemetry', () async {
      final kernel = _FakeAi2AiKernel();
      final result = await kernel.simulateAi2Ai(
        const Ai2AiSimulationRequest(
          simulationId: 'ai2ai-sim-2',
          runContext: MonteCarloRunContext(
            canonicalReplayYear: 2026,
            replayYear: 2026,
            branchId: 'branch-bham',
            runId: 'run-ai2ai-2',
            seed: 7,
            divergencePolicy: 'bounded',
          ),
          topology: <String, dynamic>{
            'ai2ai_runtime_state_frame': <String, dynamic>{
              'recent_event_count': 4,
            },
          },
        ),
      );

      expect(result.simulationId, 'ai2ai-sim-2');
      expect(result.telemetry['seed_candidate_count'], 0);
      expect(
        (result.telemetry['ai2ai_runtime_state_frame']
            as Map)['recent_event_count'],
        4,
      );
    });
  });
}

class _FakeAi2AiKernel extends Ai2AiKernelContract {
  @override
  Future<Ai2AiExchangeReceipt> commitExchange(
    Ai2AiExchangeCommit request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Ai2AiExchangeReceipt> observeExchange(
    Ai2AiExchangeObservation observation,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Ai2AiExchangePlan> planExchange(
    Ai2AiExchangeCandidate candidate,
  ) async {
    throw UnimplementedError();
  }

  @override
  Ai2AiExchangeSnapshot? snapshotExchange(String subjectId) {
    return Ai2AiExchangeSnapshot(
      subjectId: subjectId,
      conversationId: 'conversation-1',
      lifecycleState: Ai2AiExchangeLifecycleState.peerReceived,
      savedAtUtc: DateTime.utc(2026, 3, 11, 12),
      artifactClass: Ai2AiExchangeArtifactClass.memoryArtifact,
    );
  }
}

KernelContextBundle _governanceBundle() {
  return KernelContextBundle(
    who: const WhoKernelSnapshot(
      primaryActor: 'agent-a',
      affectedActor: 'peer-b',
      companionActors: <String>[],
      actorRoles: <String>['peer'],
      trustScope: 'private',
      cohortRefs: <String>[],
      identityConfidence: 0.91,
    ),
    what: const WhatKernelSnapshot(
      actionType: 'message',
      targetEntityType: 'conversation',
      targetEntityId: 'conversation-1',
      stateTransitionType: 'candidate_to_delivered',
      outcomeType: 'pending',
      semanticTags: <String>['ai2ai', 'message'],
      taxonomyConfidence: 0.87,
    ),
    when: WhenKernelSnapshot(
      observedAt: DateTime.utc(2026, 3, 11, 12),
      freshness: 0.76,
      recencyBucket: 'active',
      timingConflictFlags: const <String>['none'],
      temporalConfidence: 0.88,
    ),
    where: const WhereKernelSnapshot(
      localityToken: 'where:bham:1',
      cityCode: 'bham',
      localityCode: 'southside',
      projection: <String, dynamic>{'mode': 'local'},
      boundaryTension: 0.1,
      spatialConfidence: 0.85,
      travelFriction: 0.22,
      placeFitFlags: <String>['proximate'],
    ),
    how: const HowKernelSnapshot(
      executionPath: 'native_ai2ai',
      workflowStage: 'delivery',
      transportMode: 'mesh',
      plannerMode: 'governed',
      modelFamily: 'signal_reticulum',
      interventionChain: <String>['observe', 'decide', 'deliver'],
      failureMechanism: 'none',
      mechanismConfidence: 0.9,
    ),
    why: WhyKernelSnapshot(
      goal: 'deliver_message',
      summary: 'Message selected for delivery and learning update.',
      rootCauseType: WhyRootCauseType.mechanism,
      confidence: 0.85,
      drivers: const <WhySignal>[
        WhySignal(label: 'conversation_priority', weight: 0.88),
      ],
      inhibitors: const <WhySignal>[],
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 11, 12),
    ),
  );
}

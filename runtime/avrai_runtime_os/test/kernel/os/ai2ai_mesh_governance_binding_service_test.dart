import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ai2AiMeshGovernanceBindingService', () {
    test('builds mesh planning requests with governed runtime context',
        () async {
      final service = Ai2AiMeshGovernanceBindingService(
        kernelOs: _FakeFunctionalKernelOs(),
      );
      final request = await service.buildMeshPlanningRequest(
        planningId: 'mesh-plan-1',
        destinationId: 'peer-b',
        envelope: KernelEventEnvelope(
          eventId: 'mesh-event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 12, 10),
          agentId: 'agent-a',
          eventType: 'mesh_plan_candidate',
        ),
        predictedOutcome: 'delivered',
      );

      expect(request.governanceBundle.who?.primaryActor, 'agent-a');
      expect(request.runtimeContext['governance_record_id'], 'record-1');
      expect(request.policyContext['governance_goal'], 'deliver_message');
    });

    test('builds ai2ai exchange candidates with governed context trace',
        () async {
      final service = Ai2AiMeshGovernanceBindingService(
        kernelOs: _FakeFunctionalKernelOs(),
      );
      final candidate = await service.buildAi2AiExchangeCandidate(
        messageId: 'exchange-legacy-compat-1',
        conversationId: 'conversation-1',
        peerId: 'peer-b',
        artifactClass: Ai2AiExchangeArtifactClass.memoryArtifact,
        envelope: KernelEventEnvelope(
          eventId: 'ai2ai-event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 12, 11),
          agentId: 'agent-a',
          eventType: 'ai2ai_message_candidate',
        ),
        requiresApplyReceipt: true,
      );

      expect(candidate.governanceBundle.why?.goal, 'deliver_message');
      expect(candidate.context['governance_event_id'], 'mesh-event-1');
      expect(candidate.requiresApplyReceipt, isTrue);
    });
  });
}

class _FakeFunctionalKernelOs implements FunctionalKernelOs {
  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<KernelBundleRecord> resolveAndExplain({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return KernelBundleRecord(
      recordId: 'record-1',
      eventId: 'mesh-event-1',
      bundle: KernelContextBundle(
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
          stateTransitionType: 'queued_to_delivered',
          outcomeType: 'pending',
          semanticTags: <String>['mesh', 'ai2ai'],
          taxonomyConfidence: 0.88,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 12, 10),
          freshness: 0.8,
          recencyBucket: 'hot',
          timingConflictFlags: const <String>['none'],
          temporalConfidence: 0.91,
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
          executionPath: 'governed_runtime',
          workflowStage: 'delivery',
          transportMode: 'mesh',
          plannerMode: 'governed',
          modelFamily: 'signal_reticulum',
          interventionChain: <String>['resolve', 'explain'],
          failureMechanism: 'none',
          mechanismConfidence: 0.89,
        ),
        why: WhyKernelSnapshot(
          goal: 'deliver_message',
          summary: 'Governed delivery path selected.',
          rootCauseType: WhyRootCauseType.mechanism,
          confidence: 0.84,
          drivers: const <WhySignal>[
            WhySignal(label: 'delivery_probability', weight: 0.9),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 12, 10),
        ),
      ),
      createdAtUtc: DateTime.utc(2026, 3, 12, 10),
    );
  }

  @override
  Future<KernelContextBundle> resolveKernelContext(
    KernelEventEnvelope envelope,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhereKernelSnapshot> resolveWhere(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }
}

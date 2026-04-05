import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/ai2ai/ai2ai_connection_governance_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ai2AiConnectionGovernanceOrchestrationLane', () {
    test('records governed AI2AI connection plans', () async {
      final fakeKernelOs = _FakeFunctionalKernelOs();
      final service = Ai2AiMeshGovernanceBindingService(kernelOs: fakeKernelOs);
      String? recordedSubjectId;
      String? recordedRecordId;

      final recordId =
          await Ai2AiConnectionGovernanceOrchestrationLane.recordPlan(
        governanceBindingService: service,
        localUserId: 'user-a',
        localAgentId: 'agent-a',
        remoteNode: _remoteNode(),
        canonicalPeerMetadata: const <String, dynamic>{
          'canonical_reason_codes': <String>['shared_geography'],
          'peer_why_summary': 'Shared geography supports this peer connection.',
        },
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'Ai2AiConnectionGovernanceOrchestrationLaneTest',
        onRecorded: (subjectId, nextRecordId) {
          recordedSubjectId = subjectId;
          recordedRecordId = nextRecordId;
        },
      );

      expect(recordId, 'record-1');
      expect(recordedSubjectId, 'peer-b');
      expect(recordedRecordId, 'record-1');
      expect(fakeKernelOs.lastEnvelope?.eventType, 'ai2ai_connection_plan');
      expect(
        fakeKernelOs.lastWhyRequest?.predictedOutcome,
        'connection_established',
      );
      expect(
        fakeKernelOs.lastEnvelope?.context['canonical_peer_metadata'],
        isA<Map<String, dynamic>>(),
      );
    });

    test('records governed AI2AI connection outcomes', () async {
      final fakeKernelOs = _FakeFunctionalKernelOs();
      final service = Ai2AiMeshGovernanceBindingService(kernelOs: fakeKernelOs);
      String? recordedSubjectId;

      final connection = ConnectionMetrics.initial(
        localAISignature: 'local-agent',
        remoteAISignature: 'remote-agent',
        compatibility: 0.82,
      ).complete(
        finalStatus: ConnectionStatus.completed,
        completionReason: 'natural_completion',
      );

      final recordId =
          await Ai2AiConnectionGovernanceOrchestrationLane.recordOutcome(
        governanceBindingService: service,
        localUserId: 'user-a',
        localAgentId: 'agent-a',
        remoteNode: _remoteNode(),
        connection: connection,
        canonicalPeerMetadata: const <String, dynamic>{
          'canonical_reason_codes': <String>['personal_surface_alignment'],
          'peer_why_summary': 'Personal vibe alignment drove this connection.',
        },
        reason: 'natural_completion',
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'Ai2AiConnectionGovernanceOrchestrationLaneTest',
        onRecorded: (subjectId, _) {
          recordedSubjectId = subjectId;
        },
      );

      expect(recordId, 'record-1');
      expect(recordedSubjectId, connection.connectionId);
      expect(
        fakeKernelOs.lastEnvelope?.eventType,
        'ai2ai_connection_observation',
      );
      expect(
        fakeKernelOs.lastWhyRequest?.actualOutcome,
        'completed:natural_completion',
      );
      expect(
        fakeKernelOs.lastEnvelope?.context['canonical_peer_metadata'],
        isA<Map<String, dynamic>>(),
      );
    });
  });
}

AIPersonalityNode _remoteNode() {
  final now = DateTime.utc(2026, 3, 12, 12);
  return AIPersonalityNode(
    nodeId: 'peer-b',
    vibe: UserVibe(
      hashedSignature: 'peer-signature',
      anonymizedDimensions: const <String, double>{
        'openness': 0.7,
        'warmth': 0.6,
      },
      overallEnergy: 0.71,
      socialPreference: 0.64,
      explorationTendency: 0.69,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 6)),
      privacyLevel: 0.9,
      temporalContext: 'midday',
    ),
    lastSeen: now,
    trustScore: 0.84,
    learningHistory: const <String, dynamic>{
      'shared_topics': <String>['routing', 'delivery'],
    },
  );
}

class _FakeFunctionalKernelOs implements FunctionalKernelOs {
  int _recordCounter = 0;
  KernelEventEnvelope? lastEnvelope;
  KernelWhyRequest? lastWhyRequest;

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
    lastEnvelope = envelope;
    lastWhyRequest = whyRequest;
    _recordCounter += 1;
    return KernelBundleRecord(
      recordId: 'record-$_recordCounter',
      eventId: envelope.eventId,
      bundle: KernelContextBundle(
        who: WhoKernelSnapshot(
          primaryActor: envelope.agentId ?? 'unknown_agent',
          affectedActor: envelope.entityId ?? 'unknown_entity',
          companionActors: const <String>[],
          actorRoles: const <String>['peer'],
          trustScope: 'private',
          cohortRefs: const <String>[],
          identityConfidence: 0.91,
        ),
        what: WhatKernelSnapshot(
          actionType: envelope.actionType ?? 'observe',
          targetEntityType: envelope.entityType ?? 'ai2ai_connection',
          targetEntityId: envelope.entityId ?? 'unknown_entity',
          stateTransitionType: 'governed_record',
          outcomeType: whyRequest.actualOutcome ??
              whyRequest.predictedOutcome ??
              'pending',
          semanticTags: const <String>['ai2ai', 'governance'],
          taxonomyConfidence: 0.88,
        ),
        when: WhenKernelSnapshot(
          observedAt: envelope.occurredAtUtc,
          freshness: 0.86,
          recencyBucket: 'hot',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.9,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:test',
          cityCode: 'test',
          localityCode: 'runtime',
          projection: <String, dynamic>{'mode': 'local'},
          boundaryTension: 0.1,
          spatialConfidence: 0.84,
          travelFriction: 0.2,
          placeFitFlags: <String>['proximate'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'governed_runtime',
          workflowStage: 'ai2ai_connection',
          transportMode: 'mesh',
          plannerMode: 'kernel_bound',
          modelFamily: 'signal_reticulum',
          interventionChain: <String>['resolve', 'explain'],
          failureMechanism: 'none',
          mechanismConfidence: 0.89,
        ),
        why: WhyKernelSnapshot(
          goal: whyRequest.goal ?? 'observe_ai2ai_connection',
          summary: 'Governed AI2AI connection record resolved.',
          rootCauseType: WhyRootCauseType.mechanism,
          confidence: 0.83,
          drivers: whyRequest.coreSignals,
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: envelope.occurredAtUtc,
        ),
      ),
      createdAtUtc: envelope.occurredAtUtc,
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

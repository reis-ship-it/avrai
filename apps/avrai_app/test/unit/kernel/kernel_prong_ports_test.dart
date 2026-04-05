import 'package:avrai_core/models/why/why_models.dart' as core_why;
import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_orchestrator.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart' as semantic_what;
import 'package:avrai_runtime_os/kernel/when/legacy/dart_when_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/who/legacy/dart_who_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/why/legacy/dart_why_fallback_kernel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 1 kernel contract defaults', () {
    test('who fallback signs, verifies, and projects for reality model',
        () async {
      const whoKernel = DartWhoFallbackKernel();

      final signature = await whoKernel.sign(
        const WhoSigningRequest(
          actorId: 'agent-1',
          payload: <String, dynamic>{'goal': 'recommend_event'},
        ),
      );
      final verification = await whoKernel.verify(
        WhoVerificationRequest(
          actorId: 'agent-1',
          payload: const <String, dynamic>{'goal': 'recommend_event'},
          signature: signature.signature,
        ),
      );
      final projection = await whoKernel.projectForRealityModel(
        const KernelProjectionRequest(subjectId: 'agent-1'),
      );

      expect(verification.valid, isTrue);
      expect(projection.domain, KernelDomain.who);
      expect(projection.summary, contains('agent-1'));
    });

    test('when fallback issues timestamps and validates windows', () async {
      const whenKernel = DartWhenFallbackKernel();
      final timestamp = await whenKernel.issueTimestamp(
        WhenTimestampRequest(
          referenceId: 'event-1',
          occurredAtUtc: DateTime.utc(2026, 3, 7, 16),
        ),
      );
      final result = await whenKernel.validateWhen(
        WhenValidityWindow(
          timestamp: timestamp,
          effectiveAtUtc: DateTime.utc(2026, 3, 7, 15, 59),
          expiresAtUtc: DateTime.utc(2026, 3, 7, 16, 1),
          allowedDriftMs: 120000,
        ),
      );

      expect(result.valid, isTrue);
      expect(timestamp.quantumAtomicTick, greaterThan(0));
    });
  });

  group('FunctionalKernelProngPorts', () {
    test('exposes fused model truth and governance reports', () async {
      final whoKernel = const DartWhoFallbackKernel();
      final whenKernel = const DartWhenFallbackKernel();
      final whyKernel = const DartWhyFallbackKernel();
      final whatKernel = _FakeWhatKernel();
      final whereKernel = _FakeWhereKernel();
      final howKernel = _FakeHowKernel();
      final kernelOs = FunctionalKernelOrchestrator(
        whoKernel: whoKernel,
        whatKernel: whatKernel,
        whenKernel: whenKernel,
        spatialWhereKernel: whereKernel,
        howKernel: howKernel,
        whyKernel: whyKernel,
      );
      final ports = FunctionalKernelProngPorts(
        kernelOs: kernelOs,
        whoKernel: whoKernel,
        whatKernel: whatKernel,
        whenKernel: whenKernel,
        whereKernel: whereKernel,
        howKernel: howKernel,
        whyKernel: whyKernel,
      );
      final envelope = KernelEventEnvelope(
        eventId: 'event-ports-1',
        agentId: 'agent-1',
        userId: 'user-1',
        occurredAtUtc: DateTime.utc(2026, 3, 7, 16),
        sourceSystem: 'kernel_ports_test',
        eventType: 'recommendation_generated',
        actionType: 'recommend_event',
        entityId: 'event-1',
        entityType: 'event',
        context: const <String, dynamic>{
          'latitude': 41.8781,
          'longitude': -87.6298,
          'location_label': 'Loop',
        },
      );
      const whyRequest = KernelWhyRequest(
        bundle: KernelContextBundleWithoutWhy(),
        goal: 'recommend_event',
        actualOutcome: 'generated',
        actualOutcomeScore: 1.0,
        coreSignals: <WhySignal>[
          WhySignal(label: 'preference_match', weight: 0.8, source: 'core'),
        ],
      );

      final fusion = await ports.buildRealityKernelFusionInput(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      final governance = await ports.inspectTrustGovernance(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      final projectionDomains =
          governance.projections.map((entry) => entry.domain).toSet();

      expect(fusion.localityContainedInWhere, isTrue);
      expect(fusion.where.features['locality_contained_in_where'], isTrue);
      expect(
        projectionDomains,
        equals(<KernelDomain>{
          KernelDomain.who,
          KernelDomain.what,
          KernelDomain.when,
          KernelDomain.where,
          KernelDomain.how,
          KernelDomain.why,
          KernelDomain.vibe,
        }),
      );
    });
  });
}

class _FakeWhatKernel extends WhatKernelContract {
  @override
  Future<semantic_what.WhatState> resolveWhat(
    semantic_what.WhatPerceptionInput input,
  ) async {
    return semantic_what.WhatState(
      entityRef: input.entityRef,
      canonicalType: 'event',
      placeType: 'event',
      activityTypes: const <String>['recommend_event'],
      socialContexts: const <String>['generated'],
      userRelation: semantic_what.WhatUserRelation.neutral,
      lifecycleState: semantic_what.WhatLifecycleState.established,
      confidence: 0.88,
      firstObservedAtUtc: input.observedAtUtc,
      lastObservedAtUtc: input.observedAtUtc,
    );
  }

  @override
  Future<semantic_what.WhatUpdateReceipt> observeWhat(
    semantic_what.WhatObservation observation,
  ) async {
    final state = await resolveWhat(
      semantic_what.WhatPerceptionInput(
        agentId: observation.agentId,
        observedAtUtc: observation.observedAtUtc,
        source: observation.source,
        entityRef: observation.entityRef,
      ),
    );
    return semantic_what.WhatUpdateReceipt(state: state);
  }

  @override
  semantic_what.WhatProjection projectWhat(
    semantic_what.WhatProjectionRequest request,
  ) {
    return semantic_what.WhatProjection(
      baseEntityRef: request.entityRef,
      projectedTypes: const <String>['event'],
      confidence: 0.8,
      basis: 'kernel_prong_ports_test',
    );
  }

  @override
  semantic_what.WhatKernelSnapshot? snapshotWhat(String agentId) {
    return semantic_what.WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.utc(2026, 3, 7, 16),
    );
  }

  @override
  Future<semantic_what.WhatSyncResult> syncWhat(
    semantic_what.WhatSyncRequest request,
  ) async {
    return semantic_what.WhatSyncResult(
      acceptedCount: request.deltas.length,
      rejectedCount: 0,
      mergedEntityRefs: request.deltas.map((entry) => entry.entityRef).toList(),
      savedAtUtc: request.observedAtUtc,
    );
  }

  @override
  Future<semantic_what.WhatRecoveryResult> recoverWhat(
    semantic_what.WhatRecoveryRequest request,
  ) async {
    return semantic_what.WhatRecoveryResult(
      restoredCount: 1,
      droppedCount: 0,
      schemaVersion: 1,
      savedAtUtc: DateTime.utc(2026, 3, 7, 16),
    );
  }
}

class _FakeWhereKernel extends WhereKernelContract {
  final WhereState _state = WhereState(
    activeTokenId: 'gh7:dp3wjzt',
    activeTokenAlias: 'Loop',
    activeTokenKind: LocalityTokenKind.geohashCell.name,
    embedding: const <double>[
      0.1,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6
    ],
    confidence: 0.84,
    boundaryTension: 0.18,
    reliabilityTier: LocalityReliabilityTier.established.name,
    freshness: DateTime.utc(2026, 3, 7, 16),
    evidenceCount: 9,
    evolutionRate: 0.03,
    advisoryStatus: LocalityAdvisoryStatus.inactive.name,
    sourceMix: const <String, double>{
      'local': 0.6,
      'mesh': 0.1,
      'federated': 0.2,
      'geometry': 0.1,
      'synthetic_prior': 0.0,
    },
    topAlias: 'Loop',
    parentTokenId: 'chicago_il',
  );

  @override
  Future<WhereState> resolveWhere(WhereKernelInput input) async => _state;

  @override
  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'where_seed',
  }) async =>
      _state;

  @override
  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  }) async {
    return WhereObservationReceipt(
      state: _state,
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  Future<WhereObservationReceipt> observe(WhereObservation observation) async {
    return WhereObservationReceipt(
      state: _state,
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  Future<WhereSyncResult> sync(WhereSyncRequest request) async {
    return const WhereSyncResult(synced: true, message: 'ok');
  }

  @override
  WhereProjection project(WhereProjectionRequest request) {
    return WhereProjection(
      primaryLabel: request.state.topAlias ?? 'Loop',
      confidenceBucket: 'high',
      nearBoundary: false,
      activeTokenId: request.state.activeTokenId,
      activeTokenKind: request.state.activeTokenKind,
      activeTokenAlias: request.state.activeTokenAlias,
      metadata: const <String, dynamic>{'locality_contained_in_where': true},
    );
  }

  @override
  Future<WherePointResolution> resolvePoint(WherePointQuery request) async {
    return WherePointResolution(
      state: _state,
      projection: project(
        WhereProjectionRequest(audience: request.audience, state: _state),
      ),
      localityCode: 'loop_chicago',
      cityCode: 'chicago_il',
      displayName: 'Loop',
    );
  }

  @override
  Future<bool> observeMeshUpdate({
    required WhereMeshKey key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    return true;
  }

  @override
  Future<WhereZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily = 'reality_kernel',
    int localityCount = 12,
  }) async {
    return const LocalityZeroReliabilityReport(
      evaluationId: 'eval-1',
      metrics: <LocalityEvaluationMetric>[],
      calibration: <String, dynamic>{},
    );
  }

  @override
  WhereSnapshot? snapshot(String agentId) {
    return WhereSnapshot(
      agentId: agentId,
      state: _state,
      savedAtUtc: DateTime.utc(2026, 3, 7, 16),
    );
  }

  @override
  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request) async {
    return WhereRecoveryResult(
      state: _state,
      recoveredFromSnapshot: true,
    );
  }

  @override
  WhereWhySnapshot explainWhy(WhereWhyRequest request) {
    return core_why.WhySnapshot(
      goal: 'explain_where',
      drivers: const <core_why.WhySignal>[],
      inhibitors: const <core_why.WhySignal>[],
      confidence: 0.84,
      rootCauseType: core_why.WhyRootCauseType.locality,
      summary: 'stable locality',
      counterfactuals: const <core_why.WhyCounterfactual>[],
    );
  }
}

class _FakeHowKernel extends HowKernelContract {
  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) async {
    return const HowKernelSnapshot(
      executionPath: 'native_orchestrated',
      workflowStage: 'recommendation_generation',
      transportMode: 'in_process',
      plannerMode: 'recommendation_ranker',
      modelFamily: 'event_recommendation_service',
      interventionChain: <String>['resolve', 'rank', 'filter'],
      failureMechanism: 'none',
      mechanismConfidence: 0.84,
    );
  }
}

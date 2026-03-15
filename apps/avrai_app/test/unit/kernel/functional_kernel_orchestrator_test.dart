import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_orchestrator.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_bundle_store.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart' as semantic_what;
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FunctionalKernelOrchestrator', () {
    test('builds and persists a six-kernel bundle', () async {
      final store = InMemoryKernelBundleStore();
      final orchestrator = FunctionalKernelOrchestrator(
        whoKernel: _FakeWhoKernel(),
        whatKernel: _FakeWhatKernel(),
        whenKernel: _FakeWhenKernel(),
        spatialWhereKernel: _FakeSpatialWhereKernel(),
        howKernel: _FakeHowKernel(),
        whyKernel: _FakeWhyKernel(),
        bundleStore: store,
      );

      final record = await orchestrator.resolveAndExplain(
        envelope: KernelEventEnvelope(
          eventId: 'event-1',
          agentId: 'agent-1',
          userId: 'user-1',
          occurredAtUtc: DateTime.utc(2026, 3, 7, 12),
          sourceSystem: 'test',
          eventType: 'recommendation_generated',
          actionType: 'recommend_event',
          entityId: 'event-123',
          entityType: 'event',
          context: const <String, dynamic>{
            'latitude': 33.52,
            'longitude': -86.77,
            'location_label': 'Avondale',
          },
        ),
        whyRequest: const KernelWhyRequest(
          bundle: KernelContextBundleWithoutWhy(
            who: null,
            what: null,
            when: null,
            where: null,
            how: null,
          ),
          goal: 'recommend_event',
          actualOutcome: 'generated',
          actualOutcomeScore: 1.0,
          coreSignals: <WhySignal>[
            WhySignal(label: 'preference_match', weight: 0.7, source: 'core'),
          ],
        ),
      );

      expect(record.bundle.who, isNotNull);
      expect(record.bundle.what, isNotNull);
      expect(record.bundle.when, isNotNull);
      expect(record.bundle.where, isNotNull);
      expect(record.bundle.how, isNotNull);
      expect(record.bundle.vibe, isNotNull);
      expect(record.bundle.vibeStack, isNotNull);
      expect(record.bundle.vibeStack!.geographicSnapshots, isNotEmpty);
      expect(
        record.bundle.vibeStack!.geographicSnapshots.first.subjectRef
            .effectiveGeographicLevel,
        isNotNull,
      );
      expect(record.bundle.why, isNotNull);
      expect(record.bundle.why!.rootCauseType, WhyRootCauseType.contextDriven);
      expect(store.getByEventId('event-1'), isNotNull);
    });

    test('builds fused reality-model input with locality contained in where',
        () async {
      final orchestrator = FunctionalKernelOrchestrator(
        whoKernel: _FakeWhoKernel(),
        whatKernel: _FakeWhatKernel(),
        whenKernel: _FakeWhenKernel(),
        spatialWhereKernel: _FakeSpatialWhereKernel(),
        howKernel: _FakeHowKernel(),
        whyKernel: _FakeWhyKernel(),
      );

      final fusion = await orchestrator.buildRealityKernelFusionInput(
        envelope: KernelEventEnvelope(
          eventId: 'event-2',
          agentId: 'agent-1',
          userId: 'user-1',
          occurredAtUtc: DateTime.utc(2026, 3, 7, 13),
          sourceSystem: 'test',
          eventType: 'recommendation_generated',
          actionType: 'recommend_event',
          entityId: 'event-456',
          entityType: 'event',
          context: const <String, dynamic>{
            'latitude': 33.52,
            'longitude': -86.77,
            'location_label': 'Avondale',
          },
        ),
        whyRequest: const KernelWhyRequest(
          bundle: KernelContextBundleWithoutWhy(),
          goal: 'recommend_event',
          actualOutcome: 'generated',
          actualOutcomeScore: 1.0,
          coreSignals: <WhySignal>[
            WhySignal(label: 'preference_match', weight: 0.7, source: 'core'),
          ],
        ),
      );

      expect(fusion.localityContainedInWhere, isTrue);
      expect(fusion.where.domain, KernelDomain.where);
      expect(fusion.where.features['locality_contained_in_where'], isTrue);
      expect(fusion.what.domain, KernelDomain.what);
      expect(fusion.bundle.vibeStack, isNotNull);
      expect(fusion.bundle.vibeStack!.geographicSnapshots, isNotEmpty);
      expect(fusion.why.summary, contains('context-driven'));
    });
  });
}

class _FakeWhoKernel extends WhoKernelContract {
  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) async {
    return const WhoKernelSnapshot(
      primaryActor: 'agent-1',
      affectedActor: 'user-1',
      companionActors: <String>[],
      actorRoles: <String>['requester'],
      trustScope: 'private',
      cohortRefs: <String>[],
      identityConfidence: 0.9,
    );
  }
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
      basis: 'test_fixture',
    );
  }

  @override
  semantic_what.WhatKernelSnapshot? snapshotWhat(String agentId) {
    return semantic_what.WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.utc(2026, 3, 7, 12),
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
      savedAtUtc: DateTime.utc(2026, 3, 7, 12),
    );
  }
}

class _FakeWhenKernel extends WhenKernelContract {
  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    return WhenKernelSnapshot(
      observedAt: envelope.occurredAtUtc,
      effectiveAt: envelope.occurredAtUtc,
      expiresAt: envelope.occurredAtUtc.add(const Duration(hours: 4)),
      freshness: 1.0,
      cadence: null,
      recencyBucket: 'immediate',
      timingConflictFlags: const <String>[],
      temporalConfidence: 0.95,
    );
  }
}

class _FakeSpatialWhereKernel extends WhereKernelContract {
  final LocalityState _state = LocalityState(
    activeToken: const LocalityToken(
      kind: LocalityTokenKind.geohashCell,
      id: 'gh7:dr5ru7k',
      alias: 'Avondale',
    ),
    embedding: const <double>[
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.4,
      0.3,
      0.5,
      0.6,
      0.4,
      0.5,
    ],
    confidence: 0.82,
    boundaryTension: 0.28,
    reliabilityTier: LocalityReliabilityTier.established,
    freshness: DateTime.utc(2026, 3, 7),
    evidenceCount: 10,
    evolutionRate: 0.04,
    advisoryStatus: LocalityAdvisoryStatus.inactive,
    sourceMix: LocalitySourceMix(
      local: 0.5,
      mesh: 0.1,
      federated: 0.3,
      geometry: 0.1,
      syntheticPrior: 0.0,
    ),
    topAlias: 'Avondale',
    parentToken: const LocalityToken(
      kind: LocalityTokenKind.cityPrior,
      id: 'birmingham_alabama',
      alias: 'Birmingham',
    ),
  );

  @override
  Future<WhereZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily = 'default',
    int localityCount = 12,
  }) async {
    return const LocalityZeroReliabilityReport(
      evaluationId: 'eval-1',
      metrics: <LocalityEvaluationMetric>[],
      calibration: <String, dynamic>{},
    );
  }

  @override
  Future<WhereObservationReceipt> observe(WhereObservation observation) async {
    return WhereObservationReceipt(
      state: WhereState.fromLocality(_state),
      cloudUpdated: false,
      meshForwarded: false,
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
  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  }) async {
    return WhereObservationReceipt(
      state: WhereState.fromLocality(_state),
      cloudUpdated: false,
      meshForwarded: false,
    );
  }

  @override
  WhereProjection project(WhereProjectionRequest request) {
    return WhereProjection(
      primaryLabel: request.state.topAlias ?? 'Avondale',
      confidenceBucket: 'high',
      nearBoundary: false,
      activeTokenId: request.state.activeTokenId,
      activeTokenKind: request.state.activeTokenKind,
      activeTokenAlias: request.state.activeTokenAlias,
      metadata: const <String, dynamic>{'label': 'Avondale'},
    );
  }

  @override
  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request) async {
    return WhereRecoveryResult(
      state: WhereState.fromLocality(_state),
      recoveredFromSnapshot: true,
    );
  }

  @override
  Future<WherePointResolution> resolvePoint(WherePointQuery request) async {
    return WherePointResolution(
      state: WhereState.fromLocality(_state),
      projection: project(
        WhereProjectionRequest(
          audience: request.audience,
          state: WhereState.fromLocality(_state),
        ),
      ),
      cityCode: 'birmingham_alabama',
      localityCode: 'avondale',
      displayName: 'Avondale',
    );
  }

  @override
  Future<WhereState> resolveWhere(WhereKernelInput input) async =>
      WhereState.fromLocality(_state);

  @override
  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'seed',
  }) async =>
      WhereState.fromLocality(_state);

  @override
  WhereSnapshot? snapshot(String agentId) {
    return WhereSnapshot(
      agentId: agentId,
      state: WhereState.fromLocality(_state),
      savedAtUtc: DateTime.utc(2026, 3, 7),
    );
  }

  @override
  Future<WhereSyncResult> sync(WhereSyncRequest request) async {
    return const WhereSyncResult(synced: true, message: 'ok');
  }

  @override
  WhereWhySnapshot explainWhy(WhereWhyRequest request) {
    throw UnimplementedError('unused in functional kernel orchestrator test');
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

class _FakeWhyKernel extends WhyKernelContract {
  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    return WhyKernelSnapshot(
      goal: request.goal ?? 'explain_outcome',
      summary: 'context-driven recommendation generation',
      rootCauseType: WhyRootCauseType.contextDriven,
      confidence: 0.88,
      drivers: const <WhySignal>[
        WhySignal(label: 'preference_match', weight: 0.7, source: 'core'),
      ],
      inhibitors: const <WhySignal>[],
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 7, 12),
    );
  }
}

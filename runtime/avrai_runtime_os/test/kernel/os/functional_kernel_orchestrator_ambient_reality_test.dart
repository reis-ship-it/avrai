import 'dart:io';

import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    hide WhatKernelSnapshot;
import 'package:avrai_runtime_os/kernel/os/functional_kernel_orchestrator.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

void main() {
  group('FunctionalKernelOrchestrator ambient reality fusion', () {
    setUp(() {
      VibeKernel.resetFallbackStateForTesting();
      TrajectoryKernel.resetFallbackStateForTesting();
      TrajectoryKernel().importJournalWindow(records: const []);
    });

    test(
      'builds fused reality input with ambient-social what and locality vibe evidence',
      () async {
        final vibeKernel = VibeKernel();
        vibeKernel.ingestEcosystemObservation(
          subjectId: 'agent-local',
          source: 'ambient_social_place_vibe',
          dimensions: const <String, double>{
            'community_orientation': 0.84,
            'energy_preference': 0.74,
          },
          provenanceTags: const <String>[
            'ambient_social_runtime',
            'place_vibe:intimate_social',
          ],
        );
        final orchestrator = _buildOrchestrator(vibeKernel: vibeKernel);

        final fusion = await orchestrator.buildRealityKernelFusionInput(
          envelope: _ambientEnvelope(),
          whyRequest: const KernelWhyRequest(
            bundle: KernelContextBundleWithoutWhy(),
            goal: 'forecast_place_vibe',
          ),
        );

        expect(
          (fusion.what.payload['projectedTypes'] as List<dynamic>),
          contains('ambient_social_scene'),
        );
        expect(
          (fusion.what.payload['projectedVibeSignature']
              as Map<String, dynamic>)['intimate_social'],
          greaterThan(0.0),
        );
        expect(
          (fusion.where.payload['metadata']
              as Map<String, dynamic>)['locality_stable_key'],
          'bham-downtown',
        );
        expect(
          (fusion.vibe!.payload['provenance_tags'] as List<dynamic>),
          contains('ambient_social_runtime'),
        );
      },
    );

    test(
      'headless host model truth uses the same fused reality path without a forecast bypass API',
      () async {
        final orchestrator = _buildOrchestrator(vibeKernel: VibeKernel());
        final ports = FunctionalKernelProngPorts(
          kernelOs: orchestrator,
          whoKernel: orchestrator.whoKernel,
          whatKernel: orchestrator.whatKernel,
          whenKernel: orchestrator.whenKernel,
          whereKernel: orchestrator.spatialWhereKernel,
          howKernel: orchestrator.howKernel,
          whyKernel: orchestrator.whyKernel,
        );
        final host = DefaultHeadlessAvraiOsHost(
          modelTruthPort: ports,
          runtimeExecutionPort: ports,
          trustGovernancePort: ports,
          whoKernel: orchestrator.whoKernel,
          whatKernel: orchestrator.whatKernel,
          whenKernel: orchestrator.whenKernel,
          whereKernel: orchestrator.spatialWhereKernel,
          howKernel: orchestrator.howKernel,
          whyKernel: orchestrator.whyKernel,
        );

        final fusion = await host.buildModelTruth(
          envelope: _ambientEnvelope(),
          whyRequest: const KernelWhyRequest(
            bundle: KernelContextBundleWithoutWhy(),
            goal: 'forecast_place_vibe',
          ),
        );
        final orchestratorSource = File(
          'runtime/avrai_runtime_os/lib/kernel/os/functional_kernel_orchestrator.dart',
        ).readAsStringSync();

        expect(
          (fusion.what.payload['projectedTypes'] as List<dynamic>),
          contains('ambient_social_scene'),
        );
        expect(
          (fusion.where.payload['metadata']
              as Map<String, dynamic>)['locality_stable_key'],
          'bham-downtown',
        );
        expect(orchestratorSource, isNot(contains('forecastIngress')));
        expect(orchestratorSource, isNot(contains('ambientSocialForecast')));
      },
    );
  });
}

FunctionalKernelOrchestrator _buildOrchestrator({
  required VibeKernel vibeKernel,
}) {
  return FunctionalKernelOrchestrator(
    whoKernel: const _FakeWhoKernel(),
    whatKernel: const _FakeWhatKernel(),
    whenKernel: const _FakeWhenKernel(),
    spatialWhereKernel: const _FakeWhereKernel(),
    howKernel: const _FakeHowKernel(),
    whyKernel: const _FakeWhyKernel(),
    vibeKernel: vibeKernel,
  );
}

KernelEventEnvelope _ambientEnvelope() {
  return KernelEventEnvelope(
    eventId: 'ambient-reality-event',
    occurredAtUtc: DateTime.utc(2026, 3, 14, 1),
    agentId: 'agent-local',
    userId: 'user-local',
    sourceSystem: 'ambient_social_validation',
    eventType: 'ambient_social_scene',
    actionType: 'observe',
    entityId: 'ambient_social_scene:locality=bham-downtown',
    entityType: 'ambient_social_scene',
    context: const <String, dynamic>{
      'social_context': 'small_group',
      'location_label': 'Bham Downtown',
      'latitude': 33.5207,
      'longitude': -86.8025,
    },
  );
}

class _FakeWhoKernel extends WhoKernelContract {
  const _FakeWhoKernel();

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) async {
    return const WhoKernelSnapshot(
      primaryActor: 'agent-local',
      affectedActor: 'locality:bham-downtown',
      companionActors: <String>['peer-a', 'peer-b'],
      actorRoles: <String>['local_agent', 'observer'],
      trustScope: 'private',
      cohortRefs: <String>['ambient_social_scene'],
      identityConfidence: 0.91,
    );
  }
}

class _FakeWhatKernel extends WhatKernelContract {
  const _FakeWhatKernel();

  @override
  Future<WhatState> resolveWhat(WhatPerceptionInput input) async {
    return WhatState(
      entityRef: input.entityRef,
      canonicalType: 'ambient_social_scene',
      placeType: 'third_place',
      activityTypes: const <String>['ambient_socializing'],
      socialContexts: const <String>['small_group'],
      confidence: 0.9,
      evidenceCount: 2,
      firstObservedAtUtc: input.observedAtUtc,
      lastObservedAtUtc: input.observedAtUtc,
      sourceMix: const WhatSourceMix(structured: 1.0),
      lineageRefs: const <String>['ambient:seed'],
    );
  }

  @override
  Future<WhatUpdateReceipt> observeWhat(WhatObservation observation) async {
    return WhatUpdateReceipt(
      state: await resolveWhat(
        WhatPerceptionInput(
          agentId: observation.agentId,
          observedAtUtc: observation.observedAtUtc,
          source: observation.source,
          entityRef: observation.entityRef,
        ),
      ),
    );
  }

  @override
  WhatProjection projectWhat(WhatProjectionRequest request) {
    return const WhatProjection(
      baseEntityRef: 'ambient_social_scene:locality=bham-downtown',
      projectedTypes: <String>['ambient_social_scene', 'third_place'],
      projectedAffordances: <String, double>{'social_discovery': 0.82},
      projectedVibeSignature: <String, double>{'intimate_social': 0.84},
      adjacentOpportunities: <String>['forecast_place_vibe'],
      confidence: 0.9,
      basis: 'ambient_social_projection',
    );
  }

  @override
  WhatKernelSnapshot? snapshotWhat(String agentId) {
    return WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.utc(2026, 3, 14, 1),
      states: <WhatState>[
        WhatState(
          entityRef: 'ambient_social_scene:locality=bham-downtown',
          canonicalType: 'ambient_social_scene',
          placeType: 'third_place',
          activityTypes: const <String>['ambient_socializing'],
          socialContexts: const <String>['small_group'],
          confidence: 0.9,
          evidenceCount: 2,
          firstObservedAtUtc: DateTime.utc(2026, 3, 14, 1),
          lastObservedAtUtc: DateTime.utc(2026, 3, 14, 1),
          sourceMix: const WhatSourceMix(structured: 1.0),
          lineageRefs: const <String>['ambient:seed'],
        ),
      ],
    );
  }

  @override
  Future<WhatSyncResult> syncWhat(WhatSyncRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<WhatRecoveryResult> recoverWhat(WhatRecoveryRequest request) async {
    throw UnimplementedError();
  }
}

class _FakeWhenKernel extends WhenKernelContract {
  const _FakeWhenKernel();

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    return WhenKernelSnapshot(
      observedAt: envelope.occurredAtUtc,
      freshness: 0.92,
      recencyBucket: 'hot',
      timingConflictFlags: const <String>[],
      temporalConfidence: 0.9,
    );
  }
}

class _FakeWhereKernel extends WhereKernelContract {
  const _FakeWhereKernel();

  @override
  Future<WhereState> resolveWhere(WhereKernelInput input) async {
    return WhereState(
      activeTokenId: 'bham-downtown',
      activeTokenAlias: 'Bham Downtown',
      activeTokenKind: 'locality',
      embedding: List<double>.filled(12, 0.5),
      confidence: 0.88,
      boundaryTension: 0.08,
      reliabilityTier: 'stable',
      freshness: DateTime.utc(2026, 3, 14, 1),
      evidenceCount: 4,
      evolutionRate: 0.2,
      parentTokenId: 'bham',
      topAlias: 'Birmingham',
      advisoryStatus: 'active',
      sourceMix: const <String, double>{
        'local': 0.7,
        'mesh': 0.2,
        'federated': 0.0,
        'geometry': 0.1,
        'synthetic_prior': 0.0,
      },
    );
  }

  @override
  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'test',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<WhereObservationReceipt> observe(WhereObservation observation) async {
    throw UnimplementedError();
  }

  @override
  Future<WhereSyncResult> sync(WhereSyncRequest request) async {
    throw UnimplementedError();
  }

  @override
  WhereProjection project(WhereProjectionRequest request) {
    return const WhereProjection(
      primaryLabel: 'Bham Downtown',
      confidenceBucket: 'high',
      nearBoundary: false,
      activeTokenId: 'bham-downtown',
      activeTokenKind: 'locality',
      activeTokenAlias: 'Bham Downtown',
      metadata: <String, dynamic>{
        'locality_stable_key': 'bham-downtown',
        'place_vibe_label': 'intimate_social',
      },
    );
  }

  @override
  Future<WherePointResolution> resolvePoint(WherePointQuery request) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> observeMeshUpdate({
    required WhereMeshKey key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<WhereZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily = 'where_v0',
    int localityCount = 0,
  }) async {
    throw UnimplementedError();
  }

  @override
  WhereSnapshot? snapshot(String agentId) => null;

  @override
  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request) async {
    throw UnimplementedError();
  }

  @override
  WhereWhySnapshot explainWhy(WhereWhyRequest request) {
    throw UnimplementedError();
  }
}

class _FakeHowKernel extends HowKernelContract {
  const _FakeHowKernel();

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) async {
    return const HowKernelSnapshot(
      executionPath: 'ambient_social_runtime',
      workflowStage: 'fused_reality_projection',
      transportMode: 'mesh',
      plannerMode: 'governed',
      modelFamily: 'signal_reticulum',
      interventionChain: <String>['plan', 'commit', 'observe'],
      failureMechanism: 'none',
      mechanismConfidence: 0.88,
    );
  }
}

class _FakeWhyKernel extends WhyKernelContract {
  const _FakeWhyKernel();

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    return WhyKernelSnapshot(
      goal: request.goal ?? 'forecast_place_vibe',
      summary: 'Ambient social context informs fused reality projections.',
      rootCauseType: WhyRootCauseType.mechanism,
      confidence: 0.87,
      drivers: const <WhySignal>[
        WhySignal(label: 'ambient_social_scene', weight: 1.0),
      ],
      inhibitors: const <WhySignal>[],
      counterfactuals: const <WhyCounterfactual>[],
      createdAtUtc: DateTime.utc(2026, 3, 14, 1),
    );
  }
}

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_population_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant instant(DateTime time) => TemporalInstant(
        referenceTime: time.toUtc(),
        civilTime: time,
        timezoneId: 'America/Chicago',
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'test',
        ),
        uncertainty: const TemporalUncertainty.zero(),
        monotonicTicks: time.microsecondsSinceEpoch,
      );

  ReplayNormalizedObservation observation({
    required String id,
    required String entityId,
    required String entityType,
    required String canonicalName,
    required String locality,
    required Map<String, dynamic> normalizedFields,
  }) {
    return ReplayNormalizedObservation(
      observationId: id,
      subjectIdentity: ReplayEntityIdentity(
        normalizedEntityId: entityId,
        entityType: entityType,
        canonicalName: canonicalName,
        localityAnchor: locality,
      ),
      replayEnvelope: ReplayTemporalEnvelope(
        envelopeId: 'env-$id',
        subjectId: entityId,
        observedAt: instant(DateTime.utc(2023, 1, 1)),
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'test',
        ),
        uncertainty: const TemporalUncertainty.zero(),
        temporalAuthoritySource: 'when_kernel',
      ),
      status: ReplayNormalizationStatus.normalized,
      sourceRefs: const <String>['test'],
      normalizedFields: normalizedFields,
    );
  }

  Map<String, dynamic> buildConsolidatedArtifact() {
    return <String, dynamic>{
      'ingestion': <String, dynamic>{
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'observations': <Map<String, dynamic>>[
              observation(
                id: 'obs-pop-downtown',
                entityId: 'population:downtown',
                entityType: 'population_cohort',
                canonicalName: 'Downtown Population',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{
                  'series_key': 'population_total',
                  'metric_value': 120000,
                },
              ).toJson(),
              observation(
                id: 'obs-pop-southside',
                entityId: 'population:southside',
                entityType: 'population_cohort',
                canonicalName: 'Southside Population',
                locality: 'Southside',
                normalizedFields: const <String, dynamic>{
                  'series_key': 'population_total',
                  'metric_value': 88000,
                },
              ).toJson(),
              observation(
                id: 'obs-house-downtown',
                entityId: 'housing:downtown',
                entityType: 'housing_signal',
                canonicalName: 'Downtown Housing',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{
                  'series_key': 'housing_units',
                  'metric_value': 52000,
                },
              ).toJson(),
              observation(
                id: 'obs-house-southside',
                entityId: 'housing:southside',
                entityType: 'housing_signal',
                canonicalName: 'Southside Housing',
                locality: 'Southside',
                normalizedFields: const <String, dynamic>{
                  'series_key': 'housing_units',
                  'metric_value': 39000,
                },
              ).toJson(),
              observation(
                id: 'obs-house-west-end',
                entityId: 'housing:west-end',
                entityType: 'housing_signal',
                canonicalName: 'West End Housing',
                locality: 'West End',
                normalizedFields: const <String, dynamic>{
                  'series_key': 'housing_units',
                  'metric_value': 14000,
                },
              ).toJson(),
              observation(
                id: 'obs-venue',
                entityId: 'venue:1',
                entityType: 'venue',
                canonicalName: 'Venue One',
                locality: 'Downtown',
                normalizedFields: const <String, dynamic>{'category': 'music'},
              ).toJson(),
              observation(
                id: 'obs-community',
                entityId: 'community:1',
                entityType: 'community',
                canonicalName: 'Community One',
                locality: 'Southside',
                normalizedFields: const <String, dynamic>{'category': 'arts'},
              ).toJson(),
            ],
          },
        ],
      },
    };
  }

  ReplayVirtualWorldEnvironment buildEnvironment() {
    return ReplayVirtualWorldEnvironment(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2023,
        replayYear: 2023,
        branchId: 'canonical',
        runId: 'run-1',
        seed: 2023,
        divergencePolicy: 'none',
      ),
      isolationBoundary: const ReplayWorldIsolationBoundary(
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>['36', '37', '39'],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 6,
      observationCount: 6,
      forecastEvaluatedCount: 4,
      sourceCounts: const <String, int>{'test': 6},
      entityTypeCounts: const <String, int>{
        'population_cohort': 2,
        'housing_signal': 2,
        'venue': 1,
        'community': 1,
      },
      localityCounts: const <String, int>{'Downtown': 3, 'Southside': 3},
      forecastDispositionCounts: const <String, int>{'admitted': 4},
      nodes: const <ReplayVirtualWorldNode>[],
      metadata: const <String, dynamic>{},
    );
  }

  test('builds a representative Birmingham population profile with age safety', () {
    final profile = const BhamReplayPopulationProfileService().buildProfile(
      consolidatedArtifact: buildConsolidatedArtifact(),
      environment: buildEnvironment(),
    );

    expect(profile.totalPopulation, 208000);
    expect(profile.totalHousingUnits, 105000);
    expect(profile.agentEligiblePopulation, greaterThan(0));
    expect(profile.dependentMobilityPopulation, greaterThan(0));
    expect(profile.modeledActorCount, greaterThanOrEqualTo(25000));
    expect(profile.metadata['under13AgentPolicy'], 'blocked');
    expect(profile.metadata['populationModelKind'], 'dense_weighted_synthetic_city');
    expect(profile.metadata['localityCoveragePct'], 1.0);
    expect(profile.metadata['actorRecordCount'], profile.actors.length);
    expect(
      profile.metadata['modeledUserLayerKind'],
      'all_modeled_actors_are_avrai_users',
    );
    expect(
      profile.eligibilityRecords.where(
        (record) => record.ageBand == 'under_13' && record.personalAgentAllowed,
      ),
      isEmpty,
    );
    expect(profile.actors.every((actor) => actor.hasPersonalAgent), isTrue);
    expect(
      profile.actors.every(
        (actor) =>
            actor.populationRole == SimulatedPopulationRole.humanWithAgent,
      ),
      isTrue,
    );
    expect(
      profile.actors.every(
        (actor) =>
            actor.kernelBundle != null &&
            actor.kernelBundle!.attachedKernelIds.length >= 9 &&
            actor.kernelBundle!.readyKernelIds.length >= 9,
      ),
      isTrue,
    );
    expect(profile.localityPopulationCounts['Downtown'], 120000);
    expect(profile.localityPopulationCounts['Southside'], 88000);
    expect(
      profile.actors.any((actor) => actor.localityAnchor == 'West End'),
      isTrue,
    );
    final syntheticPopulationBatch = Map<String, dynamic>.from(
      profile.metadata['syntheticPopulationBatch'] as Map? ??
          const <String, dynamic>{},
    );
    expect(
      syntheticPopulationBatch['weightedActorCount'],
      profile.modeledActorCount,
    );
  });
}

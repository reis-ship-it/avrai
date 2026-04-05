import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_virtual_world_environment_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
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
  }

  Map<String, dynamic> buildArtifact() {
    return <String, dynamic>{
      'pack': ReplaySourcePack(
        packId: 'pack-1',
        replayYear: 2023,
        generatedAtUtc: DateTime.utc(2026, 3, 12),
        metadata: const <String, dynamic>{
          'citySlug': 'atx',
          'cityCode': 'atx',
          'cityDisplayName': 'Austin',
          'cityPackId': 'austin_core_2024',
          'cityPackManifestRef': 'city_packs/atx/2024_manifest.json',
          'campaignDefaultsRef': 'city_packs/atx/campaign_defaults.json',
          'localityExpectationProfileRef':
              'city_packs/atx/locality_expectations.json',
          'worldHealthProfileRef': 'city_packs/atx/world_health.json',
        },
      ).toJson(),
      'ingestion': <String, dynamic>{
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'observations': <Map<String, dynamic>>[
              ReplayNormalizedObservation(
                observationId: 'obs-event',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'event:1',
                  entityType: 'event',
                  canonicalName: 'City Event',
                  localityAnchor: 'Downtown',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-event',
                  subjectId: 'event:1',
                  observedAt: buildInstant(DateTime.utc(2023, 1, 5)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty.zero(),
                  temporalAuthoritySource: 'when_kernel',
                ),
                status: ReplayNormalizationStatus.normalized,
                sourceRefs: const <String>['Source A'],
              ).toJson(),
              ReplayNormalizedObservation(
                observationId: 'obs-venue',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'venue:1',
                  entityType: 'venue',
                  canonicalName: 'Venue One',
                  localityAnchor: 'Downtown',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-venue',
                  subjectId: 'venue:1',
                  observedAt: buildInstant(DateTime.utc(2023, 1, 6)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty.zero(),
                  temporalAuthoritySource: 'when_kernel',
                ),
                status: ReplayNormalizationStatus.normalized,
                sourceRefs: const <String>['Source B'],
              ).toJson(),
            ],
          },
        ],
      },
    };
  }

  test(
      'builds an isolated replay virtual world environment with no live runtime leak',
      () {
    final service = BhamReplayVirtualWorldEnvironmentService();
    final runContext = const MonteCarloRunContext(
      canonicalReplayYear: 2023,
      replayYear: 2023,
      branchId: 'canonical',
      runId: 'run-1',
      seed: 2023,
      divergencePolicy: 'none',
    );
    final environment = service.buildEnvironment(
      consolidatedArtifact: buildArtifact(),
      executionPlan: BhamReplayExecutionPlan(
        packId: 'pack-1',
        replayYear: 2023,
        runContext: runContext,
        entries: <BhamReplayExecutionEntry>[
          BhamReplayExecutionEntry(
            sequenceNumber: 1,
            observation: ReplayNormalizedObservation.fromJson(
              Map<String, dynamic>.from(
                (buildArtifact()['ingestion']
                        as Map<String, dynamic>)['results'][0]['observations']
                    [0] as Map,
              ),
            ),
            executionInstant: buildInstant(DateTime.utc(2023, 1, 5, 12)),
            primarySourceName: 'Source A',
            dayKey: '2023-01-05',
            monthKey: '2023-01',
          ),
          BhamReplayExecutionEntry(
            sequenceNumber: 2,
            observation: ReplayNormalizedObservation.fromJson(
              Map<String, dynamic>.from(
                (buildArtifact()['ingestion']
                        as Map<String, dynamic>)['results'][0]['observations']
                    [1] as Map,
              ),
            ),
            executionInstant: buildInstant(DateTime.utc(2023, 1, 6, 12)),
            primarySourceName: 'Source B',
            dayKey: '2023-01-06',
            monthKey: '2023-01',
          ),
        ],
        skippedSources: const <String>[],
        sourceCounts: const <String, int>{'Source A': 1, 'Source B': 1},
        entityTypeCounts: const <String, int>{'event': 1, 'venue': 1},
        dayCounts: const <String, int>{'2023-01-05': 1, '2023-01-06': 1},
        metadata: const <String, dynamic>{
          'citySlug': 'atx',
          'cityCode': 'atx',
          'cityDisplayName': 'Austin',
          'cityPackId': 'austin_core_2024',
          'cityPackManifestRef': 'city_packs/atx/2024_manifest.json',
          'cityPackStructuralRef': 'city_pack:austin_core_2024',
          'campaignDefaultsRef': 'city_packs/atx/campaign_defaults.json',
          'localityExpectationProfileRef':
              'city_packs/atx/locality_expectations.json',
          'worldHealthProfileRef': 'city_packs/atx/world_health.json',
        },
      ),
      forecastBatch: BhamReplayForecastBatchResult(
        runContext: runContext,
        evaluatedCount: 2,
        dispositionCounts: const <String, int>{
          'admitted': 1,
          'admittedWithCaution': 1,
        },
        entityTypeCounts: const <String, int>{'event': 1, 'venue': 1},
        sourceCounts: const <String, int>{'Source A': 1, 'Source B': 1},
        items: const <BhamReplayForecastBatchItem>[
          BhamReplayForecastBatchItem(
            sequenceNumber: 1,
            observationId: 'obs-event',
            subjectId: 'event:1',
            entityType: 'event',
            primarySourceName: 'Source A',
            disposition: ForecastGovernanceDisposition.admitted,
            predictedOutcome: 'steady',
            confidence: 0.8,
            actionabilityScore: 0.8,
            governanceReasons: <String>[],
          ),
          BhamReplayForecastBatchItem(
            sequenceNumber: 2,
            observationId: 'obs-venue',
            subjectId: 'venue:1',
            entityType: 'venue',
            primarySourceName: 'Source B',
            disposition: ForecastGovernanceDisposition.admittedWithCaution,
            predictedOutcome: 'busy',
            confidence: 0.62,
            actionabilityScore: 0.6,
            governanceReasons: <String>['low completeness'],
          ),
        ],
        metadata: const <String, dynamic>{
          'selected_forecast_kernel_id': 'baseline_forecast_kernel',
          'selected_forecast_kernel_execution_mode': 'baseline',
        },
      ),
      sourceArtifactRefs: const <String>[
        '36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json',
        '37_BHAM_REPLAY_EXECUTION_PLAN_2023.json',
        '39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json',
      ],
    );

    expect(environment.nodeCount, 2);
    expect(environment.environmentId, 'atx-replay-world-2023');
    expect(
      environment.isolationBoundary.environmentNamespace,
      'replay-world/atx/2023/run-1',
    );
    expect(environment.isolationBoundary.runtimeMutationPolicy,
        ReplayWorldAccessPolicy.blocked);
    expect(environment.isolationBoundary.appSurfacePolicy,
        ReplayWorldAccessPolicy.blocked);
    expect(environment.isolationBoundary.adminInspectionPolicy,
        ReplayWorldAccessPolicy.adminOnly);
    expect(environment.localityCounts['Downtown'], 2);
    expect(environment.forecastDispositionCounts['admittedWithCaution'], 1);
    expect(
      environment.metadata['cityPackStructuralRef'],
      'city_pack:austin_core_2024',
    );
    expect(
      environment.metadata.containsKey('mesh_runtime_state_summary'),
      isFalse,
    );
    expect(
      environment.metadata.containsKey('mesh_runtime_state_frame'),
      isFalse,
    );
    expect(
      environment.metadata.containsKey('ai2ai_runtime_state_summary'),
      isFalse,
    );
    expect(
      environment.metadata.containsKey('ai2ai_runtime_state_frame'),
      isFalse,
    );
    expect(environment.metadata['selected_forecast_kernel_id'],
        'baseline_forecast_kernel');
    expect(environment.metadata['cityDisplayName'], 'Austin');
    expect(
      environment.metadata['simulationEnvironmentId'],
      'atx-simulation-environment-2023',
    );
    expect(
      environment.metadata['simulationEnvironmentNamespace'],
      'simulation-world/atx/2023/run-1',
    );
    expect(
      environment.metadata['simulationLabel'],
      'Austin Simulation Environment 2023',
    );
    expect(
      environment.isolationBoundary.metadata['simulationEnvironmentId'],
      'atx-simulation-environment-2023',
    );
    expect(
      environment.isolationBoundary.metadata['simulationEnvironmentNamespace'],
      'simulation-world/atx/2023/run-1',
    );
    expect(environment.metadata['cityPackManifestRef'],
        'city_packs/atx/2024_manifest.json');
  });
}

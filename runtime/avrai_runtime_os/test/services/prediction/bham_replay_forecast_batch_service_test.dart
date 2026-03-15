import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/governed_forecast_runtime_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/forecast/baseline_forecast_kernel.dart';

void main() {
  TemporalInstant buildInstant(DateTime time) {
    return TemporalInstant(
      referenceTime: time.toUtc(),
      civilTime: time,
      timezoneId: 'America/Chicago',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'test',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: time.microsecondsSinceEpoch,
    );
  }

  Map<String, dynamic> buildArtifact() {
    return <String, dynamic>{
      'pack': ReplaySourcePack(
        packId: 'bham-consolidated-replay-2023',
        replayYear: 2023,
        generatedAtUtc: DateTime.utc(2026, 3, 12),
      ).toJson(),
      'ingestion': <String, dynamic>{
        'manifest': const <String, dynamic>{},
        'results': <Map<String, dynamic>>[
          <String, dynamic>{
            'sourcePlan': <String, dynamic>{
              'source': const ReplaySourceDescriptor(
                sourceName: 'Source A',
                sourceType: 'official_calendar',
                accessMethod: ReplaySourceAccessMethod.api,
                trustTier: ReplaySourceTrustTier.tier1,
                status: ReplaySourceStatus.ingested,
                entityCoverage: <String>['events', 'venues', 'communities'],
                temporalStartYear: 2023,
                temporalEndYear: 2023,
                replayRole: 'event_truth',
                legalStatus: 'allowed',
                structuredExportAvailable: true,
              ).toJson(),
            },
            'observations': <Map<String, dynamic>>[
              ReplayNormalizedObservation(
                observationId: 'obs-event',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'event:sample',
                  entityType: 'event',
                  canonicalName: 'Sample Event',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-event',
                  subjectId: 'event:sample',
                  observedAt: buildInstant(DateTime.utc(2023, 4, 1, 12)),
                  eventStartAt: buildInstant(DateTime.utc(2023, 4, 1, 18)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty(
                    window: Duration(minutes: 30),
                    confidence: 0.85,
                  ),
                  temporalAuthoritySource: 'when_kernel',
                ),
                status: ReplayNormalizationStatus.normalized,
                sourceRefs: const <String>['Source A'],
              ).toJson(),
            ],
          },
          <String, dynamic>{
            'sourcePlan': <String, dynamic>{
              'source': const ReplaySourceDescriptor(
                sourceName: 'Source B',
                sourceType: 'poi',
                accessMethod: ReplaySourceAccessMethod.openData,
                trustTier: ReplaySourceTrustTier.tier2,
                status: ReplaySourceStatus.ingested,
                entityCoverage: <String>['venues'],
                temporalStartYear: 2023,
                temporalEndYear: 2023,
                replayRole: 'spatial_truth',
                legalStatus: 'allowed',
                structuredExportAvailable: true,
              ).toJson(),
            },
            'observations': <Map<String, dynamic>>[
              ReplayNormalizedObservation(
                observationId: 'obs-venue',
                subjectIdentity: const ReplayEntityIdentity(
                  normalizedEntityId: 'venue:sample',
                  entityType: 'venue',
                  canonicalName: 'Sample Venue',
                ),
                replayEnvelope: ReplayTemporalEnvelope(
                  envelopeId: 'env-venue',
                  subjectId: 'venue:sample',
                  observedAt: buildInstant(DateTime.utc(2023, 4, 1, 10)),
                  provenance: const TemporalProvenance(
                    authority: TemporalAuthority.historicalImport,
                    source: 'test',
                  ),
                  uncertainty: const TemporalUncertainty(
                    window: Duration(minutes: 15),
                    confidence: 0.8,
                  ),
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

  test('evaluates a governed replay forecast batch from execution plan',
      () async {
    final fixedClock = FixedClockSource(buildInstant(DateTime.utc(2023, 1, 1)));
    final temporalKernel = SystemTemporalKernel(clockSource: fixedClock);
    final executionService = BhamReplayExecutionService(
      temporalKernel: temporalKernel,
      replayClockSource: fixedClock,
    );
    final artifact = buildArtifact();
    const runContext = MonteCarloRunContext(
      canonicalReplayYear: 2023,
      replayYear: 2023,
      branchId: 'canonical',
      runId: 'run-forecast',
      seed: 2023,
      divergencePolicy: 'none',
    );
    final plan = executionService.buildPlanFromConsolidatedArtifact(
      artifact: artifact,
      runContext: runContext,
    );

    final forecastService = BhamReplayForecastBatchService(
      governedForecastRuntimeService: GovernedForecastRuntimeService(
        forecastGovernanceProjectionService:
            ForecastGovernanceProjectionService(
          forecastKernel: const BaselineForecastKernel(),
          temporalKernel: temporalKernel,
        ),
        replayYearSelectionService:
            const AuthoritativeReplayYearSelectionService(
          completenessService: ReplayYearCompletenessService(),
        ),
      ),
      replayClockSource: fixedClock,
    );

    final result = await forecastService.evaluatePlan(
      plan: plan,
      artifact: artifact,
      maxPerEntityType: 5,
    );

    expect(result.evaluatedCount, 2);
    expect(result.dispositionCounts['admitted'], 2);
    expect(result.entityTypeCounts['event'], 1);
    expect(result.entityTypeCounts['venue'], 1);
    expect(result.runContext.metadata.containsKey('mesh_runtime_state_summary'),
        false);
    expect(result.runContext.metadata.containsKey('mesh_runtime_state_frame'),
        false);
    expect(result.runContext.metadata.containsKey('ai2ai_runtime_state_summary'),
        false);
    expect(result.runContext.metadata.containsKey('ai2ai_runtime_state_frame'),
        false);
    expect(result.metadata['selected_forecast_kernel_id'],
        'baseline_forecast_kernel');
    expect(
      result.metadata['selected_forecast_kernel_execution_mode'],
      'baseline',
    );
  });
}

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/governed_forecast_runtime_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/forecast/baseline_forecast_kernel.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

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

  ForecastKernelRequest buildRequest() {
    final instant = buildInstant(DateTime.utc(2025, 4, 1, 18));
    return ForecastKernelRequest(
      forecastId: 'forecast-1',
      subjectId: 'venue:saturn',
      replayEnvelope: ReplayTemporalEnvelope(
        envelopeId: 'env-1',
        subjectId: 'venue:saturn',
        observedAt: instant,
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'bham_registry',
        ),
        uncertainty: const TemporalUncertainty(
          window: Duration(minutes: 10),
          confidence: 0.9,
        ),
        temporalAuthoritySource: 'when_kernel',
        metadata: const <String, dynamic>{'demand_signal': 0.9},
      ),
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2025,
        replayYear: 2025,
        branchId: 'branch-a',
        runId: 'run-1',
        seed: 1,
        divergencePolicy: 'none',
      ),
      targetWindow: TemporalInterval(start: instant, end: instant),
      evidenceWindow: TemporalInterval(start: instant, end: instant),
    );
  }

  test('selects replay year and evaluates governed forecast together',
      () async {
    final temporalKernel = SystemTemporalKernel(
      clockSource:
          FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
    );
    final service = GovernedForecastRuntimeService(
      forecastGovernanceProjectionService: ForecastGovernanceProjectionService(
        forecastKernel: const BaselineForecastKernel(),
        temporalKernel: temporalKernel,
      ),
      replayYearSelectionService: const AuthoritativeReplayYearSelectionService(
        completenessService: ReplayYearCompletenessService(),
      ),
    );

    final result = await service.evaluateBhamForecast(
      request: buildRequest(),
      candidateYears: const <int>[2024, 2025],
      sources: const <ReplaySourceDescriptor>[
        ReplaySourceDescriptor(
          sourceName: 'City Events',
          sourceType: 'official_calendar',
          accessMethod: ReplaySourceAccessMethod.api,
          trustTier: ReplaySourceTrustTier.tier1,
          status: ReplaySourceStatus.ingested,
          entityCoverage: <String>['events', 'venues', 'communities'],
          temporalStartYear: 2024,
          temporalEndYear: 2025,
          replayRole: 'event_truth',
          legalStatus: 'allowed',
          updateCadence: 'daily',
          richestYear: 2025,
          structuredExportAvailable: true,
        ),
      ],
    );

    expect(result.selection.selectedScore.year, 2025);
    expect(
      result.projection.disposition,
      ForecastGovernanceDisposition.admittedWithCaution,
    );
  });
}

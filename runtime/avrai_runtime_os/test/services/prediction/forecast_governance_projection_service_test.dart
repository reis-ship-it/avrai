import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';
import 'package:reality_engine/forecast/baseline_forecast_kernel.dart';

void main() {
  group('ForecastGovernanceProjectionService', () {
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
      const truthScope = TruthScopeDescriptor.defaultForecast(
        governanceStratum: GovernanceStratum.locality,
        agentClass: TruthAgentClass.business,
        sphereId: 'bham_replay',
        familyId: 'default_forecast_family',
      );
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
            window: Duration(minutes: 15),
            confidence: 0.82,
          ),
          temporalAuthoritySource: 'when_kernel',
          branchId: 'branch-a',
          runId: 'run-7',
          metadata: const <String, dynamic>{'demand_signal': 0.9},
        ),
        runContext: const MonteCarloRunContext(
          canonicalReplayYear: 2025,
          replayYear: 2025,
          branchId: 'branch-a',
          runId: 'run-7',
          seed: 7,
          divergencePolicy: 'seasonal_variation',
        ),
        targetWindow: TemporalInterval(start: instant, end: instant),
        evidenceWindow: TemporalInterval(start: instant, end: instant),
        truthScope: truthScope,
        metadata: const <String, dynamic>{
          'source_refs': <String>['city-events', 'venue-calendars'],
          'agent_class': 'business',
        },
      );
    }

    ReplayYearCompletenessScore buildScore(double score) {
      return ReplayYearCompletenessScore(
        year: 2025,
        eventCoverage: score,
        venueCoverage: score,
        communityCoverage: score,
        recurrenceFidelity: score,
        temporalCertainty: score,
        trustQuality: score,
        overallScore: score,
      );
    }

    test('admits a strong forecast and records it temporally', () async {
      final kernel = SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
      );
      final service = ForecastGovernanceProjectionService(
        forecastKernel: const BaselineForecastKernel(),
        temporalKernel: kernel,
      );

      final projection = await service.evaluateForecast(
        request: buildRequest(),
        replayYearScore: buildScore(0.84),
      );

      expect(
        projection.disposition,
        ForecastGovernanceDisposition.admittedWithCaution,
      );
      expect(projection.result.confidence, greaterThan(0.35));
      expect(projection.actionabilityScore, greaterThan(0.15));
      expect(projection.result.diagnostics, isNotNull);
      expect(projection.result.truthScope, isNotNull);
      expect(
        projection.trace.truthScope?.truthSurfaceKind,
        TruthSurfaceKind.forecast,
      );

      final stored = await kernel.getForecast('forecast-1');
      expect(stored?.claim.claimId, 'forecast-1');
      expect(stored?.claim.confidence, projection.result.confidence);
      expect(stored?.claim.truthScope?.scopeKey,
          projection.result.truthScope?.scopeKey);
    });

    test('downgrades when ground-truth overrides are present', () async {
      final kernel = SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
      );
      final service = ForecastGovernanceProjectionService(
        forecastKernel: const BaselineForecastKernel(),
        temporalKernel: kernel,
      );
      final request = buildRequest();

      final projection = await service.evaluateForecast(
        request: request,
        replayYearScore: buildScore(0.82),
        overrideRecords: <GroundTruthOverrideRecord>[
          GroundTruthOverrideRecord(
            overrideId: 'override-1',
            subjectId: request.subjectId,
            priorSource: 'historical_replay',
            overrideSource: 'locality_agent',
            overriddenAt: buildInstant(DateTime.utc(2025, 4, 1, 18, 5)),
            reason: 'locality closure contradiction',
            resolution: 'prior_downgraded',
            branchId: request.runContext.branchId,
            runId: request.runContext.runId,
          ),
        ],
      );

      expect(projection.disposition, ForecastGovernanceDisposition.downgraded);
      expect(projection.contradictionStress, 1);
      expect(
        projection.governanceReasons,
        contains('ground truth overrides contradict this forecast'),
      );
    });

    test('blocks when replay completeness is too weak', () async {
      final kernel = SystemTemporalKernel(
        clockSource:
            FixedClockSource(buildInstant(DateTime.utc(2026, 3, 10, 12))),
      );
      final service = ForecastGovernanceProjectionService(
        forecastKernel: const BaselineForecastKernel(),
        temporalKernel: kernel,
      );

      final projection = await service.evaluateForecast(
        request: buildRequest(),
        replayYearScore: buildScore(0.3),
      );

      expect(projection.disposition, ForecastGovernanceDisposition.blocked);
      expect(
        projection.governanceReasons,
        contains('support quality is too weak for forecast admission'),
      );
    });
  });
}

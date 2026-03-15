import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_calibration_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_ensemble_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_regime_shift_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';
import 'package:flutter_test/flutter_test.dart';
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
    const truthScope = TruthScopeDescriptor.defaultForecast(
      governanceStratum: GovernanceStratum.locality,
      agentClass: TruthAgentClass.business,
      sphereId: 'bham_replay',
      familyId: 'venue_attendance',
    );
    return ForecastKernelRequest(
      forecastId: 'forecast-live',
      subjectId: 'venue:saturn',
      replayEnvelope: ReplayTemporalEnvelope(
        envelopeId: 'env-live',
        subjectId: 'venue:saturn',
        observedAt: instant,
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.historicalImport,
          source: 'bham_registry',
        ),
        uncertainty: const TemporalUncertainty(
          window: Duration(minutes: 10),
          confidence: 0.88,
        ),
        temporalAuthoritySource: 'when_kernel',
        metadata: const <String, dynamic>{'demand_signal': 0.90},
      ),
      runContext: const MonteCarloRunContext(
        canonicalReplayYear: 2025,
        replayYear: 2025,
        branchId: 'branch-a',
        runId: 'run-live',
        seed: 7,
        divergencePolicy: 'none',
      ),
      targetWindow: TemporalInterval(start: instant, end: instant),
      evidenceWindow: TemporalInterval(start: instant, end: instant),
      forecastFamilyId: 'venue_attendance',
      truthScope: truthScope,
      metadata: const <String, dynamic>{
        'forecast_sphere_id': 'bham_replay',
        'agent_class': 'business',
      },
    );
  }

  ForecastKernelResult buildKernelResult(ForecastKernelRequest request) {
    return ForecastKernelResult(
      claim: ForecastTemporalClaim(
        claimId: request.forecastId,
        forecastCreatedAt: request.replayEnvelope.observedAt.referenceTime,
        targetWindow: request.targetWindow,
        evidenceWindow: request.evidenceWindow,
        confidence: 0.80,
        modelVersion: 'test_kernel_v2',
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.forecast,
          source: 'test.kernel',
        ),
      ),
      predictedOutcome: 'positive',
      confidence: 0.80,
      branchId: request.runContext.branchId,
      runId: request.runContext.runId,
      explanation: 'test forecast',
      forecastFamilyId: request.forecastFamilyId,
      outcomeProbability: 0.85,
      outcomeKind: ForecastOutcomeKind.binary,
      rawPredictiveDistribution: const ForecastPredictiveDistribution(
        outcomeKind: ForecastOutcomeKind.binary,
        discreteProbabilities: <String, double>{
          'positive': 0.85,
          'negative': 0.15,
        },
        mean: 0.85,
        variance: 0.1275,
        componentId: 'component_primary',
      ),
    );
  }

  ReplayYearCompletenessScore buildScore(double overall) {
    return ReplayYearCompletenessScore(
      year: 2025,
      eventCoverage: overall,
      venueCoverage: overall,
      communityCoverage: overall,
      recurrenceFidelity: overall,
      temporalCertainty: overall,
      trustQuality: overall,
      overallScore: overall,
    );
  }

  test('assess blends prior and empirical skill into forecast strength',
      () async {
    final ledger = ForecastSkillLedger(
      nowProvider: () => DateTime.utc(2025, 4, 2),
    );
    const truthScope = TruthScopeDescriptor.defaultForecast(
      governanceStratum: GovernanceStratum.locality,
      agentClass: TruthAgentClass.business,
      sphereId: 'bham_replay',
      familyId: 'venue_attendance',
    );
    final bucketKey = ForecastSkillBucketKey(
      scope: truthScope,
      outcomeKind: ForecastOutcomeKind.binary,
      horizonBand: '<1h',
    ).value;
    for (var index = 0; index < 24; index++) {
      final issuedAt = DateTime.utc(2025, 3, 1).add(Duration(hours: index));
      ledger.recordIssuedForecast(
        ForecastIssuedForecastRecord(
          forecastId: 'hist-$index',
          bucketKey: bucketKey,
          subjectId: 'venue:saturn',
          forecastFamilyId: 'venue_attendance',
          outcomeKind: ForecastOutcomeKind.binary,
          issuedAt: issuedAt,
          predictedOutcome: 'positive',
          rawPredictiveDistribution: const ForecastPredictiveDistribution(
            outcomeKind: ForecastOutcomeKind.binary,
            discreteProbabilities: <String, double>{
              'positive': 0.82,
              'negative': 0.18,
            },
            mean: 0.82,
            variance: 0.1476,
            componentId: 'component_primary',
          ),
          calibratedPredictiveDistribution:
              const ForecastPredictiveDistribution(
            outcomeKind: ForecastOutcomeKind.binary,
            discreteProbabilities: <String, double>{
              'positive': 0.80,
              'negative': 0.20,
            },
            mean: 0.80,
            variance: 0.16,
            componentId: 'component_primary',
          ),
          forecastStrength: 0.72,
          actionability: 0.61,
          supportQuality: 0.84,
          diagnostics: const ForecastStrengthDiagnostics(
            forecastStrength: 0.72,
            actionability: 0.61,
            supportQuality: 0.84,
            decisionMargin: 0.60,
            calibrationGap: 0.12,
            disagreement: 0.08,
            changePointProbability: 0.12,
            skillLowerConfidenceBound: 0.18,
            effectiveSampleSize: 18,
          ),
          truthScope: truthScope,
          sphereId: 'bham_replay',
        ),
      );
      await ledger.recordResolution(
        ForecastResolutionRecord(
          resolutionId: 'res-$index',
          forecastId: 'hist-$index',
          forecastFamilyId: 'venue_attendance',
          subjectId: 'venue:saturn',
          outcomeKind: ForecastOutcomeKind.binary,
          resolvedAt: issuedAt.add(const Duration(days: 1)),
          actualOutcomeLabel: index < 20 ? 'positive' : 'negative',
          sphereId: 'bham_replay',
          truthScope: truthScope,
        ),
      );
    }

    final strengthService = ForecastStrengthService(
      ensembleService: ForecastEnsembleService(skillLedger: ledger),
      calibrationService: ForecastCalibrationService(skillLedger: ledger),
      regimeShiftService: ForecastRegimeShiftService(skillLedger: ledger),
    );
    final request = buildRequest();
    final assessment = strengthService.assess(
      request: request,
      kernelResult: buildKernelResult(request),
      replayYearScore: buildScore(0.84),
    );

    expect(assessment.forecastStrength, greaterThan(0.35));
    expect(assessment.actionability, greaterThan(0.20));
    expect(
        assessment.calibrationSnapshot.sampleCount, greaterThanOrEqualTo(20));
    expect(assessment.predictedOutcome, 'positive');
    expect(assessment.truthScope.scopeKey, truthScope.scopeKey);
    expect(assessment.bucketKey, bucketKey);
  });
}

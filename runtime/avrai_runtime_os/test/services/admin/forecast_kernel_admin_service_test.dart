import 'package:avrai_runtime_os/services/admin/forecast_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/avra_core.dart';

void main() {
  test('aggregates recent forecast strength rows into admin snapshot',
      () async {
    final ledger = ForecastSkillLedger(
      nowProvider: () => DateTime.utc(2025, 4, 2, 12),
    );
    const truthScope = TruthScopeDescriptor.defaultForecast(
      governanceStratum: GovernanceStratum.locality,
      agentClass: TruthAgentClass.business,
      sphereId: 'bham_replay',
      familyId: 'family',
    );
    ledger.recordIssuedForecast(
      ForecastIssuedForecastRecord(
        forecastId: 'forecast-1',
        bucketKey: ForecastSkillBucketKey(
          scope: truthScope,
          outcomeKind: ForecastOutcomeKind.binary,
          horizonBand: '<1h',
        ).value,
        subjectId: 'venue:saturn',
        forecastFamilyId: 'family',
        outcomeKind: ForecastOutcomeKind.binary,
        issuedAt: DateTime.utc(2025, 4, 2, 11),
        predictedOutcome: 'positive',
        rawPredictiveDistribution: const ForecastPredictiveDistribution(
          outcomeKind: ForecastOutcomeKind.binary,
          discreteProbabilities: <String, double>{
            'positive': 0.72,
            'negative': 0.28,
          },
          componentId: 'component_primary',
        ),
        calibratedPredictiveDistribution: const ForecastPredictiveDistribution(
          outcomeKind: ForecastOutcomeKind.binary,
          discreteProbabilities: <String, double>{
            'positive': 0.74,
            'negative': 0.26,
          },
          componentId: 'component_primary',
        ),
        forecastStrength: 0.68,
        actionability: 0.41,
        supportQuality: 0.84,
        diagnostics: const ForecastStrengthDiagnostics(
          forecastStrength: 0.68,
          actionability: 0.41,
          supportQuality: 0.84,
          decisionMargin: 0.48,
          calibrationGap: 0.14,
          disagreement: 0.08,
          changePointProbability: 0.12,
          skillLowerConfidenceBound: 0.11,
          effectiveSampleSize: 16,
          metadata: <String, dynamic>{
            'calibration_snapshot': <String, dynamic>{
              'skillLowerConfidenceBound': 0.11,
              'warmingUp': true,
            },
          },
        ),
        truthScope: truthScope,
        sphereId: 'bham_replay',
        metadata: const <String, dynamic>{
          'disposition': 'admittedWithCaution',
          'outcome_probability': 0.74,
          'representation_mix': <String, int>{'classical': 1},
        },
      ),
    );

    final service = ForecastKernelAdminService(
      skillLedger: ledger,
      nowProvider: () => DateTime.utc(2025, 4, 2, 12),
    );
    final snapshot = await service.getForecastSnapshot();

    expect(snapshot.issuedCount, 1);
    expect(snapshot.averageForecastStrength, 0.68);
    expect(snapshot.bandCounts[ForecastStrengthBand.guarded.label], 1);
    expect(snapshot.dispositionCounts['admittedWithCaution'], 1);
    expect(snapshot.recentForecasts.single.warmingUp, isTrue);
    expect(
      snapshot.recentForecasts.single.truthScope.scopeKey,
      truthScope.scopeKey,
    );
    expect(
      snapshot.recentForecasts.single.tenantScope,
      TruthTenantScope.avraiNative,
    );
  });

  test(
    'stages one bounded assistant observation for forecast snapshots and suppresses duplicate refreshes',
    () async {
      final ledger = ForecastSkillLedger(
        nowProvider: () => DateTime.utc(2025, 4, 2, 12),
      );
      const truthScope = TruthScopeDescriptor.defaultForecast(
        governanceStratum: GovernanceStratum.locality,
        agentClass: TruthAgentClass.business,
        sphereId: 'bham_replay',
        familyId: 'family',
      );
      ledger.recordIssuedForecast(
        ForecastIssuedForecastRecord(
          forecastId: 'forecast-2',
          bucketKey: ForecastSkillBucketKey(
            scope: truthScope,
            outcomeKind: ForecastOutcomeKind.binary,
            horizonBand: '<1h',
          ).value,
          subjectId: 'venue:lyric',
          forecastFamilyId: 'family',
          outcomeKind: ForecastOutcomeKind.binary,
          issuedAt: DateTime.utc(2025, 4, 2, 11),
          predictedOutcome: 'positive',
          rawPredictiveDistribution: const ForecastPredictiveDistribution(
            outcomeKind: ForecastOutcomeKind.binary,
            discreteProbabilities: <String, double>{
              'positive': 0.70,
              'negative': 0.30,
            },
            componentId: 'component_primary',
          ),
          calibratedPredictiveDistribution:
              const ForecastPredictiveDistribution(
            outcomeKind: ForecastOutcomeKind.binary,
            discreteProbabilities: <String, double>{
              'positive': 0.73,
              'negative': 0.27,
            },
            componentId: 'component_primary',
          ),
          forecastStrength: 0.66,
          actionability: 0.43,
          supportQuality: 0.82,
          diagnostics: const ForecastStrengthDiagnostics(
            forecastStrength: 0.66,
            actionability: 0.43,
            supportQuality: 0.82,
            decisionMargin: 0.46,
            calibrationGap: 0.12,
            disagreement: 0.07,
            changePointProbability: 0.10,
            skillLowerConfidenceBound: 0.10,
            effectiveSampleSize: 16,
            metadata: <String, dynamic>{
              'calibration_snapshot': <String, dynamic>{
                'skillLowerConfidenceBound': 0.10,
                'warmingUp': true,
              },
            },
          ),
          truthScope: truthScope,
          sphereId: 'bham_replay',
          metadata: const <String, dynamic>{
            'disposition': 'admittedWithCaution',
            'outcome_probability': 0.73,
            'representation_mix': <String, int>{'classical': 1},
          },
        ),
      );

      final upwardRepository = UniversalIntakeRepository();
      final governedUpwardLearningIntakeService =
          GovernedUpwardLearningIntakeService(
        intakeRepository: upwardRepository,
        atomicClockService: AtomicClockService(),
      );
      final service = ForecastKernelAdminService(
        skillLedger: ledger,
        nowProvider: () => DateTime.utc(2025, 4, 2, 12),
        governedUpwardLearningIntakeService:
            governedUpwardLearningIntakeService,
      );

      await service.getForecastSnapshot();
      await service.getForecastSnapshot();

      final reviewItems = await upwardRepository.getAllReviewItems();
      final sources = await upwardRepository.getAllSources();

      expect(reviewItems, hasLength(1));
      expect(
        reviewItems.single.payload['sourceKind'],
        'assistant_bounded_observation_intake',
      );
      expect(
        reviewItems.single.payload['channel'],
        'forecast_kernel_snapshot',
      );
      expect(reviewItems.single.payload['airGapArtifact'],
          isA<Map<String, dynamic>>());
      expect(sources, hasLength(1));
      expect(
        sources.single.sourceProvider,
        'assistant_bounded_observation_intake',
      );
    },
  );
}

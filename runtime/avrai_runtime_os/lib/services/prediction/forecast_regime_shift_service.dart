import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_math_support.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';

class ForecastRegimeShiftAssessment {
  const ForecastRegimeShiftAssessment({
    required this.probability,
    required this.recentSkillMean,
    required this.historicalSkillMean,
    required this.effectiveSampleSize,
    required this.deteriorationZScore,
  });

  final double probability;
  final double recentSkillMean;
  final double historicalSkillMean;
  final double effectiveSampleSize;
  final double deteriorationZScore;
}

class ForecastRegimeShiftService {
  ForecastRegimeShiftService({
    required ForecastSkillLedger skillLedger,
    DateTime Function()? nowProvider,
  })  : _skillLedger = skillLedger,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final ForecastSkillLedger _skillLedger;
  final DateTime Function() _nowProvider;

  ForecastRegimeShiftAssessment assess({
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final records = _skillLedger
        .resolvedRecordsForBucketKeys(bucketKeys)
        .where((entry) => entry.resolution.outcomeKind == outcomeKind)
        .toList()
      ..sort(
        (left, right) =>
            left.resolution.resolvedAt.compareTo(right.resolution.resolvedAt),
      );
    if (records.length < 12) {
      return const ForecastRegimeShiftAssessment(
        probability: 0.15,
        recentSkillMean: 0.0,
        historicalSkillMean: 0.0,
        effectiveSampleSize: 0.0,
        deteriorationZScore: 0.0,
      );
    }

    final recentCount = math.max(4, (records.length / 3).ceil());
    final historical = records.sublist(0, records.length - recentCount);
    final recent = records.sublist(records.length - recentCount);
    final now = _nowProvider();
    final historicalWeights = historical
        .map(
          (entry) => recencyWeight(
            nowUtc: now,
            observedAtUtc: entry.resolution.resolvedAt.toUtc(),
          ),
        )
        .toList(growable: false);
    final recentWeights = recent
        .map(
          (entry) => recencyWeight(
            nowUtc: now,
            observedAtUtc: entry.resolution.resolvedAt.toUtc(),
          ),
        )
        .toList(growable: false);
    final historicalImprovements = historical
        .map((entry) => entry.baselinePrimaryScore - entry.primaryScore)
        .toList(growable: false);
    final recentImprovements = recent
        .map((entry) => entry.baselinePrimaryScore - entry.primaryScore)
        .toList(growable: false);
    final historicalMean =
        weightedMean(historicalImprovements, historicalWeights);
    final recentMean = weightedMean(recentImprovements, recentWeights);
    final historicalVariance =
        weightedVariance(historicalImprovements, historicalWeights);
    final recentVariance = weightedVariance(recentImprovements, recentWeights);
    final deterioration = historicalMean - recentMean;
    final scale =
        math.sqrt(math.max(historicalVariance + recentVariance, 0.0)) + 0.05;
    final deteriorationZScore = deterioration / scale;
    final combinedWeights = [...historicalWeights, ...recentWeights];
    final ess = effectiveSampleSize(combinedWeights);
    final sampleFactor = clamp01(ess / 30.0);
    final coreProbability =
        clamp01((sigmoid(deteriorationZScore) - 0.5) * 2.0) * sampleFactor;
    final negativeSkillPenalty = recentMean < 0 ? 0.1 : 0.0;
    return ForecastRegimeShiftAssessment(
      probability: clamp01(coreProbability + negativeSkillPenalty),
      recentSkillMean: recentMean,
      historicalSkillMean: historicalMean,
      effectiveSampleSize: ess,
      deteriorationZScore: deteriorationZScore,
    );
  }
}

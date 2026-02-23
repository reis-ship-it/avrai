import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Generic A/B testing utilities for formula-replacement experiments.
///
/// This service is domain-agnostic and can be reused across formula-vs-model
/// comparisons beyond calling score.
class FormulaABTestingService {
  const FormulaABTestingService();

  bool isTreatmentGroup({
    required String stableSubjectId,
    double treatmentPercentage = 0.5,
  }) {
    final boundedPct = treatmentPercentage.clamp(0.0, 1.0);
    final hash = sha256.convert(utf8.encode(stableSubjectId));
    final firstByte = hash.bytes.first; // 0..255
    final threshold = (boundedPct * 256).floor();
    return firstByte < threshold;
  }

  GenericABGroupMetrics calculateGroupMetrics(
    List<Map<String, dynamic>> outcomes, {
    String scoreField = 'calling_score',
    String calledField = 'is_called',
    String outcomeTypeField = 'outcome_type',
    String outcomeScoreField = 'outcome_score',
    String positiveOutcomeType = 'positive',
  }) {
    if (outcomes.isEmpty) {
      return GenericABGroupMetrics.empty();
    }

    var totalScore = 0.0;
    var calledCount = 0;
    var positiveOutcomes = 0;
    var totalOutcomesWithLabel = 0;
    var totalOutcomeScore = 0.0;

    for (final outcome in outcomes) {
      totalScore += (outcome[scoreField] as num?)?.toDouble() ?? 0.0;
      if (outcome[calledField] == true) {
        calledCount++;
      }

      final outcomeType = outcome[outcomeTypeField] as String?;
      if (outcomeType != null) {
        totalOutcomesWithLabel++;
        if (outcomeType == positiveOutcomeType) {
          positiveOutcomes++;
        }
        totalOutcomeScore +=
            (outcome[outcomeScoreField] as num?)?.toDouble() ?? 0.0;
      }
    }

    final totalRows = outcomes.length;
    return GenericABGroupMetrics(
      totalOutcomes: totalRows,
      avgScore: totalRows > 0 ? totalScore / totalRows : 0.0,
      actionRate: totalRows > 0 ? calledCount / totalRows : 0.0,
      positiveOutcomeRate: totalOutcomesWithLabel > 0
          ? positiveOutcomes / totalOutcomesWithLabel
          : 0.0,
      avgOutcomeScore: totalOutcomesWithLabel > 0
          ? totalOutcomeScore / totalOutcomesWithLabel
          : 0.0,
    );
  }

  GenericABComparisonMetrics compare({
    required GenericABGroupMetrics controlGroup,
    required GenericABGroupMetrics treatmentGroup,
  }) {
    return GenericABComparisonMetrics(
      controlGroup: controlGroup,
      treatmentGroup: treatmentGroup,
      scoreImprovement: treatmentGroup.avgScore - controlGroup.avgScore,
      positiveOutcomeRateImprovement:
          treatmentGroup.positiveOutcomeRate - controlGroup.positiveOutcomeRate,
      outcomeScoreImprovement:
          treatmentGroup.avgOutcomeScore - controlGroup.avgOutcomeScore,
      calculatedAt: DateTime.now(),
    );
  }
}

class GenericABGroupMetrics {
  final int totalOutcomes;
  final double avgScore;
  final double actionRate;
  final double positiveOutcomeRate;
  final double avgOutcomeScore;

  const GenericABGroupMetrics({
    required this.totalOutcomes,
    required this.avgScore,
    required this.actionRate,
    required this.positiveOutcomeRate,
    required this.avgOutcomeScore,
  });

  factory GenericABGroupMetrics.empty() {
    return const GenericABGroupMetrics(
      totalOutcomes: 0,
      avgScore: 0.0,
      actionRate: 0.0,
      positiveOutcomeRate: 0.0,
      avgOutcomeScore: 0.0,
    );
  }
}

class GenericABComparisonMetrics {
  final GenericABGroupMetrics controlGroup;
  final GenericABGroupMetrics treatmentGroup;
  final double scoreImprovement;
  final double positiveOutcomeRateImprovement;
  final double outcomeScoreImprovement;
  final DateTime calculatedAt;

  const GenericABComparisonMetrics({
    required this.controlGroup,
    required this.treatmentGroup,
    required this.scoreImprovement,
    required this.positiveOutcomeRateImprovement,
    required this.outcomeScoreImprovement,
    required this.calculatedAt,
  });
}

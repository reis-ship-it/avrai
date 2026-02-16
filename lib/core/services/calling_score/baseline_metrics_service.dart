/// Generic baseline metrics service extracted from formula-specific pipelines.
///
/// Phase 1.3.1: baseline metrics generalized so additional formulas can use
/// the same evaluator.
class BaselineEvaluationRecord {
  final bool predictedPositive;
  final bool actualPositive;
  final double predictedScore;
  final double? actualScore;

  const BaselineEvaluationRecord({
    required this.predictedPositive,
    required this.actualPositive,
    required this.predictedScore,
    this.actualScore,
  });
}

class BaselineMetricsResult {
  final int totalRecords;
  final int truePositives;
  final int trueNegatives;
  final int falsePositives;
  final int falseNegatives;
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final double meanScoreError;
  final double outcomePredictionAccuracy;

  const BaselineMetricsResult({
    required this.totalRecords,
    required this.truePositives,
    required this.trueNegatives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.meanScoreError,
    required this.outcomePredictionAccuracy,
  });
}

class BaselineMetricsService {
  const BaselineMetricsService();

  BaselineMetricsResult evaluate(List<BaselineEvaluationRecord> records) {
    if (records.isEmpty) {
      return const BaselineMetricsResult(
        totalRecords: 0,
        truePositives: 0,
        trueNegatives: 0,
        falsePositives: 0,
        falseNegatives: 0,
        accuracy: 0.0,
        precision: 0.0,
        recall: 0.0,
        f1Score: 0.0,
        meanScoreError: 0.0,
        outcomePredictionAccuracy: 0.0,
      );
    }

    var truePositives = 0;
    var trueNegatives = 0;
    var falsePositives = 0;
    var falseNegatives = 0;
    var totalScoreError = 0.0;
    var scoreErrorCount = 0;

    for (final record in records) {
      if (record.predictedPositive && record.actualPositive) {
        truePositives++;
      } else if (!record.predictedPositive && !record.actualPositive) {
        trueNegatives++;
      } else if (record.predictedPositive && !record.actualPositive) {
        falsePositives++;
      } else if (!record.predictedPositive && record.actualPositive) {
        falseNegatives++;
      }

      if (record.actualScore != null) {
        totalScoreError += (record.predictedScore - record.actualScore!).abs();
        scoreErrorCount++;
      }
    }

    final total = records.length;
    final accuracy = (truePositives + trueNegatives) / total;
    final precision = (truePositives + falsePositives) > 0
        ? truePositives / (truePositives + falsePositives)
        : 0.0;
    final recall = (truePositives + falseNegatives) > 0
        ? truePositives / (truePositives + falseNegatives)
        : 0.0;
    final f1Score = (precision + recall) > 0
        ? 2 * (precision * recall) / (precision + recall)
        : 0.0;
    final meanScoreError =
        scoreErrorCount > 0 ? totalScoreError / scoreErrorCount : 0.0;
    final outcomePredictionAccuracy = 1.0 - meanScoreError.clamp(0.0, 1.0);

    return BaselineMetricsResult(
      totalRecords: total,
      truePositives: truePositives,
      trueNegatives: trueNegatives,
      falsePositives: falsePositives,
      falseNegatives: falseNegatives,
      accuracy: accuracy,
      precision: precision,
      recall: recall,
      f1Score: f1Score,
      meanScoreError: meanScoreError,
      outcomePredictionAccuracy: outcomePredictionAccuracy,
    );
  }
}

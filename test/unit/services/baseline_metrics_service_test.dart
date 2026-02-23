import 'package:avrai/core/services/calling_score/baseline_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaselineMetricsService', () {
    const service = BaselineMetricsService();

    test('calculates confusion metrics and score error', () {
      final metrics = service.calculateFromRecords(
        const [
          FormulaEvaluationRecord(
            predictedPositive: true,
            actualPositive: true,
            predictedScore: 0.9,
            actualScore: 1.0,
          ),
          FormulaEvaluationRecord(
            predictedPositive: true,
            actualPositive: false,
            predictedScore: 0.8,
            actualScore: 0.1,
          ),
          FormulaEvaluationRecord(
            predictedPositive: false,
            actualPositive: false,
            predictedScore: 0.2,
            actualScore: 0.0,
          ),
          FormulaEvaluationRecord(
            predictedPositive: false,
            actualPositive: true,
            predictedScore: 0.1,
            actualScore: 0.9,
          ),
        ],
      );

      expect(metrics.totalRecords, equals(4));
      expect(metrics.truePositives, equals(1));
      expect(metrics.trueNegatives, equals(1));
      expect(metrics.falsePositives, equals(1));
      expect(metrics.falseNegatives, equals(1));
      expect(metrics.accuracy, equals(0.5));
      expect(metrics.precision, equals(0.5));
      expect(metrics.recall, equals(0.5));
      expect(metrics.f1Score, equals(0.5));
      expect(metrics.meanScoreError, closeTo(0.45, 0.0001));
      expect(metrics.outcomePredictionAccuracy, closeTo(0.55, 0.0001));
    });

    test('returns empty metrics for no records', () {
      final metrics = service.calculateFromRecords(const []);
      expect(metrics.totalRecords, equals(0));
      expect(metrics.accuracy, equals(0.0));
      expect(metrics.outcomePredictionAccuracy, equals(0.0));
    });
  });
}

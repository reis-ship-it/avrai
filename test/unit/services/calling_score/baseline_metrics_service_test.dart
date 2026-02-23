import 'package:avrai/core/services/calling_score/baseline_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaselineMetricsService', () {
    const service = BaselineMetricsService();

    test('evaluates confusion-matrix metrics', () {
      final result = service.evaluate(const [
        BaselineEvaluationRecord(
          predictedPositive: true,
          actualPositive: true,
          predictedScore: 0.9,
          actualScore: 0.8,
        ),
        BaselineEvaluationRecord(
          predictedPositive: true,
          actualPositive: false,
          predictedScore: 0.8,
          actualScore: 0.1,
        ),
        BaselineEvaluationRecord(
          predictedPositive: false,
          actualPositive: false,
          predictedScore: 0.2,
          actualScore: 0.2,
        ),
        BaselineEvaluationRecord(
          predictedPositive: false,
          actualPositive: true,
          predictedScore: 0.3,
          actualScore: 0.7,
        ),
      ]);

      expect(result.totalRecords, 4);
      expect(result.truePositives, 1);
      expect(result.trueNegatives, 1);
      expect(result.falsePositives, 1);
      expect(result.falseNegatives, 1);
      expect(result.accuracy, 0.5);
      expect(result.precision, 0.5);
      expect(result.recall, 0.5);
      expect(result.f1Score, 0.5);
    });
  });
}

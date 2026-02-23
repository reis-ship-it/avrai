import 'package:avrai/core/services/calling_score/training_data_preparation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingDataPreparationService', () {
    const service = TrainingDataPreparationService();

    test('normalizes features and handles flat dimensions', () {
      final normalized = service.normalizeFeatures([
        [1.0, 10.0, 5.0],
        [3.0, 20.0, 5.0],
        [2.0, 30.0, 5.0],
      ]);

      expect(normalized, hasLength(3));
      expect(normalized[0][0], closeTo(0.0, 0.0001));
      expect(normalized[1][0], closeTo(1.0, 0.0001));
      expect(normalized[2][1], closeTo(1.0, 0.0001));
      expect(normalized[0][2], closeTo(0.5, 0.0001));
      expect(normalized[1][2], closeTo(0.5, 0.0001));
    });

    test('splits features and labels with valid split ratios', () {
      final features = List<List<double>>.generate(
        10,
        (i) => [i.toDouble()],
      );
      final labels = List<double>.generate(10, (i) => i / 10.0);

      final splits = service.split(
        features: features,
        labels: labels,
        trainSplit: 0.8,
        valSplit: 0.1,
        testSplit: 0.1,
      );

      expect(splits.trainFeatures.length, equals(8));
      expect(splits.valFeatures.length, equals(1));
      expect(splits.testFeatures.length, equals(1));
      expect(splits.trainLabels.length, equals(8));
      expect(splits.valLabels.length, equals(1));
      expect(splits.testLabels.length, equals(1));
    });

    test('throws when split ratios are invalid', () {
      expect(
        () => service.validateSplits(
          trainSplit: 0.8,
          valSplit: 0.15,
          testSplit: 0.15,
        ),
        throwsArgumentError,
      );
    });
  });
}

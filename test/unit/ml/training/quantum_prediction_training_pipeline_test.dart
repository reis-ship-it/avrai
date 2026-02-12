import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ml/training/quantum_prediction_training_pipeline.dart';
import 'package:avrai/core/ml/training/quantum_prediction_training_models.dart';
import 'package:avrai/core/models/quantum/quantum_prediction_features.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QuantumPredictionTrainingPipeline', () {
    late QuantumPredictionTrainingPipeline pipeline;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      pipeline = QuantumPredictionTrainingPipeline();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should train model with training examples', () async {
      // Arrange
      final examples = List.generate(100, (i) {
        return QuantumTrainingExample(
          features: QuantumPredictionFeatures.minimal(
            temporalCompatibility: 0.5 + (i % 10) / 20.0,
            weekdayMatch: 0.5 + (i % 7) / 14.0,
          ),
          groundTruth: 0.5 + (i % 10) / 20.0,
          timestamp: DateTime.now(),
        );
      });

      // Act
      final model = await pipeline.trainModel(
        trainingExamples: examples,
        epochs: 10,
        targetAccuracy: 0.5, // Lower threshold for test
      );

      // Assert
      expect(model.featureWeights.isNotEmpty, isTrue);
      expect(model.accuracy, greaterThanOrEqualTo(0.0));
      expect(model.accuracy, lessThanOrEqualTo(1.0));
      expect(model.loss, greaterThanOrEqualTo(0.0));
      expect(model.trainingExamples, equals(80)); // 80% train split
    });

    test('should split dataset into train and validation sets', () async {
      // Arrange
      final examples = List.generate(100, (i) {
        return QuantumTrainingExample(
          features: QuantumPredictionFeatures.minimal(
            temporalCompatibility: 0.5,
            weekdayMatch: 0.5,
          ),
          groundTruth: 0.5,
          timestamp: DateTime.now(),
        );
      });

      // Act - Test split by training with validation split
      final model = await pipeline.trainModel(
        trainingExamples: examples,
        validationSplit: 0.2,
        epochs: 1,
        targetAccuracy: 0.5,
      );

      // Assert - Model should have been trained with split data
      expect(model.trainingExamples, equals(80)); // 80% train
    });

    test('should predict using trained model', () async {
      // Arrange
      final examples = List.generate(50, (i) {
        return QuantumTrainingExample(
          features: QuantumPredictionFeatures.minimal(
            temporalCompatibility: 0.7,
            weekdayMatch: 0.8,
          ),
          groundTruth: 0.75,
          timestamp: DateTime.now(),
        );
      });

      final model = await pipeline.trainModel(
        trainingExamples: examples,
        epochs: 5,
        targetAccuracy: 0.5,
      );

      final testFeatures = QuantumPredictionFeatures.minimal(
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
      );

      // Act
      final prediction = model.predict(testFeatures);

      // Assert
      expect(prediction, greaterThanOrEqualTo(0.0));
      expect(prediction, lessThanOrEqualTo(1.0));
    });

    test('should calculate feature importance', () async {
      // Arrange
      final examples = List.generate(50, (i) {
        return QuantumTrainingExample(
          features: QuantumPredictionFeatures.minimal(
            temporalCompatibility: 0.5,
            weekdayMatch: 0.5,
          ),
          groundTruth: 0.5,
          timestamp: DateTime.now(),
        );
      });

      // Act
      final model = await pipeline.trainModel(
        trainingExamples: examples,
        epochs: 5,
        targetAccuracy: 0.5,
      );

      // Assert
      expect(model.featureImportance.isNotEmpty, isTrue);
      // Importance should sum to approximately 1.0 (allowing for rounding)
      final totalImportance = model.featureImportance.values
          .reduce((a, b) => a + b);
      expect(totalImportance, closeTo(1.0, 0.1));
    });

    test('should serialize and deserialize model correctly (round-trip)', () async {
      // Arrange
      final examples = List.generate(50, (i) {
        return QuantumTrainingExample(
          features: QuantumPredictionFeatures.minimal(
            temporalCompatibility: 0.5,
            weekdayMatch: 0.5,
          ),
          groundTruth: 0.5,
          timestamp: DateTime.now(),
        );
      });

      final original = await pipeline.trainModel(
        trainingExamples: examples,
        epochs: 5,
        targetAccuracy: 0.5,
      );

      // Act
      final json = original.toJson();
      final restored = QuantumTrainedModel.fromJson(json);

      // Assert
      expect(restored.featureWeights.length, equals(original.featureWeights.length));
      expect(restored.accuracy, closeTo(original.accuracy, 0.001));
      expect(restored.loss, closeTo(original.loss, 0.001));
      expect(restored.trainingExamples, equals(original.trainingExamples));
    });

    test('should throw error for empty training examples', () async {
      // Act & Assert
      expect(
        () => pipeline.trainModel(trainingExamples: []),
        throwsArgumentError,
      );
    });
  });
}



import 'dart:developer' as developer;
import 'package:avrai_core/models/quantum/quantum_prediction_features.dart';
import 'package:avrai_runtime_os/ml/training/quantum_prediction_training_models.dart';

/// Quantum Prediction Training Pipeline
///
/// Trains a model to predict user behavior using quantum features.
///
/// **Purpose:**
/// - Collect training data with quantum features
/// - Train model with quantum features
/// - Validate improvement (target: 88-92% accuracy)
/// - Optimize feature weights using machine learning
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 3.1
class QuantumPredictionTrainingPipeline {
  static const String _logName = 'QuantumPredictionTrainingPipeline';

  QuantumPredictionTrainingPipeline();

  /// Train model with quantum features
  ///
  /// **Parameters:**
  /// - `trainingExamples`: List of training examples with features and ground truth
  /// - `validationSplit`: Fraction of data to use for validation (default: 0.2)
  /// - `learningRate`: Learning rate for gradient descent (default: 0.01)
  /// - `epochs`: Number of training epochs (default: 100)
  /// - `targetAccuracy`: Minimum accuracy to accept (default: 0.88)
  ///
  /// **Returns:**
  /// Trained model with optimized feature weights
  Future<QuantumTrainedModel> trainModel({
    required List<QuantumTrainingExample> trainingExamples,
    double validationSplit = 0.2,
    double learningRate = 0.01,
    int epochs = 100,
    double targetAccuracy = 0.88,
  }) async {
    try {
      developer.log(
        'Training model with ${trainingExamples.length} examples',
        name: _logName,
      );

      if (trainingExamples.isEmpty) {
        throw ArgumentError('Training examples cannot be empty');
      }

      // Split into training and validation sets
      final split = _splitDataset(trainingExamples, validationSplit);

      developer.log(
        'Dataset split: ${split.train.length} train, ${split.validation.length} validation',
        name: _logName,
      );

      // Initialize feature weights (start with current weights from enhancer)
      final featureNames = trainingExamples.first.features.getFeatureNames();
      final initialWeights = _initializeWeights(featureNames);

      // Train model using gradient descent
      var weights = Map<String, double>.from(initialWeights);
      double bestValidationAccuracy = 0.0;
      Map<String, double> bestWeights = Map<String, double>.from(weights);

      for (int epoch = 0; epoch < epochs; epoch++) {
        // Train on training set
        weights = await _trainEpoch(
          weights: weights,
          examples: split.train,
          learningRate: learningRate,
        );

        // Validate on validation set
        final validationMetrics = _evaluateModel(
          weights: weights,
          examples: split.validation,
        );

        if (validationMetrics.accuracy > bestValidationAccuracy) {
          bestValidationAccuracy = validationMetrics.accuracy;
          bestWeights = Map<String, double>.from(weights);
        }

        if (epoch % 10 == 0) {
          developer.log(
            'Epoch $epoch: validation accuracy = ${(validationMetrics.accuracy * 100).toStringAsFixed(2)}%',
            name: _logName,
          );
        }
      }

      // Final evaluation
      final finalMetrics = _evaluateModel(
        weights: bestWeights,
        examples: split.validation,
      );

      // Calculate feature importance
      final featureImportance = _calculateFeatureImportance(
        weights: bestWeights,
        examples: split.train,
      );

      // Check if target accuracy is met
      if (finalMetrics.accuracy < targetAccuracy) {
        developer.log(
          'Warning: Model accuracy ${(finalMetrics.accuracy * 100).toStringAsFixed(2)}% '
          'below target ${(targetAccuracy * 100).toStringAsFixed(2)}%',
          name: _logName,
        );
      }

      final model = QuantumTrainedModel(
        featureWeights: bestWeights,
        accuracy: finalMetrics.accuracy,
        loss: finalMetrics.loss,
        trainingExamples: split.train.length,
        trainedAt: DateTime.now(),
        featureImportance: featureImportance,
      );

      developer.log(
        '✅ Model training complete: accuracy = ${(finalMetrics.accuracy * 100).toStringAsFixed(2)}%, '
        'loss = ${finalMetrics.loss.toStringAsFixed(4)}',
        name: _logName,
      );

      return model;
    } catch (e, stackTrace) {
      developer.log(
        'Error training model: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Split dataset into training and validation sets
  QuantumDatasetSplit _splitDataset(
    List<QuantumTrainingExample> examples,
    double validationSplit,
  ) {
    final shuffled = List<QuantumTrainingExample>.from(examples)..shuffle();
    final splitIndex = (examples.length * (1.0 - validationSplit)).round();

    return QuantumDatasetSplit(
      train: shuffled.sublist(0, splitIndex),
      validation: shuffled.sublist(splitIndex),
    );
  }

  /// Initialize feature weights (start with current enhancer weights)
  Map<String, double> _initializeWeights(List<String> featureNames) {
    final weights = <String, double>{};

    // Initialize with current enhancer weights (normalized)
    final enhancerWeights = {
      'temporalCompatibility': 0.7 * 0.6, // Base weight * temporal portion
      'weekdayMatch': 0.7 * 0.4, // Base weight * weekday portion
      'decoherenceRate': 0.05,
      'decoherenceStability': 0.05,
      'interferenceStrength': 0.05,
      'entanglementStrength': 0.03,
      'phaseAlignment': 0.02,
      'coherenceLevel': 0.01,
      'temporalQuantumMatch': 0.03,
      'preferenceDrift': 0.01,
    };

    // Initialize all features
    for (final name in featureNames) {
      if (name.startsWith('quantumVibeMatch_')) {
        weights[name] =
            0.05 / 12; // Split vibe match weight across 12 dimensions
      } else {
        weights[name] = enhancerWeights[name] ?? 0.0;
      }
    }

    return weights;
  }

  /// Train one epoch using gradient descent
  Future<Map<String, double>> _trainEpoch({
    required Map<String, double> weights,
    required List<QuantumTrainingExample> examples,
    required double learningRate,
  }) async {
    final gradients = <String, double>{};
    final featureNames = examples.first.features.getFeatureNames();

    // Initialize gradients
    for (final name in featureNames) {
      gradients[name] = 0.0;
    }

    // Calculate gradients
    for (final example in examples) {
      final prediction = _predict(weights, example.features);
      final error = prediction - example.groundTruth;

      final featureVector = example.features.toFeatureVector();
      for (int i = 0;
          i < featureVector.length && i < featureNames.length;
          i++) {
        gradients[featureNames[i]] =
            (gradients[featureNames[i]] ?? 0.0) + error * featureVector[i];
      }
    }

    // Update weights
    final updatedWeights = <String, double>{};
    for (final entry in weights.entries) {
      final gradient = (gradients[entry.key] ?? 0.0) / examples.length;
      updatedWeights[entry.key] =
          (entry.value - learningRate * gradient).clamp(-1.0, 1.0);
    }

    return updatedWeights;
  }

  /// Predict using current weights
  double _predict(
      Map<String, double> weights, QuantumPredictionFeatures features) {
    final featureVector = features.toFeatureVector();
    final featureNames = features.getFeatureNames();

    double prediction = 0.0;
    for (int i = 0; i < featureVector.length && i < featureNames.length; i++) {
      final weight = weights[featureNames[i]] ?? 0.0;
      prediction += featureVector[i] * weight;
    }

    return prediction.clamp(0.0, 1.0);
  }

  /// Evaluate model on examples
  QuantumTrainingMetrics _evaluateModel({
    required Map<String, double> weights,
    required List<QuantumTrainingExample> examples,
  }) {
    if (examples.isEmpty) {
      return QuantumTrainingMetrics(
        accuracy: 0.0,
        loss: 1.0,
        validationAccuracy: 0.0,
        validationLoss: 1.0,
        featureImportance: {},
        trainingExamples: 0,
        validationExamples: 0,
      );
    }

    double totalSquaredError = 0.0;
    int correctPredictions = 0;

    for (final example in examples) {
      final prediction = _predict(weights, example.features);
      final error = (prediction - example.groundTruth).abs();
      totalSquaredError += error * error;

      // Count correct predictions (within 0.1 threshold)
      if (error < 0.1) {
        correctPredictions++;
      }
    }

    final accuracy = correctPredictions / examples.length;
    final loss = totalSquaredError / examples.length;

    return QuantumTrainingMetrics(
      accuracy: accuracy,
      loss: loss,
      validationAccuracy: accuracy,
      validationLoss: loss,
      featureImportance: _calculateFeatureImportance(
        weights: weights,
        examples: examples,
      ),
      trainingExamples: examples.length,
      validationExamples: 0,
    );
  }

  /// Calculate feature importance (absolute weight normalized)
  Map<String, double> _calculateFeatureImportance({
    required Map<String, double> weights,
    required List<QuantumTrainingExample> examples,
  }) {
    final importance = <String, double>{};
    double totalAbsWeight = 0.0;

    // Calculate total absolute weight
    for (final weight in weights.values) {
      totalAbsWeight += weight.abs();
    }

    // Normalize to get importance percentages
    if (totalAbsWeight > 0.0) {
      for (final entry in weights.entries) {
        importance[entry.key] = entry.value.abs() / totalAbsWeight;
      }
    }

    return importance;
  }
}

import 'package:avrai_core/models/quantum/quantum_prediction_features.dart';

/// Training example with features and ground truth
class QuantumTrainingExample {
  final QuantumPredictionFeatures features;
  final double groundTruth; // Actual outcome (0.0-1.0)
  final DateTime timestamp;

  QuantumTrainingExample({
    required this.features,
    required this.groundTruth,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'features': features.toJson(),
        'groundTruth': groundTruth,
        'timestamp': timestamp.toIso8601String(),
      };

  factory QuantumTrainingExample.fromJson(Map<String, dynamic> json) {
    return QuantumTrainingExample(
      features: QuantumPredictionFeatures.fromJson(json['features']),
      groundTruth: (json['groundTruth'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Trained model with weights and metrics
class QuantumTrainedModel {
  final Map<String, double> featureWeights;
  final double accuracy;
  final double loss;
  final int trainingExamples;
  final DateTime trainedAt;
  final Map<String, double> featureImportance;

  QuantumTrainedModel({
    required this.featureWeights,
    required this.accuracy,
    required this.loss,
    required this.trainingExamples,
    required this.trainedAt,
    required this.featureImportance,
  });

  /// Predict using trained model
  double predict(QuantumPredictionFeatures features) {
    final featureVector = features.toFeatureVector();
    final featureNames = features.getFeatureNames();

    double prediction = 0.0;
    for (int i = 0; i < featureVector.length && i < featureNames.length; i++) {
      final weight = featureWeights[featureNames[i]] ?? 0.0;
      prediction += featureVector[i] * weight;
    }

    return prediction.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'featureWeights': featureWeights,
        'accuracy': accuracy,
        'loss': loss,
        'trainingExamples': trainingExamples,
        'trainedAt': trainedAt.toIso8601String(),
        'featureImportance': featureImportance,
      };

  factory QuantumTrainedModel.fromJson(Map<String, dynamic> json) {
    return QuantumTrainedModel(
      featureWeights: Map<String, double>.from(
        (json['featureWeights'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      accuracy: (json['accuracy'] as num).toDouble(),
      loss: (json['loss'] as num).toDouble(),
      trainingExamples: json['trainingExamples'] as int,
      trainedAt: DateTime.parse(json['trainedAt']),
      featureImportance: Map<String, double>.from(
        (json['featureImportance'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
    );
  }
}

/// Training metrics
class QuantumTrainingMetrics {
  final double accuracy;
  final double loss;
  final double validationAccuracy;
  final double validationLoss;
  final Map<String, double> featureImportance;
  final int trainingExamples;
  final int validationExamples;

  QuantumTrainingMetrics({
    required this.accuracy,
    required this.loss,
    required this.validationAccuracy,
    required this.validationLoss,
    required this.featureImportance,
    required this.trainingExamples,
    required this.validationExamples,
  });
}

/// Dataset split
class QuantumDatasetSplit {
  final List<QuantumTrainingExample> train;
  final List<QuantumTrainingExample> validation;

  QuantumDatasetSplit({
    required this.train,
    required this.validation,
  });
}

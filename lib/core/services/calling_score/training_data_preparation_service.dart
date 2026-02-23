class GenericTrainingDataSplits {
  final List<List<double>> trainFeatures;
  final List<double> trainLabels;
  final List<List<double>> valFeatures;
  final List<double> valLabels;
  final List<List<double>> testFeatures;
  final List<double> testLabels;

  const GenericTrainingDataSplits({
    required this.trainFeatures,
    required this.trainLabels,
    required this.valFeatures,
    required this.valLabels,
    required this.testFeatures,
    required this.testLabels,
  });
}

/// Generic feature normalization + train/validation/test split service.
///
/// Extracted from calling score training data flow so other formula-replacement
/// tracks can reuse the same preparation pipeline.
class TrainingDataPreparationService {
  const TrainingDataPreparationService();

  void validateSplits({
    required double trainSplit,
    required double valSplit,
    required double testSplit,
  }) {
    if ((trainSplit + valSplit + testSplit - 1.0).abs() > 0.001) {
      throw ArgumentError('Splits must sum to 1.0');
    }
  }

  List<List<double>> normalizeFeatures(List<List<double>> features) {
    if (features.isEmpty) return const [];

    final numFeatures = features.first.length;
    final mins = List<double>.filled(numFeatures, double.infinity);
    final maxs = List<double>.filled(numFeatures, double.negativeInfinity);

    for (final featureVector in features) {
      for (var i = 0; i < numFeatures; i++) {
        if (featureVector[i] < mins[i]) mins[i] = featureVector[i];
        if (featureVector[i] > maxs[i]) maxs[i] = featureVector[i];
      }
    }

    final normalized = <List<double>>[];
    for (final featureVector in features) {
      final normalizedVector = <double>[];
      for (var i = 0; i < numFeatures; i++) {
        final range = maxs[i] - mins[i];
        normalizedVector.add(
          range > 0.001 ? (featureVector[i] - mins[i]) / range : 0.5,
        );
      }
      normalized.add(normalizedVector);
    }
    return normalized;
  }

  GenericTrainingDataSplits split({
    required List<List<double>> features,
    required List<double> labels,
    required double trainSplit,
    required double valSplit,
    required double testSplit,
  }) {
    validateSplits(
      trainSplit: trainSplit,
      valSplit: valSplit,
      testSplit: testSplit,
    );

    final trainSize = (features.length * trainSplit).round();
    final valSize = (features.length * valSplit).round();

    return GenericTrainingDataSplits(
      trainFeatures: features.sublist(0, trainSize),
      trainLabels: labels.sublist(0, trainSize),
      valFeatures: features.sublist(trainSize, trainSize + valSize),
      valLabels: labels.sublist(trainSize, trainSize + valSize),
      testFeatures: features.sublist(trainSize + valSize),
      testLabels: labels.sublist(trainSize + valSize),
    );
  }
}

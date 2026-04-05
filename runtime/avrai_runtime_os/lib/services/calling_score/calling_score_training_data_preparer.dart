// Calling Score Training Data Preparer for Phase 12: Neural Network Implementation
// Section 2.1: Calling Score Prediction Model
// Prepares training data for neural network model training

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/ml/calling_score_neural_model.dart';

/// Calling Score Training Data Preparer
///
/// Prepares training data from collected calling score data for neural network training.
///
/// Phase 12 Section 2.1: Calling Score Prediction Model
/// - Extracts features from training data records
/// - Normalizes features for model input
/// - Creates training/validation/test splits
/// - Exports data in format suitable for PyTorch/TensorFlow training
class CallingScoreTrainingDataPreparer {
  static const String _logName = 'CallingScoreTrainingDataPreparer';

  final SupabaseClient _supabase;
  final CallingScoreNeuralModel _neuralModel;

  CallingScoreTrainingDataPreparer({
    required SupabaseClient supabase,
    required AgentIdService
        agentIdService, // Not used currently, but kept for future use
    required CallingScoreNeuralModel neuralModel,
  })  : _supabase = supabase,
        _neuralModel = neuralModel;

  /// Prepare training data for neural network training
  ///
  /// **Parameters:**
  /// - `minRecords`: Minimum number of records required (default: 1000)
  /// - `trainSplit`: Training split ratio (default: 0.8)
  /// - `valSplit`: Validation split ratio (default: 0.1)
  /// - `testSplit`: Test split ratio (default: 0.1)
  ///
  /// **Returns:**
  /// Training data splits (train, validation, test) with features and labels
  Future<TrainingDataSplits> prepareTrainingData({
    int minRecords = 1000,
    double trainSplit = 0.8,
    double valSplit = 0.1,
    double testSplit = 0.1,
  }) async {
    try {
      developer.log('Preparing training data for neural network...',
          name: _logName);

      // Validate splits sum to 1.0
      if ((trainSplit + valSplit + testSplit - 1.0).abs() > 0.001) {
        throw ArgumentError('Splits must sum to 1.0');
      }

      // Get all training data with outcomes
      final records = await _supabase
          .from('calling_score_training_data')
          .select('*')
          .not('outcome_type', 'is', null)
          .order('timestamp', ascending: true);

      final recordsList = List<Map<String, dynamic>>.from(records);

      if (recordsList.length < minRecords) {
        throw StateError(
          'Insufficient data: ${recordsList.length} records, need $minRecords minimum',
        );
      }

      developer.log(
        'Found ${recordsList.length} records with outcomes',
        name: _logName,
      );

      // Extract features and labels
      final features = <List<double>>[];
      final labels = <double>[];

      for (final record in recordsList) {
        try {
          // Prepare features using neural model
          final featureVector = _neuralModel.prepareFeatures(record);
          features.add(featureVector);

          // Extract label (outcome score, or formula score if outcome not available)
          final outcomeScore = record['outcome_score'] as num?;
          final formulaScore =
              (record['formula_calling_score'] as num).toDouble();

          // Use outcome score if available, otherwise use formula score
          final label = outcomeScore?.toDouble() ?? formulaScore;
          labels.add(label.clamp(0.0, 1.0));
        } catch (e) {
          developer.log(
            'Error processing record ${record['id']}: $e',
            name: _logName,
          );
          // Skip this record
          continue;
        }
      }

      if (features.isEmpty) {
        throw StateError('No valid features extracted from records');
      }

      // Normalize features
      final normalizedFeatures = _normalizeFeatures(features);

      // Split data
      final trainSize = (normalizedFeatures.length * trainSplit).round();
      final valSize = (normalizedFeatures.length * valSplit).round();

      final trainFeatures = normalizedFeatures.sublist(0, trainSize);
      final trainLabels = labels.sublist(0, trainSize);

      final valFeatures =
          normalizedFeatures.sublist(trainSize, trainSize + valSize);
      final valLabels = labels.sublist(trainSize, trainSize + valSize);

      final testFeatures = normalizedFeatures.sublist(trainSize + valSize);
      final testLabels = labels.sublist(trainSize + valSize);

      developer.log(
        '✅ Training data prepared: '
        'train=${trainFeatures.length}, '
        'val=${valFeatures.length}, '
        'test=${testFeatures.length}',
        name: _logName,
      );

      return TrainingDataSplits(
        trainFeatures: trainFeatures,
        trainLabels: trainLabels,
        valFeatures: valFeatures,
        valLabels: valLabels,
        testFeatures: testFeatures,
        testLabels: testLabels,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error preparing training data: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Normalize features (min-max scaling to [0, 1])
  ///
  /// **Parameters:**
  /// - `features`: Raw feature vectors
  ///
  /// **Returns:**
  /// Normalized feature vectors
  List<List<double>> _normalizeFeatures(List<List<double>> features) {
    if (features.isEmpty) return [];

    final numFeatures = features.first.length;
    final mins = List<double>.filled(numFeatures, double.infinity);
    final maxs = List<double>.filled(numFeatures, double.negativeInfinity);

    // Find min and max for each feature
    for (final featureVector in features) {
      for (int i = 0; i < numFeatures; i++) {
        if (featureVector[i] < mins[i]) mins[i] = featureVector[i];
        if (featureVector[i] > maxs[i]) maxs[i] = featureVector[i];
      }
    }

    // Normalize features
    final normalized = <List<double>>[];
    for (final featureVector in features) {
      final normalizedVector = <double>[];
      for (int i = 0; i < numFeatures; i++) {
        final range = maxs[i] - mins[i];
        if (range > 0.001) {
          normalizedVector.add((featureVector[i] - mins[i]) / range);
        } else {
          // If range is too small, keep original value (or set to 0.5)
          normalizedVector.add(0.5);
        }
      }
      normalized.add(normalizedVector);
    }

    return normalized;
  }

  /// Export training data to JSON format (for Python training scripts)
  ///
  /// **Parameters:**
  /// - `splits`: Training data splits
  /// - `outputPath`: Path to save JSON file (optional)
  ///
  /// **Returns:**
  /// JSON string representation of training data
  String exportToJson(TrainingDataSplits splits) {
    // Note: In a real implementation, you'd use jsonEncode from dart:convert
    // For now, return a placeholder indicating the structure
    return 'Training data JSON export: '
        'train=${splits.trainFeatures.length}, '
        'val=${splits.valFeatures.length}, '
        'test=${splits.testFeatures.length}, '
        'features=${splits.numFeatures}';
  }
}

/// Training Data Splits
///
/// Contains training, validation, and test splits with features and labels
class TrainingDataSplits {
  final List<List<double>> trainFeatures;
  final List<double> trainLabels;
  final List<List<double>> valFeatures;
  final List<double> valLabels;
  final List<List<double>> testFeatures;
  final List<double> testLabels;

  TrainingDataSplits({
    required this.trainFeatures,
    required this.trainLabels,
    required this.valFeatures,
    required this.valLabels,
    required this.testFeatures,
    required this.testLabels,
  });

  /// Get total number of samples
  int get totalSamples =>
      trainFeatures.length + valFeatures.length + testFeatures.length;

  /// Get number of features
  int get numFeatures =>
      trainFeatures.isNotEmpty ? trainFeatures.first.length : 0;
}

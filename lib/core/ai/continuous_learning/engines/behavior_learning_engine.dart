import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:avrai/core/ai/continuous_learning/base/learning_dimension_engine.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Behavior Learning Engine
///
/// Handles learning dimensions related to user behavior patterns:
/// - `temporal_patterns`
/// - `authenticity_detection`
class BehaviorLearningEngine implements LearningDimensionEngine {
  static const String _logName = 'BehaviorLearningEngine';
  final LearningDataProcessor _processor;

  @override
  final List<String> dimensions = [
    'temporal_patterns',
    'authenticity_detection',
  ];

  @override
  final Map<String, double> learningRates = {
    'temporal_patterns': 0.10,
    'authenticity_detection': 0.20,
  };

  BehaviorLearningEngine({
    required LearningDataProcessor processor,
  }) : _processor = processor;

  @override
  Future<Map<String, double>> learn(
    LearningData data,
    Map<String, double> currentState,
  ) async {
    final results = <String, double>{};

    for (final dimension in dimensions) {
      try {
        final current = currentState[dimension] ?? 0.5;
        final learningRate = getLearningRate(dimension);
        final improvement = await calculateImprovement(dimension, data);

        // Apply learning with bounds
        final newState = math.max(
          0.0,
          math.min(1.0, current + (improvement * learningRate)),
        );

        results[dimension] = newState;
      } catch (e) {
        developer.log(
          'Error learning dimension $dimension: $e',
          name: _logName,
        );
        // Keep current state on error
        results[dimension] = currentState[dimension] ?? 0.5;
      }
    }

    return results;
  }

  @override
  Future<double> calculateImprovement(
    String dimension,
    LearningData data,
  ) async {
    switch (dimension) {
      case 'temporal_patterns':
        return await _calculateTemporalPatternsImprovement(data);
      case 'authenticity_detection':
        return await _calculateAuthenticityDetectionImprovement(data);
      default:
        return 0.01; // Default small improvement
    }
  }

  @override
  double getLearningRate(String dimension) {
    return learningRates[dimension] ?? 0.1;
  }

  @override
  bool handlesDimension(String dimension) {
    return dimensions.contains(dimension);
  }

  /// Calculates improvement in temporal pattern recognition
  Future<double> _calculateTemporalPatternsImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from time data
    if (data.timeData.isNotEmpty) {
      final temporalPatterns = _processor.analyzeTemporalPatterns(data.timeData);
      final seasonalPatterns = _processor.analyzeSeasonalPatterns(data.timeData);
      improvement += (temporalPatterns + seasonalPatterns) * 0.5;
    }

    // Learn from user action timing
    if (data.userActions.isNotEmpty) {
      final actionTimingPatterns =
          _processor.analyzeActionTimingPatterns(data.userActions);
      improvement += actionTimingPatterns * 0.3;
    }

    // Learn from weather-time correlations
    if (data.weatherData.isNotEmpty && data.timeData.isNotEmpty) {
      final weatherTimeCorrelation =
          _processor.analyzeWeatherTimeCorrelation(data.weatherData, data.timeData);
      improvement += weatherTimeCorrelation * 0.2;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }

  /// Calculates improvement in authenticity detection
  Future<double> _calculateAuthenticityDetectionImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from user behavior authenticity
    if (data.userActions.isNotEmpty) {
      final behaviorAuthenticity =
          _processor.analyzeBehaviorAuthenticity(data.userActions);
      improvement += behaviorAuthenticity * 0.4;
    }

    // Learn from community authenticity patterns
    if (data.communityData.isNotEmpty) {
      final communityAuthenticity =
          _processor.analyzeCommunityAuthenticity(data.communityData);
      improvement += communityAuthenticity * 0.3;
    }

    // Learn from AI2AI authenticity insights
    if (data.ai2aiData.isNotEmpty) {
      final aiAuthenticity =
          _processor.analyzeAIAuthenticityInsights(data.ai2aiData);
      improvement += aiAuthenticity * 0.3;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }
}

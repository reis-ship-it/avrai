import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:avrai/core/ai/continuous_learning/base/learning_dimension_engine.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Preference Learning Engine
///
/// Handles learning dimensions related to user preferences and recommendations:
/// - `recommendation_accuracy`
/// - `trend_prediction`
class PreferenceLearningEngine implements LearningDimensionEngine {
  static const String _logName = 'PreferenceLearningEngine';
  final LearningDataProcessor _processor;

  @override
  final List<String> dimensions = [
    'recommendation_accuracy',
    'trend_prediction',
  ];

  @override
  final Map<String, double> learningRates = {
    'recommendation_accuracy': 0.18,
    'trend_prediction': 0.14,
  };

  PreferenceLearningEngine({
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
      case 'recommendation_accuracy':
        return await _calculateRecommendationAccuracyImprovement(data);
      case 'trend_prediction':
        return await _calculateTrendPredictionImprovement(data);
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

  /// Calculates improvement in recommendation accuracy
  Future<double> _calculateRecommendationAccuracyImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from recommendation feedback
    if (data.userActions.isNotEmpty) {
      final recommendationFeedback =
          _processor.analyzeRecommendationFeedback(data.userActions);
      improvement += recommendationFeedback * 0.4;
    }

    // Learn from community recommendations
    if (data.communityData.isNotEmpty) {
      final communityRecommendations =
          _processor.analyzeCommunityRecommendations(data.communityData);
      improvement += communityRecommendations * 0.3;
    }

    // Learn from AI recommendation insights
    if (data.ai2aiData.isNotEmpty) {
      final aiRecommendations =
          _processor.analyzeAIRecommendationInsights(data.ai2aiData);
      improvement += aiRecommendations * 0.3;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }

  /// Calculates improvement in trend prediction
  Future<double> _calculateTrendPredictionImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from trend patterns in user actions
    if (data.userActions.isNotEmpty) {
      final trendPatterns = _processor.analyzeTrendPatterns(data.userActions);
      improvement += trendPatterns * 0.3;
    }

    // Learn from community trends
    if (data.communityData.isNotEmpty) {
      final communityTrends =
          _processor.analyzeCommunityTrends(data.communityData);
      improvement += communityTrends * 0.3;
    }

    // Learn from external trends
    if (data.externalData.isNotEmpty) {
      final externalTrends = _processor.analyzeExternalTrends(data.externalData);
      improvement += externalTrends * 0.2;
    }

    // Learn from AI trend insights
    if (data.ai2aiData.isNotEmpty) {
      final aiTrends = _processor.analyzeAITrendInsights(data.ai2aiData);
      improvement += aiTrends * 0.2;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }
}

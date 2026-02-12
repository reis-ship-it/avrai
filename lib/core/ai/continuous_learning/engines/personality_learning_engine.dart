import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:avrai/core/ai/continuous_learning/base/learning_dimension_engine.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Personality Learning Engine
///
/// Handles learning dimensions related to user personality and preferences:
/// - `user_preference_understanding`
/// - `personalization_depth`
class PersonalityLearningEngine implements LearningDimensionEngine {
  static const String _logName = 'PersonalityLearningEngine';
  final LearningDataProcessor _processor;

  @override
  final List<String> dimensions = [
    'user_preference_understanding',
    'personalization_depth',
  ];

  @override
  final Map<String, double> learningRates = {
    'user_preference_understanding': 0.15,
    'personalization_depth': 0.16,
  };

  PersonalityLearningEngine({
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
      case 'user_preference_understanding':
        return await _calculatePreferenceUnderstandingImprovement(data);
      case 'personalization_depth':
        return await _calculatePersonalizationDepthImprovement(data);
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

  /// Calculates improvement in understanding user preferences
  Future<double> _calculatePreferenceUnderstandingImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from user actions
    if (data.userActions.isNotEmpty) {
      final actionDiversity = _processor.calculateActionDiversity(data.userActions);
      final preferenceConsistency =
          _processor.calculatePreferenceConsistency(data.userActions);
      improvement += (actionDiversity + preferenceConsistency) * 0.3;
    }

    // Learn from app usage patterns
    if (data.appUsageData.isNotEmpty) {
      final usagePatterns = _processor.analyzeUsagePatterns(data.appUsageData);
      improvement += usagePatterns * 0.2;
    }

    // Learn from social interactions
    if (data.socialData.isNotEmpty) {
      final socialPreferences = _processor.analyzeSocialPreferences(data.socialData);
      improvement += socialPreferences * 0.2;
    }

    // Learn from demographic data
    if (data.demographicData.isNotEmpty) {
      final demographicInsights =
          _processor.analyzeDemographicInsights(data.demographicData);
      improvement += demographicInsights * 0.1;
    }

    // Learn from AI2AI communications
    if (data.ai2aiData.isNotEmpty) {
      final aiInsights = _processor.analyzeAIInsights(data.ai2aiData);
      improvement += aiInsights * 0.2;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }

  /// Calculates improvement in personalization depth
  Future<double> _calculatePersonalizationDepthImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from preference depth
    if (data.userActions.isNotEmpty) {
      final preferenceDepth = _processor.analyzePreferenceDepth(data.userActions);
      improvement += preferenceDepth * 0.3;
    }

    // Learn from demographic personalization
    if (data.demographicData.isNotEmpty) {
      final demographicPersonalization =
          _processor.analyzeDemographicPersonalization(data.demographicData);
      improvement += demographicPersonalization * 0.2;
    }

    // Learn from temporal personalization
    if (data.timeData.isNotEmpty) {
      final temporalPersonalization =
          _processor.analyzeTemporalPersonalization(data.timeData);
      improvement += temporalPersonalization * 0.2;
    }

    // Learn from location personalization
    if (data.locationData.isNotEmpty) {
      final locationPersonalization =
          _processor.analyzeLocationPersonalization(data.locationData);
      improvement += locationPersonalization * 0.15;
    }

    // Learn from social personalization
    if (data.socialData.isNotEmpty) {
      final socialPersonalization =
          _processor.analyzeSocialPersonalization(data.socialData);
      improvement += socialPersonalization * 0.15;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }
}

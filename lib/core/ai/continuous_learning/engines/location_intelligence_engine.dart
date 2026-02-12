import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:avrai/core/ai/continuous_learning/base/learning_dimension_engine.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Location Intelligence Engine
///
/// Handles learning dimensions related to location-based intelligence:
/// - `location_intelligence`
class LocationIntelligenceEngine implements LearningDimensionEngine {
  static const String _logName = 'LocationIntelligenceEngine';
  final LearningDataProcessor _processor;

  @override
  final List<String> dimensions = [
    'location_intelligence',
  ];

  @override
  final Map<String, double> learningRates = {
    'location_intelligence': 0.12,
  };

  LocationIntelligenceEngine({
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
      case 'location_intelligence':
        return await _calculateLocationIntelligenceImprovement(data);
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

  /// Calculates improvement in location intelligence
  Future<double> _calculateLocationIntelligenceImprovement(
    LearningData data,
  ) async {
    var improvement = 0.0;

    // Learn from location data
    if (data.locationData.isNotEmpty) {
      final locationPatterns = _processor.analyzeLocationPatterns(data.locationData);
      final locationDiversity = _processor.calculateLocationDiversity(data.locationData);
      improvement += (locationPatterns + locationDiversity) * 0.4;
    }

    // Learn from weather correlation
    if (data.weatherData.isNotEmpty && data.locationData.isNotEmpty) {
      final weatherLocationCorrelation = _processor.analyzeWeatherLocationCorrelation(
          data.weatherData, data.locationData);
      improvement += weatherLocationCorrelation * 0.3;
    }

    // Learn from time-based location patterns
    if (data.timeData.isNotEmpty && data.locationData.isNotEmpty) {
      final temporalLocationPatterns =
          _processor.analyzeTemporalLocationPatterns(data.timeData, data.locationData);
      improvement += temporalLocationPatterns * 0.3;
    }

    return math.min(0.1, improvement); // Cap improvement at 10%
  }
}

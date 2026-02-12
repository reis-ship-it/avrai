import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Base interface for learning dimension engines
///
/// Each dimension engine is responsible for learning from a specific
/// set of learning dimensions (e.g., personality, behavior, preferences).
abstract class LearningDimensionEngine {
  /// List of dimensions this engine handles
  List<String> get dimensions;

  /// Learning rates for each dimension
  Map<String, double> get learningRates;

  /// Learn from collected data for all dimensions handled by this engine
  ///
  /// **Parameters:**
  /// - `data`: Collected learning data from all sources
  /// - `currentState`: Current learning state for all dimensions
  ///
  /// **Returns:**
  /// Map of dimension -> new learning state value
  Future<Map<String, double>> learn(
    LearningData data,
    Map<String, double> currentState,
  );

  /// Calculate improvement for a specific dimension
  ///
  /// **Parameters:**
  /// - `dimension`: Dimension name
  /// - `data`: Collected learning data
  ///
  /// **Returns:**
  /// Improvement value (0.0 to 1.0)
  Future<double> calculateImprovement(
    String dimension,
    LearningData data,
  );

  /// Get learning rate for a dimension
  double getLearningRate(String dimension) {
    return learningRates[dimension] ?? 0.1;
  }

  /// Check if this engine handles a specific dimension
  bool handlesDimension(String dimension) {
    return dimensions.contains(dimension);
  }
}

import 'package:avrai/core/ai/quantum/quantum_vibe_state.dart';

/// Quantum vibe dimension state
/// Wraps a quantum state with dimension name and confidence
class QuantumVibeDimension {
  final String dimension;
  final QuantumVibeState state;
  final double confidence; // Measurement confidence (0.0-1.0)

  QuantumVibeDimension({
    required this.dimension,
    required this.state,
    this.confidence = 0.5,
  }) : assert(confidence >= 0.0 && confidence <= 1.0,
         'Confidence must be between 0.0 and 1.0');

  /// Measure (collapse) to classical value
  /// This performs a quantum measurement, collapsing the state to a classical probability
  double measure() => state.collapse();

  /// Get probability without collapsing
  /// Returns the probability of the quantum state without performing a measurement
  double get probability => state.probability;

  /// Get phase of the quantum state
  double get phase => state.phase;

  /// Get magnitude of the amplitude
  double get magnitude => state.magnitude;

  /// Create a copy with updated state
  QuantumVibeDimension copyWith({
    String? dimension,
    QuantumVibeState? state,
    double? confidence,
  }) {
    return QuantumVibeDimension(
      dimension: dimension ?? this.dimension,
      state: state ?? this.state,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() => 'QuantumVibeDimension(dimension: $dimension, probability: ${probability.toStringAsFixed(3)}, confidence: ${confidence.toStringAsFixed(3)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantumVibeDimension &&
          runtimeType == other.runtimeType &&
          dimension == other.dimension &&
          state == other.state &&
          (confidence - other.confidence).abs() < 1e-10;

  @override
  int get hashCode => dimension.hashCode ^ state.hashCode ^ confidence.hashCode;
}


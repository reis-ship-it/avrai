import 'dart:math';

/// Quantum state representation for vibe dimensions
/// Uses complex probability amplitudes instead of classical probabilities
/// 
/// This enables:
/// - Quantum Superposition: Dimensions exist in multiple states simultaneously
/// - Quantum Interference: Constructive/destructive interference patterns
/// - Quantum Entanglement: Correlated dimensions that influence each other
class QuantumVibeState {
  final double real; // Real component of amplitude
  final double imaginary; // Imaginary component of amplitude

  QuantumVibeState(this.real, this.imaginary);

  /// Probability of this state (|amplitude|²)
  /// This is the probability of measuring this state
  double get probability => real * real + imaginary * imaginary;

  /// Phase of the quantum state
  /// Represents the phase angle in the complex plane
  double get phase => atan2(imaginary, real);

  /// Magnitude of the amplitude
  double get magnitude => sqrt(real * real + imaginary * imaginary);

  /// Create from classical probability (collapsed state)
  /// Converts a classical probability (0.0-1.0) to a quantum state
  factory QuantumVibeState.fromClassical(double probability) {
    final clamped = probability.clamp(0.0, 1.0);
    final magnitude = sqrt(clamped);
    return QuantumVibeState(magnitude, 0.0);
  }

  /// Collapse to classical probability (measurement)
  /// When we measure a quantum state, it collapses to a classical value
  double collapse() => probability.clamp(0.0, 1.0);

  /// Quantum superposition: combine two states
  /// Creates a new state that is a weighted combination of two states
  /// [other] - The other quantum state to superpose with
  /// [weight] - Weight of this state (0.0-1.0), weight of other is (1.0 - weight)
  QuantumVibeState superpose(QuantumVibeState other, double weight) {
    final clampedWeight = weight.clamp(0.0, 1.0);
    final w1 = sqrt(clampedWeight);
    final w2 = sqrt(1.0 - clampedWeight);
    final newReal = w1 * real + w2 * other.real;
    final newImaginary = w1 * imaginary + w2 * other.imaginary;
    final magnitude = sqrt(newReal * newReal + newImaginary * newImaginary);
    
    // Normalize to maintain probability interpretation
    if (magnitude > 0.0) {
      return QuantumVibeState(newReal / magnitude, newImaginary / magnitude);
    }
    return QuantumVibeState(0.0, 0.0);
  }

  /// Quantum interference: add amplitudes (constructive/destructive)
  /// [other] - The other quantum state to interfere with
  /// [constructive] - If true, amplitudes add (constructive interference)
  ///                  If false, amplitudes subtract (destructive interference)
  QuantumVibeState interfere(QuantumVibeState other, {bool constructive = true}) {
    if (constructive) {
      // Constructive interference: amplitudes add
      return QuantumVibeState(real + other.real, imaginary + other.imaginary);
    } else {
      // Destructive interference: amplitudes subtract
      return QuantumVibeState(real - other.real, imaginary - other.imaginary);
    }
  }

  /// Quantum entanglement: correlate with another state
  /// Creates a correlated state where the phase is adjusted based on correlation
  /// [other] - The other quantum state to entangle with
  /// [correlation] - Correlation strength (0.0-1.0)
  QuantumVibeState entangle(QuantumVibeState other, double correlation) {
    final clampedCorrelation = correlation.clamp(0.0, 1.0);
    final phaseDiff = (phase - other.phase) * clampedCorrelation;
    final newPhase = phase + phaseDiff;
    return QuantumVibeState(
      magnitude * cos(newPhase),
      magnitude * sin(newPhase),
    );
  }

  @override
  String toString() => 'QuantumVibeState(real: ${real.toStringAsFixed(3)}, imaginary: ${imaginary.toStringAsFixed(3)}, probability: ${probability.toStringAsFixed(3)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantumVibeState &&
          runtimeType == other.runtimeType &&
          (real - other.real).abs() < 1e-10 &&
          (imaginary - other.imaginary).abs() < 1e-10;

  @override
  int get hashCode => real.hashCode ^ imaginary.hashCode;
}


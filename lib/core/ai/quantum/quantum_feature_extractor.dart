import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai/core/models/quantum/quantum_prediction_features.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_state.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/services/quantum/decoherence_tracking_service.dart';

/// Quantum Feature Extractor
///
/// Extracts quantum properties as features for prediction models.
///
/// **Purpose:**
/// - Extract quantum features from quantum states, decoherence patterns, etc.
/// - Calculate interference strength, entanglement strength, phase alignment
/// - Extract quantum vibe match (12 dimensions)
/// - Calculate temporal quantum match
/// - Calculate preference drift and coherence level
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 3.1
class QuantumFeatureExtractor {
  static const String _logName = 'QuantumFeatureExtractor';

  final DecoherenceTrackingService? _decoherenceTracking;

  QuantumFeatureExtractor({
    DecoherenceTrackingService? decoherenceTracking,
  }) : _decoherenceTracking = decoherenceTracking;

  /// Extract quantum prediction features
  ///
  /// **Parameters:**
  /// - `userId`: User ID for decoherence pattern lookup
  /// - `userVibeDimensions`: User's vibe dimensions (12 dimensions)
  /// - `eventVibeDimensions`: Event's vibe dimensions (12 dimensions)
  /// - `userTemporalState`: User's quantum temporal state
  /// - `eventTemporalState`: Event's quantum temporal state
  /// - `previousVibeDimensions`: Previous vibe dimensions (for preference drift)
  /// - `temporalCompatibility`: Existing temporal compatibility (0.0-1.0)
  /// - `weekdayMatch`: Existing weekday match (0.0-1.0)
  Future<QuantumPredictionFeatures> extractFeatures({
    required String userId,
    required Map<String, double> userVibeDimensions,
    required Map<String, double> eventVibeDimensions,
    required QuantumTemporalState userTemporalState,
    required QuantumTemporalState eventTemporalState,
    Map<String, double>? previousVibeDimensions,
    required double temporalCompatibility,
    required double weekdayMatch,
  }) async {
    try {
      // Get decoherence pattern (from Phase 2)
      final decoherencePattern = await _decoherenceTracking?.getPattern(userId);
      final decoherenceRate = decoherencePattern?.decoherenceRate ?? 0.0;
      final decoherenceStability = decoherencePattern?.decoherenceStability ?? 1.0;

      // Calculate interference strength: Re(⟨ψ_user|ψ_event⟩)
      final interferenceStrength = _calculateInterferenceStrength(
        userVibeDimensions,
        eventVibeDimensions,
      );

      // Calculate entanglement strength: -Tr(ρ_A log ρ_A) (Von Neumann entropy approximation)
      final entanglementStrength = _calculateEntanglementStrength(
        userVibeDimensions,
        eventVibeDimensions,
      );

      // Calculate phase alignment: cos(phase_user - phase_event)
      final phaseAlignment = _calculatePhaseAlignment(
        userTemporalState,
        eventTemporalState,
      );

      // Extract quantum vibe match (12 dimensions)
      final quantumVibeMatch = _extractQuantumVibeMatch(
        userVibeDimensions,
        eventVibeDimensions,
      );

      // Calculate temporal quantum match
      final temporalQuantumMatch = userTemporalState.temporalCompatibility(
        eventTemporalState,
      );

      // Calculate preference drift: |⟨ψ_current|ψ_previous⟩|²
      final preferenceDrift = _calculatePreferenceDrift(
        userVibeDimensions,
        previousVibeDimensions,
      );

      // Calculate coherence level: |⟨ψ_user|ψ_user⟩|² (normalization check)
      final coherenceLevel = _calculateCoherenceLevel(userVibeDimensions);

      return QuantumPredictionFeatures(
        temporalCompatibility: temporalCompatibility,
        weekdayMatch: weekdayMatch,
        decoherenceRate: decoherenceRate,
        decoherenceStability: decoherenceStability,
        interferenceStrength: interferenceStrength,
        entanglementStrength: entanglementStrength,
        phaseAlignment: phaseAlignment,
        quantumVibeMatch: quantumVibeMatch,
        temporalQuantumMatch: temporalQuantumMatch,
        preferenceDrift: preferenceDrift,
        coherenceLevel: coherenceLevel,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error extracting quantum features: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return minimal features on error
      return QuantumPredictionFeatures.minimal(
        temporalCompatibility: temporalCompatibility,
        weekdayMatch: weekdayMatch,
      );
    }
  }

  /// Calculate interference strength: Re(⟨ψ_user|ψ_event⟩)
  ///
  /// Formula: `interferenceStrength = Re(⟨ψ_user|ψ_event⟩)`
  /// This represents the real part of the quantum inner product.
  double _calculateInterferenceStrength(
    Map<String, double> userVibeDimensions,
    Map<String, double> eventVibeDimensions,
  ) {
    // Convert vibe dimensions to quantum states and calculate inner product
    double realSum = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final userValue = userVibeDimensions[dimension] ?? 0.5;
      final eventValue = eventVibeDimensions[dimension] ?? 0.5;

      // Convert to quantum states
      final userState = QuantumVibeState.fromClassical(userValue);
      final eventState = QuantumVibeState.fromClassical(eventValue);

      // Calculate inner product: ⟨ψ_user|ψ_event⟩ = real_user * real_event + imag_user * imag_event
      final innerProduct = userState.real * eventState.real +
          userState.imaginary * eventState.imaginary;

      realSum += innerProduct;
      count++;
    }

    return count > 0 ? (realSum / count).clamp(-1.0, 1.0) : 0.0;
  }

  /// Calculate entanglement strength: -Tr(ρ_A log ρ_A) (Von Neumann entropy approximation)
  ///
  /// Formula: `entanglementStrength = -Σ p_i log(p_i)` where p_i are probabilities
  /// This is an approximation of Von Neumann entropy.
  double _calculateEntanglementStrength(
    Map<String, double> userVibeDimensions,
    Map<String, double> eventVibeDimensions,
  ) {
    // Calculate entropy from probability distribution
    double entropy = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final userValue = userVibeDimensions[dimension] ?? 0.5;
      final eventValue = eventVibeDimensions[dimension] ?? 0.5;

      // Average probability
      final avgProb = (userValue + eventValue) / 2.0;

      // Avoid log(0)
      if (avgProb > 0.0 && avgProb < 1.0) {
        entropy -= avgProb * math.log(avgProb);
      }
      count++;
    }

    // Normalize to [0, 1] range
    final maxEntropy = count * math.log(2.0); // Maximum entropy for uniform distribution
    return maxEntropy > 0.0
        ? (entropy / maxEntropy).clamp(0.0, 1.0)
        : 0.0;
  }

  /// Calculate phase alignment: cos(phase_user - phase_event)
  ///
  /// Formula: `phaseAlignment = cos(phase_user - phase_event)`
  double _calculatePhaseAlignment(
    QuantumTemporalState userTemporalState,
    QuantumTemporalState eventTemporalState,
  ) {
    // Calculate phase from temporal states
    // Use the phase state components to estimate phase
    double userPhase = 0.0;
    double eventPhase = 0.0;

    if (userTemporalState.phaseState.isNotEmpty) {
      // Estimate phase from phase state (average of components)
      userPhase = userTemporalState.phaseState.reduce((a, b) => a + b) /
          userTemporalState.phaseState.length;
    }

    if (eventTemporalState.phaseState.isNotEmpty) {
      eventPhase = eventTemporalState.phaseState.reduce((a, b) => a + b) /
          eventTemporalState.phaseState.length;
    }

    // Calculate phase difference and alignment
    final phaseDiff = userPhase - eventPhase;
    return math.cos(phaseDiff).clamp(-1.0, 1.0);
  }

  /// Extract quantum vibe match (12 dimensions)
  ///
  /// Returns a list of 12 compatibility values, one for each vibe dimension.
  List<double> _extractQuantumVibeMatch(
    Map<String, double> userVibeDimensions,
    Map<String, double> eventVibeDimensions,
  ) {
    final match = <double>[];

    for (final dimension in VibeConstants.coreDimensions) {
      final userValue = userVibeDimensions[dimension] ?? 0.5;
      final eventValue = eventVibeDimensions[dimension] ?? 0.5;

      // Calculate compatibility: 1.0 - |user - event|
      final compatibility = (1.0 - (userValue - eventValue).abs()).clamp(0.0, 1.0);
      match.add(compatibility);
    }

    // Ensure we have exactly 12 dimensions
    while (match.length < 12) {
      match.add(0.5); // Default value
    }

    return match.take(12).toList();
  }

  /// Calculate preference drift: |⟨ψ_current|ψ_previous⟩|²
  ///
  /// Formula: `preferenceDrift = |⟨ψ_current|ψ_previous⟩|²`
  /// Measures how much preferences have changed.
  double _calculatePreferenceDrift(
    Map<String, double> currentVibeDimensions,
    Map<String, double>? previousVibeDimensions,
  ) {
    if (previousVibeDimensions == null || previousVibeDimensions.isEmpty) {
      return 0.0; // No previous data
    }

    // Calculate inner product between current and previous states
    double innerProduct = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final currentValue = currentVibeDimensions[dimension] ?? 0.5;
      final previousValue = previousVibeDimensions[dimension] ?? 0.5;

      // Convert to quantum states
      final currentState = QuantumVibeState.fromClassical(currentValue);
      final previousState = QuantumVibeState.fromClassical(previousValue);

      // Inner product: ⟨ψ_current|ψ_previous⟩
      final innerProd = currentState.real * previousState.real +
          currentState.imaginary * previousState.imaginary;

      innerProduct += innerProd;
      count++;
    }

    if (count == 0) return 0.0;

    // Squared magnitude: |⟨ψ_current|ψ_previous⟩|²
    final avgInnerProduct = innerProduct / count;
    return (avgInnerProduct * avgInnerProduct).clamp(0.0, 1.0);
  }

  /// Calculate coherence level: |⟨ψ_user|ψ_user⟩|² (normalization check)
  ///
  /// Formula: `coherenceLevel = |⟨ψ_user|ψ_user⟩|²`
  /// Measures how well-normalized the quantum state is.
  double _calculateCoherenceLevel(Map<String, double> vibeDimensions) {
    // Calculate normalization of quantum state
    double normSquared = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final value = vibeDimensions[dimension] ?? 0.5;
      final state = QuantumVibeState.fromClassical(value);

      // |⟨ψ|ψ⟩|² = |amplitude|² = probability
      normSquared += state.probability;
      count++;
    }

    return count > 0 ? (normSquared / count).clamp(0.0, 1.0) : 1.0;
  }
}


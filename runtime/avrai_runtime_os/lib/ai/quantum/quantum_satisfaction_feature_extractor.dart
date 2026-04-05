import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum/quantum_satisfaction_features.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_vibe_state.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai_runtime_os/ai/quantum/location_quantum_state.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_runtime_os/services/quantum/decoherence_tracking_service.dart';
import 'package:avrai_core/models/quantum/decoherence_pattern.dart';

/// Quantum Satisfaction Feature Extractor
///
/// Extracts quantum properties as features for satisfaction models.
///
/// **Purpose:**
/// - Extract quantum features for satisfaction prediction
/// - Calculate quantum vibe match, entanglement, interference
/// - Calculate location and timing quantum matches
/// - Calculate decoherence optimization factor
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 4.1
class QuantumSatisfactionFeatureExtractor {
  static const String _logName = 'QuantumSatisfactionFeatureExtractor';

  final DecoherenceTrackingService? _decoherenceTracking;

  QuantumSatisfactionFeatureExtractor({
    DecoherenceTrackingService? decoherenceTracking,
  }) : _decoherenceTracking = decoherenceTracking;

  /// Extract quantum satisfaction features
  ///
  /// **Parameters:**
  /// - `userId`: User ID for decoherence pattern lookup
  /// - `userVibeDimensions`: User's vibe dimensions (12 dimensions)
  /// - `eventVibeDimensions`: Event's vibe dimensions (12 dimensions)
  /// - `userTemporalState`: User's quantum temporal state
  /// - `eventTemporalState`: Event's quantum temporal state
  /// - `userLocationState`: User's location quantum state (optional)
  /// - `eventLocationState`: Event's location quantum state (optional)
  /// - `contextMatch`: Existing context match (0.0-1.0)
  /// - `preferenceAlignment`: Existing preference alignment (0.0-1.0)
  /// - `noveltyScore`: Existing novelty score (0.0-1.0)
  Future<QuantumSatisfactionFeatures> extractFeatures({
    required String userId,
    required Map<String, double> userVibeDimensions,
    required Map<String, double> eventVibeDimensions,
    required QuantumTemporalState userTemporalState,
    required QuantumTemporalState eventTemporalState,
    LocationQuantumState? userLocationState,
    LocationQuantumState? eventLocationState,
    required double contextMatch,
    required double preferenceAlignment,
    required double noveltyScore,
  }) async {
    try {
      // Calculate quantum vibe match (average of 12 dimensions)
      final quantumVibeMatch = _calculateQuantumVibeMatch(
        userVibeDimensions,
        eventVibeDimensions,
      );

      // Calculate entanglement compatibility: |⟨ψ_user_entangled|ψ_event_entangled⟩|²
      final entanglementCompatibility = _calculateEntanglementCompatibility(
        userVibeDimensions,
        eventVibeDimensions,
      );

      // Calculate interference effect: Re(⟨ψ_user|ψ_event⟩)
      final interferenceEffect = _calculateInterferenceEffect(
        userVibeDimensions,
        eventVibeDimensions,
      );

      // Calculate decoherence optimization factor
      final decoherenceOptimization = await _calculateDecoherenceOptimization(
        userId,
      );

      // Calculate phase alignment: cos(phase_user - phase_event)
      final phaseAlignment = _calculatePhaseAlignment(
        userTemporalState,
        eventTemporalState,
      );

      // Calculate location quantum match
      final locationQuantumMatch = _calculateLocationQuantumMatch(
        userLocationState,
        eventLocationState,
      );

      // Calculate timing quantum match
      final timingQuantumMatch = userTemporalState.temporalCompatibility(
        eventTemporalState,
      );

      return QuantumSatisfactionFeatures(
        contextMatch: contextMatch,
        preferenceAlignment: preferenceAlignment,
        noveltyScore: noveltyScore,
        quantumVibeMatch: quantumVibeMatch,
        entanglementCompatibility: entanglementCompatibility,
        interferenceEffect: interferenceEffect,
        decoherenceOptimization: decoherenceOptimization,
        phaseAlignment: phaseAlignment,
        locationQuantumMatch: locationQuantumMatch,
        timingQuantumMatch: timingQuantumMatch,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error extracting quantum satisfaction features: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return minimal features on error
      return QuantumSatisfactionFeatures.minimal(
        contextMatch: contextMatch,
        preferenceAlignment: preferenceAlignment,
        noveltyScore: noveltyScore,
      );
    }
  }

  /// Calculate quantum vibe match (average of 12 dimensions)
  ///
  /// Returns average compatibility across all 12 vibe dimensions.
  double _calculateQuantumVibeMatch(
    Map<String, double> userVibeDimensions,
    Map<String, double> eventVibeDimensions,
  ) {
    double totalMatch = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final userValue = userVibeDimensions[dimension] ?? 0.5;
      final eventValue = eventVibeDimensions[dimension] ?? 0.5;

      // Calculate compatibility: 1.0 - |user - event|
      final compatibility =
          (1.0 - (userValue - eventValue).abs()).clamp(0.0, 1.0);
      totalMatch += compatibility;
      count++;
    }

    return count > 0 ? totalMatch / count : 0.5;
  }

  /// Calculate entanglement compatibility: |⟨ψ_user_entangled|ψ_event_entangled⟩|²
  ///
  /// Formula: `entanglementCompatibility = |⟨ψ_user_entangled|ψ_event_entangled⟩|²`
  double _calculateEntanglementCompatibility(
    Map<String, double> userVibeDimensions,
    Map<String, double> eventVibeDimensions,
  ) {
    // Calculate inner product of entangled states
    double innerProduct = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final userValue = userVibeDimensions[dimension] ?? 0.5;
      final eventValue = eventVibeDimensions[dimension] ?? 0.5;

      // Convert to quantum states
      final userState = QuantumVibeState.fromClassical(userValue);
      final eventState = QuantumVibeState.fromClassical(eventValue);

      // Inner product: ⟨ψ_user|ψ_event⟩
      final innerProd = userState.real * eventState.real +
          userState.imaginary * eventState.imaginary;

      innerProduct += innerProd;
      count++;
    }

    if (count == 0) return 0.0;

    // Squared magnitude: |⟨ψ_user|ψ_event⟩|²
    final avgInnerProduct = innerProduct / count;
    return (avgInnerProduct * avgInnerProduct).clamp(0.0, 1.0);
  }

  /// Calculate interference effect: Re(⟨ψ_user|ψ_event⟩)
  ///
  /// Formula: `interferenceEffect = Re(⟨ψ_user|ψ_event⟩)`
  /// Positive = constructive (good match), Negative = destructive (bad match)
  double _calculateInterferenceEffect(
    Map<String, double> userVibeDimensions,
    Map<String, double> eventVibeDimensions,
  ) {
    double realSum = 0.0;
    int count = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final userValue = userVibeDimensions[dimension] ?? 0.5;
      final eventValue = eventVibeDimensions[dimension] ?? 0.5;

      // Convert to quantum states
      final userState = QuantumVibeState.fromClassical(userValue);
      final eventState = QuantumVibeState.fromClassical(eventValue);

      // Real part of inner product: Re(⟨ψ_user|ψ_event⟩)
      final realPart = userState.real * eventState.real +
          userState.imaginary * eventState.imaginary;

      realSum += realPart;
      count++;
    }

    return count > 0 ? (realSum / count).clamp(-1.0, 1.0) : 0.0;
  }

  /// Calculate decoherence optimization factor
  ///
  /// Uses decoherence patterns to optimize satisfaction:
  /// - Exploration phase: boost for diverse recommendations
  /// - Settled phase: boost for similar recommendations
  Future<double> _calculateDecoherenceOptimization(String userId) async {
    try {
      final decoherencePattern = await _decoherenceTracking?.getPattern(userId);

      if (decoherencePattern == null) {
        return 0.0; // No optimization if no pattern
      }

      // Use behavior phase to determine optimization
      switch (decoherencePattern.behaviorPhase) {
        case BehaviorPhase.exploration:
          // User exploring - boost satisfaction for diverse recommendations
          return 0.1;
        case BehaviorPhase.settled:
          // User settled - boost satisfaction for similar recommendations
          return 0.05;
        case BehaviorPhase.settling:
          // User settling - moderate boost
          return 0.025;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating decoherence optimization: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }

  /// Calculate phase alignment: cos(phase_user - phase_event)
  ///
  /// Formula: `phaseAlignment = cos(phase_user - phase_event)`
  double _calculatePhaseAlignment(
    QuantumTemporalState userTemporalState,
    QuantumTemporalState eventTemporalState,
  ) {
    // Calculate phase from temporal states
    double userPhase = 0.0;
    double eventPhase = 0.0;

    if (userTemporalState.phaseState.isNotEmpty) {
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

  /// Calculate location quantum match
  ///
  /// Returns location compatibility if both states provided, otherwise 0.0.
  double _calculateLocationQuantumMatch(
    LocationQuantumState? userLocationState,
    LocationQuantumState? eventLocationState,
  ) {
    if (userLocationState == null || eventLocationState == null) {
      return 0.0;
    }

    return userLocationState.locationCompatibility(eventLocationState);
  }
}

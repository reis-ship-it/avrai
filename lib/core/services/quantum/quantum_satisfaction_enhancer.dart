import 'dart:developer' as developer;
import 'package:avrai/core/models/quantum/quantum_satisfaction_features.dart';
import 'package:avrai/core/ai/quantum/quantum_satisfaction_feature_extractor.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';
import 'package:avrai/core/ai/quantum/location_quantum_state.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';

/// Quantum Satisfaction Enhancer
///
/// Enhances satisfaction predictions with quantum features to improve
/// user satisfaction from 75% to 80-85%.
///
/// **Purpose:**
/// - Extract quantum features for satisfaction
/// - Enhance satisfaction predictions using quantum values
/// - Improve user satisfaction with quantum-enhanced matching
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 4.1
class QuantumSatisfactionEnhancer {
  static const String _logName = 'QuantumSatisfactionEnhancer';

  final QuantumSatisfactionFeatureExtractor _featureExtractor;
  final FeatureFlagService? _featureFlags;

  QuantumSatisfactionEnhancer({
    required QuantumSatisfactionFeatureExtractor featureExtractor,
    FeatureFlagService? featureFlags,
  }) : _featureExtractor = featureExtractor,
       _featureFlags = featureFlags;

  /// Enhance satisfaction prediction with quantum features
  ///
  /// **Parameters:**
  /// - `baseSatisfaction`: Base satisfaction from existing model (0.0-1.0)
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
  ///
  /// **Returns:**
  /// Enhanced satisfaction (0.0-1.0) with quantum features applied
  Future<double> enhanceSatisfaction({
    required double baseSatisfaction,
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
      // Check if quantum satisfaction enhancement is enabled
      final quantumSatisfactionEnabled = _featureFlags != null
          ? await _featureFlags.isEnabled(
              QuantumFeatureFlags.quantumSatisfactionEnhancement,
              userId: userId,
              defaultValue: false,
            )
          : false;

      // If not enabled, return base satisfaction
      if (!quantumSatisfactionEnabled) {
        return baseSatisfaction;
      }

      // Extract quantum features
      final features = await _featureExtractor.extractFeatures(
        userId: userId,
        userVibeDimensions: userVibeDimensions,
        eventVibeDimensions: eventVibeDimensions,
        userTemporalState: userTemporalState,
        eventTemporalState: eventTemporalState,
        userLocationState: userLocationState,
        eventLocationState: eventLocationState,
        contextMatch: contextMatch,
        preferenceAlignment: preferenceAlignment,
        noveltyScore: noveltyScore,
      );

      // Enhance satisfaction using quantum features
      final enhancedSatisfaction = _applyQuantumEnhancement(
        baseSatisfaction,
        features,
      );

      developer.log(
        'Satisfaction enhanced: ${(baseSatisfaction * 100).toStringAsFixed(1)}% -> '
        '${(enhancedSatisfaction * 100).toStringAsFixed(1)}%',
        name: _logName,
      );

      return enhancedSatisfaction.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error enhancing satisfaction: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return base satisfaction on error
      return baseSatisfaction;
    }
  }

  /// Apply quantum enhancement to base satisfaction
  ///
  /// Uses weighted combination of quantum features to adjust satisfaction.
  /// Formula: `enhanced = weighted_average(existing_features, quantum_features) + decoherence_optimization`
  double _applyQuantumEnhancement(
    double baseSatisfaction,
    QuantumSatisfactionFeatures features,
  ) {
    // Enhanced satisfaction model with quantum values
    // Existing features (reduced weights)
    var enhanced = features.contextMatch * 0.25 +
        features.preferenceAlignment * 0.25 +
        features.noveltyScore * 0.15;

    // Quantum values (new weights)
    enhanced += features.quantumVibeMatch * 0.15; // 12 vibe dimensions
    enhanced += features.entanglementCompatibility * 0.10; // Entanglement strength
    enhanced += features.interferenceEffect.clamp(0.0, 1.0) * 0.05; // Quantum interference (positive only)
    enhanced += features.locationQuantumMatch * 0.03; // Location quantum
    enhanced += features.timingQuantumMatch * 0.02; // Timing quantum

    // Apply decoherence optimization
    if (features.decoherenceOptimization > 0.0) {
      // User exploring - boost satisfaction for diverse recommendations
      // User settled - boost satisfaction for similar recommendations
      enhanced *= (1.0 + features.decoherenceOptimization);
    }

    return enhanced.clamp(0.0, 1.0);
  }

  /// Get quantum feature importance (for model interpretation)
  ///
  /// Returns a map of feature names to their importance weights.
  Map<String, double> getFeatureImportance() {
    return {
      'contextMatch': 0.25,
      'preferenceAlignment': 0.25,
      'noveltyScore': 0.15,
      'quantumVibeMatch': 0.15,
      'entanglementCompatibility': 0.10,
      'interferenceEffect': 0.05,
      'locationQuantumMatch': 0.03,
      'timingQuantumMatch': 0.02,
      'decoherenceOptimization': 0.0, // Applied as multiplier, not weight
    };
  }
}


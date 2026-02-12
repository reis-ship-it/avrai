/// Quantum Satisfaction Features
///
/// Extracts quantum properties as features for satisfaction models to improve
/// user satisfaction from 75% to 80-85%.
///
/// **Purpose:**
/// - Add quantum values as features to satisfaction models
/// - Improve user satisfaction using quantum state information
/// - Enable better satisfaction prediction and optimization
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 4.1
class QuantumSatisfactionFeatures {
  /// Existing features
  final double contextMatch;
  final double preferenceAlignment;
  final double noveltyScore;

  /// NEW: Quantum values
  /// Quantum vibe match (12-dimensional vibe compatibility)
  final double quantumVibeMatch;

  /// Entanglement compatibility
  final double entanglementCompatibility;

  /// Quantum interference effect
  final double interferenceEffect;

  /// Decoherence-based optimization factor
  final double decoherenceOptimization;

  /// Phase alignment
  final double phaseAlignment;

  /// Location quantum compatibility
  final double locationQuantumMatch;

  /// Timing quantum compatibility
  final double timingQuantumMatch;

  QuantumSatisfactionFeatures({
    required this.contextMatch,
    required this.preferenceAlignment,
    required this.noveltyScore,
    required this.quantumVibeMatch,
    required this.entanglementCompatibility,
    required this.interferenceEffect,
    required this.decoherenceOptimization,
    required this.phaseAlignment,
    required this.locationQuantumMatch,
    required this.timingQuantumMatch,
  });

  /// Create from minimal features (for backward compatibility)
  factory QuantumSatisfactionFeatures.minimal({
    required double contextMatch,
    required double preferenceAlignment,
    required double noveltyScore,
  }) {
    return QuantumSatisfactionFeatures(
      contextMatch: contextMatch,
      preferenceAlignment: preferenceAlignment,
      noveltyScore: noveltyScore,
      quantumVibeMatch: 0.0,
      entanglementCompatibility: 0.0,
      interferenceEffect: 0.0,
      decoherenceOptimization: 0.0,
      phaseAlignment: 0.0,
      locationQuantumMatch: 0.0,
      timingQuantumMatch: 0.0,
    );
  }

  /// Convert to feature vector for model input
  ///
  /// Returns a list of features in the order expected by the satisfaction model.
  List<double> toFeatureVector() {
    return [
      // Existing features (3)
      contextMatch,
      preferenceAlignment,
      noveltyScore,
      // Quantum features (7)
      quantumVibeMatch,
      entanglementCompatibility,
      interferenceEffect,
      decoherenceOptimization,
      phaseAlignment,
      locationQuantumMatch,
      timingQuantumMatch,
    ];
  }

  /// Get feature names (for model interpretation)
  List<String> getFeatureNames() {
    return [
      // Existing features
      'contextMatch',
      'preferenceAlignment',
      'noveltyScore',
      // Quantum features
      'quantumVibeMatch',
      'entanglementCompatibility',
      'interferenceEffect',
      'decoherenceOptimization',
      'phaseAlignment',
      'locationQuantumMatch',
      'timingQuantumMatch',
    ];
  }

  /// Get feature count
  int get featureCount => toFeatureVector().length;

  Map<String, dynamic> toJson() => {
        'contextMatch': contextMatch,
        'preferenceAlignment': preferenceAlignment,
        'noveltyScore': noveltyScore,
        'quantumVibeMatch': quantumVibeMatch,
        'entanglementCompatibility': entanglementCompatibility,
        'interferenceEffect': interferenceEffect,
        'decoherenceOptimization': decoherenceOptimization,
        'phaseAlignment': phaseAlignment,
        'locationQuantumMatch': locationQuantumMatch,
        'timingQuantumMatch': timingQuantumMatch,
      };

  factory QuantumSatisfactionFeatures.fromJson(Map<String, dynamic> json) {
    return QuantumSatisfactionFeatures(
      contextMatch: (json['contextMatch'] as num).toDouble(),
      preferenceAlignment: (json['preferenceAlignment'] as num).toDouble(),
      noveltyScore: (json['noveltyScore'] as num).toDouble(),
      quantumVibeMatch: (json['quantumVibeMatch'] as num).toDouble(),
      entanglementCompatibility: (json['entanglementCompatibility'] as num).toDouble(),
      interferenceEffect: (json['interferenceEffect'] as num).toDouble(),
      decoherenceOptimization: (json['decoherenceOptimization'] as num).toDouble(),
      phaseAlignment: (json['phaseAlignment'] as num).toDouble(),
      locationQuantumMatch: (json['locationQuantumMatch'] as num).toDouble(),
      timingQuantumMatch: (json['timingQuantumMatch'] as num).toDouble(),
    );
  }
}


/// Quantum Prediction Features
///
/// Extracts quantum properties as features for prediction models to improve
/// accuracy from 85% to 88-92%.
///
/// **Purpose:**
/// - Add quantum properties as features to prediction models
/// - Improve prediction accuracy using quantum state information
/// - Enable more accurate user journey planning
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 3.1
class QuantumPredictionFeatures {
  /// Existing features
  final double temporalCompatibility;
  final double weekdayMatch;

  /// NEW: Quantum properties
  /// Decoherence features (from Phase 2)
  final double decoherenceRate; // How fast preferences changing
  final double decoherenceStability; // How stable preferences are

  /// Interference features
  final double interferenceStrength; // Quantum interference effect

  /// Entanglement features
  final double entanglementStrength; // How strongly entangled

  /// Phase features
  final double phaseAlignment; // Phase alignment between states

  /// Quantum vibe features (12 dimensions)
  final List<double> quantumVibeMatch; // 12 vibe dimensions

  /// Temporal quantum features
  final double temporalQuantumMatch; // Quantum temporal compatibility

  /// Preference drift
  final double preferenceDrift; // How much preferences drifted

  /// Coherence level
  final double coherenceLevel; // Quantum coherence level

  QuantumPredictionFeatures({
    required this.temporalCompatibility,
    required this.weekdayMatch,
    required this.decoherenceRate,
    required this.decoherenceStability,
    required this.interferenceStrength,
    required this.entanglementStrength,
    required this.phaseAlignment,
    required this.quantumVibeMatch,
    required this.temporalQuantumMatch,
    required this.preferenceDrift,
    required this.coherenceLevel,
  });

  /// Create from minimal features (for backward compatibility)
  factory QuantumPredictionFeatures.minimal({
    required double temporalCompatibility,
    required double weekdayMatch,
  }) {
    return QuantumPredictionFeatures(
      temporalCompatibility: temporalCompatibility,
      weekdayMatch: weekdayMatch,
      decoherenceRate: 0.0,
      decoherenceStability: 1.0,
      interferenceStrength: 0.0,
      entanglementStrength: 0.0,
      phaseAlignment: 0.0,
      quantumVibeMatch: List.filled(12, 0.0),
      temporalQuantumMatch: 0.0,
      preferenceDrift: 0.0,
      coherenceLevel: 1.0,
    );
  }

  /// Convert to feature vector for model input
  ///
  /// Returns a list of features in the order expected by the prediction model.
  List<double> toFeatureVector() {
    return [
      // Existing features (2)
      temporalCompatibility,
      weekdayMatch,
      // Decoherence features (2)
      decoherenceRate,
      decoherenceStability,
      // Quantum features (4)
      interferenceStrength,
      entanglementStrength,
      phaseAlignment,
      coherenceLevel,
      // Quantum vibe features (12 dimensions)
      ...quantumVibeMatch,
      // Temporal quantum feature (1)
      temporalQuantumMatch,
      // Preference drift (1)
      preferenceDrift,
    ];
  }

  /// Get feature names (for model interpretation)
  List<String> getFeatureNames() {
    return [
      // Existing features
      'temporalCompatibility',
      'weekdayMatch',
      // Decoherence features
      'decoherenceRate',
      'decoherenceStability',
      // Quantum features
      'interferenceStrength',
      'entanglementStrength',
      'phaseAlignment',
      'coherenceLevel',
      // Quantum vibe features
      'quantumVibeMatch_0',
      'quantumVibeMatch_1',
      'quantumVibeMatch_2',
      'quantumVibeMatch_3',
      'quantumVibeMatch_4',
      'quantumVibeMatch_5',
      'quantumVibeMatch_6',
      'quantumVibeMatch_7',
      'quantumVibeMatch_8',
      'quantumVibeMatch_9',
      'quantumVibeMatch_10',
      'quantumVibeMatch_11',
      // Temporal quantum feature
      'temporalQuantumMatch',
      // Preference drift
      'preferenceDrift',
    ];
  }

  /// Get feature count
  int get featureCount => toFeatureVector().length;

  Map<String, dynamic> toJson() => {
        'temporalCompatibility': temporalCompatibility,
        'weekdayMatch': weekdayMatch,
        'decoherenceRate': decoherenceRate,
        'decoherenceStability': decoherenceStability,
        'interferenceStrength': interferenceStrength,
        'entanglementStrength': entanglementStrength,
        'phaseAlignment': phaseAlignment,
        'quantumVibeMatch': quantumVibeMatch,
        'temporalQuantumMatch': temporalQuantumMatch,
        'preferenceDrift': preferenceDrift,
        'coherenceLevel': coherenceLevel,
      };

  factory QuantumPredictionFeatures.fromJson(Map<String, dynamic> json) {
    return QuantumPredictionFeatures(
      temporalCompatibility: (json['temporalCompatibility'] as num).toDouble(),
      weekdayMatch: (json['weekdayMatch'] as num).toDouble(),
      decoherenceRate: (json['decoherenceRate'] as num).toDouble(),
      decoherenceStability: (json['decoherenceStability'] as num).toDouble(),
      interferenceStrength: (json['interferenceStrength'] as num).toDouble(),
      entanglementStrength: (json['entanglementStrength'] as num).toDouble(),
      phaseAlignment: (json['phaseAlignment'] as num).toDouble(),
      quantumVibeMatch: (json['quantumVibeMatch'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      temporalQuantumMatch: (json['temporalQuantumMatch'] as num).toDouble(),
      preferenceDrift: (json['preferenceDrift'] as num).toDouble(),
      coherenceLevel: (json['coherenceLevel'] as num).toDouble(),
    );
  }
}


import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/quantum/quantum_prediction_features.dart';

void main() {
  group('QuantumPredictionFeatures', () {
    test('should create features with all properties', () {
      final features = QuantumPredictionFeatures(
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
        decoherenceRate: 0.1,
        decoherenceStability: 0.9,
        interferenceStrength: 0.6,
        entanglementStrength: 0.5,
        phaseAlignment: 0.7,
        quantumVibeMatch: List.filled(12, 0.6),
        temporalQuantumMatch: 0.75,
        preferenceDrift: 0.2,
        coherenceLevel: 0.95,
      );

      expect(features.temporalCompatibility, equals(0.7));
      expect(features.weekdayMatch, equals(0.8));
      expect(features.decoherenceRate, equals(0.1));
      expect(features.decoherenceStability, equals(0.9));
      expect(features.interferenceStrength, equals(0.6));
      expect(features.entanglementStrength, equals(0.5));
      expect(features.phaseAlignment, equals(0.7));
      expect(features.quantumVibeMatch.length, equals(12));
      expect(features.temporalQuantumMatch, equals(0.75));
      expect(features.preferenceDrift, equals(0.2));
      expect(features.coherenceLevel, equals(0.95));
    });

    test('should create minimal features for backward compatibility', () {
      final features = QuantumPredictionFeatures.minimal(
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
      );

      expect(features.temporalCompatibility, equals(0.7));
      expect(features.weekdayMatch, equals(0.8));
      expect(features.decoherenceRate, equals(0.0));
      expect(features.decoherenceStability, equals(1.0));
      expect(features.interferenceStrength, equals(0.0));
      expect(features.entanglementStrength, equals(0.0));
      expect(features.phaseAlignment, equals(0.0));
      expect(features.quantumVibeMatch.length, equals(12));
      expect(features.temporalQuantumMatch, equals(0.0));
      expect(features.preferenceDrift, equals(0.0));
      expect(features.coherenceLevel, equals(1.0));
    });

    test('should convert to feature vector correctly', () {
      final features = QuantumPredictionFeatures(
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
        decoherenceRate: 0.1,
        decoherenceStability: 0.9,
        interferenceStrength: 0.6,
        entanglementStrength: 0.5,
        phaseAlignment: 0.7,
        quantumVibeMatch: List.filled(12, 0.6),
        temporalQuantumMatch: 0.75,
        preferenceDrift: 0.2,
        coherenceLevel: 0.95,
      );

      final vector = features.toFeatureVector();

      // Should have 2 (existing) + 2 (decoherence) + 4 (quantum) + 12 (vibe) + 1 (temporal) + 1 (drift) = 22 features
      expect(vector.length, equals(22));
      expect(vector[0], equals(0.7)); // temporalCompatibility
      expect(vector[1], equals(0.8)); // weekdayMatch
      expect(vector[2], equals(0.1)); // decoherenceRate
      expect(vector[3], equals(0.9)); // decoherenceStability
    });

    test('should get feature names correctly', () {
      final features = QuantumPredictionFeatures.minimal(
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
      );

      final names = features.getFeatureNames();

      expect(names.length, equals(22));
      expect(names[0], equals('temporalCompatibility'));
      expect(names[1], equals('weekdayMatch'));
      expect(names[2], equals('decoherenceRate'));
      expect(names[3], equals('decoherenceStability'));
      expect(names[4], equals('interferenceStrength'));
      expect(names[5], equals('entanglementStrength'));
      expect(names[6], equals('phaseAlignment'));
      expect(names[7], equals('coherenceLevel'));
      expect(names[8], equals('quantumVibeMatch_0'));
      expect(names[19], equals('quantumVibeMatch_11'));
      expect(names[20], equals('temporalQuantumMatch'));
      expect(names[21], equals('preferenceDrift'));
    });

    test('should serialize and deserialize correctly (round-trip)', () {
      final original = QuantumPredictionFeatures(
        temporalCompatibility: 0.7,
        weekdayMatch: 0.8,
        decoherenceRate: 0.1,
        decoherenceStability: 0.9,
        interferenceStrength: 0.6,
        entanglementStrength: 0.5,
        phaseAlignment: 0.7,
        quantumVibeMatch: List.filled(12, 0.6),
        temporalQuantumMatch: 0.75,
        preferenceDrift: 0.2,
        coherenceLevel: 0.95,
      );

      final json = original.toJson();
      final restored = QuantumPredictionFeatures.fromJson(json);

      expect(restored.temporalCompatibility,
          closeTo(original.temporalCompatibility, 0.001));
      expect(restored.weekdayMatch, closeTo(original.weekdayMatch, 0.001));
      expect(
          restored.decoherenceRate, closeTo(original.decoherenceRate, 0.001));
      expect(restored.decoherenceStability,
          closeTo(original.decoherenceStability, 0.001));
      expect(restored.interferenceStrength,
          closeTo(original.interferenceStrength, 0.001));
      expect(restored.entanglementStrength,
          closeTo(original.entanglementStrength, 0.001));
      expect(restored.phaseAlignment, closeTo(original.phaseAlignment, 0.001));
      expect(restored.quantumVibeMatch.length,
          equals(original.quantumVibeMatch.length));
      expect(restored.temporalQuantumMatch,
          closeTo(original.temporalQuantumMatch, 0.001));
      expect(
          restored.preferenceDrift, closeTo(original.preferenceDrift, 0.001));
      expect(restored.coherenceLevel, closeTo(original.coherenceLevel, 0.001));
    });
  });
}

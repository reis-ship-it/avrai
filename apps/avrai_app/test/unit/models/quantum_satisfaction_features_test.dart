import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/quantum/quantum_satisfaction_features.dart';

void main() {
  group('QuantumSatisfactionFeatures', () {
    test('should create minimal features with default quantum values', () {
      final features = QuantumSatisfactionFeatures.minimal(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      expect(features.contextMatch, equals(0.7));
      expect(features.preferenceAlignment, equals(0.8));
      expect(features.noveltyScore, equals(0.6));
      expect(features.quantumVibeMatch, equals(0.0));
      expect(features.entanglementCompatibility, equals(0.0));
      expect(features.interferenceEffect, equals(0.0));
      expect(features.decoherenceOptimization, equals(0.0));
      expect(features.phaseAlignment, equals(0.0));
      expect(features.locationQuantumMatch, equals(0.0));
      expect(features.timingQuantumMatch, equals(0.0));
    });

    test('should create full features with all values', () {
      final features = QuantumSatisfactionFeatures(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
        quantumVibeMatch: 0.75,
        entanglementCompatibility: 0.65,
        interferenceEffect: 0.5,
        decoherenceOptimization: 0.1,
        phaseAlignment: 0.8,
        locationQuantumMatch: 0.7,
        timingQuantumMatch: 0.85,
      );

      expect(features.contextMatch, equals(0.7));
      expect(features.preferenceAlignment, equals(0.8));
      expect(features.noveltyScore, equals(0.6));
      expect(features.quantumVibeMatch, equals(0.75));
      expect(features.entanglementCompatibility, equals(0.65));
      expect(features.interferenceEffect, equals(0.5));
      expect(features.decoherenceOptimization, equals(0.1));
      expect(features.phaseAlignment, equals(0.8));
      expect(features.locationQuantumMatch, equals(0.7));
      expect(features.timingQuantumMatch, equals(0.85));
    });

    test('should convert to feature vector correctly', () {
      final features = QuantumSatisfactionFeatures(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
        quantumVibeMatch: 0.75,
        entanglementCompatibility: 0.65,
        interferenceEffect: 0.5,
        decoherenceOptimization: 0.1,
        phaseAlignment: 0.8,
        locationQuantumMatch: 0.7,
        timingQuantumMatch: 0.85,
      );

      final vector = features.toFeatureVector();

      expect(vector.length, equals(10));
      expect(vector[0], equals(0.7)); // contextMatch
      expect(vector[1], equals(0.8)); // preferenceAlignment
      expect(vector[2], equals(0.6)); // noveltyScore
      expect(vector[3], equals(0.75)); // quantumVibeMatch
      expect(vector[4], equals(0.65)); // entanglementCompatibility
      expect(vector[5], equals(0.5)); // interferenceEffect
      expect(vector[6], equals(0.1)); // decoherenceOptimization
      expect(vector[7], equals(0.8)); // phaseAlignment
      expect(vector[8], equals(0.7)); // locationQuantumMatch
      expect(vector[9], equals(0.85)); // timingQuantumMatch
    });

    test('should return correct feature names', () {
      final features = QuantumSatisfactionFeatures.minimal(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      final names = features.getFeatureNames();

      expect(names.length, equals(10));
      expect(names[0], equals('contextMatch'));
      expect(names[1], equals('preferenceAlignment'));
      expect(names[2], equals('noveltyScore'));
      expect(names[3], equals('quantumVibeMatch'));
      expect(names[4], equals('entanglementCompatibility'));
      expect(names[5], equals('interferenceEffect'));
      expect(names[6], equals('decoherenceOptimization'));
      expect(names[7], equals('phaseAlignment'));
      expect(names[8], equals('locationQuantumMatch'));
      expect(names[9], equals('timingQuantumMatch'));
    });

    test('should return correct feature count', () {
      final features = QuantumSatisfactionFeatures.minimal(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
      );

      expect(features.featureCount, equals(10));
    });

    test('should serialize and deserialize correctly (round-trip)', () {
      final original = QuantumSatisfactionFeatures(
        contextMatch: 0.7,
        preferenceAlignment: 0.8,
        noveltyScore: 0.6,
        quantumVibeMatch: 0.75,
        entanglementCompatibility: 0.65,
        interferenceEffect: 0.5,
        decoherenceOptimization: 0.1,
        phaseAlignment: 0.8,
        locationQuantumMatch: 0.7,
        timingQuantumMatch: 0.85,
      );

      final json = original.toJson();
      final restored = QuantumSatisfactionFeatures.fromJson(json);

      expect(restored.contextMatch, equals(original.contextMatch));
      expect(
          restored.preferenceAlignment, equals(original.preferenceAlignment));
      expect(restored.noveltyScore, equals(original.noveltyScore));
      expect(restored.quantumVibeMatch, equals(original.quantumVibeMatch));
      expect(restored.entanglementCompatibility,
          equals(original.entanglementCompatibility));
      expect(restored.interferenceEffect, equals(original.interferenceEffect));
      expect(restored.decoherenceOptimization,
          equals(original.decoherenceOptimization));
      expect(restored.phaseAlignment, equals(original.phaseAlignment));
      expect(
          restored.locationQuantumMatch, equals(original.locationQuantumMatch));
      expect(restored.timingQuantumMatch, equals(original.timingQuantumMatch));
    });
  });
}

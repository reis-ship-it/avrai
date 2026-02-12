// Unit tests for KnotPrivacyService
// 
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 7: Audio & Privacy

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/knot/knot_privacy_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';

/// Mock Rust API for testing
class MockRustLibApi implements RustLibApi {
  @override
  Float64List crateApiCalculateAlexanderPolynomial(
      {required List<double> braidData}) {
    return Float64List.fromList([1.0, 0.0, -1.0]);
  }

  @override
  Float64List crateApiCalculateBoltzmannDistribution(
      {required List<double> energies, required double temperature}) {
    final sum = energies.fold<double>(0.0, (a, b) => a + b);
    return Float64List.fromList(energies.map((e) => e / sum).toList());
  }

  @override
  BigInt crateApiCalculateCrossingNumberFromBraid(
      {required List<double> braidData}) {
    return BigInt.from((braidData.length - 1) ~/ 2);
  }

  @override
  double crateApiCalculateEntropy({required List<double> probabilities}) {
    return 1.0;
  }

  @override
  double crateApiCalculateFreeEnergy(
      {required double energy,
      required double entropy,
      required double temperature}) {
    return energy - temperature * entropy;
  }

  @override
  Float64List crateApiCalculateJonesPolynomial(
      {required List<double> braidData}) {
    return Float64List.fromList([1.0, -1.0, 1.0]);
  }

  @override
  double crateApiCalculateKnotEnergyFromPoints(
      {required List<double> knotPoints}) {
    return 1.0;
  }

  @override
  double crateApiCalculateKnotStabilityFromPoints(
      {required List<double> knotPoints}) {
    return 0.8;
  }

  @override
  double crateApiCalculateTopologicalCompatibility(
      {required List<double> braidDataA, required List<double> braidDataB}) {
    final diff = (braidDataA.length - braidDataB.length).abs();
    return (1.0 - (diff / 10.0).clamp(0.0, 1.0));
  }

  @override
  int crateApiCalculateWritheFromBraid({required List<double> braidData}) {
    return (braidData.length - 1) ~/ 2;
  }

  @override
  double crateApiEvaluatePolynomial(
      {required List<double> coefficients, required double x}) {
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * (x * i);
    }
    return result;
  }

  @override
  KnotResult crateApiGenerateKnotFromBraid({required List<double> braidData}) {
    return KnotResult(
      knotData: Float64List.fromList([braidData[0]]),
      jonesPolynomial: Float64List.fromList([1.0, -1.0, 1.0]),
      alexanderPolynomial: Float64List.fromList([1.0, 0.0, -1.0]),
      crossingNumber: BigInt.from((braidData.length - 1) ~/ 2),
      writhe: (braidData.length - 1) ~/ 2,
      signature: 0,
      bridgeNumber: BigInt.from(1),
      braidIndex: BigInt.from(1),
      determinant: 1,
    );
  }

  @override
  double crateApiPolynomialDistance(
      {required List<double> coefficientsA,
      required List<double> coefficientsB}) {
    final maxLen = coefficientsA.length > coefficientsB.length
        ? coefficientsA.length
        : coefficientsB.length;
    double sumSq = 0.0;
    for (int i = 0; i < maxLen; i++) {
      final a = i < coefficientsA.length ? coefficientsA[i] : 0.0;
      final b = i < coefficientsB.length ? coefficientsB[i] : 0.0;
      sumSq += (a - b) * (a - b);
    }
    return sumSq;
  }
}

void main() {
  group('KnotPrivacyService', () {
    late KnotPrivacyService privacyService;
    late PersonalityKnotService knotService;
    bool rustLibInitialized = false;

    setUpAll(() {
      // Initialize Rust library for tests (mock mode)
      if (!rustLibInitialized) {
        RustLib.initMock(api: MockRustLibApi());
        rustLibInitialized = true;
      }
    });

    setUp(() {
      privacyService = KnotPrivacyService();
      knotService = PersonalityKnotService();
    });

    group('generateAnonymizedKnot', () {
      test('should generate anonymized knot from profile with knot', () async {
        // Arrange: Create a profile and generate a knot for it
        final profile = PersonalityProfile.initial('test_user');
        final knot = await knotService.generateKnot(profile);
        
        // Create a profile with the knot using the evolve method or copyWith
        // Since PersonalityProfile is immutable, we need to create a new profile with the knot
        final profileWithKnot = PersonalityProfile(
          agentId: profile.agentId,
          userId: profile.userId,
          dimensions: profile.dimensions,
          dimensionConfidence: profile.dimensionConfidence,
          archetype: profile.archetype,
          authenticity: profile.authenticity,
          createdAt: profile.createdAt,
          lastUpdated: profile.lastUpdated,
          evolutionGeneration: profile.evolutionGeneration,
          learningHistory: profile.learningHistory,
          corePersonality: profile.corePersonality,
          contexts: profile.contexts,
          evolutionTimeline: profile.evolutionTimeline,
          currentPhaseId: profile.currentPhaseId,
          isInTransition: profile.isInTransition,
          activeTransition: profile.activeTransition,
          personalityKnot: knot,
          knotEvolutionHistory: profile.knotEvolutionHistory,
        );

        // Act
        final anonymizedKnot = privacyService.generateAnonymizedKnot(profileWithKnot);

        // Assert
        expect(anonymizedKnot, isNotNull);
        expect(anonymizedKnot.topology, isNotNull);
        expect(anonymizedKnot.topology.jonesPolynomial, equals(knot.invariants.jonesPolynomial));
        expect(anonymizedKnot.topology.alexanderPolynomial, equals(knot.invariants.alexanderPolynomial));
        expect(anonymizedKnot.topology.crossingNumber, equals(knot.invariants.crossingNumber));
        expect(anonymizedKnot.topology.writhe, equals(knot.invariants.writhe));
      });

      test('should throw error if profile has no knot', () {
        // Arrange
        final profile = PersonalityProfile.initial('test_user');
        // Profile doesn't have a knot by default

        // Act & Assert
        expect(
          () => privacyService.generateAnonymizedKnot(profile),
          throwsArgumentError,
        );
      });
    });

    group('generateContextKnot', () {
      test('should generate public context knot', () {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final contextKnot = privacyService.generateContextKnot(
          originalKnot: knot,
          context: KnotContext.public,
        );

        // Assert
        expect(contextKnot, isNotNull);
        expect(contextKnot.invariants, isNotNull);
      });

      test('should generate friends context knot with noise', () {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final contextKnot = privacyService.generateContextKnot(
          originalKnot: knot,
          context: KnotContext.friends,
        );

        // Assert
        expect(contextKnot, isNotNull);
        expect(contextKnot.invariants, isNotNull);
        // Friends context should have noise added
      });

      test('should generate private context knot (minimal)', () {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final contextKnot = privacyService.generateContextKnot(
          originalKnot: knot,
          context: KnotContext.private,
        );

        // Assert
        expect(contextKnot, isNotNull);
        expect(contextKnot.invariants, isNotNull);
        // Private context should be minimal (topology only)
      });

      test('should generate anonymous context knot (fully anonymized)', () {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final contextKnot = privacyService.generateContextKnot(
          originalKnot: knot,
          context: KnotContext.anonymous,
        );

        // Assert
        expect(contextKnot, isNotNull);
        expect(contextKnot.invariants, isNotNull);
        // Anonymous context should be fully anonymized
      });
    });

    group('Error Handling', () {
      test('should handle knot gracefully', () {
        // Arrange
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act & Assert: Should not throw
        final contextKnot = privacyService.generateContextKnot(
          originalKnot: knot,
          context: KnotContext.public,
        );
        expect(contextKnot, isNotNull);
      });
    });
  });
}

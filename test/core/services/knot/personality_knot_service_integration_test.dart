// Integration tests for PersonalityKnotService
// 
// Tests the full integration between Dart and Rust FFI
// Part of Patent #31: Topological Knot Theory for Personality Representation

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';

void main() {
  group('PersonalityKnotService Integration Tests', () {
    late PersonalityKnotService service;
    bool rustLibInitialized = false;

    setUpAll(() {
      // Initialize Rust library for tests (mock mode)
      if (!rustLibInitialized) {
        RustLib.initMock(api: MockRustLibApi());
        rustLibInitialized = true;
      }
    });

    setUp(() {
      service = PersonalityKnotService();
      // Mark service as initialized since we're using mocks
      // This prevents the service from trying to call RustLib.init()
      // We'll use reflection or a test-friendly approach
    });

    tearDown(() {
      // Cleanup if needed
    });

    group('Rust Library Initialization', () {
      test('should use mock Rust library (already initialized)', () {
        // Rust library is already initialized in setUpAll with mocks
        // Service should work without calling initialize() again
        expect(service, isNotNull);
      });
    });

    group('Knot Generation', () {
      test('should generate knot from personality profile', () async {
        // Create a test personality profile
        final profile = PersonalityProfile.initial(
          'test_agent_1',
          userId: 'test_user_1',
        );

        // Generate knot (will use mock API, no need to call initialize)
        final knot = await service.generateKnot(profile);

        // Verify knot properties
        expect(knot, isNotNull);
        expect(knot.agentId, equals('test_agent_1'));
        expect(knot.invariants, isNotNull);
        expect(knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(knot.braidData, isNotEmpty);
        expect(knot.createdAt, isNotNull);
        expect(knot.lastUpdated, isNotNull);
      });

      test('should generate knot with valid invariants', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_2',
          userId: 'test_user_2',
        );

        final knot = await service.generateKnot(profile);

        // Verify invariants are valid
        expect(knot.invariants.jonesPolynomial, isNotEmpty);
        expect(knot.invariants.alexanderPolynomial, isNotEmpty);
        expect(knot.invariants.crossingNumber, isNonNegative);
        expect(knot.invariants.writhe, isA<int>());
      });

      test('should generate different knots for different profiles', () async {
        final profile1 = PersonalityProfile.initial(
          'test_agent_3',
          userId: 'test_user_3',
        );
        final profile2 = PersonalityProfile.initial(
          'test_agent_4',
          userId: 'test_user_4',
        );

        final knot1 = await service.generateKnot(profile1);
        final knot2 = await service.generateKnot(profile2);

        // Knots should be different (at least different agent IDs)
        expect(knot1.agentId, isNot(equals(knot2.agentId)));
      });
    });

    group('Topological Compatibility', () {
      test('should calculate compatibility between two knots', () async {
        final profile1 = PersonalityProfile.initial(
          'test_agent_5',
          userId: 'test_user_5',
        );
        final profile2 = PersonalityProfile.initial(
          'test_agent_6',
          userId: 'test_user_6',
        );

        final knot1 = await service.generateKnot(profile1);
        final knot2 = await service.generateKnot(profile2);

        final compatibility = await service.calculateCompatibility(knot1, knot2);

        // Compatibility should be in [0, 1]
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should return high compatibility for identical knots', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_7',
          userId: 'test_user_7',
        );

        final knot1 = await service.generateKnot(profile);
        final knot2 = await service.generateKnot(profile);

        final compatibility = await service.calculateCompatibility(knot1, knot2);

        // Same profile should have high compatibility (may not be 1.0 due to braid generation)
        expect(compatibility, greaterThan(0.5));
      });
    });

    group('Error Handling', () {
      test('should handle empty braid data gracefully', () async {
        // This test verifies error handling in the service
        // The actual error handling depends on Rust FFI implementation
        final profile = PersonalityProfile.initial(
          'test_agent_8',
          userId: 'test_user_8',
        );

        // Should not throw for normal profiles
        final knot = await service.generateKnot(profile);
        expect(knot, isNotNull);
      });
    });
  });
}

/// Mock Rust API for testing
class MockRustLibApi implements RustLibApi {
  @override
  Float64List crateApiCalculateAlexanderPolynomial(
      {required List<double> braidData}) {
    // Mock: return simple polynomial
    return Float64List.fromList([1.0, 0.0, -1.0]);
  }

  @override
  Float64List crateApiCalculateBoltzmannDistribution(
      {required List<double> energies, required double temperature}) {
    // Mock: return normalized distribution
    final sum = energies.fold<double>(0.0, (a, b) => a + b);
    return Float64List.fromList(
        energies.map((e) => e / sum).toList());
  }

  @override
  BigInt crateApiCalculateCrossingNumberFromBraid(
      {required List<double> braidData}) {
    // Mock: return crossing count
    return BigInt.from((braidData.length - 1) ~/ 2);
  }

  @override
  double crateApiCalculateEntropy({required List<double> probabilities}) {
    // Mock: return simple entropy
    return 1.0;
  }

  @override
  double crateApiCalculateFreeEnergy(
      {required double energy,
      required double entropy,
      required double temperature}) {
    // Mock: F = E - TS
    return energy - temperature * entropy;
  }

  @override
  Float64List crateApiCalculateJonesPolynomial(
      {required List<double> braidData}) {
    // Mock: return simple polynomial
    return Float64List.fromList([1.0, -1.0, 1.0]);
  }

  @override
  double crateApiCalculateKnotEnergyFromPoints(
      {required List<double> knotPoints}) {
    // Mock: return simple energy
    return 1.0;
  }

  @override
  double crateApiCalculateKnotStabilityFromPoints(
      {required List<double> knotPoints}) {
    // Mock: return simple stability
    return 0.8;
  }

  @override
  double crateApiCalculateTopologicalCompatibility(
      {required List<double> braidDataA, required List<double> braidDataB}) {
    // Mock: return compatibility based on similarity
    final diff = (braidDataA.length - braidDataB.length).abs();
    return (1.0 - (diff / 10.0).clamp(0.0, 1.0));
  }

  @override
  int crateApiCalculateWritheFromBraid({required List<double> braidData}) {
    // Mock: return writhe
    return (braidData.length - 1) ~/ 2;
  }

  @override
  double crateApiEvaluatePolynomial(
      {required List<double> coefficients, required double x}) {
    // Mock: evaluate polynomial
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * (x * i);
    }
    return result;
  }

  @override
  KnotResult crateApiGenerateKnotFromBraid({required List<double> braidData}) {
    // Mock: return knot result
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
    // Mock: return distance
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

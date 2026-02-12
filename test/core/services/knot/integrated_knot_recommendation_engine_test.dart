// Unit tests for IntegratedKnotRecommendationEngine
// 
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 6: Integrated Recommendations

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';
import 'package:avrai/injection_container.dart' as di;
import '../../../helpers/platform_channel_helper.dart';

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
    return 0.5;
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
  group('IntegratedKnotRecommendationEngine', () {
    late IntegratedKnotRecommendationEngine engine;
    late PersonalityKnotService knotService;

    setUpAll(() async {
      try {
        // Initialize Rust library for tests (mock mode)
        try {
          RustLib.initMock(api: MockRustLibApi());
        } catch (e) {
          // Already initialized, that's fine
        }

        // Ensure StorageService uses test storage (avoids path_provider / GetStorage.init).
        await setupTestStorage();

        // Initialize dependency injection
        await di.init();

        knotService = di.sl<PersonalityKnotService>();
        engine = di.sl<IntegratedKnotRecommendationEngine>();
      } catch (e) {
        // If initialization fails, log and rethrow
      // ignore: avoid_print
        print('Error in setUpAll: $e');
        rethrow;
      }
    });

    setUp(() async {
      // Ensure Rust library is initialized
      try {
        RustLib.initMock(api: MockRustLibApi());
      } catch (e) {
        // Already initialized, that's fine
      }
    });

    group('calculateIntegratedCompatibility', () {
      test('should calculate integrated compatibility for two profiles', () async {
        // Arrange
        final profileA = PersonalityProfile.initial('user_a');
        final profileB = PersonalityProfile.initial('user_b');

        // Act
        final result = await engine.calculateIntegratedCompatibility(
          profileA: profileA,
          profileB: profileB,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.quantum, greaterThanOrEqualTo(0.0));
        expect(result.quantum, lessThanOrEqualTo(1.0));
        expect(result.knot, greaterThanOrEqualTo(0.0));
        expect(result.knot, lessThanOrEqualTo(1.0));
        expect(result.combined, greaterThanOrEqualTo(0.0));
        expect(result.combined, lessThanOrEqualTo(1.0));
        expect(result.knotInsights, isNotEmpty);
      });

      test('should return valid compatibility score for profiles', () async {
        // Arrange: Create profiles
        final profileA = PersonalityProfile.initial('user_a');
        final profileB = PersonalityProfile.initial('user_b');

        // Note: PersonalityProfile is immutable, so we test with default profiles
        // In production, profiles would naturally have different compatibility scores

        // Act
        final result = await engine.calculateIntegratedCompatibility(
          profileA: profileA,
          profileB: profileB,
        );

        // Assert: Should return valid compatibility score
        expect(result.combined, greaterThanOrEqualTo(0.0));
        expect(result.combined, lessThanOrEqualTo(1.0));
      });

      test('should include knot insights in result', () async {
        // Arrange
        final profileA = PersonalityProfile.initial('user_a');
        final profileB = PersonalityProfile.initial('user_b');

        // Act
        final result = await engine.calculateIntegratedCompatibility(
          profileA: profileA,
          profileB: profileB,
        );

        // Assert
        expect(result.knotInsights, isNotEmpty);
        expect(result.knotInsights.length, greaterThan(0));
      });
    });

    group('calculateKnotBonus', () {
      test('should calculate knot bonus for two knots', () async {
        // Arrange
        final profileA = PersonalityProfile.initial('user_a');
        final profileB = PersonalityProfile.initial('user_b');
        final knotA = await knotService.generateKnot(profileA);
        final knotB = await knotService.generateKnot(profileB);

        // Act
        final bonus = engine.calculateKnotBonus(
          userKnot: knotA,
          targetKnot: knotB,
        );

        // Assert
        expect(bonus, greaterThanOrEqualTo(0.0));
        expect(bonus, lessThanOrEqualTo(1.0));
      });

      test('should return valid bonus for knots', () async {
        // Arrange: Create profiles to get knots
        final profileA = PersonalityProfile.initial('user_a');
        final profileB = PersonalityProfile.initial('user_b');

        final knotA = await knotService.generateKnot(profileA);
        final knotB = await knotService.generateKnot(profileB);

        // Act
        final bonus = engine.calculateKnotBonus(
          userKnot: knotA,
          targetKnot: knotB,
        );

        // Assert: Should return valid bonus
        expect(bonus, greaterThanOrEqualTo(0.0));
        expect(bonus, lessThanOrEqualTo(1.0));
      });
    });

    group('Error Handling', () {
      test('should handle missing knots gracefully', () async {
        // Arrange: Create profiles that might not generate knots
        final profileA = PersonalityProfile.initial('user_a');
        final profileB = PersonalityProfile.initial('user_b');

        // Act & Assert: Should not throw
        final result = await engine.calculateIntegratedCompatibility(
          profileA: profileA,
          profileB: profileB,
        );

        expect(result, isNotNull);
      });
    });
  });
}

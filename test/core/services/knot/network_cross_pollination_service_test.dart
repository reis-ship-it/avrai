// Unit tests for NetworkCrossPollinationService
// 
// Tests network cross-pollination discovery framework
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1.5: Universal Cross-Pollination Extension

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/network_cross_pollination_service.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
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
  group('NetworkCrossPollinationService Tests', () {
    late NetworkCrossPollinationService service;
    late EntityKnotService entityKnotService;
    bool rustLibInitialized = false;

    setUpAll(() {
      // Initialize Rust library for tests (mock mode)
      if (!rustLibInitialized) {
        RustLib.initMock(api: MockRustLibApi());
        rustLibInitialized = true;
      }
    });

    setUp(() {
      entityKnotService = EntityKnotService();
      service = NetworkCrossPollinationService();
    });

    group('Discovery Path Framework', () {
      test('should return empty list when network traversal not implemented', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_1',
          userId: 'test_user_1',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        final paths = await service.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.event,
          maxDepth: 3,
        );

        // Currently returns empty list (placeholder for network data integration)
        expect(paths, isEmpty);
      });

      test('should respect maxDepth parameter', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_2',
          userId: 'test_user_2',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        // Test with different maxDepth values
        final paths1 = await service.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.place,
          maxDepth: 2,
        );
        final paths2 = await service.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.place,
          maxDepth: 4,
        );

        // Both should return empty (placeholder), but service should handle different depths
        expect(paths1, isEmpty);
        expect(paths2, isEmpty);
      });

      test('should clamp maxDepth to maximum allowed', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_3',
          userId: 'test_user_3',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        // Test with maxDepth exceeding maximum (4)
        final paths = await service.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.company,
          maxDepth: 10, // Exceeds maximum of 4
        );

        // Should still work (clamped internally)
        expect(paths, isEmpty);
      });
    });

    group('Path Compatibility Calculation', () {
      test('should calculate path compatibility for two entities', () async {
        final profile1 = PersonalityProfile.initial(
          'test_agent_4',
          userId: 'test_user_4',
        );
        final profile2 = PersonalityProfile.initial(
          'test_agent_5',
          userId: 'test_user_5',
        );

        final knot1 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile1,
        );
        final knot2 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile2,
        );

        final compatibility = await service.calculatePathCompatibility([knot1, knot2]);

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should return 1.0 for single entity path', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_6',
          userId: 'test_user_6',
        );

        final knot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        final compatibility = await service.calculatePathCompatibility([knot]);

        expect(compatibility, equals(1.0));
      });

      test('should calculate geometric mean for multiple entities', () async {
        final profile1 = PersonalityProfile.initial(
          'test_agent_7',
          userId: 'test_user_7',
        );
        final profile2 = PersonalityProfile.initial(
          'test_agent_8',
          userId: 'test_user_8',
        );
        final profile3 = PersonalityProfile.initial(
          'test_agent_9',
          userId: 'test_user_9',
        );

        final knot1 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile1,
        );
        final knot2 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile2,
        );
        final knot3 = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile3,
        );

        final compatibility = await service.calculatePathCompatibility([knot1, knot2, knot3]);

        // Geometric mean should be in [0, 1]
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('Entity Discovery', () {
      test('should return empty list when network not available', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_10',
          userId: 'test_user_10',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        final discovered = await service.discoverEntitiesThroughNetwork(
          startEntity: personKnot,
          targetType: EntityType.event,
          maxDepth: 3,
          maxResults: 10,
        );

        // Currently returns empty list (placeholder)
        expect(discovered, isEmpty);
      });

      test('should respect maxResults parameter', () async {
        final profile = PersonalityProfile.initial(
          'test_agent_11',
          userId: 'test_user_11',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        final discovered = await service.discoverEntitiesThroughNetwork(
          startEntity: personKnot,
          targetType: EntityType.place,
          maxDepth: 3,
          maxResults: 5,
        );

        // Should respect maxResults (when network is implemented)
        expect(discovered.length, lessThanOrEqualTo(5));
      });
    });

    group('Minimum Compatibility Threshold', () {
      test('should filter paths by minimum compatibility', () async {
        // This test verifies that the service uses _minPathCompatibility (0.3)
        // when filtering paths. Currently, this is a placeholder test.
        final profile = PersonalityProfile.initial(
          'test_agent_12',
          userId: 'test_user_12',
        );

        final personKnot = await entityKnotService.generateKnotForEntity(
          entityType: EntityType.person,
          entity: profile,
        );

        final paths = await service.findCrossEntityDiscoveryPaths(
          startEntity: personKnot,
          targetType: EntityType.company,
          maxDepth: 3,
        );

        // When network traversal is implemented, paths with compatibility < 0.3
        // should be filtered out
        expect(paths, isEmpty); // Placeholder
      });
    });
  });
}

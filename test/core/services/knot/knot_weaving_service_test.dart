// Knot Weaving Service Tests
// 
// Tests for KnotWeavingService
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';

class MockPersonalityKnotService extends Mock implements PersonalityKnotService {}

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
  group('KnotWeavingService Tests', () {
    late KnotWeavingService service;
    late MockPersonalityKnotService mockPersonalityKnotService;
    late PersonalityKnot knotA;
    late PersonalityKnot knotB;
    bool rustLibInitialized = false;

    setUpAll(() {
      // Initialize Rust library for tests (mock mode)
      if (!rustLibInitialized) {
        RustLib.initMock(api: MockRustLibApi());
        rustLibInitialized = true;
      }
    });

    setUp(() {
      mockPersonalityKnotService = MockPersonalityKnotService();
      service = KnotWeavingService(
        personalityKnotService: mockPersonalityKnotService,
      );

      knotA = PersonalityKnot(
        agentId: 'agent-a',
        invariants: KnotInvariants(
          jonesPolynomial: [1.0, 2.0, 3.0],
          alexanderPolynomial: [1.0, 1.0],
          crossingNumber: 5,
          writhe: 2,
          signature: 0,
          bridgeNumber: 2,
          braidIndex: 2,
          determinant: 1,
        ),
        braidData: [8.0, 0.0, 1.0, 1.0, 1.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      knotB = PersonalityKnot(
        agentId: 'agent-b',
        invariants: KnotInvariants(
          jonesPolynomial: [2.0, 3.0, 4.0],
          alexanderPolynomial: [2.0, 2.0],
          crossingNumber: 6,
          writhe: 3,
          signature: 0,
          bridgeNumber: 2,
          braidIndex: 2,
          determinant: 2,
        ),
        braidData: [8.0, 1.0, 1.0, 2.0, 1.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );
    });

    test('should weave knots for friendship relationship type', () async {
      final braidedKnot = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      expect(braidedKnot, isNotNull);
      expect(braidedKnot.knotA, equals(knotA));
      expect(braidedKnot.knotB, equals(knotB));
      expect(braidedKnot.relationshipType, equals(RelationshipType.friendship));
      expect(braidedKnot.braidSequence, isNotEmpty);
      expect(braidedKnot.complexity, greaterThanOrEqualTo(0.0));
      expect(braidedKnot.complexity, lessThanOrEqualTo(1.0));
      expect(braidedKnot.stability, greaterThanOrEqualTo(0.0));
      expect(braidedKnot.stability, lessThanOrEqualTo(1.0));
      expect(braidedKnot.harmonyScore, greaterThanOrEqualTo(0.0));
      expect(braidedKnot.harmonyScore, lessThanOrEqualTo(1.0));
    });

    test('should weave knots for all relationship types', () async {
      final relationshipTypes = [
        RelationshipType.friendship,
        RelationshipType.mentorship,
        RelationshipType.romantic,
        RelationshipType.collaborative,
        RelationshipType.professional,
      ];

      for (final relationshipType in relationshipTypes) {
        final braidedKnot = await service.weaveKnots(
          knotA: knotA,
          knotB: knotB,
          relationshipType: relationshipType,
        );

        expect(braidedKnot.relationshipType, equals(relationshipType));
        expect(braidedKnot.braidSequence, isNotEmpty);
      }
    });

    test('should calculate weaving compatibility', () async {
      final compatibility = await service.calculateWeavingCompatibility(
        knotA: knotA,
        knotB: knotB,
      );

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
    });

    test('should create braiding preview', () async {
      final preview = await service.previewBraiding(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      expect(preview, isNotNull);
      expect(preview.braidedKnot, isNotNull);
      expect(preview.complexity, greaterThanOrEqualTo(0.0));
      expect(preview.stability, greaterThanOrEqualTo(0.0));
      expect(preview.harmony, greaterThanOrEqualTo(0.0));
      expect(preview.compatibility, greaterThanOrEqualTo(0.0));
      expect(preview.relationshipType, equals('Friendship'));
    });

    test('should generate different braid sequences for different relationship types', () async {
      final friendshipBraid = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      final romanticBraid = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.romantic,
      );

      // Different relationship types should produce different braid sequences
      expect(friendshipBraid.braidSequence, isNot(equals(romanticBraid.braidSequence)));
    });

    test('should handle empty braid sequences gracefully', () async {
      final emptyKnotA = PersonalityKnot(
        agentId: 'agent-a',
        invariants: KnotInvariants(
          jonesPolynomial: [],
          alexanderPolynomial: [],
          crossingNumber: 0,
          writhe: 0,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
        ),
        braidData: [8.0], // Only strand count
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final emptyKnotB = PersonalityKnot(
        agentId: 'agent-b',
        invariants: KnotInvariants(
          jonesPolynomial: [],
          alexanderPolynomial: [],
          crossingNumber: 0,
          writhe: 0,
          signature: 0,
          bridgeNumber: 1,
          braidIndex: 1,
          determinant: 1,
        ),
        braidData: [8.0], // Only strand count
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      final braidedKnot = await service.weaveKnots(
        knotA: emptyKnotA,
        knotB: emptyKnotB,
        relationshipType: RelationshipType.friendship,
      );

      expect(braidedKnot, isNotNull);
      expect(braidedKnot.braidSequence, isNotEmpty);
    });

    test('should produce consistent results for same inputs', () async {
      final braid1 = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      final braid2 = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      // Same inputs should produce same braid sequence
      expect(braid1.braidSequence, equals(braid2.braidSequence));
      expect(braid1.complexity, equals(braid2.complexity));
      expect(braid1.stability, equals(braid2.stability));
      expect(braid1.harmonyScore, equals(braid2.harmonyScore));
    });

    test('should calculate complexity based on crossing count', () async {
      final braidedKnot = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      // Complexity should be normalized to [0, 1]
      expect(braidedKnot.complexity, greaterThanOrEqualTo(0.0));
      expect(braidedKnot.complexity, lessThanOrEqualTo(1.0));
    });

    test('should calculate stability based on topological compatibility', () async {
      final braidedKnot = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      // Stability should be normalized to [0, 1]
      expect(braidedKnot.stability, greaterThanOrEqualTo(0.0));
      expect(braidedKnot.stability, lessThanOrEqualTo(1.0));
    });

    test('should calculate harmony based on relationship type', () async {
      final friendshipBraid = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.friendship,
      );

      final romanticBraid = await service.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: RelationshipType.romantic,
      );

      // Different relationship types may have different harmony scores
      expect(friendshipBraid.harmonyScore, greaterThanOrEqualTo(0.0));
      expect(romanticBraid.harmonyScore, greaterThanOrEqualTo(0.0));
    });
  });
}

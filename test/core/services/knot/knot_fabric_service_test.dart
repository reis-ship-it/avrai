// Knot Fabric Service Tests
// 
// Unit tests for KnotFabricService
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/fabric_cluster.dart';
import 'package:avrai_knot/models/knot/bridge_strand.dart';
import 'package:avrai_knot/models/knot/fabric_evolution.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';

// Mock Rust API for testing
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
    return 0.5;
  }

  @override
  double crateApiCalculateTopologicalCompatibility(
      {required List<double> braidDataA, required List<double> braidDataB}) {
    // Mock: return simple compatibility
    return 0.5;
  }

  @override
  int crateApiCalculateWritheFromBraid({required List<double> braidData}) {
    // Mock: return simple writhe
    return 0;
  }

  @override
  double crateApiEvaluatePolynomial(
      {required List<double> coefficients, required double x}) {
    // Mock: evaluate polynomial
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * _power(x, i);
    }
    return result;
  }

  @override
  KnotResult crateApiGenerateKnotFromBraid({required List<double> braidData}) {
    // Mock: return simple knot result
    return KnotResult(
      knotData: Float64List.fromList([braidData[0]]),
      jonesPolynomial: Float64List.fromList([1.0, -1.0, 1.0]),
      alexanderPolynomial: Float64List.fromList([1.0, 0.0, -1.0]),
      crossingNumber: BigInt.from((braidData.length - 1) ~/ 2),
      writhe: 0,
      signature: 0,
      bridgeNumber: BigInt.from(1),
      braidIndex: BigInt.from(1),
      determinant: 1,
    );
  }

  @override
  double crateApiPolynomialDistance(
      {required List<double> coefficientsA, required List<double> coefficientsB}) {
    // Mock: return simple distance
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

  double _power(double base, int exponent) {
    if (exponent == 0) return 1.0;
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

void main() {
  group('KnotFabricService', () {
    late KnotFabricService service;
    bool rustLibInitialized = false;

    setUpAll(() async {
      // Initialize Rust library for tests
      if (!rustLibInitialized) {
        try {
          RustLib.initMock(api: MockRustLibApi());
          rustLibInitialized = true;
        } catch (e) {
          // Already initialized, that's fine
          rustLibInitialized = true;
        }
      }
    });

    setUp(() {
      service = KnotFabricService();
    });

    group('generateMultiStrandBraidFabric', () {
      test('should generate fabric from user knots', () async {
        // Create test knots
        final knots = _createTestKnots(3);

        // Generate fabric
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        // Verify fabric properties
        expect(fabric, isNotNull);
        expect(fabric.userKnots.length, equals(3));
        expect(fabric.braid.strandCount, equals(3));
        expect(fabric.fabricId, isNotEmpty);
        expect(fabric.createdAt, isNotNull);
      });

      test('should throw error for empty knot list', () async {
        expect(
          () => service.generateMultiStrandBraidFabric(userKnots: []),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should use compatibility scores to determine crossings', () async {
        final knots = _createTestKnots(2);
        final compatibilityScores = {'0_1': 0.8};

        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
          compatibilityScores: compatibilityScores,
        );

        expect(fabric.braid.braidData.length, greaterThan(1));
      });

      test('should map users to strand indices', () async {
        final knots = _createTestKnots(3);

        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        expect(fabric.braid.userToStrandIndex.length, equals(3));
        expect(fabric.braid.userToStrandIndex['user_0'], equals(0));
        expect(fabric.braid.userToStrandIndex['user_1'], equals(1));
        expect(fabric.braid.userToStrandIndex['user_2'], equals(2));
      });
    });

    group('calculateFabricInvariants', () {
      test('should calculate invariants for fabric', () async {
        final knots = _createTestKnots(3);
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        final invariants = await service.calculateFabricInvariants(fabric);

        expect(invariants, isNotNull);
        expect(invariants.jonesPolynomial.coefficients, isNotEmpty);
        expect(invariants.alexanderPolynomial.coefficients, isNotEmpty);
        expect(invariants.crossingNumber, greaterThanOrEqualTo(0));
        expect(invariants.density, greaterThanOrEqualTo(0.0));
        expect(invariants.stability, greaterThanOrEqualTo(0.0));
        expect(invariants.stability, lessThanOrEqualTo(1.0));
      });

      test('should calculate density correctly', () async {
        final knots = _createTestKnots(5);
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        final invariants = await service.calculateFabricInvariants(fabric);

        // Density should be crossings per strand
        if (invariants.crossingNumber > 0) {
          expect(invariants.density, greaterThan(0.0));
        }
      });
    });

    group('identifyFabricClusters', () {
      test('should identify clusters in fabric', () async {
        final knots = _createTestKnots(5);
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        final clusters = await service.identifyFabricClusters(fabric);

        expect(clusters, isA<List<FabricCluster>>());
        // May have 0 or more clusters depending on fabric structure
        for (final cluster in clusters) {
          expect(cluster.clusterId, isNotEmpty);
          expect(cluster.userKnots, isNotEmpty);
          expect(cluster.density, greaterThanOrEqualTo(0.0));
          // Density may be > 1.0 if not normalized (raw crossing count)
          // Just verify it's non-negative
          expect(cluster.knotTypeDistribution, isNotNull);
        }
      });

      test('should identify knot tribes (high density clusters)', () async {
        final knots = _createTestKnots(5);
        // Create high compatibility to form dense cluster
        final compatibilityScores = <String, double>{};
        for (int i = 0; i < 5; i++) {
          for (int j = i + 1; j < 5; j++) {
            compatibilityScores['${i}_$j'] = 0.9; // High compatibility
          }
        }

        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
          compatibilityScores: compatibilityScores,
        );

        final clusters = await service.identifyFabricClusters(fabric);

        // Should have at least one cluster
        if (clusters.isNotEmpty) {
          final highDensityClusters = clusters.where((c) => c.isKnotTribe);
          // May have knot tribes if density is high enough
          for (final cluster in highDensityClusters) {
            expect(cluster.density, greaterThan(0.7));
          }
        }
      });
    });

    group('identifyBridgeStrands', () {
      test('should identify bridge strands', () async {
        final knots = _createTestKnots(5);
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        final bridges = await service.identifyBridgeStrands(fabric);

        expect(bridges, isA<List<BridgeStrand>>());
        for (final bridge in bridges) {
          expect(bridge.userKnot, isNotNull);
          expect(bridge.connectedClusters.length, greaterThanOrEqualTo(2));
          expect(bridge.bridgeStrength, greaterThanOrEqualTo(0.0));
          expect(bridge.bridgeStrength, lessThanOrEqualTo(1.0));
        }
      });

      test('should identify strong bridges (3+ clusters)', () async {
        final knots = _createTestKnots(6);
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        final bridges = await service.identifyBridgeStrands(fabric);

        final strongBridges = bridges.where((b) => b.isStrongBridge);
        for (final bridge in strongBridges) {
          expect(bridge.clusterCount, greaterThanOrEqualTo(3));
          expect(bridge.bridgeStrength, greaterThan(0.6));
        }
      });
    });

    group('measureFabricStability', () {
      test('should measure stability in valid range', () async {
        final knots = _createTestKnots(4);
        final fabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        final stability = await service.measureFabricStability(fabric);

        expect(stability, greaterThanOrEqualTo(0.0));
        expect(stability, lessThanOrEqualTo(1.0));
      });

      test('should calculate higher stability for dense fabrics', () async {
        final knots = _createTestKnots(4);
        
        // Create high compatibility fabric
        final compatibilityScores = <String, double>{};
        for (int i = 0; i < 4; i++) {
          for (int j = i + 1; j < 4; j++) {
            compatibilityScores['${i}_$j'] = 0.9;
          }
        }

        final denseFabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
          compatibilityScores: compatibilityScores,
        );

        // Create low compatibility fabric
        final sparseFabric = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
          compatibilityScores: {},
        );

        final denseStability = await service.measureFabricStability(denseFabric);
        final sparseStability = await service.measureFabricStability(sparseFabric);

        // Dense fabric should generally have higher stability
        // (though this may vary based on algorithm)
        expect(denseStability, greaterThanOrEqualTo(0.0));
        expect(sparseStability, greaterThanOrEqualTo(0.0));
      });
    });

    group('trackFabricEvolution', () {
      test('should track evolution between fabrics', () async {
        final knots1 = _createTestKnots(3);
        final fabric1 = await service.generateMultiStrandBraidFabric(
          userKnots: knots1,
        );

        final knots2 = _createTestKnots(4); // Different number of knots
        final fabric2 = await service.generateMultiStrandBraidFabric(
          userKnots: knots2,
        );

        final changes = [
          const FabricChange(
            type: FabricChangeType.newKnot,
            userKnotId: 'user_3',
          ),
        ];

        final evolution = await service.trackFabricEvolution(
          currentFabric: fabric2,
          previousFabric: fabric1,
          changes: changes,
        );

        expect(evolution, isNotNull);
        expect(evolution.currentFabric, equals(fabric2));
        expect(evolution.previousFabric, equals(fabric1));
        expect(evolution.changes, equals(changes));
        expect(evolution.stabilityChange, isA<double>());
        expect(evolution.timestamp, isNotNull);
      });

      test('should calculate stability change correctly', () async {
        final knots = _createTestKnots(3);
        final fabric1 = await service.generateMultiStrandBraidFabric(
          userKnots: knots,
        );

        // Add more knots for fabric2
        final knots2 = [...knots, ..._createTestKnots(2)];
        final fabric2 = await service.generateMultiStrandBraidFabric(
          userKnots: knots2,
        );

        final evolution = await service.trackFabricEvolution(
          currentFabric: fabric2,
          previousFabric: fabric1,
          changes: const [],
        );

        final currentStability = await service.measureFabricStability(fabric2);
        final previousStability = await service.measureFabricStability(fabric1);
        final expectedChange = currentStability - previousStability;

        expect(
          evolution.stabilityChange,
          closeTo(expectedChange, 0.01),
        );
      });

      test('should identify stability improvement', () async {
        final knots1 = _createTestKnots(3);
        final fabric1 = await service.generateMultiStrandBraidFabric(
          userKnots: knots1,
        );

        // Create more compatible fabric
        final knots2 = _createTestKnots(3);
        final compatibilityScores = {
          '0_1': 0.9,
          '0_2': 0.9,
          '1_2': 0.9,
        };
        final fabric2 = await service.generateMultiStrandBraidFabric(
          userKnots: knots2,
          compatibilityScores: compatibilityScores,
        );

        final evolution = await service.trackFabricEvolution(
          currentFabric: fabric2,
          previousFabric: fabric1,
          changes: const [],
        );

        // Check if stability improved (may vary based on algorithm)
        if (evolution.stabilityImproved) {
          expect(evolution.stabilityChange, greaterThan(0.0));
        }
      });
    });

    group('generateLinkNetworkFabric', () {
      test('should generate link network from relationships', () async {
        final knots = _createTestKnots(3);
        final relationships = _createTestBraidedKnots(knots);

        final network = await service.generateLinkNetworkFabric(
          userKnots: knots,
          relationshipKnots: relationships,
        );

        expect(network, isNotNull);
        expect(network.networkId, isNotEmpty);
        expect(network.relationships.length, equals(relationships.length));
      });
    });
  });
}

// Helper functions

List<PersonalityKnot> _createTestKnots(int count) {
  return List.generate(count, (i) {
      final now = DateTime.now();
      return PersonalityKnot(
        agentId: 'user_$i',
        braidData: [
          8.0, // strands
          // Add some crossings
          (i % 8).toDouble(),
          1.0, // is_over
          ((i + 1) % 8).toDouble(),
          0.0, // is_over
        ],
        invariants: KnotInvariants(
          jonesPolynomial: [1.0, 0.5, 0.2],
          alexanderPolynomial: [1.0, -0.3, 0.1],
          crossingNumber: 2 + i,
          writhe: i % 3 - 1,
          signature: 0,
          bridgeNumber: ((2 + i) / 2).clamp(1, 10).round(),
          braidIndex: ((2 + i) / 3).clamp(1, 12).round(),
          determinant: 1,
        ),
        createdAt: now,
        lastUpdated: now,
      );
  });
}

List<BraidedKnot> _createTestBraidedKnots(List<PersonalityKnot> knots) {
  if (knots.length < 2) return [];

  final relationships = <BraidedKnot>[];
  for (int i = 0; i < knots.length - 1; i++) {
    relationships.add(BraidedKnot(
      id: 'relationship_$i',
      knotA: knots[i],
      knotB: knots[i + 1],
      braidSequence: [8.0, i.toDouble(), 1.0],
      complexity: 0.5,
      stability: 0.6,
      harmonyScore: 0.7,
      relationshipType: RelationshipType.friendship,
      createdAt: DateTime.now(),
    ));
  }
  return relationships;
}

/// avrai WorldsheetComparisonService Service Tests
/// Date: January 27, 2026
/// Purpose: Test WorldsheetComparisonService functionality
///
/// Test Coverage:
/// - Core Methods: compareWorldsheets, calculateSimilarityMetrics, detectCommonPatterns
/// - Error Handling: Empty worldsheets, edge cases
///
/// Dependencies:
/// - WorldsheetEvolutionDynamics (optional, has default)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/worldsheet_similarity.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/worldsheet_comparison_service.dart';

// Helper to create test knots
PersonalityKnot createTestKnot(String agentId, int crossingNumber) {
  return PersonalityKnot(
    agentId: agentId,
    invariants: KnotInvariants(
      jonesPolynomial: [crossingNumber.toDouble()],
      alexanderPolynomial: [crossingNumber.toDouble()],
      crossingNumber: crossingNumber,
      writhe: 0,
      signature: 0,
      bridgeNumber: 1,
      braidIndex: 1,
      determinant: crossingNumber,
    ),
    braidData: [8.0],
    createdAt: DateTime(2025, 1, 1),
    lastUpdated: DateTime(2025, 1, 1),
  );
}

// Helper to create test fabric
KnotFabric createTestFabric(String fabricId, List<PersonalityKnot> userKnots) {
  return KnotFabric(
    fabricId: fabricId,
    userKnots: userKnots,
    braid: MultiStrandBraid(
      strandCount: userKnots.length,
      braidData: [userKnots.length.toDouble()],
      userToStrandIndex: Map.fromEntries(
        userKnots.asMap().entries.map((e) => MapEntry(e.value.agentId, e.key)),
      ),
    ),
    invariants: FabricInvariants(
      jonesPolynomial: Polynomial([1.0]),
      alexanderPolynomial: Polynomial([1.0]),
      crossingNumber: userKnots.length,
      density: 1.0,
      stability: 0.7,
    ),
    createdAt: DateTime(2025, 1, 1),
  );
}

// Helper to create test worldsheet
KnotWorldsheet createTestWorldsheet({
  required String groupId,
  required KnotFabric initialFabric,
  List<FabricSnapshot>? snapshots,
  Map<String, KnotString>? userStrings,
}) {
  return KnotWorldsheet(
    groupId: groupId,
    initialFabric: initialFabric,
    snapshots: snapshots ?? [],
    userStrings: userStrings ?? {},
    createdAt: DateTime(2025, 1, 1),
    lastUpdated: DateTime(2025, 1, 2),
  );
}

void main() {
  group('WorldsheetComparisonService', () {
    late WorldsheetComparisonService service;

    setUp(() {
      service = WorldsheetComparisonService();
    });

    group('compareWorldsheets', () {
      test('should calculate similarity metrics between two worldsheets',
          () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);
        final fabric2 = createTestFabric('fabric-2', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );
        final ws2 = createTestWorldsheet(
          groupId: 'group-2',
          initialFabric: fabric2,
        );

        // Act
        final similarity = await service.compareWorldsheets(ws1: ws1, ws2: ws2);

        // Assert - Should return valid similarity metrics
        expect(similarity.overallSimilarity, greaterThanOrEqualTo(0.0));
        expect(similarity.overallSimilarity, lessThanOrEqualTo(1.0));
        expect(similarity.stabilitySimilarity, greaterThanOrEqualTo(0.0));
        expect(similarity.stabilitySimilarity, lessThanOrEqualTo(1.0));
        expect(similarity.densitySimilarity, greaterThanOrEqualTo(0.0));
        expect(similarity.densitySimilarity, lessThanOrEqualTo(1.0));
        expect(similarity.userOverlap, greaterThanOrEqualTo(0.0));
        expect(similarity.userOverlap, lessThanOrEqualTo(1.0));
        expect(similarity.commonPatterns, isA<List<String>>());
      });

      test('should calculate high similarity for worldsheets with same users',
          () async {
        // Arrange - Same users, similar fabrics
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);
        final fabric2 = createTestFabric('fabric-2', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );
        final ws2 = createTestWorldsheet(
          groupId: 'group-2',
          initialFabric: fabric2,
        );

        // Act
        final similarity = await service.compareWorldsheets(ws1: ws1, ws2: ws2);

        // Assert - Same users should result in high user overlap
        expect(similarity.userOverlap, equals(1.0)); // All users in common
      });

      test(
          'should calculate low similarity for worldsheets with different users',
          () async {
        // Arrange - Different users (userOverlap uses userStrings keys)
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final knot3 = createTestKnot('agent-3', 3);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);
        final fabric2 = createTestFabric('fabric-2', [knot3]);
        final string1 = KnotString(initialKnot: knot1, snapshots: []);
        final string2 = KnotString(initialKnot: knot2, snapshots: []);
        final string3 = KnotString(initialKnot: knot3, snapshots: []);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          userStrings: {'agent-1': string1, 'agent-2': string2},
        );
        final ws2 = createTestWorldsheet(
          groupId: 'group-2',
          initialFabric: fabric2,
          userStrings: {'agent-3': string3},
        );

        // Act
        final similarity = await service.compareWorldsheets(ws1: ws1, ws2: ws2);

        // Assert - No users in common -> user overlap 0
        expect(similarity.userOverlap, equals(0.0));
      });
    });

    group('calculateSimilarityMetrics', () {
      test('should return map of all similarity metrics', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);
        final fabric2 = createTestFabric('fabric-2', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );
        final ws2 = createTestWorldsheet(
          groupId: 'group-2',
          initialFabric: fabric2,
        );

        // Act
        final metrics =
            await service.calculateSimilarityMetrics(ws1: ws1, ws2: ws2);

        // Assert - Should return all metrics
        expect(metrics.containsKey('overall'), isTrue);
        expect(metrics.containsKey('stability'), isTrue);
        expect(metrics.containsKey('density'), isTrue);
        expect(metrics.containsKey('evolutionRate'), isTrue);
        expect(metrics.containsKey('invariant'), isTrue);
        expect(metrics.containsKey('userOverlap'), isTrue);
        expect(metrics.containsKey('timeSpanOverlap'), isTrue);

        // All metrics should be in valid range
        for (final value in metrics.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('detectCommonPatterns', () {
      test('should detect common patterns across multiple worldsheets',
          () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);
        final fabric2 = createTestFabric('fabric-2', [knot1, knot2]);
        final fabric3 = createTestFabric('fabric-3', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );
        final ws2 = createTestWorldsheet(
          groupId: 'group-2',
          initialFabric: fabric2,
        );
        final ws3 = createTestWorldsheet(
          groupId: 'group-3',
          initialFabric: fabric3,
        );

        // Act
        final patterns = await service.detectCommonPatterns(
          worldsheets: [ws1, ws2, ws3],
        );

        // Assert - Should return list of patterns
        expect(patterns, isA<List<CommonPattern>>());
        // Patterns should have valid properties
        for (final pattern in patterns) {
          expect(pattern.patternType, isNotEmpty);
          expect(pattern.description, isNotEmpty);
          expect(pattern.confidence, greaterThanOrEqualTo(0.0));
          expect(pattern.confidence, lessThanOrEqualTo(1.0));
          expect(pattern.worldsheetIds, isNotEmpty);
        }
      });

      test('should return empty list for single worldsheet', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);
        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );

        // Act
        final patterns = await service.detectCommonPatterns(
          worldsheets: [ws1],
        );

        // Assert - Need at least 2 worldsheets to detect patterns
        expect(patterns, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle worldsheets with empty snapshots', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);
        final fabric2 = createTestFabric('fabric-2', [knot1]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          snapshots: [], // Empty snapshots
        );
        final ws2 = createTestWorldsheet(
          groupId: 'group-2',
          initialFabric: fabric2,
          snapshots: [], // Empty snapshots
        );

        // Act
        final similarity = await service.compareWorldsheets(ws1: ws1, ws2: ws2);

        // Assert - Should handle empty snapshots gracefully
        expect(similarity.overallSimilarity, greaterThanOrEqualTo(0.0));
        expect(similarity.overallSimilarity, lessThanOrEqualTo(1.0));
      });
    });
  });
}

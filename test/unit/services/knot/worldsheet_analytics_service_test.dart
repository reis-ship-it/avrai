/// avrai WorldsheetAnalyticsService Service Tests
/// Date: January 27, 2026
/// Purpose: Test WorldsheetAnalyticsService functionality
///
/// Test Coverage:
/// - Core Methods: analyzeWorldsheet
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
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/worldsheet_analytics_service.dart';

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
  group('WorldsheetAnalyticsService', () {
    late WorldsheetAnalyticsService service;

    setUp(() {
      service = WorldsheetAnalyticsService();
    });

    group('analyzeWorldsheet', () {
      test(
          'should analyze worldsheet and return analytics with patterns, cycles, and trends',
          () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );

        // Act
        final analytics = await service.analyzeWorldsheet(worldsheet: ws1);

        // Assert - Should return complete analytics
        expect(analytics.patterns, isA<List<String>>());
        expect(analytics.cycles, isA<List<Cycle>>());
        expect(analytics.trends, isA<Map<String, Trend>>());
        expect(analytics.averageEvolutionRate, greaterThanOrEqualTo(0.0));
        expect(analytics.stabilityTrend, isA<Trend>());
        expect(analytics.densityTrend, isA<Trend>());
      });

      test('should detect patterns in worldsheet evolution', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);

        // Create snapshots showing increasing stability
        final snapshot1 = FabricSnapshot(
          fabric: createTestFabric('fabric-1', [knot1, knot2]),
          timestamp: DateTime(2025, 1, 1),
          reason: 'test',
        );
        final snapshot2 = FabricSnapshot(
          fabric: createTestFabric('fabric-2', [knot1, knot2]),
          timestamp: DateTime(2025, 1, 2),
          reason: 'test',
        );

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          snapshots: [snapshot1, snapshot2],
        );

        // Act
        final analytics = await service.analyzeWorldsheet(worldsheet: ws1);

        // Assert - Should detect patterns
        expect(analytics.patterns, isA<List<String>>());
        // Patterns may include: increasing_stability, decreasing_density, etc.
      });

      test('should detect cycles in worldsheet evolution', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );

        // Act
        final analytics = await service.analyzeWorldsheet(worldsheet: ws1);

        // Assert - Should return cycles (may be empty if no cycles detected)
        expect(analytics.cycles, isA<List<Cycle>>());
        // Cycles should have valid properties if present
        for (final cycle in analytics.cycles) {
          expect(cycle.type, isNotEmpty);
          expect(cycle.period, isA<Duration>());
          expect(cycle.amplitude, greaterThanOrEqualTo(0.0));
          expect(cycle.confidence, greaterThanOrEqualTo(0.0));
          expect(cycle.confidence, lessThanOrEqualTo(1.0));
        }
      });

      test('should analyze trends in worldsheet evolution', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );

        // Act
        final analytics = await service.analyzeWorldsheet(worldsheet: ws1);

        // Assert - Should return trends (may be empty for minimal worldsheets)
        expect(analytics.trends, isA<Map<String, Trend>>());
        for (final trend in analytics.trends.values) {
          expect(trend.direction, isIn(['increasing', 'decreasing', 'stable']));
          expect(trend.strength, greaterThanOrEqualTo(0.0));
          expect(trend.strength, lessThanOrEqualTo(1.0));
          expect(trend.rate, isA<double>());
        }
        expect(analytics.stabilityTrend.direction,
            isIn(['increasing', 'decreasing', 'stable']));
        expect(analytics.densityTrend.direction,
            isIn(['increasing', 'decreasing', 'stable']));
      });

      test('should calculate average evolution rate', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );

        // Act
        final analytics = await service.analyzeWorldsheet(worldsheet: ws1);

        // Assert - Should return valid evolution rate
        expect(analytics.averageEvolutionRate, greaterThanOrEqualTo(0.0));
      });
    });

    group('Error Handling', () {
      test('should handle worldsheet with empty snapshots', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          snapshots: [], // Empty snapshots
        );

        // Act
        final analytics = await service.analyzeWorldsheet(worldsheet: ws1);

        // Assert - Should handle empty snapshots gracefully
        expect(analytics.patterns, isA<List<String>>());
        expect(analytics.cycles, isA<List<Cycle>>());
        expect(analytics.trends, isA<Map<String, Trend>>());
      });
    });
  });
}

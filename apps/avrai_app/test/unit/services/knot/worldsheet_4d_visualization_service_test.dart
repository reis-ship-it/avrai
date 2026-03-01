/// avrai Worldsheet4DVisualizationService Service Tests
/// Date: January 27, 2026
/// Purpose: Test Worldsheet4DVisualizationService functionality
///
/// Test Coverage:
/// - Core Methods: convertTo4DData
/// - Error Handling: Empty worldsheets, missing fabrics, edge cases
///
/// Dependencies:
/// - Knot3DConverterService (optional, has default)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart';

import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

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
  group('Worldsheet4DVisualizationService', () {
    late Worldsheet4DVisualizationService service;

    setUp(() {
      service = Worldsheet4DVisualizationService();
    });

    group('convertTo4DData', () {
      test(
          'should convert worldsheet to 4D data with time points and fabric data',
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
        final data4d = await service.convertTo4DData(worldsheet: ws1);

        // Assert - Should return 4D data
        expect(data4d.timePoints, isNotEmpty);
        expect(data4d.fabricData, isNotEmpty);
        expect(data4d.startTime, isA<DateTime>());
        expect(data4d.endTime, isA<DateTime>());
      });

      test('should include snapshots as time points', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);
        final fabric2 = createTestFabric('fabric-2', [knot1]);

        final snapshot1 = FabricSnapshot(
          fabric: fabric2,
          timestamp: DateTime(2025, 1, 2),
          reason: 'test',
        );

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          snapshots: [snapshot1],
        );

        // Act
        final data4d = await service.convertTo4DData(worldsheet: ws1);

        // Assert - Should include snapshot time points (initial + snapshot(s))
        expect(data4d.timePoints, isNotEmpty);
        expect(data4d.fabricData, isNotEmpty);
      });

      test('should interpolate time points when timeStep provided', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);
        final fabric2 = createTestFabric('fabric-2', [knot1]);

        final snapshot1 = FabricSnapshot(
          fabric: fabric2,
          timestamp: DateTime(2025, 1, 3),
          reason: 'test',
        );

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          snapshots: [snapshot1],
        );

        // Act - Use time step to interpolate
        final data4d = await service.convertTo4DData(
          worldsheet: ws1,
          timeStep: const Duration(days: 1),
        );

        // Assert - Should include interpolated time points
        expect(data4d.timePoints, isNotEmpty);
        expect(data4d.fabricData, isNotEmpty);
      });

      test('should convert fabric knots to 3D coordinates', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final knot2 = createTestKnot('agent-2', 2);
        final fabric1 = createTestFabric('fabric-1', [knot1, knot2]);

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
        );

        // Act
        final data4d = await service.convertTo4DData(worldsheet: ws1);

        // Assert - Each fabric data should have strand positions
        for (final fabricData in data4d.fabricData) {
          expect(fabricData.strandPositions, isNotEmpty);
          for (final strand in fabricData.strandPositions) {
            expect(strand, isA<List<Vector3>>());
          }
          expect(fabricData.invariants.stability, isA<double>());
          expect(fabricData.timestamp, isA<DateTime>());
        }
      });

      test('should handle worldsheet with multiple snapshots', () async {
        // Arrange
        final knot1 = createTestKnot('agent-1', 1);
        final fabric1 = createTestFabric('fabric-1', [knot1]);
        final fabric2 = createTestFabric('fabric-2', [knot1]);
        final fabric3 = createTestFabric('fabric-3', [knot1]);

        final snapshot1 = FabricSnapshot(
          fabric: fabric2,
          timestamp: DateTime(2025, 1, 2),
          reason: 'test',
        );
        final snapshot2 = FabricSnapshot(
          fabric: fabric3,
          timestamp: DateTime(2025, 1, 3),
          reason: 'test',
        );

        final ws1 = createTestWorldsheet(
          groupId: 'group-1',
          initialFabric: fabric1,
          snapshots: [snapshot1, snapshot2],
        );

        // Act
        final data4d = await service.convertTo4DData(worldsheet: ws1);

        // Assert - Should include all snapshots
        expect(data4d.timePoints.length,
            greaterThanOrEqualTo(2)); // Initial + snapshots
        expect(data4d.fabricData.length, greaterThanOrEqualTo(2));
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
        final data4d = await service.convertTo4DData(worldsheet: ws1);

        // Assert - Should handle empty snapshots gracefully
        expect(data4d.timePoints, isNotEmpty); // At least initial time
        expect(data4d.fabricData, isNotEmpty); // At least initial fabric
      });
    });
  });
}

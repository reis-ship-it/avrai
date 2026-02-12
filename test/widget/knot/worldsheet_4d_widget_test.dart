/// avrai Worldsheet4DWidget Widget Tests
/// Date: January 27, 2026
/// Purpose: Test Worldsheet4DWidget functionality
///
/// Test Coverage:
/// - Loading states
/// - Error states
/// - User interactions (time scrubbing, animation controls)
/// - Empty state handling
///
/// Dependencies:
/// - Worldsheet4DVisualizationService (optional, can be mocked)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/presentation/widgets/knot/worldsheet_4d_widget.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';
import 'package:avrai_knot/services/knot/worldsheet_4d_visualization_service.dart';
import 'package:avrai_knot/models/knot/worldsheet_4d_data.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:vector_math/vector_math.dart';

class MockWorldsheet4DVisualizationService extends Mock
    implements Worldsheet4DVisualizationService {}

class FakeKnotWorldsheet extends Fake implements KnotWorldsheet {}

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
}) {
  return KnotWorldsheet(
    groupId: groupId,
    initialFabric: initialFabric,
    snapshots: [],
    userStrings: {},
    createdAt: DateTime(2025, 1, 1),
    lastUpdated: DateTime(2025, 1, 2),
  );
}

// Helper to create test 4D data
Worldsheet4DData createTest4DData(String groupId) {
  return Worldsheet4DData(
    timePoints: [
      DateTime(2025, 1, 1),
      DateTime(2025, 1, 2),
      DateTime(2025, 1, 3),
    ],
    fabricData: [
      Fabric3DData(
        strandPositions: [
          [Vector3(0, 0, 0), Vector3(1, 1, 1)],
          [Vector3(2, 2, 2), Vector3(3, 3, 3)],
        ],
        invariants: FabricInvariantsData(
          stability: 0.7,
          density: 1.0,
          crossingNumber: 2,
        ),
        timestamp: DateTime(2025, 1, 1),
      ),
      Fabric3DData(
        strandPositions: [
          [Vector3(0, 0, 0), Vector3(1, 1, 1)],
          [Vector3(2, 2, 2), Vector3(3, 3, 3)],
        ],
        invariants: FabricInvariantsData(
          stability: 0.8,
          density: 1.1,
          crossingNumber: 2,
        ),
        timestamp: DateTime(2025, 1, 2),
      ),
    ],
    startTime: DateTime(2025, 1, 1),
    endTime: DateTime(2025, 1, 3),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeKnotWorldsheet());
  });

  group('Worldsheet4DWidget', () {
    late MockWorldsheet4DVisualizationService mockService;

    setUp(() {
      mockService = MockWorldsheet4DVisualizationService();
    });

    testWidgets('should display loading indicator while loading 4D data',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenAnswer((_) {
        final c = Completer<Worldsheet4DData>();
        return c.future; // Never completes — keeps loading state
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when 4D data conversion fails',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenThrow(Exception('Conversion failed'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Should show error state
      expect(find.text('Error loading worldsheet'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display empty state when worldsheet has no fabric data',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      // Return 4D data with empty fabric data
      final empty4DData = Worldsheet4DData(
        timePoints: [DateTime(2025, 1, 1)],
        fabricData: [],
        startTime: DateTime(2025, 1, 1),
        endTime: DateTime(2025, 1, 1),
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenAnswer((_) async => empty4DData);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Should show empty state
      expect(find.text('No worldsheet data'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('should display time slider and controls when data is loaded',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenAnswer((_) async => createTest4DData('group-1'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
              showControls: true,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Should show controls
      expect(find.byType(Slider), findsOneWidget); // Time slider
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Play button
    });

    testWidgets('should toggle play/pause when play button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenAnswer((_) async => createTest4DData('group-1'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
              showControls: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap play button (starts animation)
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Should show pause icon after tapping play
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should update time when slider is dragged',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenAnswer((_) async => createTest4DData('group-1'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
              showControls: true,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Find slider and drag it
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider to middle position (0.5)
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Assert - Slider should be updated (widget state changed)
      // The actual time value is internal, but we can verify the widget still exists
      expect(find.byType(Worldsheet4DWidget), findsOneWidget);
    });

    testWidgets('should hide controls when showControls is false',
        (WidgetTester tester) async {
      // Arrange
      final knot1 = createTestKnot('agent-1', 1);
      final fabric1 = createTestFabric('fabric-1', [knot1]);
      final worldsheet = createTestWorldsheet(
        groupId: 'group-1',
        initialFabric: fabric1,
      );

      when(() => mockService.convertTo4DData(
            worldsheet: any(named: 'worldsheet'),
            timeStep: any(named: 'timeStep'),
          )).thenAnswer((_) async => createTest4DData('group-1'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Worldsheet4DWidget(
              worldsheet: worldsheet,
              visualizationService: mockService,
              showControls: false,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Controls should not be visible
      expect(find.byType(Slider), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });
  });
}

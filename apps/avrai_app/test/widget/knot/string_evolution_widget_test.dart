/// avrai StringEvolutionWidget Widget Tests
/// Date: January 27, 2026
/// Purpose: Test StringEvolutionWidget functionality
///
/// Test Coverage:
/// - Loading states
/// - Error states
/// - User interactions (play/pause, reset, property selection)
/// - Empty state handling
///
/// Dependencies:
/// - KnotEvolutionStringService (required)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/presentation/widgets/knot/string_evolution_widget.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/personality_knot.dart';

class MockKnotEvolutionStringService extends Mock
    implements KnotEvolutionStringService {}

// Helper to create test knot
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

// Helper to create test string
KnotString createTestString(PersonalityKnot initialKnot) {
  return KnotString(
    initialKnot: initialKnot,
    snapshots: [
      KnotSnapshot(
        timestamp: DateTime(2025, 1, 2),
        knot: createTestKnot(initialKnot.agentId, 2),
        reason: 'test',
      ),
      KnotSnapshot(
        timestamp: DateTime(2025, 1, 3),
        knot: createTestKnot(initialKnot.agentId, 3),
        reason: 'test',
      ),
    ],
  );
}

void main() {
  group('StringEvolutionWidget', () {
    late MockKnotEvolutionStringService mockService;

    setUp(() {
      mockService = MockKnotEvolutionStringService();
    });

    testWidgets('should display loading indicator while loading string',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => Future.delayed(
                const Duration(seconds: 1),
                () => createTestString(createTestKnot('agent-123', 1)),
              ));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when string loading fails',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockService.createStringFromHistory(any()))
          .thenThrow(Exception('Failed to load string'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Should show error state
      expect(find.text('Error loading string'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display empty state when string has no snapshots',
        (WidgetTester tester) async {
      // Arrange
      final emptyString = KnotString(
        initialKnot: createTestKnot('agent-123', 1),
        snapshots: [], // Empty snapshots
      );

      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => emptyString);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Should show empty state
      expect(find.text('No string evolution data'), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
    });

    testWidgets(
        'should display visualization and controls when string is loaded',
        (WidgetTester tester) async {
      // Arrange
      final string = createTestString(createTestKnot('agent-123', 1));

      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => string);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Assert - Should show visualization and controls
      expect(find.byType(CustomPaint), findsOneWidget); // Visualization
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Play button
      expect(find.byIcon(Icons.refresh), findsOneWidget); // Reset button
      expect(find.byType(DropdownButton<String>),
          findsOneWidget); // Property selector
    });

    testWidgets('should toggle play/pause when play button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final string = createTestString(createTestKnot('agent-123', 1));

      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => string);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Tap play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Assert - Should show pause icon after tapping play
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should reset animation when reset button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final string = createTestString(createTestKnot('agent-123', 1));

      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => string);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Start animation
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Tap reset button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert - Should show play icon (animation reset)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should change property when dropdown selection changes',
        (WidgetTester tester) async {
      // Arrange
      final string = createTestString(createTestKnot('agent-123', 1));

      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => string);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Find dropdown
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      // Tap dropdown to open
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select different property (writhe)
      await tester.tap(find.text('Writhe'));
      await tester.pumpAndSettle();

      // Assert - Widget should still be rendered (property changed)
      expect(find.byType(StringEvolutionWidget), findsOneWidget);
      expect(find.byType(CustomPaint),
          findsOneWidget); // Visualization still present
    });

    testWidgets('should display all three property options in dropdown',
        (WidgetTester tester) async {
      // Arrange
      final string = createTestString(createTestKnot('agent-123', 1));

      when(() => mockService.createStringFromHistory(any()))
          .thenAnswer((_) async => string);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringEvolutionWidget(
              agentId: 'agent-123',
              stringService: mockService,
            ),
          ),
        ),
      );

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Tap dropdown to open
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert - Should show all property options
      expect(find.text('Crossing Number'), findsOneWidget);
      expect(find.text('Writhe'), findsOneWidget);
      expect(find.text('Signature'), findsOneWidget);
    });
  });
}

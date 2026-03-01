import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/lists/spot_picker_dialog.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai_core/models/misc/list.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for SpotPickerDialog
/// Tests spot picker dialog functionality including search, selection, and filtering
void main() {
  group('SpotPickerDialog Widget Tests', () {
    late MockSpotsBloc mockSpotsBloc;

    setUp(() {
      mockSpotsBloc = MockSpotsBloc();
    });

    tearDown(() {
      mockSpotsBloc.close();
    });

    testWidgets('should display dialog with list title and initial UI elements',
        (WidgetTester tester) async {
      // Arrange: Create test list and spots
      final testList = WidgetTestHelpers.createTestList(
        id: 'list-123',
        name: 'Test List',
      );
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Restaurant', category: 'Food'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Verify dialog displays correctly
      expect(find.byType(SpotPickerDialog), findsOneWidget);
      expect(find.text('Add Spots to Test List'), findsOneWidget);
      expect(find.text('Search spots...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('should filter spots by search query',
        (WidgetTester tester) async {
      // Arrange: Create spots with different names
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Pizza Place', category: 'Food'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-3', name: 'Tea House', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Coffee');
      await tester.pumpAndSettle();

      // Assert: Only matching spots are displayed
      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('Pizza Place'), findsNothing);
      expect(find.text('Tea House'), findsNothing);
    });

    testWidgets('should exclude spots from excludedSpotIds',
        (WidgetTester tester) async {
      // Arrange: Create spots
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Pizza Place', category: 'Food'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-3', name: 'Tea House', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(
          list: testList,
          excludedSpotIds: const ['spot-1', 'spot-3'],
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Excluded spots are not displayed
      expect(find.text('Coffee Shop'), findsNothing);
      expect(find.text('Pizza Place'), findsOneWidget);
      expect(find.text('Tea House'), findsNothing);
    });

    testWidgets('should exclude spots already in list',
        (WidgetTester tester) async {
      // Arrange: Create spots and list with some spots already in it
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Pizza Place', category: 'Food'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-3', name: 'Tea House', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = SpotList(
        id: 'test-list-id',
        title: 'Test List',
        description: 'A test list',
        spots: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        spotIds: ['spot-1'], // spot-1 is already in the list
      );
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Spots already in list are not displayed
      expect(find.text('Coffee Shop'), findsNothing);
      expect(find.text('Pizza Place'), findsOneWidget);
      expect(find.text('Tea House'), findsOneWidget);
    });

    testWidgets('should toggle spot selection and update selected count',
        (WidgetTester tester) async {
      // Arrange: Create spots
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Pizza Place', category: 'Food'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Select first spot
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Assert: Selected count updates
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('0 selected'), findsNothing);

      // Act: Select second spot
      await tester.tap(checkboxes.last);
      await tester.pumpAndSettle();

      // Assert: Selected count updates to 2
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);

      // Act: Deselect first spot
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Assert: Selected count updates back to 1
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('2 selected'), findsNothing);
    });

    testWidgets('should dismiss dialog when cancel button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final navigatorObserver = NavigatorObserver();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        navigatorObserver: navigatorObserver,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => SpotPickerDialog(list: testList),
              );
            });
            return const Scaffold(body: SizedBox());
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Verify dialog is shown
      expect(find.byType(SpotPickerDialog), findsOneWidget);

      // Act: Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert: Dialog is dismissed
      expect(find.byType(SpotPickerDialog), findsNothing);
    });

    testWidgets('should dismiss dialog when close button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => SpotPickerDialog(list: testList),
              );
            });
            return const Scaffold(body: SizedBox());
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Verify dialog is shown
      expect(find.byType(SpotPickerDialog), findsOneWidget);

      // Act: Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert: Dialog is dismissed
      expect(find.byType(SpotPickerDialog), findsNothing);
    });

    testWidgets('should return selected spots when add button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Pizza Place', category: 'Food'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      List<String>? returnedSpots;

      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final result = await showDialog<List<String>>(
                context: context,
                builder: (context) => SpotPickerDialog(list: testList),
              );
              returnedSpots = result;
            });
            return const Scaffold(body: SizedBox());
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Select spots and tap add
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.tap(checkboxes.last);
      await tester.pumpAndSettle();

      // Find and tap the Add button (which shows count)
      final addButton = find.byType(ElevatedButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Assert: Dialog returns selected spot IDs
      expect(returnedSpots, isNotNull);
      expect(returnedSpots, hasLength(2));
      expect(returnedSpots, contains('spot-1'));
      expect(returnedSpots, contains('spot-2'));
    });

    testWidgets(
        'should show snackbar when add button is tapped with no selections',
        (WidgetTester tester) async {
      // Arrange
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => SpotPickerDialog(list: testList),
              );
            });
            return const Scaffold(body: SizedBox());
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap add button without selecting any spots
      final addButton = find.byType(ElevatedButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Assert: Snackbar is shown
      expect(find.text('Please select at least one spot'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Dialog should still be open
      expect(find.byType(SpotPickerDialog), findsOneWidget);
    });

    testWidgets('should clear search when clear button is tapped',
        (WidgetTester tester) async {
      // Arrange: Create spots
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
        WidgetTestHelpers.createTestSpot(
            id: 'spot-2', name: 'Pizza Place', category: 'Food'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Coffee');
      await tester.pumpAndSettle();

      // Verify search is active (only Coffee Shop visible)
      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('Pizza Place'), findsNothing);

      // Act: Tap clear button
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Assert: All spots are visible again
      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('Pizza Place'), findsOneWidget);
    });

    testWidgets('should display empty state when no spots match search',
        (WidgetTester tester) async {
      // Arrange
      final testSpots = [
        WidgetTestHelpers.createTestSpot(
            id: 'spot-1', name: 'Coffee Shop', category: 'Cafe'),
      ];

      mockSpotsBloc.setState(SpotsLoaded(
        testSpots,
        filteredSpots: testSpots,
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Enter search query that matches nothing
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonExistentSpot');
      await tester.pumpAndSettle();

      // Assert: Empty state is displayed
      expect(find.text('No spots found matching "nonexistentspot"'),
          findsOneWidget);
      expect(find.text('Try a different search term'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('should display empty state when no spots are available',
        (WidgetTester tester) async {
      // Arrange: No spots
      mockSpotsBloc.setState(SpotsLoaded(
        const [],
        filteredSpots: const [],
        respectedSpots: const [],
      ));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Empty state is displayed
      expect(find.text('No spots available to add'), findsOneWidget);
      expect(
          find.text('Create spots first to add them to lists'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('should display loading state while spots are loading',
        (WidgetTester tester) async {
      // Arrange: Set loading state
      mockSpotsBloc.setState(SpotsLoading());

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'should display error state and retry button when spots fail to load',
        (WidgetTester tester) async {
      // Arrange: Set error state
      mockSpotsBloc.setState(SpotsError('Failed to load spots'));

      final testList = WidgetTestHelpers.createTestList();
      final widget = WidgetTestHelpers.createTestableWidget(
        spotsBloc: mockSpotsBloc,
        child: SpotPickerDialog(list: testList),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Error state is displayed
      expect(find.text('Error: Failed to load spots'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Act: Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert: Retry button is present (verifies error handling works)
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

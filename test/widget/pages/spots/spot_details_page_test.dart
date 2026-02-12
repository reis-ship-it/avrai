import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:avrai/core/models/spots/spot.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for SpotDetailsPage
/// Tests spot details display, actions, and navigation
void main() {
  group('SpotDetailsPage Widget Tests', () {
    late MockListsBloc mockListsBloc;
    late Spot testSpot;

    setUp(() {
      mockListsBloc = MockListsBloc();
      testSpot = ModelFactories.createTestSpot(
        id: 'spot-123',
        name: 'Test Coffee Shop',
        category: 'Cafe',
      );
    });

    // Removed: Property assignment tests
    // Spot details page tests focus on business logic (spot name display, action buttons, category display, spot details), not property assignment

    testWidgets(
        'should display spot name in app bar, display edit and share buttons, display spot category, or display spot details',
        (WidgetTester tester) async {
      // Test business logic: Spot details page display
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: SpotDetailsPage(spot: testSpot),
        listsBloc: mockListsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      // Spot name is shown in both AppBar title and page header.
      expect(find.text('Test Coffee Shop'), findsNWidgets(2));
      expect(find.byIcon(Icons.edit), findsOneWidget);
      // Share affordance exists in the AppBar and as an on-page action button.
      expect(find.byIcon(Icons.share), findsNWidgets(2));
      expect(find.text('Cafe'), findsOneWidget);

      final detailedSpot = ModelFactories.createTestSpot(
        id: 'spot-456',
        name: 'Detailed Spot',
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: SpotDetailsPage(spot: detailedSpot),
        listsBloc: mockListsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      // Spot name is shown in both AppBar title and page header.
      expect(find.text('Detailed Spot'), findsNWidgets(2));
      // ModelFactories.createTestSpot uses a deterministic default description.
      expect(find.text('A test location for unit testing'), findsOneWidget);
    });
  });
}

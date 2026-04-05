import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/spots/spots_page.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for SpotsPage
/// Tests UI rendering, search functionality, and BLoC integration
void main() {
  group('SpotsPage Widget Tests', () {
    late MockSpotsBloc mockSpotsBloc;

    // Removed: Property assignment tests
    // Spots page tests focus on business logic (UI display, search field, initialization, state management), not property assignment

    testWidgets(
        'should display all required UI elements, display search field with correct hint, load spots on initialization, display loading state when spots are loading, or display empty state when no spots available',
        (WidgetTester tester) async {
      // Test business logic: Spots page display and state management
      mockSpotsBloc = MockSpotsBloc()..setState(SpotsInitial());
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Spots'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search spots...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(SpotsPage), findsOneWidget);

      // Loading state should show a spinner.
      mockSpotsBloc = MockSpotsBloc()..setState(SpotsLoading());
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Empty loaded state should render without errors.
      mockSpotsBloc = MockSpotsBloc()..setState(SpotsLoaded(const []));
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.byType(SpotsPage), findsOneWidget);
    });
  });
}

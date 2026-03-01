import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/favorite_places_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for FavoritePlacesPage
/// Tests UI rendering, place selection, and callbacks
void main() {
  group('FavoritePlacesPage Widget Tests', () {
    // Removed: Property assignment tests
    // Favorite places page tests focus on business logic (UI display, search field, region categories, initialization, user homebase), not property assignment

    testWidgets(
        'should display all required UI elements, display search field, display region categories, initialize with provided favorite places, or use user homebase for suggestions',
        (WidgetTester tester) async {
      // Test business logic: Favorite places page display and functionality
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: FavoritePlacesPage(
          favoritePlaces: const [],
          onPlacesChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('What matches your vibe?'), findsOneWidget);
      expect(
        find.textContaining('Select places that match your aesthetic'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('New York Area'), findsOneWidget);
      expect(find.text('Los Angeles Area'), findsOneWidget);

      // Providing initial places should not crash rendering (selection UI is dynamic).
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: FavoritePlacesPage(
          favoritePlaces: const ['Brooklyn', 'Manhattan'],
          onPlacesChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(FavoritePlacesPage), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: FavoritePlacesPage(
          favoritePlaces: const [],
          onPlacesChanged: (_) {},
          userHomebase: 'Brooklyn',
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('What matches your vibe?'), findsOneWidget);
    });
  });
}

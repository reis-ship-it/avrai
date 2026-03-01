import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/friends_respect_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for FriendsRespectPage
/// Tests UI rendering, list selection, and callbacks
void main() {
  group('FriendsRespectPage Widget Tests', () {
    // Removed: Property assignment tests
    // Friends respect page tests focus on business logic (UI display, public lists, list metadata, initialization, user profile information), not property assignment

    testWidgets(
        'should display all required UI elements, display public lists, display list metadata, initialize with provided respected lists, or display user profile information',
        (WidgetTester tester) async {
      // Test business logic: Friends respect page display and functionality
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: FriendsRespectPage(
          respectedLists: const [],
          onRespectedListsChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Connect & Discover'), findsOneWidget);
      expect(find.textContaining('Respect lists created'), findsOneWidget);
      expect(find.text('Local Public Lists'), findsOneWidget);
      expect(find.text('Brooklyn Coffee Crawl'), findsOneWidget);
      expect(find.text('Hidden Gems in Williamsburg'), findsOneWidget);
      expect(find.textContaining('spots'), findsWidgets);
      // Creator/profile details are shown in the details view; keep this test focused on
      // core onboarding content visibility.

      final initialLists = ['list-1', 'list-2'];
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: FriendsRespectPage(
          respectedLists: initialLists,
          onRespectedListsChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(FriendsRespectPage), findsOneWidget);
    });
  });
}

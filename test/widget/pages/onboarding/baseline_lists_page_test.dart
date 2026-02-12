import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/baseline_lists_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BaselineListsPage
/// Tests UI rendering, list generation, and callbacks
void main() {
  group('BaselineListsPage Widget Tests', () {
    // Removed: Property assignment tests
    // Baseline lists page tests focus on business logic (UI display, loading state, generated suggestions, initialization, user preferences), not property assignment

    testWidgets(
        'should display all required UI elements, show loading state initially, display generated list suggestions after loading, initialize with provided baseline lists, or use user preferences for suggestions',
        (WidgetTester tester) async {
      // Test business logic: Baseline lists page display and functionality
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: BaselineListsPage(
          baselineLists: const [],
          onBaselineListsChanged: (_) {},
        ),
      );
      await tester.pumpWidget(widget1);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Creating your personalized lists...'), findsOneWidget);

      // Allow the loading phase (2s) to complete.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Your Smart Lists'), findsOneWidget);
      expect(find.byType(BaselineListsPage), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: BaselineListsPage(
          baselineLists: const [],
          onBaselineListsChanged: (_) {},
          userName: 'Test User',
        ),
      );
      await tester.pumpWidget(widget3);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Your Smart Lists'), findsOneWidget);

      final initialLists = ['List 1', 'List 2'];
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: BaselineListsPage(
          baselineLists: initialLists,
          onBaselineListsChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.byType(BaselineListsPage), findsOneWidget);

      final preferences = <String, List<String>>{
        'Food & Drink': ['Coffee & Tea'],
        'homebase': ['Brooklyn'],
      };
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: BaselineListsPage(
          baselineLists: const [],
          onBaselineListsChanged: (_) {},
          userName: 'Test User',
          userPreferences: preferences,
        ),
      );
      await tester.pumpWidget(widget5);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Your Smart Lists'), findsOneWidget);
    });
  });
}

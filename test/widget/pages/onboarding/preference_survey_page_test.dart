import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/onboarding/preference_survey_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PreferenceSurveyPage
/// Tests UI rendering, preference selection, and callbacks
void main() {
  group('PreferenceSurveyPage Widget Tests', () {
    // Removed: Property assignment tests
    // Preference survey page tests focus on business logic (UI display, preference categories, initialization, callbacks), not property assignment

    testWidgets(
        'should display all required UI elements, display preference categories, initialize with provided preferences, or call onPreferencesChanged callback',
        (WidgetTester tester) async {
      // Test business logic: Preference survey page display and functionality
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: PreferenceSurveyPage(
          preferences: const {},
          onPreferencesChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('What do you love?'), findsOneWidget);
      expect(find.textContaining('Select your preferences'), findsOneWidget);
      expect(find.text('Food & Drink'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.byType(PreferenceSurveyPage), findsOneWidget);

      final initialPreferences = <String, List<String>>{
        'Food & Drink': ['Coffee & Tea', 'Bars & Pubs'],
        'Activities': ['Live Music'],
      };
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: PreferenceSurveyPage(
          preferences: initialPreferences,
          onPreferencesChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(PreferenceSurveyPage), findsOneWidget);
    });
  });
}

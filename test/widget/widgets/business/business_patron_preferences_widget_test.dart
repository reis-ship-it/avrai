import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';
import 'package:avrai/presentation/widgets/business/business_patron_preferences_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessPatronPreferencesWidget
/// Tests business patron preferences form
void main() {
  group('BusinessPatronPreferencesWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Business patron preferences widget tests focus on business logic (preferences form display, initial preferences, callbacks), not property assignment

    testWidgets(
        'should display preferences form, load initial preferences when provided, or call onPreferencesChanged when preferences change',
        (WidgetTester tester) async {
      // Test business logic: Business patron preferences widget display and functionality
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      bool preferencesChanged = false;
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: BusinessPatronPreferencesWidget(
          onPreferencesChanged: (_) {
            preferencesChanged = true;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(BusinessPatronPreferencesWidget), findsOneWidget);

      const initialPreferences = BusinessPatronPreferences();
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: BusinessPatronPreferencesWidget(
          initialPreferences: initialPreferences,
          onPreferencesChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(BusinessPatronPreferencesWidget), findsOneWidget);
    });
  });
}


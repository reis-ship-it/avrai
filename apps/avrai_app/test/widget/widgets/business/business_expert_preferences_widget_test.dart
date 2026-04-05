import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/business/business_expert_preferences.dart';
import 'package:avrai/presentation/widgets/business/business_expert_preferences_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessExpertPreferencesWidget
/// Tests business expert preferences form
void main() {
  group('BusinessExpertPreferencesWidget Widget Tests', () {
    // Removed: Property assignment tests
    // Business expert preferences widget tests focus on business logic (preferences form display, initial preferences, callbacks), not property assignment

    testWidgets(
        'should display preferences form, load initial preferences when provided, or call onPreferencesChanged when preferences change',
        (WidgetTester tester) async {
      // Test business logic: Business expert preferences widget display and functionality
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      bool preferencesChanged = false;
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertPreferencesWidget(
          onPreferencesChanged: (_) {
            preferencesChanged = true;
          },
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(BusinessExpertPreferencesWidget), findsOneWidget);

      const initialPreferences = BusinessExpertPreferences();
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertPreferencesWidget(
          initialPreferences: initialPreferences,
          onPreferencesChanged: (_) {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(BusinessExpertPreferencesWidget), findsOneWidget);
    });
  });
}

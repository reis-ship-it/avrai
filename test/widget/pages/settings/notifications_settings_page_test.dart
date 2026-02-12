import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/settings/notifications_settings_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for NotificationsSettingsPage
/// Tests notification settings UI and preferences
void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('NotificationsSettingsPage Widget Tests', () {
    // Removed: Property assignment tests
    // Notifications settings page tests focus on business logic (UI display, notification preference toggles), not property assignment

    testWidgets(
        'should display all required UI elements or display notification preference toggles',
        (WidgetTester tester) async {
      // Test business logic: Notifications settings page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const NotificationsSettingsPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy First'), findsOneWidget);
      expect(find.text('Notification Types'), findsOneWidget);
      expect(find.byType(NotificationsSettingsPage), findsOneWidget);
    });
  });
}

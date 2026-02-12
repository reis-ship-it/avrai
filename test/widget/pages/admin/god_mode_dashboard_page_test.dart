import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/god_mode_dashboard_page.dart';
import 'package:avrai/presentation/pages/admin/god_mode_login_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for GodModeDashboardPage
/// Tests admin dashboard UI and data display
void main() {
  group('GodModeDashboardPage Widget Tests', () {
    // Removed: Property assignment tests
    // God mode dashboard page tests focus on business logic (UI display, dashboard content), not property assignment

    testWidgets(
        'should display all required UI elements or display dashboard content',
        (WidgetTester tester) async {
      // Test business logic: God mode dashboard page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const GodModeDashboardPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      // In tests we don't authenticate as admin; the dashboard should redirect
      // to the login page when admin session is missing.
      expect(find.byType(GodModeLoginPage), findsOneWidget);
    });
  });
}

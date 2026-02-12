import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/business_accounts_viewer_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessAccountsViewerPage
/// Tests business accounts viewer UI
void main() {
  group('BusinessAccountsViewerPage Widget Tests', () {
    // Removed: Property assignment tests
    // Business accounts viewer page tests focus on business logic (UI display, business accounts content), not property assignment

    testWidgets(
        'should display all required UI elements or display business accounts content',
        (WidgetTester tester) async {
      // Test business logic: Business accounts viewer page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const BusinessAccountsViewerPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('Business Accounts Viewer'), findsOneWidget);
      expect(find.text('View and manage business accounts'), findsOneWidget);
      expect(find.byType(BusinessAccountsViewerPage), findsOneWidget);
    });
  });
}

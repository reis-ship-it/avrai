import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/settings/help_support_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for HelpSupportPage
/// Tests help and support content
void main() {
  group('HelpSupportPage Widget Tests', () {
    // Removed: Property assignment tests
    // Help support page tests focus on business logic (UI display, help content), not property assignment

    testWidgets(
        'should display all required UI elements or display help content',
        (WidgetTester tester) async {
      // Test business logic: Help support page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HelpSupportPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('We\'re Here to Help'), findsOneWidget);
      expect(find.byType(HelpSupportPage), findsOneWidget);
    });
  });
}

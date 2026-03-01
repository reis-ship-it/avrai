import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/settings/privacy_settings_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PrivacySettingsPage
/// Tests privacy settings UI and controls
void main() {
  group('PrivacySettingsPage Widget Tests', () {
    // Removed: Property assignment tests
    // Privacy settings page tests focus on business logic (UI display, privacy preference controls), not property assignment

    testWidgets(
        'should display all required UI elements or display privacy preference controls',
        (WidgetTester tester) async {
      // Test business logic: Privacy settings page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PrivacySettingsPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('Privacy Settings'), findsOneWidget);
      expect(find.text('OUR_GUTS.md Commitment'), findsOneWidget);
      expect(find.text('Core Privacy Controls'), findsOneWidget);
      expect(find.byType(PrivacySettingsPage), findsOneWidget);
    });
  });
}

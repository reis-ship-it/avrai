import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/settings/about_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AboutPage
/// Tests about page content and links
void main() {
  group('AboutPage Widget Tests', () {
    // Removed: Property assignment tests
    // About page tests focus on business logic (UI display, app information), not property assignment

    testWidgets(
        'should display all required UI elements or display app information',
        (WidgetTester tester) async {
      // Test business logic: About page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AboutPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.text('About SPOTS'), findsOneWidget);
      expect(find.text('SPOTS'), findsOneWidget);
      expect(find.text('know you belong.'), findsOneWidget);
      expect(find.byType(AboutPage), findsOneWidget);
    });
  });
}

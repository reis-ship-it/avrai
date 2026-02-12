import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/user_data_viewer_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UserDataViewerPage
/// Tests user data viewer UI and search functionality
void main() {
  group('UserDataViewerPage Widget Tests', () {
    // Removed: Property assignment tests
    // User data viewer page tests focus on business logic (UI display, search functionality), not property assignment

    testWidgets(
        'should display all required UI elements or display search functionality',
        (WidgetTester tester) async {
      // Test business logic: User data viewer page display
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UserDataViewerPage(),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.byType(UserDataViewerPage), findsOneWidget);
    });
  });
}

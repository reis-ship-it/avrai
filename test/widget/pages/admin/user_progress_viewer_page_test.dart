import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/user_progress_viewer_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UserProgressViewerPage
/// Tests user progress viewer UI
void main() {
  group('UserProgressViewerPage Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UserProgressViewerPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify viewer UI is present
      expect(find.text('User Progress Viewer'), findsOneWidget);
      expect(find.text('Search for a user to view their progress'), findsOneWidget);
    });
  });
}


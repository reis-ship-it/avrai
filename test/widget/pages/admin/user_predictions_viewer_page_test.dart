import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/user_predictions_viewer_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UserPredictionsViewerPage
/// Tests user predictions viewer UI
void main() {
  group('UserPredictionsViewerPage Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UserPredictionsViewerPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify viewer UI is present
      expect(find.text('User Predictions Viewer'), findsOneWidget);
      expect(find.text('Search for a user to view their predictions'), findsOneWidget);
    });
  });
}


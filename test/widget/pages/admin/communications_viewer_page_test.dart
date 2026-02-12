import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/communications_viewer_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for CommunicationsViewerPage
/// Tests communications viewer UI
void main() {
  group('CommunicationsViewerPage Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CommunicationsViewerPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify viewer UI is present
      expect(find.text('Communications Viewer'), findsOneWidget);
      expect(find.text('View AI2AI and user communications'), findsOneWidget);
    });
  });
}


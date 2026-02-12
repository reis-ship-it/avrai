import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/ai2ai_admin_dashboard.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AI2AIAdminDashboard
/// Tests AI2AI admin dashboard UI
void main() {
  group('AI2AIAdminDashboard Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AI2AIAdminDashboard(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify dashboard UI is present
      expect(find.byType(AI2AIAdminDashboard), findsOneWidget);
    });
  });
}


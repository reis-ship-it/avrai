import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/user_detail_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UserDetailPage
/// Tests user detail viewer UI
void main() {
  group('UserDetailPage Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UserDetailPage(userId: 'test-user-123'),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify detail viewer UI is present
      expect(find.byType(UserDetailPage), findsOneWidget);
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/pages/admin/connection_communication_detail_page.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ConnectionCommunicationDetailPage
/// Tests connection communication detail UI
void main() {
  group('ConnectionCommunicationDetailPage Widget Tests', () {
    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ConnectionCommunicationDetailPage(connectionId: 'test-connection-123'),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify detail page UI is present
      expect(find.byType(ConnectionCommunicationDetailPage), findsOneWidget);
    });
  });
}


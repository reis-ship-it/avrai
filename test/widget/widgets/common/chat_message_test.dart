import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/common/chat_message.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ChatMessage
/// Tests chat message display for user and AI messages
void main() {
  group('ChatMessage Widget Tests', () {
    // Removed: Property assignment tests
    // Chat message tests focus on business logic (message display, alignment, timestamp formatting), not property assignment

    testWidgets('should display user message correctly, display AI message correctly, display timestamp for user/AI messages, display "Just now" for recent messages, align user message to the right, align AI message to the left, or handle long messages correctly', (WidgetTester tester) async {
      // Test business logic: chat message display and formatting
      // Use a timestamp recent enough to render as "Xm ago" (not a calendar date).
      final timestamp = DateTime.now().subtract(const Duration(minutes: 5));
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Hello, AI!',
          isUser: true,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(ChatMessage), findsOneWidget);
      expect(find.text('Hello, AI!'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsNothing);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Hello! How can I help you?',
          isUser: false,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(ChatMessage), findsOneWidget);
      expect(find.text('Hello! How can I help you?'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Test message',
          isUser: true,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.textContaining('ago'), findsOneWidget);

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'AI response',
          isUser: false,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.textContaining('ago'), findsOneWidget);

      final recentTimestamp = DateTime.now();
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Recent message',
          isUser: true,
          timestamp: recentTimestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      expect(find.text('Just now'), findsOneWidget);

      final widget6 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'User message',
          isUser: true,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget6);
      final row1 = tester.widget<Row>(find.byType(Row));
      expect(row1.mainAxisAlignment, equals(MainAxisAlignment.end));

      final widget7 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'AI message',
          isUser: false,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget7);
      final row2 = tester.widget<Row>(find.byType(Row));
      expect(row2.mainAxisAlignment, equals(MainAxisAlignment.start));

      const longMessage = 'This is a very long message that should wrap correctly '
          'and display properly in the chat interface without breaking the layout.';
      final widget8 = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: longMessage,
          isUser: true,
          timestamp: timestamp,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget8);
      expect(find.text(longMessage), findsOneWidget);
    });
  });
}


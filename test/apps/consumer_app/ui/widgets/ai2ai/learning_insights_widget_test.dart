import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/ai2ai/learning_insights_widget.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for LearningInsightsWidget
/// Tests display of learning insights from AI2AI interactions including formatting, limits, and reliability indicators
void main() {
  group('LearningInsightsWidget Widget Tests', () {
    testWidgets('should display empty state when no insights', (WidgetTester tester) async {
      // Arrange: Empty insights list
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LearningInsightsWidget(insights: []),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Empty state is displayed
      expect(find.byType(LearningInsightsWidget), findsOneWidget);
      expect(find.text('Learning Insights'), findsOneWidget);
      expect(find.text('No insights yet'), findsOneWidget);
      expect(find.text('Insights will appear as your AI learns from interactions'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      
      // Verify count chip is NOT displayed when empty
      expect(find.byType(Chip), findsNothing);
      
      // Verify no insight cards are displayed
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('should display count chip when insights exist', (WidgetTester tester) async {
      // Arrange: Insights list
      final insights = [
        SharedInsight(
          category: 'Preference Learning',
          dimension: 'adventure',
          value: 0.75,
          description: 'User shows strong preference for adventure activities',
          reliability: 0.9,
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Social Patterns',
          dimension: 'social',
          value: 0.6,
          description: 'Moderate social interaction patterns detected',
          reliability: 0.7,
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Count chip displays total count (not limited count)
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('should limit displayed insights to 5 items', (WidgetTester tester) async {
      // Arrange: 10 insights (more than the 5-item limit)
      final insights = List.generate(10, (index) => SharedInsight(
        category: 'Category $index',
        dimension: 'test',
        value: 0.5,
        description: 'Description $index',
        reliability: 0.7,
        timestamp: TestHelpers.createTestDateTime(),
      ));

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Only first 5 insights are displayed
      expect(find.text('10'), findsOneWidget); // Count shows total
      expect(find.text('Category 0'), findsOneWidget);
      expect(find.text('Category 1'), findsOneWidget);
      expect(find.text('Category 2'), findsOneWidget);
      expect(find.text('Category 3'), findsOneWidget);
      expect(find.text('Category 4'), findsOneWidget);
      expect(find.text('Category 5'), findsNothing); // 6th item not displayed
      expect(find.text('Category 9'), findsNothing); // 10th item not displayed
      
      // Verify exactly 5 ListTiles are displayed
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('should display exactly 5 insights when list has exactly 5 items', (WidgetTester tester) async {
      // Arrange: Exactly 5 insights
      final insights = List.generate(5, (index) => SharedInsight(
        category: 'Category $index',
        dimension: 'test',
        value: 0.5,
        description: 'Description $index',
        reliability: 0.7,
        timestamp: TestHelpers.createTestDateTime(),
      ));

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All 5 insights are displayed
      expect(find.text('5'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(find.text('Category 0'), findsOneWidget);
      expect(find.text('Category 4'), findsOneWidget);
    });

    testWidgets('should display insight details correctly', (WidgetTester tester) async {
      // Arrange: Single insight with specific values
      final insights = [
        SharedInsight(
          category: 'Test Category',
          dimension: 'adventure',
          value: 0.8,
          description: 'Test description',
          reliability: 0.85,
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All insight details are displayed
      expect(find.text('Test Category'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.textContaining('adventure: 80%'), findsOneWidget);
      expect(find.textContaining('Reliability: 85%'), findsOneWidget);
    });

    testWidgets('should display high reliability icon (>=0.8) for high reliability insights', (WidgetTester tester) async {
      // Arrange: High reliability insight
      final insights = [
        SharedInsight(
          category: 'High Reliability',
          dimension: 'test',
          value: 0.8,
          description: 'High reliability insight',
          reliability: 0.9, // >= 0.8
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Boundary High',
          dimension: 'test',
          value: 0.7,
          description: 'Boundary high reliability',
          reliability: 0.8, // Exactly 0.8 (boundary)
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Both show trending_up icon (>= 0.8)
      final icons = find.byIcon(Icons.trending_up);
      expect(icons, findsNWidgets(2));
      
      // Verify no other reliability icons are shown
      expect(find.byIcon(Icons.info), findsNothing);
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('should display medium reliability icon (>=0.5, <0.8) for medium reliability insights', (WidgetTester tester) async {
      // Arrange: Medium reliability insights
      final insights = [
        SharedInsight(
          category: 'Medium Reliability',
          dimension: 'test',
          value: 0.6,
          description: 'Medium reliability insight',
          reliability: 0.6, // >= 0.5, < 0.8
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Boundary Medium',
          dimension: 'test',
          value: 0.5,
          description: 'Boundary medium reliability',
          reliability: 0.5, // Exactly 0.5 (boundary)
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Just Below High',
          dimension: 'test',
          value: 0.79,
          description: 'Just below high threshold',
          reliability: 0.79, // Just below 0.8
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All show info icon (>= 0.5, < 0.8)
      final icons = find.byIcon(Icons.info);
      expect(icons, findsNWidgets(3));
      
      // Verify no other reliability icons are shown
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('should display low reliability icon (<0.5) for low reliability insights', (WidgetTester tester) async {
      // Arrange: Low reliability insights
      final insights = [
        SharedInsight(
          category: 'Low Reliability',
          dimension: 'test',
          value: 0.4,
          description: 'Low reliability insight',
          reliability: 0.3, // < 0.5
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Very Low',
          dimension: 'test',
          value: 0.2,
          description: 'Very low reliability',
          reliability: 0.1, // Very low
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Just Below Medium',
          dimension: 'test',
          value: 0.49,
          description: 'Just below medium threshold',
          reliability: 0.49, // Just below 0.5
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All show help_outline icon (< 0.5)
      final icons = find.byIcon(Icons.help_outline);
      expect(icons, findsNWidgets(3));
      
      // Verify no other reliability icons are shown
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.info), findsNothing);
    });

    testWidgets('should format timestamp as days ago when difference is days', (WidgetTester tester) async {
      // Arrange: Insight with timestamp 2 days ago
      final insights = [
        SharedInsight(
          category: 'Old Insight',
          dimension: 'test',
          value: 0.5,
          description: 'Old insight',
          reliability: 0.7,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Timestamp formatted as days
      expect(find.textContaining('2d ago'), findsOneWidget);
    });

    testWidgets('should format timestamp as hours ago when difference is hours', (WidgetTester tester) async {
      // Arrange: Insight with timestamp 3 hours ago
      final insights = [
        SharedInsight(
          category: 'Recent Insight',
          dimension: 'test',
          value: 0.5,
          description: 'Recent insight',
          reliability: 0.7,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Timestamp formatted as hours
      expect(find.textContaining('3h ago'), findsOneWidget);
    });

    testWidgets('should format timestamp as minutes ago when difference is minutes', (WidgetTester tester) async {
      // Arrange: Insight with timestamp 15 minutes ago
      final insights = [
        SharedInsight(
          category: 'Very Recent Insight',
          dimension: 'test',
          value: 0.5,
          description: 'Very recent insight',
          reliability: 0.7,
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Timestamp formatted as minutes
      expect(find.textContaining('15m ago'), findsOneWidget);
    });

    testWidgets('should format timestamp as "Just now" when difference is less than a minute', (WidgetTester tester) async {
      // Arrange: Insight with very recent timestamp
      final insights = [
        SharedInsight(
          category: 'Just Now Insight',
          dimension: 'test',
          value: 0.5,
          description: 'Just now insight',
          reliability: 0.7,
          timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Timestamp formatted as "Just now"
      expect(find.text('• Just now'), findsOneWidget);
    });

    testWidgets('should format value and reliability as percentages correctly', (WidgetTester tester) async {
      // Arrange: Insights with various values
      final insights = [
        SharedInsight(
          category: 'Test 1',
          dimension: 'adventure',
          value: 0.75, // Should show as 75%
          description: 'Test',
          reliability: 0.9, // Should show as 90%
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Test 2',
          dimension: 'social',
          value: 0.33, // Should show as 33% (rounded)
          description: 'Test',
          reliability: 0.67, // Should show as 67% (rounded)
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Values formatted as percentages
      expect(find.textContaining('adventure: 75%'), findsOneWidget);
      expect(find.textContaining('Reliability: 90%'), findsOneWidget);
      expect(find.textContaining('social: 33%'), findsOneWidget);
      expect(find.textContaining('Reliability: 67%'), findsOneWidget);
    });

    testWidgets('should display multiple insights with correct details', (WidgetTester tester) async {
      // Arrange: Multiple insights
      final insights = [
        SharedInsight(
          category: 'Preference Learning',
          dimension: 'adventure',
          value: 0.75,
          description: 'User shows strong preference for adventure activities',
          reliability: 0.9,
          timestamp: TestHelpers.createTestDateTime(),
        ),
        SharedInsight(
          category: 'Social Patterns',
          dimension: 'social',
          value: 0.6,
          description: 'Moderate social interaction patterns detected',
          reliability: 0.7,
          timestamp: TestHelpers.createTestDateTime().subtract(const Duration(hours: 2)),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Both insights are displayed with correct details
      expect(find.text('Preference Learning'), findsOneWidget);
      expect(find.text('User shows strong preference for adventure activities'), findsOneWidget);
      expect(find.text('Social Patterns'), findsOneWidget);
      expect(find.text('Moderate social interaction patterns detected'), findsOneWidget);
      
      // Verify both have correct icons (high and medium reliability)
      expect(find.byIcon(Icons.trending_up), findsOneWidget); // 0.9 reliability
      expect(find.byIcon(Icons.info), findsOneWidget); // 0.7 reliability
    });

    testWidgets('should display card with correct styling', (WidgetTester tester) async {
      // Arrange
      final insights = [
        SharedInsight(
          category: 'Test',
          dimension: 'test',
          value: 0.5,
          description: 'Test',
          reliability: 0.7,
          timestamp: TestHelpers.createTestDateTime(),
        ),
      ];

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningInsightsWidget(insights: insights),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Card is displayed with correct elevation
      final cards = find.byType(Card);
      expect(cards, findsAtLeastNWidgets(2)); // Outer card + insight card
      
      final outerCard = tester.widget<Card>(cards.first);
      expect(outerCard.elevation, equals(2));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/ai2ai/performance_issues_list.dart';
import 'package:avrai/core/monitoring/network_analytics.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for PerformanceIssuesList
/// Tests performance issues and recommendations display
void main() {
  group('PerformanceIssuesList Widget Tests', () {
    // Removed: Property assignment tests
    // Performance issues list tests focus on business logic (issues and recommendations display), not property assignment

    testWidgets(
        'should display empty state when no issues or recommendations, display performance issues, display optimization recommendations, or display both issues and recommendations',
        (WidgetTester tester) async {
      // Test business logic: performance issues list display
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const PerformanceIssuesList(
          issues: [],
          recommendations: [],
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(PerformanceIssuesList), findsOneWidget);
      expect(find.text('Performance & Optimization'), findsOneWidget);
      expect(find.text('No issues detected. Network operating optimally.'),
          findsOneWidget);

      final issues1 = [
        PerformanceIssue(
          type: IssueType.highUtilization,
          severity: IssueSeverity.high,
          description: 'High latency detected',
          impact: 'May cause connection delays',
          recommendedAction: 'Consider load balancing optimization',
        ),
        PerformanceIssue(
          type: IssueType.lowConnectionSuccess,
          severity: IssueSeverity.critical,
          description: 'Low throughput',
          impact: 'Reduced AI2AI personality matching',
          recommendedAction: 'Review compatibility algorithms',
        ),
      ];
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: PerformanceIssuesList(
          issues: issues1,
          recommendations: const [],
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Issues (2)'), findsOneWidget);
      expect(find.text('High latency detected'), findsOneWidget);
      expect(find.text('Low throughput'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsWidgets);
      expect(find.byIcon(Icons.error), findsWidgets);

      final recommendations1 = [
        OptimizationRecommendation(
          category: 'Connection Quality',
          recommendation: 'Consider reducing connection pool size',
          expectedImpact: 'Increase average compatibility by 10-15%',
          priority: Priority.high,
          estimatedEffort: 'Medium',
        ),
        OptimizationRecommendation(
          category: 'Learning Effectiveness',
          recommendation: 'Enable connection caching',
          expectedImpact: 'Accelerate personality evolution by 20%',
          priority: Priority.medium,
          estimatedEffort: 'Low',
        ),
      ];
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: PerformanceIssuesList(
          issues: const [],
          recommendations: recommendations1,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Recommendations (2)'), findsOneWidget);
      expect(
          find.text('Consider reducing connection pool size'), findsOneWidget);
      expect(find.text('Enable connection caching'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);

      final issues2 = [
        PerformanceIssue(
          type: IssueType.highUtilization,
          severity: IssueSeverity.high,
          description: 'Test issue',
          impact: 'May cause connection delays',
          recommendedAction: 'Consider load balancing optimization',
        ),
      ];
      final recommendations2 = [
        OptimizationRecommendation(
          category: 'Connection Quality',
          recommendation: 'Test recommendation',
          expectedImpact: 'Increase average compatibility by 10-15%',
          priority: Priority.high,
          estimatedEffort: 'Medium',
        ),
      ];
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: PerformanceIssuesList(
          issues: issues2,
          recommendations: recommendations2,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.text('Issues (1)'), findsOneWidget);
      expect(find.text('Recommendations (1)'), findsOneWidget);
    });
  });
}

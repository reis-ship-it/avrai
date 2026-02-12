import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/ai2ai/user_connections_display.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for UserConnectionsDisplay
/// Tests display of active AI2AI connections
void main() {
  group('UserConnectionsDisplay Widget Tests', () {
    // Removed: Property assignment tests
    // User connections display tests focus on business logic (connections display, statistics, user interactions), not property assignment

    testWidgets(
        'should display empty state when no connections, display connection statistics when connections exist, display top performing connections, or handle zero average duration correctly',
        (WidgetTester tester) async {
      // Test business logic: user connections display widget display and interactions
      final overview1 = ActiveConnectionsOverview.empty();
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: UserConnectionsDisplay(overview: overview1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(UserConnectionsDisplay), findsOneWidget);
      expect(find.text('Active Connections'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No active connections'), findsOneWidget);
      expect(
          find.text('Your AI will discover nearby personalities automatically'),
          findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);

      final overview2 = ActiveConnectionsOverview(
        totalActiveConnections: 3,
        aggregateMetrics: AggregateConnectionMetrics(0.75),
        topPerformingConnections: ['conn-1', 'conn-2', 'conn-3'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 15),
        totalAlertsGenerated: 0,
        generatedAt: DateTime.now(),
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: UserConnectionsDisplay(overview: overview2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.byType(UserConnectionsDisplay), findsOneWidget);
      expect(find.text('Active Connections'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Avg Compatibility'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Avg Duration'), findsOneWidget);
      expect(find.text('15min'), findsOneWidget);
      expect(find.text('Top Connections'), findsOneWidget);

      final overview3 = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['connection-12345', 'connection-67890'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: DateTime.now(),
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: UserConnectionsDisplay(overview: overview3),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Top Connections'), findsOneWidget);
      expect(find.text('High performance'), findsWidgets);
      expect(find.byIcon(Icons.link), findsWidgets);

      final overview4 = ActiveConnectionsOverview(
        totalActiveConnections: 1,
        aggregateMetrics: AggregateConnectionMetrics(0.5),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: Duration.zero,
        totalAlertsGenerated: 0,
        generatedAt: DateTime.now(),
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: UserConnectionsDisplay(overview: overview4),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.text('0min'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/ai2ai/connections_list.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ConnectionsList
/// Tests display of active AI2AI connections list
void main() {
  group('ConnectionsList Widget Tests', () {
    // Removed: Property assignment tests
    // Connections list tests focus on business logic (connections list display, user interactions, navigation), not property assignment

    testWidgets(
        'should display empty state when no connections, display top performing connections, display connections needing attention, display aggregate metrics, or navigate to connection detail on tap',
        (WidgetTester tester) async {
      // Test business logic: connections list widget display and interactions
      final overview1 = ActiveConnectionsOverview.empty();
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview1),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.byType(ConnectionsList), findsOneWidget);
      expect(find.text('Active Connections'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No active connections'), findsOneWidget);

      final overview2 = ActiveConnectionsOverview(
        totalActiveConnections: 3,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['conn-1', 'conn-2'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview2),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Top Performing'), findsOneWidget);
      expect(find.text('High performance connection'), findsWidgets);
      expect(find.byIcon(Icons.trending_up), findsWidgets);

      final overview3 = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.5),
        topPerformingConnections: [],
        connectionsNeedingAttention: ['conn-3', 'conn-4'],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 5),
        totalAlertsGenerated: 2,
        generatedAt: TestHelpers.createTestDateTime(),
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview3),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('May need optimization'), findsWidgets);
      expect(find.byIcon(Icons.warning), findsWidgets);

      final overview4 = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.75),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 15),
        totalAlertsGenerated: 1,
        generatedAt: TestHelpers.createTestDateTime(),
      );
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview4),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.text('Aggregate Metrics'), findsOneWidget);
      expect(find.text('Avg Compatibility'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Avg Duration'), findsOneWidget);
      expect(find.text('15min'), findsOneWidget);
      expect(find.text('Total Alerts'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      final overview5 = ActiveConnectionsOverview(
        totalActiveConnections: 1,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['connection-12345'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );
      final widget5 = WidgetTestHelpers.createTestableWidget(
        child: ConnectionsList(overview: overview5),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget5);
      final connectionTile = find.byType(ListTile).first;
      // Connection rows should indicate navigability.
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
      await tester.tap(connectionTile);
      await tester.pumpAndSettle();
      expect(find.textContaining('Connection:'), findsOneWidget);
    });
  });
}

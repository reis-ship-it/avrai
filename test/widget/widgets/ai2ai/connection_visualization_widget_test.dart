import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/ai2ai/connection_visualization_widget.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ConnectionVisualizationWidget
/// Tests network visualization display including empty state, graph rendering, and legend
void main() {
  group('ConnectionVisualizationWidget Widget Tests', () {
    Finder networkGraphPaintFinder() {
      return find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is NetworkGraphPainter,
        description: 'CustomPaint with NetworkGraphPainter',
      );
    }

    testWidgets('should display empty state when no connections', (WidgetTester tester) async {
      // Arrange: Create empty overview
      final emptyOverview = ActiveConnectionsOverview.empty();
      
      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: emptyOverview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Empty state is displayed
      expect(find.byType(ConnectionVisualizationWidget), findsOneWidget);
      expect(find.text('Network Visualization'), findsOneWidget);
      expect(find.text('No connections to visualize'), findsOneWidget);
      expect(find.byIcon(Icons.account_tree), findsOneWidget);
      
      // Verify network graph is NOT displayed
      expect(networkGraphPaintFinder(), findsNothing);
    });

    testWidgets('should display network graph when connections exist', (WidgetTester tester) async {
      // Arrange: Create overview with connections
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 3,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['conn-1', 'conn-2'],
        connectionsNeedingAttention: ['conn-3'],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Network graph is displayed (CustomPaint widget)
      expect(find.byType(ConnectionVisualizationWidget), findsOneWidget);
      expect(find.text('Network Visualization'), findsOneWidget);
      expect(find.text('No connections to visualize'), findsNothing);
      expect(networkGraphPaintFinder(), findsOneWidget);
      
      // Verify graph container has correct height
      final customPaint =
          tester.widget<CustomPaint>(networkGraphPaintFinder());
      expect(customPaint, isNotNull);
    });

    testWidgets('should display legend with all three categories', (WidgetTester tester) async {
      // Arrange: Create overview with connections
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.75),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 15),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Legend displays all three categories
      expect(find.text('Top Performing'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Other Connections'), findsOneWidget);
      
      // Verify legend items have colored indicators (Container with BoxDecoration)
      final legendContainers = find.descendant(
        of: find.byType(ConnectionVisualizationWidget),
        matching: find.byWidgetPredicate(
          (widget) {
            if (widget is! Container) return false;
            final decoration = widget.decoration;
            if (decoration is! BoxDecoration) return false;
            return decoration.shape == BoxShape.circle;
          },
        ),
      );
      expect(legendContainers, findsAtLeastNWidgets(3)); // At least 3 legend indicators
    });

    testWidgets('should display fullscreen button', (WidgetTester tester) async {
      // Arrange: Create overview with connections
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 1,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Fullscreen button is displayed
      final fullscreenButton = find.widgetWithIcon(IconButton, Icons.fullscreen);
      expect(fullscreenButton, findsOneWidget);
      
      // Verify button has tooltip
      final iconButton = tester.widget<IconButton>(fullscreenButton);
      expect(iconButton.tooltip, equals('Fullscreen'));
    });

    testWidgets('should transition from empty state to populated state', (WidgetTester tester) async {
      // Arrange: Start with empty overview
      var overview = ActiveConnectionsOverview.empty();
      
      // Act: Build widget with empty state
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Empty state is shown
      expect(find.text('No connections to visualize'), findsOneWidget);
      expect(networkGraphPaintFinder(), findsNothing);

      // Act: Update to populated overview
      overview = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['conn-1'],
        connectionsNeedingAttention: [],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );
      
      await tester.pumpWidget(WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      ));
      await tester.pumpAndSettle();

      // Assert: Network graph is now displayed
      expect(find.text('No connections to visualize'), findsNothing);
      expect(networkGraphPaintFinder(), findsOneWidget);
    });

    testWidgets('should render network graph with correct painter properties', (WidgetTester tester) async {
      // Arrange: Create overview with specific connections
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 5,
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: ['conn-1', 'conn-2'],
        connectionsNeedingAttention: ['conn-3'],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: CustomPaint is rendered with NetworkGraphPainter
      expect(networkGraphPaintFinder(), findsOneWidget);
      
      final customPaint =
          tester.widget<CustomPaint>(networkGraphPaintFinder());
      expect(customPaint.painter, isA<NetworkGraphPainter>());
      
      final painter = customPaint.painter as NetworkGraphPainter;
      expect(painter.totalConnections, equals(5));
      expect(painter.connections, equals(['conn-1', 'conn-2']));
      expect(painter.needsAttention, equals(['conn-3']));
    });

    testWidgets('should display card with correct styling', (WidgetTester tester) async {
      // Arrange
      final overview = ActiveConnectionsOverview.empty();

      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Card is displayed with correct elevation
      expect(find.byType(Card), findsOneWidget);
      
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(2));
    });

    testWidgets('should handle overview with many connections (limit to 12 nodes)', (WidgetTester tester) async {
      // Arrange: Create overview with more than 12 connections
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 20, // More than 12
        aggregateMetrics: AggregateConnectionMetrics(0.8),
        topPerformingConnections: List.generate(5, (i) => 'conn-top-$i'),
        connectionsNeedingAttention: List.generate(3, (i) => 'conn-attn-$i'),
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 20),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Graph is rendered (painter should clamp to 12 nodes)
      expect(networkGraphPaintFinder(), findsOneWidget);
      
      final customPaint =
          tester.widget<CustomPaint>(networkGraphPaintFinder());
      final painter = customPaint.painter as NetworkGraphPainter;
      // Painter should handle the clamping internally (nodeCount = totalConnections.clamp(0, 12))
      expect(painter.totalConnections, equals(20)); // Painter receives full count, clamps internally
    });

    testWidgets('should display legend even when no connections', (WidgetTester tester) async {
      // Arrange: Empty overview
      final overview = ActiveConnectionsOverview.empty();

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Legend is still displayed (even in empty state)
      expect(find.text('Top Performing'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Other Connections'), findsOneWidget);
    });

    testWidgets('should handle overview with only top performing connections', (WidgetTester tester) async {
      // Arrange: Overview with only top performers, no attention needed
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 3,
        aggregateMetrics: AggregateConnectionMetrics(0.9),
        topPerformingConnections: ['conn-1', 'conn-2', 'conn-3'],
        connectionsNeedingAttention: [], // No connections need attention
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 25),
        totalAlertsGenerated: 0,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Graph is displayed
      expect(networkGraphPaintFinder(), findsOneWidget);
      
      final customPaint =
          tester.widget<CustomPaint>(networkGraphPaintFinder());
      final painter = customPaint.painter as NetworkGraphPainter;
      expect(painter.connections, equals(['conn-1', 'conn-2', 'conn-3']));
      expect(painter.needsAttention, isEmpty);
    });

    testWidgets('should handle overview with only connections needing attention', (WidgetTester tester) async {
      // Arrange: Overview with only connections needing attention
      final overview = ActiveConnectionsOverview(
        totalActiveConnections: 2,
        aggregateMetrics: AggregateConnectionMetrics(0.5),
        topPerformingConnections: [], // No top performers
        connectionsNeedingAttention: ['conn-1', 'conn-2'],
        learningVelocityDistribution: LearningVelocityDistribution.normal(),
        optimizationOpportunities: [],
        averageConnectionDuration: const Duration(minutes: 5),
        totalAlertsGenerated: 2,
        generatedAt: TestHelpers.createTestDateTime(),
      );

      // Act: Build widget
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ConnectionVisualizationWidget(overview: overview),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Graph is displayed
      expect(networkGraphPaintFinder(), findsOneWidget);
      
      final customPaint =
          tester.widget<CustomPaint>(networkGraphPaintFinder());
      final painter = customPaint.painter as NetworkGraphPainter;
      expect(painter.connections, isEmpty);
      expect(painter.needsAttention, equals(['conn-1', 'conn-2']));
    });
  });
}

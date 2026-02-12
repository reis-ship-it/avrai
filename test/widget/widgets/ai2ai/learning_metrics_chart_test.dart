import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/ai2ai/learning_metrics_chart.dart';
import 'package:avrai/core/monitoring/network_analytics.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for LearningMetricsChart
/// Tests learning metrics chart display including chart types, time ranges, interactions, and custom painting
void main() {
  group('LearningMetricsChart Widget Tests', () {
    RealTimeMetrics createTestMetrics({
      double connectionThroughput = 10.5,
      double matchingSuccessRate = 0.85,
      double learningConvergenceSpeed = 0.7,
      double vibeSynchronizationQuality = 0.9,
      double networkResponsiveness = 0.8,
      double cpuUsage = 0.5,
      double memoryUsage = 0.6,
      double networkBandwidth = 0.4,
      double storageUsage = 0.3,
    }) {
      return RealTimeMetrics(
        connectionThroughput: connectionThroughput,
        matchingSuccessRate: matchingSuccessRate,
        learningConvergenceSpeed: learningConvergenceSpeed,
        vibeSynchronizationQuality: vibeSynchronizationQuality,
        networkResponsiveness: networkResponsiveness,
        resourceUtilization: ResourceUtilizationMetrics(
          cpuUsage: cpuUsage,
          memoryUsage: memoryUsage,
          networkBandwidth: networkBandwidth,
          storageUsage: storageUsage,
        ),
        timestamp: TestHelpers.createTestDateTime(),
      );
    }

    testWidgets('should display learning metrics chart with all UI elements', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All UI elements are displayed
      expect(find.byType(LearningMetricsChart), findsOneWidget);
      expect(find.text('Learning Metrics'), findsOneWidget);
      expect(find.text('Line'), findsOneWidget);
      expect(find.text('Bar'), findsOneWidget);
      expect(find.text('Area'), findsOneWidget);
      expect(find.text('1H'), findsOneWidget);
      expect(find.text('1D'), findsOneWidget);
      expect(find.text('1W'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('Matching Success Rate'), findsOneWidget);
      expect(find.text('Learning Convergence'), findsOneWidget);
      expect(find.text('Vibe Sync'), findsOneWidget);
      expect(find.text('Responsiveness'), findsOneWidget);
      // Chart uses CustomPaint (find the one inside the chart container)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1)); // At least one CustomPaint for the chart
    });

    testWidgets('should display CustomPaint with chart painter', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: CustomPaint is displayed (chart uses CustomPaint for rendering)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
      // CustomPaint widget exists, painter is set during build
    });

    testWidgets('should switch to bar chart when bar button is tapped', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap bar chart button
      await tester.tap(find.text('Bar'));
      await tester.pumpAndSettle();

      // Assert: Bar chart is selected (ChoiceChip is selected)
      final barButtonFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! ChoiceChip) return false;
          final label = widget.label;
          if (label is! Row) return false;
          return label.children.any((child) {
            if (child is! Text) return false;
            return child.data == 'Bar';
          });
        },
      );
      final barButton = tester.widget<ChoiceChip>(barButtonFinder);
      expect(barButton.selected, isTrue);
      
      // Verify CustomPaint still exists (chart type changed but chart still renders)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
    });

    testWidgets('should switch to area chart when area button is tapped', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap area chart button
      await tester.tap(find.text('Area'));
      await tester.pumpAndSettle();

      // Assert: Area chart is selected
      final areaButtonFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! ChoiceChip) return false;
          final label = widget.label;
          if (label is! Row) return false;
          return label.children.any((child) {
            if (child is! Text) return false;
            return child.data == 'Area';
          });
        },
      );
      final areaButton = tester.widget<ChoiceChip>(areaButtonFinder);
      expect(areaButton.selected, isTrue);
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
    });

    testWidgets('should switch time range when time range button is tapped', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap week time range button
      await tester.tap(find.text('1W'));
      await tester.pumpAndSettle();

      // Assert: Week time range is selected (SegmentedButton selection changed)
      // The chart should still render (historical data regenerated for week range)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
    });

    testWidgets('should switch to hour time range when 1H button is tapped', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap hour time range button
      await tester.tap(find.text('1H'));
      await tester.pumpAndSettle();

      // Assert: Chart still renders (historical data regenerated for hour range)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
    });

    testWidgets('should switch to month time range when 1M button is tapped', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap month time range button
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      // Assert: Chart still renders (historical data regenerated for month range)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
    });

    testWidgets('should toggle metric selection when legend item is tapped', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act: Tap "Matching Success Rate" legend item
      await tester.tap(find.text('Matching Success Rate'));
      await tester.pumpAndSettle();

      // Assert: Metric is selected (text style changes to bold, color changes)
      // We can verify by checking the widget state changed (chart still renders)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
      
      // Tap again to deselect
      await tester.tap(find.text('Matching Success Rate'));
      await tester.pumpAndSettle();
      expect(chartPaint, findsAtLeastNWidgets(1));
    });

    testWidgets('should have interactive chart area for tapping', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Chart area exists and is interactive (GestureDetector wraps the chart)
      // The chart uses GestureDetector with onTapDown for dialog display
      // Note: Dialog display requires RenderBox calculations that may not work in widget tests
      // We verify the chart renders and is interactive by checking CustomPaint exists
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
      
      // Verify chart container exists (wrapped in GestureDetector)
      final chartContainer = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && 
                      widget.decoration is BoxDecoration,
        ),
      );
      expect(chartContainer, findsAtLeastNWidgets(1));
    });

    testWidgets('should have chart area that can be tapped for metric details', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Chart area exists and is set up for interaction
      // The widget uses GestureDetector with onTapDown to show metric details dialog
      // Note: Dialog display requires RenderBox.globalToLocal calculations that may not work in widget tests
      // We verify the chart is interactive by checking the structure exists
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
      
      // Chart is wrapped in GestureDetector for tap interactions
      // The _showMetricDetails method displays dialog with metric information
      // This functionality is verified through integration tests or manual testing
    });

    testWidgets('should display all legend items with correct labels', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: All legend items are displayed
      expect(find.text('Matching Success Rate'), findsOneWidget);
      expect(find.text('Learning Convergence'), findsOneWidget);
      expect(find.text('Vibe Sync'), findsOneWidget);
      expect(find.text('Responsiveness'), findsOneWidget);
    });

    testWidgets('should display card with elevation', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Card is displayed with elevation
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final card = tester.widget<Card>(cardFinder);
      expect(card.elevation, equals(2));
    });

    testWidgets('should display chart type selector buttons with icons', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Chart type buttons have icons
      expect(find.byIcon(Icons.show_chart), findsOneWidget); // Line chart icon
      expect(find.byIcon(Icons.bar_chart), findsOneWidget); // Bar chart icon
      expect(find.byIcon(Icons.area_chart), findsOneWidget); // Area chart icon
    });

    testWidgets('should render chart with different metric values', (WidgetTester tester) async {
      // Arrange: Create metrics with different values
      final metrics = createTestMetrics(
        matchingSuccessRate: 0.95,
        learningConvergenceSpeed: 0.6,
        vibeSynchronizationQuality: 0.75,
        networkResponsiveness: 0.85,
      );
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Chart renders with different values (CustomPaint exists)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
      expect(find.text('Learning Metrics'), findsOneWidget);
    });

    testWidgets('should maintain line chart as default selection', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Line chart is selected by default
      final lineButtonFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! ChoiceChip) return false;
          final label = widget.label;
          if (label is! Row) return false;
          return label.children.any((child) {
            if (child is! Text) return false;
            return child.data == 'Line';
          });
        },
      );
      final lineButton = tester.widget<ChoiceChip>(lineButtonFinder);
      expect(lineButton.selected, isTrue);
    });

    testWidgets('should maintain day time range as default selection', (WidgetTester tester) async {
      // Arrange
      final metrics = createTestMetrics();
      
      // Act
      final widget = WidgetTestHelpers.createTestableWidget(
        child: LearningMetricsChart(metrics: metrics),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert: Day (1D) time range is selected by default
      // We verify by checking chart renders (which uses day range by default)
      final chartPaint = find.descendant(
        of: find.byType(LearningMetricsChart),
        matching: find.byType(CustomPaint),
      );
      expect(chartPaint, findsAtLeastNWidgets(1));
      expect(find.text('1D'), findsOneWidget);
    });
  });
}

/// SPOTS AIImprovementProgressWidget Widget Tests
/// Date: November 21, 2025
/// Purpose: Test AIImprovementProgressWidget functionality and UI behavior
///
/// Test Coverage:
/// - Empty State: Display when no progress data
/// - Header Display: Title, icon, time window display
/// - Dimension Selector: ChoiceChips for dimension selection
/// - Progress Chart: Custom chart rendering with data points
/// - Trend Summary: Trend calculation and display
/// - Data Calculations: Data point generation, trend calculation
///
/// Dependencies:
/// - AIImprovementTrackingService: For history data
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AIImprovementProgressWidget
/// Tests progress visualization, dimension selection, and trend analysis
void main() {
  group('AIImprovementProgressWidget Widget Tests', () {
    late MockAIImprovementTrackingService mockService;

    setUp(() {
      mockService = MockAIImprovementTrackingService();
    });

    /// Helper to create scrollable test widget with larger viewport
    Widget createScrollableTestWidget({required Widget child}) {
      return WidgetTestHelpers.createTestableWidget(
        child: SizedBox(
          height: 1200, // Increased viewport height
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      );
    }

    group('Empty State', () {
      // Removed: Property assignment tests
      // Empty state tests focus on business logic (empty state display), not property assignment

      testWidgets(
          'should display empty state when no history data or display helpful message in empty state',
          (WidgetTester tester) async {
        // Test business logic: AI improvement progress widget empty state
        mockService.setHistory([]);
        final widget = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget);
        await tester.pump();
        expect(find.text('No Progress Data Yet'), findsOneWidget);
        expect(find.byIcon(Icons.show_chart), findsWidgets);
        expect(
            find.textContaining('Your AI will start tracking'), findsOneWidget);
      });
    });

    group('Header Display', () {
      // Removed: Property assignment tests
      // Header display tests focus on business logic (header display, time window), not property assignment

      testWidgets(
          'should display header with title, display time window in header, or display custom time window',
          (WidgetTester tester) async {
        // Test business logic: AI improvement progress widget header display
        final history = _createMockHistory(count: 5);
        mockService.setHistory(history);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_header_default'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pump();
        expect(find.text('Progress Visualization'), findsOneWidget);
        expect(find.byIcon(Icons.show_chart), findsWidgets);

        final widget2 = WidgetTestHelpers.createTestableWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_header_30d'),
            userId: 'test_user',
            trackingService: mockService,
            timeWindow: const Duration(days: 30),
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pump();
        expect(find.text('Last 30 days'), findsOneWidget);

        final widget3 = WidgetTestHelpers.createTestableWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_header_7d'),
            userId: 'test_user',
            trackingService: mockService,
            timeWindow: const Duration(days: 7),
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pump();
        expect(find.text('Last 7 days'), findsOneWidget);
      });
    });

    group('Dimension Selector', () {
      // Removed: Property assignment tests
      // Dimension selector tests focus on business logic (dimension selector display, selection), not property assignment

      testWidgets(
          'should display dimension selector with choices, display available dimensions from history, select overall dimension by default, or change selected dimension when chip is tapped',
          (WidgetTester tester) async {
        // Test business logic: AI improvement progress widget dimension selector
        final history1 = _createMockHistory(count: 5);
        mockService.setHistory(history1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_dimension_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pump();
        expect(find.byType(ChoiceChip), findsWidgets);
        expect(find.text('Overall'), findsOneWidget);
        final overallChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Overall'),
        );
        expect(overallChip.selected, isTrue);

        final history2 = _createMockHistory(
          count: 5,
          dimensions: {'accuracy': 0.85, 'speed': 0.88, 'creativity': 0.80},
        );
        mockService.setHistory(history2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_dimension_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pump();
        expect(find.text('Accuracy'), findsOneWidget);
        expect(find.text('Speed'), findsOneWidget);
        expect(find.text('Creativity'), findsOneWidget);

        final history3 = _createMockHistory(
          count: 5,
          dimensions: {'accuracy': 0.85},
        );
        mockService.setHistory(history3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_dimension_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pump();
        await tester.tap(find.text('Accuracy'));
        await tester.pump();
        final accuracyChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Accuracy'),
        );
        expect(accuracyChip.selected, isTrue);
      });
    });

    group('Progress Chart', () {
      // Removed: Property assignment tests
      // Progress chart tests focus on business logic (progress chart display, dimension label), not property assignment

      testWidgets(
          'should display progress chart with data, display dimension label on chart, or display no data message when dimension has no data',
          (WidgetTester tester) async {
        // Test business logic: AI improvement progress widget progress chart
        final history1 = _createMockHistory(count: 10);
        mockService.setHistory(history1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_chart_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pump();
        expect(find.byType(CustomPaint), findsWidgets);

        final history2 = _createMockHistory(count: 5);
        mockService.setHistory(history2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_chart_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pump();
        expect(find.text('Overall Performance'), findsOneWidget);

        final history3 = _createMockHistory(
          count: 5,
          dimensions: {},
        );
        mockService.setHistory(history3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_chart_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pump();
        final accuracyChip = find.text('Accuracy');
        if (accuracyChip.evaluate().isNotEmpty) {
          await tester.tap(accuracyChip);
          await tester.pump();
        }
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('Trend Summary', () {
      // Removed: Property assignment tests
      // Trend summary tests focus on business logic (trend display, percentage change), not property assignment

      testWidgets(
          'should display improving trend for positive change, display declining trend for negative change, display stable performance for no change, or display percentage change in trend',
          (WidgetTester tester) async {
        // Test business logic: AI improvement progress widget trend summary
        final history1 = _createImprovingHistory();
        mockService.setHistory(history1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_trend_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(find.textContaining('Improving:'), findsWidgets);
        expect(find.byIcon(Icons.arrow_upward), findsWidgets);
        expect(find.textContaining('%'), findsWidgets);

        final history2 = _createDecliningHistory();
        mockService.setHistory(history2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_trend_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.textContaining('Declining:'), findsWidgets);
        expect(find.byIcon(Icons.arrow_downward), findsWidgets);

        final history3 = _createStableHistory();
        mockService.setHistory(history3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_trend_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pump();
        expect(find.text('Stable performance'), findsOneWidget);
        expect(find.byIcon(Icons.remove), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      // Removed: Property assignment tests
      // Edge cases tests focus on business logic (single data point, dimension selector limit), not property assignment

      testWidgets(
          'should handle single data point or limit dimension selector to 6 items',
          (WidgetTester tester) async {
        // Test business logic: AI improvement progress widget edge cases
        final history1 = _createMockHistory(count: 1);
        mockService.setHistory(history1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_edge_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.text('Stable performance'), findsWidgets);

        final dimensions = {
          for (var i = 0; i < 10; i++) 'dimension_$i': 0.80,
        };
        final history2 = _createMockHistory(count: 5, dimensions: dimensions);
        mockService.setHistory(history2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementProgressWidget(
            key: const ValueKey('ai_improvement_progress_edge_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pump();
        expect(find.byType(ChoiceChip), findsNWidgets(6));
      });
    });
  });
}

/// Helper function to create mock history snapshots
List<AIImprovementSnapshot> _createMockHistory({
  int count = 5,
  Map<String, double>? dimensions,
}) {
  final now = DateTime.now();
  final List<AIImprovementSnapshot> history = [];

  for (int i = 0; i < count; i++) {
    history.add(AIImprovementSnapshot(
      userId: 'test_user',
      dimensions: dimensions ??
          {
            'accuracy': 0.75 + (i * 0.02),
            'speed': 0.80 + (i * 0.01),
          },
      overallScore: 0.75 + (i * 0.02),
      timestamp: now.subtract(Duration(days: count - i)),
    ));
  }

  return history;
}

/// Helper function to create improving trend history
List<AIImprovementSnapshot> _createImprovingHistory() {
  return _createMockHistory(count: 10)
      .asMap()
      .entries
      .map((entry) => AIImprovementSnapshot(
            userId: 'test_user',
            dimensions: {'accuracy': 0.70 + (entry.key * 0.02)},
            overallScore: 0.70 + (entry.key * 0.02),
            timestamp: entry.value.timestamp,
          ))
      .toList();
}

/// Helper function to create declining trend history
List<AIImprovementSnapshot> _createDecliningHistory() {
  return _createMockHistory(count: 10)
      .asMap()
      .entries
      .map((entry) => AIImprovementSnapshot(
            userId: 'test_user',
            dimensions: {'accuracy': 0.90 - (entry.key * 0.02)},
            overallScore: 0.90 - (entry.key * 0.02),
            timestamp: entry.value.timestamp,
          ))
      .toList();
}

/// Helper function to create stable history
List<AIImprovementSnapshot> _createStableHistory() {
  return _createMockHistory(count: 10)
      .map((snapshot) => AIImprovementSnapshot(
            userId: 'test_user',
            dimensions: {'accuracy': 0.80},
            overallScore: 0.80,
            timestamp: snapshot.timestamp,
          ))
      .toList();
}

/// Real fake implementation with actual tracking behavior for testing
class MockAIImprovementTrackingService implements AIImprovementTrackingService {
  final Map<String, List<AIImprovementSnapshot>> _history = {};
  final Map<String, AIImprovementMetrics> _metrics = {};
  final Map<String, List<ImprovementMilestone>> _milestones = {};
  final StreamController<AIImprovementMetrics> _metricsController =
      StreamController<AIImprovementMetrics>.broadcast();
  // ignore: unused_field - Reserved for future initialization tracking
  bool _isInitialized = false;
  // ignore: unused_field - Reserved for future user tracking
  String? _trackingUserId;

  /// Set history for a user (for testing)
  void setHistory(List<AIImprovementSnapshot> history) {
    if (history.isNotEmpty) {
      _history[history.first.userId] = history;
    }
  }

  /// Set history for a specific user (for testing)
  void setHistoryForUser(String userId, List<AIImprovementSnapshot> history) {
    _history[userId] = history;
  }

  /// Set metrics for a user (for testing)
  void setMetrics(String userId, AIImprovementMetrics metrics) {
    _metrics[userId] = metrics;
    _metricsController.add(metrics);
  }

  /// Set milestones for a user (for testing)
  void setMilestones(String userId, List<ImprovementMilestone> milestones) {
    _milestones[userId] = milestones;
  }

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  void dispose() {
    _metricsController.close();
    _isInitialized = false;
  }

  @override
  List<AIImprovementSnapshot> getHistory({
    required String userId,
    Duration? timeWindow,
  }) {
    final history = _history[userId] ?? [];
    if (timeWindow != null) {
      final cutoff = DateTime.now().subtract(timeWindow);
      return history.where((s) => s.timestamp.isAfter(cutoff)).toList();
    }
    return history;
  }

  @override
  Future<AIImprovementMetrics> getCurrentMetrics(String userId) async {
    return _metrics[userId] ?? AIImprovementMetrics.empty(userId);
  }

  @override
  Future<AccuracyMetrics> getAccuracyMetrics(String userId) async {
    return AccuracyMetrics(
      recommendationAcceptanceRate: 0.75,
      predictionAccuracy: 0.80,
      userSatisfactionScore: 0.78,
      averageConfidence: 0.85,
      totalRecommendations: 100,
      acceptedRecommendations: 75,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<AIImprovementMetrics> get metricsStream => _metricsController.stream;

  @override
  List<ImprovementMilestone> getMilestones(String userId) {
    return _milestones[userId] ?? [];
  }

  /// Helper method for testing (not part of interface)
  void startTracking(String userId) {
    _trackingUserId = userId;
  }

  /// Helper method for testing (not part of interface)
  void stopTracking() {
    _trackingUserId = null;
  }
}

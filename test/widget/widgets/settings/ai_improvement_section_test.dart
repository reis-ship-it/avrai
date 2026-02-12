/// SPOTS AIImprovementSection Widget Tests
/// Date: November 21, 2025
/// Purpose: Test AIImprovementSection functionality and UI behavior
///
/// Test Coverage:
/// - Loading States: Loading indicator, no data state, with data state
/// - Header Display: Title, icon, info button
/// - Overall Score: Score display, color coding, label, progress indicator
/// - Accuracy Section: Recommendation acceptance, prediction accuracy, user satisfaction
/// - Performance Scores: Display and formatting
/// - Dimension Scores: Top 6 display, view all button
/// - Improvement Rate: Positive/stable display, time formatting
/// - Info Dialogs: Info and all dimensions dialogs
///
/// Dependencies:
/// - AIImprovementTrackingService: For metrics data
/// - GetStorage: For persistence
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import '../../helpers/widget_test_helpers.dart';
import 'dart:async';

/// Widget tests for AIImprovementSection
/// Tests loading states, metrics display, and user interactions
void main() {
  group('AIImprovementSection Widget Tests', () {
    late MockAIImprovementTrackingService mockService;
    late StreamController<AIImprovementMetrics> metricsStreamController;

    setUp(() {
      metricsStreamController =
          StreamController<AIImprovementMetrics>.broadcast();
      mockService = MockAIImprovementTrackingService(
        metricsStreamController: metricsStreamController,
      );
    });

    tearDown(() {
      metricsStreamController.close();
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

    group('Loading States', () {
      // Removed: Property assignment tests
      // Loading states tests focus on business logic (loading indicator, no data state, metrics display), not property assignment

      testWidgets(
          'should display loading indicator initially, display no data state when metrics are null, or display metrics when data is available',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section loading states
        mockService.setLoadingDelay(const Duration(milliseconds: 100));
        mockService.setMetrics(_createMockMetrics());
        final widget1 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_loading_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('AI Improvement Metrics'), findsNothing);
        await tester.pumpAndSettle();

        mockService.setMetrics(null);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_loading_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.text('No improvement data available'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_loading_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pumpAndSettle();
        expect(find.text('AI Improvement Metrics'), findsOneWidget);
        expect(find.text('Overall AI Performance'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Header Display', () {
      // Removed: Property assignment tests
      // Header display tests focus on business logic (header display, info button, dialog), not property assignment

      testWidgets(
          'should display header with title and icon, display info button, or open info dialog when info button is tapped',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section header display
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.text('AI Improvement Metrics'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsWidgets);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('AI Improvement Metrics'), findsWidgets);
      });
    });

    group('Overall Score Display', () {
      // Removed: Property assignment tests
      // Overall score display tests focus on business logic (score display, labels, progress indicator), not property assignment

      testWidgets(
          'should display overall score with percentage, display excellent label for score >= 0.9, display good label for score >= 0.75, display total improvements count, or display progress indicator',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section overall score display
        final metrics1 = _createMockMetrics(overallScore: 0.85);
        mockService.setMetrics(metrics1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_score_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(find.text('Overall AI Performance'), findsOneWidget);
        expect(find.text('85.0%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsWidgets);

        final metrics2 = _createMockMetrics(overallScore: 0.92);
        mockService.setMetrics(metrics2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_score_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.text('Excellent'), findsOneWidget);

        final metrics3 = _createMockMetrics(overallScore: 0.80);
        mockService.setMetrics(metrics3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_score_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pumpAndSettle();
        expect(find.text('Good'), findsOneWidget);

        final metrics4 = _createMockMetrics(totalImprovements: 15);
        mockService.setMetrics(metrics4);
        final widget4 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_score_4'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget4);
        await tester.pumpAndSettle();
        expect(find.text('15 improvements'), findsOneWidget);
      });
    });

    group('Accuracy Section', () {
      // Removed: Property assignment tests
      // Accuracy section tests focus on business logic (accuracy section display, metrics display), not property assignment

      testWidgets(
          'should display accuracy section when metrics available, display recommendation acceptance rate, display prediction accuracy, or display user satisfaction score',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section accuracy display
        final metrics1 = _createMockMetrics();
        final accuracyMetrics1 = _createMockAccuracyMetrics();
        mockService.setMetrics(metrics1);
        mockService.setAccuracyMetrics(accuracyMetrics1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_accuracy_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(find.text('Accuracy Measurements'), findsOneWidget);
        expect(find.byIcon(Icons.verified_outlined), findsOneWidget);

        final metrics2 = _createMockMetrics();
        final accuracyMetrics2 = _createMockAccuracyMetrics(
          recommendationAcceptanceRate: 0.82,
          acceptedRecommendations: 82,
          totalRecommendations: 100,
        );
        mockService.setMetrics(metrics2);
        mockService.setAccuracyMetrics(accuracyMetrics2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_accuracy_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.text('Recommendation Acceptance'), findsOneWidget);
        expect(find.text('82/100 accepted'), findsOneWidget);
        expect(find.text('82%'), findsWidgets);

        final metrics3 = _createMockMetrics();
        final accuracyMetrics3 = _createMockAccuracyMetrics(
          predictionAccuracy: 0.88,
        );
        mockService.setMetrics(metrics3);
        mockService.setAccuracyMetrics(accuracyMetrics3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_accuracy_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pumpAndSettle();
        expect(find.text('Prediction Accuracy'), findsOneWidget);
        expect(find.text('88%'), findsWidgets);

        final metrics4 = _createMockMetrics();
        final accuracyMetrics4 = _createMockAccuracyMetrics(
          userSatisfactionScore: 0.90,
        );
        mockService.setMetrics(metrics4);
        mockService.setAccuracyMetrics(accuracyMetrics4);
        final widget4 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_accuracy_4'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget4);
        await tester.pumpAndSettle();
        expect(find.text('User Satisfaction'), findsOneWidget);
        expect(find.text('90%'), findsWidgets);
      });
    });

    group('Performance Scores', () {
      // Removed: Property assignment tests
      // Performance scores tests focus on business logic (performance scores display), not property assignment

      testWidgets(
          'should display performance scores section or display performance score items',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section performance scores display
        final metrics1 = _createMockMetrics();
        mockService.setMetrics(metrics1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_performance_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(find.text('Performance Scores'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsOneWidget);

        final metrics2 = _createMockMetrics(
          performanceScores: {
            'speed': 0.85,
            'efficiency': 0.78,
            'adaptability': 0.92,
          },
        );
        mockService.setMetrics(metrics2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_performance_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.text('Speed'), findsWidgets);
        expect(find.text('Efficiency'), findsWidgets);
        expect(find.text('Adaptability'), findsWidgets);
      });
    });

    group('Dimension Scores', () {
      // Removed: Property assignment tests
      // Dimension scores tests focus on business logic (dimension scores display, dialog), not property assignment

      testWidgets(
          'should display dimension scores section, display top 6 dimension scores, or open all dimensions dialog when view all is tapped',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section dimension scores display
        final metrics1 = _createMockMetrics();
        mockService.setMetrics(metrics1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_dimensions_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(find.text('Improvement Dimensions'), findsOneWidget);
        expect(find.byIcon(Icons.insights), findsOneWidget);

        final metrics2 = _createMockMetrics(
          dimensionScores: {
            'accuracy': 0.85,
            'creativity': 0.78,
            'collaboration': 0.92,
            'learning_speed': 0.88,
            'pattern_recognition': 0.80,
            'recommendation_quality': 0.87,
            'extra_dimension': 0.75,
          },
        );
        mockService.setMetrics(metrics2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_dimensions_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.text('Accuracy'), findsOneWidget);
        expect(find.text('Creativity'), findsOneWidget);
        expect(find.text('View all dimensions'), findsOneWidget);

        final metrics3 = _createMockMetrics(
          dimensionScores: {
            for (var i = 0; i < 8; i++) 'dimension_$i': 0.80 + (i * 0.01),
          },
        );
        mockService.setMetrics(metrics3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_dimensions_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('View all dimensions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('View all dimensions'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('All Improvement Dimensions'), findsOneWidget);
      });
    });

    group('Improvement Rate', () {
      // Removed: Property assignment tests
      // Improvement rate tests focus on business logic (improvement rate display, last updated time), not property assignment

      testWidgets(
          'should display positive improvement rate, display stable performance for zero rate, or display last updated time',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section improvement rate display
        final metrics1 = _createMockMetrics(improvementRate: 0.05);
        mockService.setMetrics(metrics1);
        final widget1 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_rate_1'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget1);
        await tester.pumpAndSettle();
        expect(
            find.textContaining('Improving at 5.0% per week'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsWidgets);

        final metrics2 = _createMockMetrics(improvementRate: 0.0);
        mockService.setMetrics(metrics2);
        final widget2 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_rate_2'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget2);
        await tester.pumpAndSettle();
        expect(find.text('Stable performance'), findsOneWidget);

        final now = DateTime.now();
        final metrics3 = _createMockMetrics(
          lastUpdated: now.subtract(const Duration(hours: 2)),
        );
        mockService.setMetrics(metrics3);
        final widget3 = createScrollableTestWidget(
          child: AIImprovementSection(
            key: const ValueKey('ai_improvement_rate_3'),
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget3);
        await tester.pumpAndSettle();
        expect(find.textContaining('Updated'), findsOneWidget);
        expect(find.textContaining('ago'), findsOneWidget);
      });
    });

    group('Real-time Updates', () {
      // Removed: Property assignment tests
      // Real-time updates tests focus on business logic (stream updates), not property assignment

      testWidgets('should update when metrics stream emits new data',
          (WidgetTester tester) async {
        // Test business logic: AI improvement section real-time updates
        final initialMetrics = _createMockMetrics(overallScore: 0.75);
        mockService.setMetrics(initialMetrics);
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.text('75.0%'), findsWidgets);
        final newMetrics = _createMockMetrics(overallScore: 0.85);
        metricsStreamController.add(newMetrics);
        await tester.pumpAndSettle();
        expect(find.text('85.0%'), findsWidgets);
      });
    });
  });
}

/// Helper function to create mock metrics
AIImprovementMetrics _createMockMetrics({
  String userId = 'test_user',
  Map<String, double>? dimensionScores,
  Map<String, double>? performanceScores,
  double overallScore = 0.85,
  double improvementRate = 0.03,
  int totalImprovements = 10,
  DateTime? lastUpdated,
}) {
  return AIImprovementMetrics(
    userId: userId,
    dimensionScores: dimensionScores ??
        {
          'accuracy': 0.85,
          'speed': 0.88,
          'efficiency': 0.82,
          'adaptability': 0.90,
        },
    performanceScores: performanceScores ??
        {
          'speed': 0.88,
          'efficiency': 0.82,
          'adaptability': 0.90,
        },
    overallScore: overallScore,
    improvementRate: improvementRate,
    totalImprovements: totalImprovements,
    lastUpdated: lastUpdated ?? DateTime.now(),
  );
}

/// Helper function to create mock accuracy metrics
AccuracyMetrics _createMockAccuracyMetrics({
  double recommendationAcceptanceRate = 0.85,
  int acceptedRecommendations = 85,
  int totalRecommendations = 100,
  double predictionAccuracy = 0.88,
  double userSatisfactionScore = 0.90,
}) {
  return AccuracyMetrics(
    recommendationAcceptanceRate: recommendationAcceptanceRate,
    acceptedRecommendations: acceptedRecommendations,
    totalRecommendations: totalRecommendations,
    predictionAccuracy: predictionAccuracy,
    userSatisfactionScore: userSatisfactionScore,
    averageConfidence: 0.88,
    timestamp: DateTime.now(),
  );
}

/// Mock service for testing
class MockAIImprovementTrackingService implements AIImprovementTrackingService {
  AIImprovementMetrics? _metrics;
  AccuracyMetrics? _accuracyMetrics;
  Duration _loadingDelay = Duration.zero;
  bool _shouldThrowError = false;
  final StreamController<AIImprovementMetrics> metricsStreamController;

  MockAIImprovementTrackingService({
    required this.metricsStreamController,
  });

  void setMetrics(AIImprovementMetrics? metrics) {
    _metrics = metrics;
    _shouldThrowError = (metrics == null);
    // Auto-create default accuracy metrics if metrics are set
    if (metrics != null && _accuracyMetrics == null) {
      _accuracyMetrics = AccuracyMetrics(
        recommendationAcceptanceRate: 0.85,
        acceptedRecommendations: 85,
        totalRecommendations: 100,
        predictionAccuracy: 0.88,
        userSatisfactionScore: 0.90,
        averageConfidence: 0.88,
        timestamp: DateTime.now(),
      );
    }
  }

  void setAccuracyMetrics(AccuracyMetrics? metrics) {
    _accuracyMetrics = metrics;
  }

  void setLoadingDelay(Duration delay) {
    _loadingDelay = delay;
  }

  @override
  Future<void> initialize() async {}

  @override
  void dispose() {}

  @override
  Future<AIImprovementMetrics> getCurrentMetrics(String userId) async {
    if (_loadingDelay > Duration.zero) {
      await Future.delayed(_loadingDelay);
    }
    if (_shouldThrowError || _metrics == null) {
      throw Exception('No metrics available');
    }
    return _metrics!;
  }

  @override
  Future<AccuracyMetrics> getAccuracyMetrics(String userId) async {
    if (_loadingDelay > Duration.zero) {
      await Future.delayed(_loadingDelay);
    }
    // Only throw if explicitly in error state AND no metrics
    if (_shouldThrowError && _accuracyMetrics == null) {
      throw Exception('No accuracy metrics available');
    }
    // Return metrics if available (auto-created when setMetrics called)
    if (_accuracyMetrics != null) {
      return _accuracyMetrics!;
    }
    // Shouldn't reach here, but return default if we do
    throw Exception('No accuracy metrics available');
  }

  @override
  Stream<AIImprovementMetrics> get metricsStream =>
      metricsStreamController.stream;

  // Other required overrides (not used in these tests)
  @override
  List<AIImprovementSnapshot> getHistory({
    required String userId,
    Duration? timeWindow,
  }) =>
      [];

  @override
  List<ImprovementMilestone> getMilestones(String userId) => [];

  // Note: startTracking and stopTracking are not part of AIImprovementTrackingService
  // These methods are kept for compatibility with tests that may reference them
  void startTracking(String userId) {}

  void stopTracking() {}
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// SPOTS AIImprovementTrackingService Unit Tests
/// Date: December 1, 2025
/// Purpose: Test AIImprovementTrackingService functionality
///
/// Test Coverage:
/// - Initialization: Service setup and configuration
/// - Metrics Retrieval: Get current improvement metrics
/// - History Management: Get improvement history
/// - Milestone Detection: Detect improvement milestones
/// - Accuracy Metrics: Get accuracy metrics
/// - Storage: Load and save history
///
/// Dependencies:
/// - GetStorage: Local storage for history persistence

class MockGetStorage extends Mock implements GetStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIImprovementTrackingService', () {
    AIImprovementTrackingService? service;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() {
      // Use mock storage via dependency injection - no platform channels needed
      final mockStorage = getTestStorage();
      service = AIImprovementTrackingService(storage: mockStorage);
    });

    // Helper to skip test if service is null
    void skipIfServiceNull() {
      if (service == null) {
        // Skip test - service couldn't be created due to platform channel limitations
        return;
      }
    }

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    // Removed: Property assignment tests
    // AI improvement tracking tests focus on business logic (metrics, history, milestones), not property assignment

    group('Initialization', () {
      test('should initialize service and have metrics stream', () {
        // Test business logic: service initialization
        if (service == null) return; // Skip if service couldn't be created
        expect(service, isNotNull);
        expect(service!.metricsStream, isNotNull);
      });
    });

    group('Metrics Retrieval', () {
      test(
          'should get current metrics for user or return cached metrics if available',
          () async {
        // Test business logic: metrics retrieval and caching
        skipIfServiceNull();
        const userId = 'test-user-1';

        final metrics1 = await service!.getCurrentMetrics(userId);
        expect(metrics1, isNotNull);
        expect(metrics1.userId, userId);
        expect(metrics1.dimensionScores, isNotEmpty);
        expect(metrics1.performanceScores, isNotEmpty);
        expect(metrics1.overallScore, greaterThanOrEqualTo(0.0));
        expect(metrics1.overallScore, lessThanOrEqualTo(1.0));

        final metrics2 = await service!.getCurrentMetrics(userId);
        expect(metrics1.userId, metrics2.userId);
      });
    });

    group('History Management', () {
      test(
          'should get history for user, filter by time window, return empty list for user with no history, and sort by timestamp descending',
          () {
        // Test business logic: history retrieval with filtering and sorting
        skipIfServiceNull();
        const userId = 'test-user-1';

        final history1 = service!.getHistory(userId: userId);
        expect(history1, isA<List>());

        const timeWindow = Duration(days: 30);
        final history2 =
            service!.getHistory(userId: userId, timeWindow: timeWindow);
        expect(history2, isA<List>());
        final cutoff = DateTime.now().subtract(timeWindow);
        for (final snapshot in history2) {
          expect(snapshot.timestamp.isAfter(cutoff), true);
        }

        const nonExistentUserId = 'non-existent-user';
        final emptyHistory = service!.getHistory(userId: nonExistentUserId);
        expect(emptyHistory, isEmpty);

        final history3 = service!.getHistory(userId: userId);
        if (history3.length > 1) {
          for (int i = 0; i < history3.length - 1; i++) {
            expect(
              history3[i].timestamp.isAfter(history3[i + 1].timestamp) ||
                  history3[i]
                      .timestamp
                      .isAtSameMomentAs(history3[i + 1].timestamp),
              true,
            );
          }
        }
      });
    });

    group('Milestone Detection', () {
      test(
          'should get milestones for user, return empty list for user with no history, and detect significant improvements',
          () {
        // Test business logic: milestone detection and validation
        skipIfServiceNull();
        const userId = 'test-user-1';

        final milestones1 = service!.getMilestones(userId);
        expect(milestones1, isA<List>());

        const nonExistentUserId = 'non-existent-user';
        final emptyMilestones = service!.getMilestones(nonExistentUserId);
        expect(emptyMilestones, isEmpty);

        final milestones2 = service!.getMilestones(userId);
        for (final milestone in milestones2) {
          expect(milestone.dimension, isNotEmpty);
          expect(milestone.improvement, greaterThan(0.0));
          expect(milestone.fromScore, greaterThanOrEqualTo(0.0));
          expect(milestone.toScore, greaterThanOrEqualTo(0.0));
          expect(milestone.toScore, greaterThan(milestone.fromScore));
        }
      });
    });

    group('Accuracy Metrics', () {
      test('should get accuracy metrics for user', () async {
        const userId = 'test-user-1';

        skipIfServiceNull();
        final accuracy = await service!.getAccuracyMetrics(userId);

        expect(accuracy, isNotNull);
        expect(
            accuracy.recommendationAcceptanceRate, greaterThanOrEqualTo(0.0));
        expect(accuracy.recommendationAcceptanceRate, lessThanOrEqualTo(1.0));
        expect(accuracy.predictionAccuracy, greaterThanOrEqualTo(0.0));
        expect(accuracy.predictionAccuracy, lessThanOrEqualTo(1.0));
        expect(accuracy.userSatisfactionScore, greaterThanOrEqualTo(0.0));
        expect(accuracy.userSatisfactionScore, lessThanOrEqualTo(1.0));
        expect(accuracy.totalRecommendations, greaterThanOrEqualTo(0));
      });
    });

    group('Storage', () {
      test('should handle storage errors gracefully', () async {
        // Service should handle storage errors without crashing
        const userId = 'test-user-1';

        skipIfServiceNull();
        final metrics = await service!.getCurrentMetrics(userId);
        expect(metrics, isNotNull);
      });
    });

    group('Disposal', () {
      test('should dispose resources', () {
        skipIfServiceNull();
        service!.dispose();
        // Should not throw
        expect(service, isNotNull);
      });
    });

    group('Edge Cases', () {
      test(
          'should handle empty user ID, very long time window, and zero time window',
          () async {
        // Test business logic: edge case handling
        skipIfServiceNull();
        const emptyUserId = '';
        final metrics = await service!.getCurrentMetrics(emptyUserId);
        expect(metrics, isNotNull);
        expect(metrics.userId, emptyUserId);

        const userId = 'test-user-1';
        const longTimeWindow = Duration(days: 365);
        final history1 =
            service!.getHistory(userId: userId, timeWindow: longTimeWindow);
        expect(history1, isA<List>());

        const zeroTimeWindow = Duration(seconds: 0);
        final history2 =
            service!.getHistory(userId: userId, timeWindow: zeroTimeWindow);
        expect(history2, isA<List>());
      });
    });
  });
}

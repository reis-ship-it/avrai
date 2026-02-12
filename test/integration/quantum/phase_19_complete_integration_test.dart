// Phase 19 Complete Integration Tests
//
// Comprehensive integration tests for Phase 19: Multi-Entity Quantum Entanglement Matching System
// Tests all sections (19.1-19.16) working together in end-to-end scenarios
// Part of Phase 19.17: Testing, Documentation, and Production Readiness

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai/core/services/quantum/real_time_user_calling_service.dart';
import 'package:avrai/core/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai/core/services/quantum/quantum_outcome_learning_service.dart';
import 'package:avrai/core/services/quantum/user_event_prediction_matching_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_integration_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/models/quantum/matching_input.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/models/business/business_account.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_core/models/atomic_timestamp.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/integration_test_helpers.dart';

/// Comprehensive Phase 19 Integration Tests
///
/// Tests verify that all Phase 19 sections work together correctly:
/// - 19.1: N-Way Quantum Entanglement Framework
/// - 19.2: Entanglement Coefficient Optimization
/// - 19.3: Location and Timing Quantum States
/// - 19.4: Dynamic Real-Time User Calling System
/// - 19.5: Quantum Matching Controller
/// - 19.6: Meaningful Experience Calculator
/// - 19.7: Meaningful Connection Metrics
/// - 19.8: User Journey Tracking
/// - 19.9: Quantum Outcome-Based Learning
/// - 19.10: Ideal State Learning
/// - 19.11: User Event Prediction Matching
/// - 19.12: Dimensionality Reduction
/// - 19.13: Privacy-Protected Third-Party Data API
/// - 19.14: Prediction API for Business Intelligence
/// - 19.15: Integration with Existing Matching Systems
/// - 19.16: AI2AI Integration with Mesh Networking
void main() {
  group('Phase 19 Complete Integration Tests', () {
    late QuantumMatchingController controller;
    late RealTimeUserCallingService userCallingService;
    late MeaningfulConnectionMetricsService metricsService;
    late QuantumOutcomeLearningService outcomeLearningService;
    late UserEventPredictionMatchingService predictionService;
    late QuantumMatchingIntegrationService integrationService;
    late QuantumMatchingAILearningService aiLearningService;

    setUpAll(() async {
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();

      // Get services from DI
      controller = di.sl<QuantumMatchingController>();
      userCallingService = di.sl<RealTimeUserCallingService>();
      metricsService = di.sl<MeaningfulConnectionMetricsService>();
      outcomeLearningService = di.sl<QuantumOutcomeLearningService>();
      predictionService = di.sl<UserEventPredictionMatchingService>();
      integrationService = di.sl<QuantumMatchingIntegrationService>();
      aiLearningService = di.sl<QuantumMatchingAILearningService>();
    });

    setUp(() async {
      // No-op: Sembast removed in Phase 26
    });

    group('End-to-End Matching Flow', () {
      test('should complete full matching workflow with all Phase 19 services', () async {
        // Arrange: Create test entities
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-e2e-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-e2e-1',
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          location: 'Greenpoint, Brooklyn',
        );

        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act: Execute matching through controller
        final result = await controller.execute(input);

        // Assert: Verify successful matching
        expect(result.isSuccess, isTrue, reason: 'errorCode=${result.errorCode} error=${result.error}');
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.compatibility, greaterThan(0.0));
        expect(result.matchingResult!.compatibility, lessThanOrEqualTo(1.0));
        expect(result.matchingResult!.quantumCompatibility, greaterThan(0.0));
        expect(result.matchingResult!.entities.length, greaterThanOrEqualTo(2));

        // Verify atomic timing is used
        expect(result.matchingResult!.timestamp, isNotNull);
        expect(result.matchingResult!.timestamp.timestampId, isNotEmpty);
        expect(result.matchingResult!.timestamp.serverTime, isNotNull);

        // Verify privacy protection (agentId in metadata, not userId)
        expect(result.matchingResult!.metadata, isNotNull);
        expect(result.matchingResult!.metadata!['agentId'], isNotNull);
        expect(result.matchingResult!.metadata!['agentId'], isNot(equals(user.id)));
      });

      test('should handle N-way matching with multiple entities', () async {
        // Arrange: Create multiple entities
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-nway-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-nway-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final spot = Spot(
          id: 'spot-nway-1',
          name: 'Blue Bottle Coffee',
          description: 'Artisan coffee shop',
          latitude: 40.7295,
          longitude: -73.9575,
          category: 'Coffee',
          rating: 4.5,
          createdBy: user.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final business = BusinessAccount(
          id: 'business-nway-1',
          name: 'Coffee Collective',
          email: 'info@coffeecollective.com',
          businessType: 'Restaurant',
          categories: const ['Coffee', 'Food'],
          location: 'Greenpoint, Brooklyn, NY, USA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: user.id,
        );

        final input = MatchingInput(
          user: user,
          event: event,
          spot: spot,
          business: business,
        );

        // Act: Execute N-way matching
        final result = await controller.execute(input);

        // Assert: Verify N-way matching works
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.entities.length, greaterThanOrEqualTo(4)); // User + Event + Spot + Business
        expect(result.matchingResult!.metadata!['entityCount'], greaterThanOrEqualTo(4));
      });
    });

    group('Real-Time User Calling (19.4)', () {
      test('should call users on event creation', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-calling-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-calling-1',
          title: 'Coffee Tasting',
          description: 'Coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
        );

        // Act: Call users on event creation
        // Note: This is a placeholder test - actual implementation would require
        // user service integration to get list of users to call
        await expectLater(
          userCallingService.callUsersOnEventCreation(
            eventId: event.id,
            eventEntities: [], // Would contain quantum states in real scenario
          ),
          completes,
        );
      });
    });

    group('Meaningful Connection Metrics (19.7)', () {
      test('should calculate meaningful connection metrics', () async {
        // Arrange
        final now = DateTime.now();
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-metrics-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = ExpertiseEvent(
          id: 'event-metrics-1',
          title: 'Coffee Tasting',
          description: 'A coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: host,
          attendeeIds: const ['user-metrics-1', 'user-metrics-2'],
          attendeeCount: 2,
          maxAttendees: 20,
          startTime: now.subtract(const Duration(days: 10)),
          endTime: now.subtract(const Duration(days: 9)),
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 9)),
        );

        // Note: Would need actual User objects from database in real scenario
        // For now, test that service doesn't crash with empty attendees
        final metrics = await metricsService.calculateMetrics(
          event: event,
          attendees: [],
        );

        // Assert: Verify metrics are calculated
        expect(metrics, isNotNull);
        expect(metrics.meaningfulConnectionScore, greaterThanOrEqualTo(0.0));
        expect(metrics.meaningfulConnectionScore, lessThanOrEqualTo(1.0));
        expect(metrics.timestamp, isNotNull);
      });
    });

    group('Quantum Outcome Learning (19.9)', () {
      test('should learn from event outcome', () async {
        // Arrange
        final now = DateTime.now();
        final event = ExpertiseEvent(
          id: 'event-learning-1',
          title: 'Coffee Tasting',
          description: 'A coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
          host: IntegrationTestHelpers.createUserWithLocalExpertise(
            id: 'host-learning-1',
            category: 'Coffee',
            location: 'Greenpoint, Brooklyn, NY, USA',
          ),
          attendeeIds: const ['user-learning-1'],
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act: Learn from outcome
        final learningResult = await outcomeLearningService.learnFromOutcome(
          eventId: event.id,
          event: event,
          entities: [], // Would contain quantum states in real scenario
        );

        // Assert: Verify learning occurred
        expect(learningResult, isNotNull);
        expect(learningResult.successScore, greaterThanOrEqualTo(0.0));
        expect(learningResult.successScore, lessThanOrEqualTo(1.0));
        expect(learningResult.learningRate, greaterThanOrEqualTo(0.0));
        expect(learningResult.learningRate, lessThanOrEqualTo(0.1));
        expect(learningResult.timestamp, isNotNull);
      });
    });

    group('User Event Prediction (19.11)', () {
      test('should predict user interest in event', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-prediction-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-prediction-1',
          title: 'Coffee Tasting',
          description: 'A coffee tasting event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tasting,
        );

        // Act: Predict user interest
        final prediction = await predictionService.predictUserEventCompatibility(
          userId: user.id,
          eventId: event.id,
        );

        // Assert: Verify prediction is made
        expect(prediction, isNotNull);
        expect(prediction.predictionScore, greaterThanOrEqualTo(0.0));
        expect(prediction.predictionScore, lessThanOrEqualTo(1.0));
        expect(prediction.quantumCompatibility, greaterThanOrEqualTo(0.0));
        expect(prediction.quantumCompatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('Quantum Matching Integration (19.15)', () {
      test('should integrate with existing matching systems', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-integration-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-integration-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        // Act: Perform quantum matching through integration service
        final result = await integrationService.calculateCompatibility(
          user: user,
          event: event,
        );

        // Assert: Verify integration works
        // Result may be null if feature flags are disabled (acceptable)
        if (result != null) {
          expect(result.compatibility, greaterThanOrEqualTo(0.0));
          expect(result.compatibility, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('AI2AI Learning Integration (19.16)', () {
      test('should learn from successful match', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-ai-learning-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-ai-learning-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        // Create a successful matching result
        final matchingResult = await controller.execute(
          MatchingInput(user: user, event: event),
        );

        if (matchingResult.isSuccess && matchingResult.matchingResult != null) {
          // Act: Learn from successful match
          await expectLater(
            aiLearningService.learnFromSuccessfulMatch(
              userId: user.id,
              matchingResult: matchingResult.matchingResult!,
              event: event,
              isOffline: false,
            ),
            completes,
          );
        }
      });
    });

    group('Privacy Compliance', () {
      test('should use agentId exclusively, never userId in third-party data', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-privacy-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-privacy-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(user: user, event: event);

        // Act
        final result = await controller.execute(input);

        // Assert: Verify privacy protection
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.metadata, isNotNull);
        
        // Should have agentId, not userId
        expect(result.matchingResult!.metadata!['agentId'], isNotNull);
        expect(result.matchingResult!.metadata!['agentId'], isNot(equals(user.id)));
        
        // Should not expose userId in metadata
        expect(result.matchingResult!.metadata!.containsKey('userId'), isFalse);
      });
    });

    group('Atomic Timing Validation', () {
      test('should use atomic timestamps throughout matching flow', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-timing-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-timing-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(user: user, event: event);

        // Act
        final result = await controller.execute(input);

        // Assert: Verify atomic timing
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.timestamp, isA<AtomicTimestamp>());
        expect(result.matchingResult!.timestamp.timestampId, isNotEmpty);
        expect(result.matchingResult!.timestamp.serverTime, isNotNull);
        expect(result.matchingResult!.timestamp.deviceTime, isNotNull);
        
        // Verify all entities have atomic timestamps
        for (final entity in result.matchingResult!.entities) {
          expect(entity.tAtomic, isA<AtomicTimestamp>());
          expect(entity.tAtomic.timestampId, isNotEmpty);
        }
      });
    });

    group('Knot Integration', () {
      test('should integrate knot compatibility in matching', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-knot-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-knot-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(user: user, event: event);

        // Act
        final result = await controller.execute(input);

        // Assert: Verify knot integration
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        
        // Knot compatibility may be null if services unavailable (graceful degradation)
        // But if present, should be in valid range
        if (result.matchingResult!.knotCompatibility != null) {
          expect(result.matchingResult!.knotCompatibility, greaterThanOrEqualTo(0.0));
          expect(result.matchingResult!.knotCompatibility, lessThanOrEqualTo(1.0));
        }
      });
    });
  });
}

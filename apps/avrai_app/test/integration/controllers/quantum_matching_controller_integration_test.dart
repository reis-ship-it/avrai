// Quantum Matching Controller Integration Tests
//
// Tests controller with real service implementations from DI
// Part of Phase 19 Section 19.5: Quantum Matching Controller

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_core/models/quantum/matching_input.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/business/business_account.dart';

import 'package:avrai/injection_container.dart' as di;
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/integration_test_helpers.dart';

/// Integration tests for QuantumMatchingController
///
/// Tests verify that the controller works correctly when integrated
/// with real services from dependency injection:
/// - AtomicClockService
/// - QuantumEntanglementService
/// - LocationTimingQuantumStateService
/// - PersonalityLearning
/// - UserVibeAnalyzer
/// - AgentIdService
/// - PreferencesProfileService
/// - IntegratedKnotRecommendationEngine (optional)
/// - CrossEntityCompatibilityService (optional)
void main() {
  group('QuantumMatchingController Integration Tests', () {
    late QuantumMatchingController controller;

    setUpAll(() async {
      // Initialize Sembast for tests
      // Sembast removed in Phase 26

      // Initialize dependency injection
      await setupTestStorage();
      await di.init();

      // Get controller from DI
      controller = di.sl<QuantumMatchingController>();
    });

    setUp(() async {
      // Reset database for each test
      // No-op: Sembast removed in Phase 26
    });

    tearDown(() async {
      // Clean up test data - database is reset in setUp, so no manual cleanup needed
    });

    group('execute', () {
      test('should successfully perform matching with event', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-1',
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops in Greenpoint',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          location: 'Greenpoint, Brooklyn',
        );

        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(
          result.isSuccess,
          isTrue,
          reason: 'errorCode=${result.errorCode} error=${result.error}',
        );
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.compatibility, greaterThan(0.0));
        expect(result.matchingResult!.compatibility, lessThanOrEqualTo(1.0));
        expect(result.matchingResult!.quantumCompatibility, greaterThan(0.0));
        expect(result.matchingResult!.quantumCompatibility,
            lessThanOrEqualTo(1.0));
        expect(result.matchingResult!.locationCompatibility,
            greaterThanOrEqualTo(0.0));
        expect(result.matchingResult!.locationCompatibility,
            lessThanOrEqualTo(1.0));
        expect(result.matchingResult!.timingCompatibility,
            greaterThanOrEqualTo(0.0));
        expect(
            result.matchingResult!.timingCompatibility, lessThanOrEqualTo(1.0));
        expect(result.matchingResult!.entities.length,
            greaterThanOrEqualTo(2)); // User + Event
        expect(result.matchingResult!.timestamp, isNotNull);
        expect(result.matchingResult!.metadata, isNotNull);
        expect(result.matchingResult!.metadata!['agentId'], isNotNull);
        expect(result.matchingResult!.metadata!['entityCount'],
            greaterThanOrEqualTo(2));
      });

      test('should successfully perform matching with spot', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-2',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final now = DateTime.now();
        final spot = Spot(
          id: 'spot-1',
          name: 'Blue Bottle Coffee',
          description: 'Artisan coffee shop',
          latitude: 40.7295,
          longitude: -73.9575,
          category: 'Coffee',
          rating: 4.5,
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        );

        final input = MatchingInput(
          user: user,
          spot: spot,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(
          result.isSuccess,
          isTrue,
          reason: 'errorCode=${result.errorCode} error=${result.error}',
        );
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.compatibility, greaterThan(0.0));
        expect(result.matchingResult!.entities.length,
            greaterThanOrEqualTo(2)); // User + Spot
      });

      test('should successfully perform matching with business', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-3',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final business = BusinessAccount(
          id: 'business-1',
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
          business: business,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(
          result.isSuccess,
          isTrue,
          reason: 'errorCode=${result.errorCode} error=${result.error}',
        );
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.compatibility, greaterThan(0.0));
        expect(result.matchingResult!.entities.length,
            greaterThanOrEqualTo(2)); // User + Business
      });

      test('should successfully perform matching with multiple entities',
          () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-4',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-2',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final spot = Spot(
          id: 'spot-2',
          name: 'Stumptown Coffee',
          description: 'Portland-based coffee roaster',
          latitude: 40.7295,
          longitude: -73.9575,
          category: 'Coffee',
          rating: 4.7,
          createdBy: user.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final input = MatchingInput(
          user: user,
          event: event,
          spot: spot,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(
          result.isSuccess,
          isTrue,
          reason: 'errorCode=${result.errorCode} error=${result.error}',
        );
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.entities.length,
            greaterThanOrEqualTo(3)); // User + Event + Spot
        expect(result.matchingResult!.metadata!['entityCount'],
            greaterThanOrEqualTo(3));
      });

      test('should handle validation errors correctly', () async {
        // Arrange
        final now = DateTime.now();
        final user = UnifiedUser(
          id: '',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final input = MatchingInput(
          user: user,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('VALIDATION_ERROR'));
        expect(result.matchingResult, isNull);
      });

      test('should return privacy-protected agentId in metadata', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-5',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-3',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(
          result.isSuccess,
          isTrue,
          reason: 'errorCode=${result.errorCode} error=${result.error}',
        );
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.metadata, isNotNull);
        expect(result.matchingResult!.metadata!['agentId'], isNotNull);
        expect(result.matchingResult!.metadata!['agentId'],
            isNot(equals(user.id))); // Should be different from user ID
      });

      test('should use atomic timestamps for matching operations', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-6',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-4',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.timestamp, isNotNull);
        expect(result.matchingResult!.timestamp.timestampId, isNotEmpty);
        expect(result.matchingResult!.timestamp.serverTime, isNotNull);
        expect(result.matchingResult!.timestamp.deviceTime, isNotNull);
      });

      test('should calculate compatibility scores correctly', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-7',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-5',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          location: 'Greenpoint, Brooklyn',
        );

        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);

        // All compatibility scores should be in valid range
        expect(
            result.matchingResult!.compatibility, inInclusiveRange(0.0, 1.0));
        expect(result.matchingResult!.quantumCompatibility,
            inInclusiveRange(0.0, 1.0));
        expect(result.matchingResult!.locationCompatibility,
            inInclusiveRange(0.0, 1.0));
        expect(result.matchingResult!.timingCompatibility,
            inInclusiveRange(0.0, 1.0));

        // Combined compatibility should be weighted combination
        expect(result.matchingResult!.compatibility, greaterThan(0.0));
      });

      test('should handle missing optional services gracefully', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-8',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-6',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(
          user: user,
          event: event,
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        // Should still work even if optional services (knot compatibility) are unavailable
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        // Knot compatibility may be null if services unavailable
        // This is acceptable - graceful degradation
      });
    });
  });
}

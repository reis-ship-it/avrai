// Knot Recommendation Integration Tests
//
// Tests EventRecommendationService, EventMatchingService, and SpotVibeMatchingService
// with knot integration enabled
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Optional Enhancement: Integration Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_runtime_os/services/events/event_matching_service.dart';
import 'package:avrai_runtime_os/services/matching/spot_vibe_matching_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/matching/user_preference_learning_service.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_locality_connection_service.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/test_helpers.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for recommendation services with knot integration
void main() {
  group('Knot Recommendation Integration Tests', () {
    late EventRecommendationService eventRecommendationService;
    late EventMatchingService eventMatchingService;
    late SpotVibeMatchingService spotVibeMatchingService;

    late ExpertiseEventService eventService;
    late PersonalityKnotService personalityKnotService;
    late EntityKnotService entityKnotService;
    late IntegratedKnotRecommendationEngine knotRecommendationEngine;
    late PersonalityLearning personalityLearning;
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    late StorageService storageService;

    late UnifiedUser testUser;
    late PersonalityProfile testPersonality;

    setUp(() async {
      TestHelpers.setupTestEnvironment();

      // Initialize storage (test mode, avoids path_provider / GetStorage.init)
      await setupTestStorage();
      storageService = StorageService.instance;

      // Initialize knot services
      personalityKnotService = PersonalityKnotService();
      entityKnotService = EntityKnotService(
        personalityKnotService: personalityKnotService,
      );

      knotRecommendationEngine = IntegratedKnotRecommendationEngine(
        knotService: personalityKnotService,
      );

      // Initialize personality learning with real storage for testing
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      personalityLearning = PersonalityLearning.withPrefs(prefs);

      // Initialize event service
      eventService = ExpertiseEventService();

      // Initialize recommendation services with knot integration
      eventRecommendationService = EventRecommendationService(
        eventService: eventService,
        matchingService: EventMatchingService(
          eventService: eventService,
          knotRecommendationEngine: knotRecommendationEngine,
          personalityLearning: personalityLearning,
        ),
        preferenceService: UserPreferenceLearningService(),
        crossLocalityService: CrossLocalityConnectionService(),
        knotRecommendationEngine: knotRecommendationEngine,
        personalityLearning: personalityLearning,
      );

      eventMatchingService = EventMatchingService(
        eventService: eventService,
        knotRecommendationEngine: knotRecommendationEngine,
        personalityLearning: personalityLearning,
      );

      final prefsForVibe = await SharedPreferencesCompat.getInstance();

      spotVibeMatchingService = SpotVibeMatchingService(
        vibeAnalyzer: UserVibeAnalyzer(prefs: prefsForVibe),
        entityKnotService: entityKnotService,
        personalityKnotService: personalityKnotService,
      );

      // Create test user and personality
      testUser = ModelFactories.createTestUser(
        id: 'test-user-1',
        displayName: 'Test User',
      );

      testPersonality = PersonalityProfile.initial(
        'agent-test-user-1',
        userId: testUser.id,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('EventRecommendationService with Knot Integration', () {
      test('should generate recommendations with knot compatibility bonus',
          () async {
        // Arrange
        // Note: This test verifies the service works with knot integration
        // Actual recommendations depend on available events

        // Act
        final recommendations =
            await eventRecommendationService.getPersonalizedRecommendations(
          user: testUser,
          maxResults: 10,
        );

        // Assert
        expect(recommendations, isA<List<EventRecommendation>>());
        // Service should work without errors even if no events are available
      });

      test('should handle null knot recommendation engine gracefully',
          () async {
        // Arrange
        final serviceWithoutKnots = EventRecommendationService(
          eventService: eventService,
          matchingService: EventMatchingService(
            eventService: eventService,
            knotRecommendationEngine: null,
            personalityLearning: personalityLearning,
          ),
          preferenceService: UserPreferenceLearningService(),
          crossLocalityService: CrossLocalityConnectionService(),
          knotRecommendationEngine: null,
          personalityLearning: personalityLearning,
        );

        // Act
        final recommendations =
            await serviceWithoutKnots.getPersonalizedRecommendations(
          user: testUser,
          maxResults: 10,
        );

        // Assert
        expect(recommendations, isA<List<EventRecommendation>>());
        // Service should work without knot integration
      });
    });

    group('EventMatchingService with Knot Integration', () {
      test('should calculate matching score with knot compatibility', () async {
        // Arrange
        final expert = ModelFactories.createTestUser(
          id: 'expert-1',
          displayName: 'Expert User',
        );

        // Act
        final score = await eventMatchingService.calculateMatchingScore(
          expert: expert,
          user: testUser,
          category: 'Coffee',
          locality: 'Mission District, San Francisco',
        );

        // Assert
        expect(score, isA<double>());
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
        // Score should include knot compatibility bonus if knots are available
      });

      test('should handle null knot recommendation engine gracefully',
          () async {
        // Arrange
        final serviceWithoutKnots = EventMatchingService(
          eventService: eventService,
          knotRecommendationEngine: null,
          personalityLearning: personalityLearning,
        );

        final expert = ModelFactories.createTestUser(
          id: 'expert-1',
          displayName: 'Expert User',
        );

        // Act
        final score = await serviceWithoutKnots.calculateMatchingScore(
          expert: expert,
          user: testUser,
          category: 'Coffee',
          locality: 'Mission District, San Francisco',
        );

        // Assert
        expect(score, isA<double>());
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
        // Service should work without knot integration
      });
    });

    group('SpotVibeMatchingService with Knot Integration', () {
      test('should calculate spot-user compatibility with knot bonus',
          () async {
        // Arrange
        final spot = Spot(
          id: 'spot-1',
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'Coffee',
          rating: 4.5,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          address: 'San Francisco, CA',
        );

        final spotVibe = SpotVibe(
          spotId: 'spot-1',
          vibeDimensions: {
            'exploration_eagerness': 0.7,
            'community_orientation': 0.8,
            'adventure_seeking': 0.6,
          },
          vibeDescription: 'A test spot vibe',
          overallEnergy: 0.7,
          socialPreference: 0.8,
          explorationTendency: 0.6,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final compatibility =
            await spotVibeMatchingService.calculateSpotUserCompatibility(
          user: testUser,
          spot: spot,
          userPersonality: testPersonality,
          spotVibe: spotVibe,
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        // Compatibility should include knot bonus if knots are available
      });

      test('should handle null knot services gracefully', () async {
        // Arrange
        final prefsForVibe2 = await SharedPreferencesCompat.getInstance();

        final serviceWithoutKnots = SpotVibeMatchingService(
          vibeAnalyzer: UserVibeAnalyzer(prefs: prefsForVibe2),
          entityKnotService: null,
          personalityKnotService: null,
        );

        final spot = Spot(
          id: 'spot-1',
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'Coffee',
          rating: 4.5,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          address: 'San Francisco, CA',
        );

        final spotVibe = SpotVibe(
          spotId: 'spot-1',
          vibeDimensions: {
            'exploration_eagerness': 0.7,
            'community_orientation': 0.8,
          },
          vibeDescription: 'A test spot vibe',
          overallEnergy: 0.7,
          socialPreference: 0.8,
          explorationTendency: 0.6,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final compatibility =
            await serviceWithoutKnots.calculateSpotUserCompatibility(
          user: testUser,
          spot: spot,
          userPersonality: testPersonality,
          spotVibe: spotVibe,
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        // Service should work without knot integration
      });
    });

    group('Knot Integration Compatibility', () {
      test('all services should work together with knot integration', () async {
        // Arrange
        final expert = ModelFactories.createTestUser(
          id: 'expert-1',
          displayName: 'Expert User',
        );

        // Act & Assert - Verify all services work together
        final matchingScore = await eventMatchingService.calculateMatchingScore(
          expert: expert,
          user: testUser,
          category: 'Coffee',
          locality: 'Mission District, San Francisco',
        );
        expect(matchingScore, isA<double>());

        final recommendations =
            await eventRecommendationService.getPersonalizedRecommendations(
          user: testUser,
          maxResults: 5,
        );
        expect(recommendations, isA<List<EventRecommendation>>());

        final spot = Spot(
          id: 'spot-1',
          name: 'Test Spot',
          description: 'A test spot',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'Coffee',
          rating: 4.5,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          address: 'San Francisco, CA',
        );

        final spotCompatibility =
            await spotVibeMatchingService.calculateSpotUserCompatibility(
          user: testUser,
          spot: spot,
          userPersonality: testPersonality,
        );
        expect(spotCompatibility, isA<double>());

        // All services should work together without errors
      });
    });
  });
}

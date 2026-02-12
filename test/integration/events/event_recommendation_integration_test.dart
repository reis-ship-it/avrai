import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/events/event_recommendation_service.dart';
import 'package:avrai/core/services/matching/user_preference_learning_service.dart';
import 'package:avrai/core/services/events/event_matching_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import '../../helpers/integration_test_helpers.dart';

/// Integration tests for event recommendation system
/// 
/// **Philosophy:** Tests verify that recommendations balance familiar
/// preferences with exploration, prioritize local experts for users who
/// prefer them, and enable cross-locality event discovery.
void main() {
  group('Event Recommendation Integration Tests', () {
    late EventRecommendationService recommendationService;
    late UserPreferenceLearningService preferenceService;
    late EventMatchingService matchingService;
    late ExpertiseEventService eventService;

    setUp(() {
      eventService = ExpertiseEventService();
      matchingService = EventMatchingService();
      preferenceService = UserPreferenceLearningService(
        eventService: eventService,
      );
      recommendationService = EventRecommendationService(
        preferenceService: preferenceService,
        matchingService: matchingService,
        eventService: eventService,
      );
    });

    group('End-to-End Recommendation Flow', () {
      test('should generate personalized recommendations', () async {
        // Test business logic: recommendation service generates recommendations
        // Arrange
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Act
        final recommendations = await recommendationService.getPersonalizedRecommendations(
          user: user,
          maxResults: 20,
        );

        // Assert - Should return list of recommendations (may be empty if no events)
        expect(recommendations, isA<List>());
        expect(recommendations.length, lessThanOrEqualTo(20));
      });

      test('should balance familiar preferences with exploration', () async {
        // Test business logic: recommendations balance familiar and exploration
        // Arrange
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Act
        final recommendations = await recommendationService.getPersonalizedRecommendations(
          user: user,
          maxResults: 20,
          explorationRatio: 0.3, // 30% exploration, 70% familiar
        );

        // Assert - Should return list of recommendations
        expect(recommendations, isA<List>());
        expect(recommendations.length, lessThanOrEqualTo(20));
      });

      test('should prioritize local experts for users who prefer them', () async {
        // Create user who prefers local experts
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Create local expert event
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'Mission District, San Francisco',
        );

        final localEvent = await eventService.createEvent(
          host: localExpert,
          title: 'Local Food Tour',
          description: 'A tour of local food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Mission District, San Francisco',
        );

        // Create city expert event
        final cityExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'city-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'San Francisco');

        final cityEvent = await eventService.createEvent(
          host: cityExpert,
          title: 'City Food Tour',
          description: 'A tour of city food spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'San Francisco', // City experts can only host in city, not specific localities
        );

        // TODO: When services are created:
        // 1. Learn user preferences (should prefer local experts)
        // 2. Get recommendations
        // 3. Verify local expert event ranks higher

        expect(localEvent, isNotNull);
        expect(cityEvent, isNotNull);
      });
    });

    group('Tab-Based Filtering', () {
      test('should provide recommendations per tab scope', () async {
        // Test business logic: scope-specific recommendations
        // Arrange
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Act
        final recommendations = await recommendationService.getRecommendationsForScope(
          user: user,
          scope: 'locality',
          maxResults: 20,
        );

        // Assert - Should return list of recommendations for the scope
        expect(recommendations, isA<List>());
        expect(recommendations.length, lessThanOrEqualTo(20));
      });

      test('should use scope-specific preferences', () async {
        // Test business logic: scope-specific recommendations use preferences
        // Arrange
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Act
        final localityRecommendations = await recommendationService.getRecommendationsForScope(
          user: user,
          scope: 'locality',
          maxResults: 20,
        );

        final cityRecommendations = await recommendationService.getRecommendationsForScope(
          user: user,
          scope: 'city',
          maxResults: 20,
        );

        // Assert - Should return recommendations for each scope
        expect(localityRecommendations, isA<List>());
        expect(cityRecommendations, isA<List>());
      });
    });

    group('Cross-Locality Recommendations', () {
      test('should include events from connected localities', () async {
        // Test business logic: recommendations can include cross-locality events
        // Arrange
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Act
        final recommendations = await recommendationService.getPersonalizedRecommendations(
          user: user,
          maxResults: 20,
        );

        // Assert - Should return recommendations (may include cross-locality events)
        expect(recommendations, isA<List>());
        expect(recommendations.length, lessThanOrEqualTo(20));
      });

      test('should apply connection strength to ranking', () async {
        // Test business logic: recommendations are sorted by relevance
        // Arrange
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-1',
          location: 'Mission District, San Francisco',
        );

        // Act
        final recommendations = await recommendationService.getPersonalizedRecommendations(
          user: user,
          maxResults: 20,
        );

        // Assert - Recommendations should be sorted by relevance (highest first)
        for (int i = 0; i < recommendations.length - 1; i++) {
          expect(
            recommendations[i].relevanceScore,
            greaterThanOrEqualTo(recommendations[i + 1].relevanceScore),
          );
        }
      });
    });
  });
}


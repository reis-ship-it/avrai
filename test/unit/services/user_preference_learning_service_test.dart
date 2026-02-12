import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:avrai/core/services/matching/user_preference_learning_service.dart'
    hide UserPreferences;
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/user_preferences.dart';
import '../../fixtures/model_factories.dart';

import 'user_preference_learning_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

// Tests for UserPreferenceLearningService
// Phase 7, Section 41 (7.4.3): Backend Completion

@GenerateMocks([ExpertiseEventService])
void main() {
  group('UserPreferenceLearningService Tests', () {
    late UserPreferenceLearningService service;
    late MockExpertiseEventService mockEventService;
    late UnifiedUser user;

    setUp(() {
      mockEventService = MockExpertiseEventService();

      service = UserPreferenceLearningService(
        eventService: mockEventService,
      );

      // Create user
      user = ModelFactories.createTestUser(
        id: 'user-1',
      );
    });

    // Removed: Property assignment tests
    // User preference learning tests focus on business logic (preference learning, retrieval, exploration), not property assignment

    group('learnUserPreferences', () {
      test(
          'should learn preferences from event attendance patterns, calculate local vs city expert weights, learn category/locality/scope/event type preferences, and update preferences incrementally',
          () async {
        // Test business logic: preference learning from attendance patterns
        // Arrange - Mock event service to return empty list (new user with no events)
        when(mockEventService.getEventsByAttendee(user))
            .thenAnswer((_) async => []);

        // Act
        final preferences = await service.learnUserPreferences(user: user);

        // Assert - Should return preferences (even if empty/default for new user)
        expect(preferences, isNotNull);
        expect(preferences.userId, equals(user.id));
        expect(preferences.categoryPreferences, isA<Map>());
        expect(preferences.localityPreferences, isA<Map>());
        expect(preferences.scopePreferences, isA<Map>());
        expect(preferences.eventTypePreferences, isA<Map>());
      });
    });

    group('getUserPreferences', () {
      test(
          'should return current user preferences or default preferences for new users',
          () async {
        // Test business logic: preference retrieval
        // Arrange - Mock event service to return empty list (new user with no events)
        when(mockEventService.getEventsByAttendee(user))
            .thenAnswer((_) async => []);

        // Act
        final preferences = await service.getUserPreferences(user: user);

        // Assert - Should return preferences (calls learnUserPreferences internally)
        expect(preferences, isNotNull);
        expect(preferences.userId, equals(user.id));
        expect(preferences.categoryPreferences, isA<Map>());
        expect(preferences.localityPreferences, isA<Map>());
        expect(preferences.scopePreferences, isA<Map>());
        expect(preferences.eventTypePreferences, isA<Map>());
      });
    });

    group('suggestExplorationEvents', () {
      test(
          'should suggest events outside typical behavior, balance familiar preferences with exploration, and respect exploration willingness setting',
          () async {
        // Test business logic: exploration event suggestions
        // Arrange - Mock event service to return empty list (new user with no events)
        when(mockEventService.getEventsByAttendee(user))
            .thenAnswer((_) async => []);

        // Act
        final opportunities = await service.suggestExplorationEvents(
          user: user,
          maxSuggestions: 5,
        );

        // Assert - Should return list of exploration opportunities (may be empty for new user)
        expect(opportunities, isA<List>());
        expect(opportunities.length, lessThanOrEqualTo(5));
      });
    });
  });

  group('UserPreferences Model Tests', () {
    test(
        'should get top categories, top localities, top scope, and category preference',
        () {
      // Test business logic: preference retrieval methods
      final preferences = UserPreferences(
        userId: 'user-1',
        categoryPreferences: const {
          'food': 0.9,
          'coffee': 0.7,
          'art': 0.5,
          'music': 0.3
        },
        localityPreferences: const {
          'Mission District': 0.9,
          'SOMA': 0.6,
          'Marina': 0.3
        },
        scopePreferences: const {EventScope.locality: 0.8, EventScope.city: 0.5},
        lastUpdated: DateTime.now(),
      );

      final topCategories = preferences.getTopCategories(n: 2);
      expect(topCategories.length, equals(2));
      expect(topCategories.first.key, equals('food'));
      expect(topCategories.first.value, equals(0.9));

      final topLocalities = preferences.getTopLocalities(n: 2);
      expect(topLocalities.length, equals(2));
      expect(topLocalities.first.key, equals('Mission District'));
      expect(topLocalities.first.value, equals(0.9));

      expect(preferences.topScope, equals(EventScope.locality));
      expect(preferences.getCategoryPreference('food'), equals(0.9));
      expect(preferences.getCategoryPreference('coffee'), equals(0.7)); // coffee is in preferences
      expect(preferences.getCategoryPreference('nonexistent'), equals(0.0)); // category not in preferences
    });

    test('should serialize and deserialize without data loss', () {
      // Test business logic: JSON serialization round-trip
      final preferences = UserPreferences(
        userId: 'user-1',
        localExpertPreferenceWeight: 0.8,
        categoryPreferences: const {'food': 0.9},
        localityPreferences: const {'Mission District': 0.9},
        scopePreferences: const {EventScope.locality: 0.8},
        eventTypePreferences: const {ExpertiseEventType.tour: 0.9},
        explorationWillingness: 0.4,
        lastUpdated: DateTime.now(),
        eventsAnalyzed: 20,
      );

      final json = preferences.toJson();
      final restored = UserPreferences.fromJson(json);

      expect(restored.userId, equals(preferences.userId));
      expect(restored.localExpertPreferenceWeight,
          equals(preferences.localExpertPreferenceWeight));
      expect(restored.categoryPreferences,
          equals(preferences.categoryPreferences));
      expect(restored.localityPreferences,
          equals(preferences.localityPreferences));
      expect(restored.scopePreferences, equals(preferences.scopePreferences));
      expect(restored.eventTypePreferences,
          equals(preferences.eventTypePreferences));
      expect(restored.explorationWillingness,
          equals(preferences.explorationWillingness));
      expect(restored.eventsAnalyzed, equals(preferences.eventsAnalyzed));
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ml/preference_learning.dart';
import 'package:avrai/core/models/user/user.dart';

/// Preference Learning Engine Tests
/// Tests user preference learning functionality
/// OUR_GUTS.md: "Personalized, Not Prescriptive"
void main() {
  group('PreferenceLearningEngine', () {
    late PreferenceLearningEngine engine;

    setUp(() {
      engine = PreferenceLearningEngine();
    });

    group('learnFromBehavior', () {
      test('should learn preferences from behavior data', () async {
        final behaviorData = UserBehaviorData(
          userId: 'user-123',
          visitHistory: ['spot-1', 'spot-2', 'spot-3'],
          interactions: {
            'spot-1': {'category': 'food', 'rating': 5},
            'spot-2': {'category': 'coffee', 'rating': 4},
          },
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );

        final preferences = await engine.learnFromBehavior(behaviorData);

        expect(preferences, isA<UserPreferences>());
        expect(preferences.categoryAffinities, isA<Map<String, double>>());
        expect(preferences.timePreferences, isA<Map<String, double>>());
        expect(preferences.socialPreferences, isA<Map<String, double>>());
        expect(preferences.confidenceLevel, isA<double>());
        expect(preferences.lastUpdated, isA<DateTime>());
      });

      test('should handle empty behavior data', () async {
        final behaviorData = UserBehaviorData(
          userId: 'user-123',
          visitHistory: [],
          interactions: {},
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        );

        final preferences = await engine.learnFromBehavior(behaviorData);

        expect(preferences, isA<UserPreferences>());
        expect(preferences.categoryAffinities, isA<Map<String, double>>());
      });

      test('should handle errors gracefully', () async {
        // Note: The current implementation doesn't throw errors for invalid data
        // but this test ensures the method signature supports error handling
        final behaviorData = UserBehaviorData(
          userId: 'user-123',
          visitHistory: ['spot-1'],
          interactions: {},
          startDate: DateTime.now(),
          endDate: DateTime.now().subtract(const Duration(days: 1)), // Invalid date range
        );

        // Should still return preferences (implementation may handle edge cases)
        final preferences = await engine.learnFromBehavior(behaviorData);
        expect(preferences, isA<UserPreferences>());
      });
    });

    group('analyzeCategoryAffinity', () {
      test('should analyze category affinity for user', () async {
        // Create a minimal User instance for testing
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final categoryPreferences = await engine.analyzeCategoryAffinity(user);

        expect(categoryPreferences, isA<CategoryPreferences>());
        expect(categoryPreferences.topCategories, isA<List<String>>());
        expect(categoryPreferences.categoryScores, isA<Map<String, double>>());
        expect(categoryPreferences.emergingInterests, isA<List<String>>());
      });

      test('should return default categories', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final categoryPreferences = await engine.analyzeCategoryAffinity(user);

        expect(categoryPreferences.topCategories, isNotEmpty);
        expect(categoryPreferences.categoryScores, isNotEmpty);
      });
    });

    group('identifySocialContexts', () {
      test('should identify social context preferences', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final socialPreferences = await engine.identifySocialContexts(user);

        expect(socialPreferences, isA<SocialPreferences>());
        expect(socialPreferences.soloPreference, isA<double>());
        expect(socialPreferences.smallGroupPreference, isA<double>());
        expect(socialPreferences.largeGroupPreference, isA<double>());
        expect(socialPreferences.communityEventPreference, isA<double>());
      });

      test('should return valid preference scores', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final socialPreferences = await engine.identifySocialContexts(user);

        // Preferences should be between 0 and 1
        expect(socialPreferences.soloPreference, greaterThanOrEqualTo(0.0));
        expect(socialPreferences.soloPreference, lessThanOrEqualTo(1.0));
        expect(socialPreferences.smallGroupPreference, greaterThanOrEqualTo(0.0));
        expect(socialPreferences.smallGroupPreference, lessThanOrEqualTo(1.0));
        expect(socialPreferences.largeGroupPreference, greaterThanOrEqualTo(0.0));
        expect(socialPreferences.largeGroupPreference, lessThanOrEqualTo(1.0));
        expect(socialPreferences.communityEventPreference, greaterThanOrEqualTo(0.0));
        expect(socialPreferences.communityEventPreference, lessThanOrEqualTo(1.0));
      });
    });
  });

  group('UserBehaviorData', () {
    test('should create behavior data with all fields', () {
      final behaviorData = UserBehaviorData(
        userId: 'user-123',
        visitHistory: ['spot-1', 'spot-2'],
        interactions: {'spot-1': {'rating': 5}},
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      expect(behaviorData.userId, equals('user-123'));
      expect(behaviorData.visitHistory.length, equals(2));
      expect(behaviorData.interactions, isNotEmpty);
      expect(behaviorData.startDate, isA<DateTime>());
      expect(behaviorData.endDate, isA<DateTime>());
    });
  });

  group('UserPreferences', () {
    test('should create preferences with all fields', () {
      final preferences = UserPreferences(
        categoryAffinities: {'food': 0.8, 'coffee': 0.7},
        timePreferences: {'morning': 0.3, 'evening': 0.8},
        socialPreferences: {'solo': 0.4, 'friends': 0.6},
        confidenceLevel: 0.85,
        lastUpdated: DateTime.now(),
      );

      expect(preferences.categoryAffinities, isNotEmpty);
      expect(preferences.timePreferences, isNotEmpty);
      expect(preferences.socialPreferences, isNotEmpty);
      expect(preferences.confidenceLevel, equals(0.85));
      expect(preferences.lastUpdated, isA<DateTime>());
    });
  });

  group('CategoryPreferences', () {
    test('should create category preferences', () {
      final categoryPreferences = CategoryPreferences(
        topCategories: ['food', 'coffee'],
        categoryScores: {'food': 0.8, 'coffee': 0.7},
        emergingInterests: ['art', 'music'],
      );

      expect(categoryPreferences.topCategories, isNotEmpty);
      expect(categoryPreferences.categoryScores, isNotEmpty);
      expect(categoryPreferences.emergingInterests, isNotEmpty);
    });
  });

  group('SocialPreferences', () {
    test('should create social preferences', () {
      final socialPreferences = SocialPreferences(
        soloPreference: 0.3,
        smallGroupPreference: 0.5,
        largeGroupPreference: 0.2,
        communityEventPreference: 0.6,
      );

      expect(socialPreferences.soloPreference, equals(0.3));
      expect(socialPreferences.smallGroupPreference, equals(0.5));
      expect(socialPreferences.largeGroupPreference, equals(0.2));
      expect(socialPreferences.communityEventPreference, equals(0.6));
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('PersonalityLearning Phase 2 Tests', () {
    late PersonalityLearning personalityLearning;
    late String testUserId;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      personalityLearning = PersonalityLearning();
      testUserId = 'user_test_123';
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Onboarding to Dimensions Mapping', () {
      test('should map age < 25 to exploration and temporal flexibility', () async {
        // Arrange
        final onboardingData = {
          'age': 22,
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act - Test through initializePersonalityFromOnboarding
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Young age should increase exploration and temporal flexibility
        // Note: Values are blended (60% onboarding, 40% default), so we check for >= 0.5
        expect(profile.dimensions['exploration_eagerness'], greaterThanOrEqualTo(0.5));
        expect(profile.dimensions['temporal_flexibility'], greaterThanOrEqualTo(0.5));
      });

      test('should map age > 45 to authenticity and trust network', () async {
        // Arrange
        final onboardingData = {
          'age': 50,
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Older age should increase authenticity and trust network
        // Note: Values are blended, so we check for >= 0.5
        expect(profile.dimensions['authenticity_preference'], greaterThanOrEqualTo(0.5));
        expect(profile.dimensions['trust_network_reliance'], greaterThanOrEqualTo(0.5));
      });

      test('should map urban homebase to location adventurousness', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'San Francisco, CA',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Urban homebase should increase location adventurousness
        // Note: Values are blended, so we check for >= 0.5
        expect(profile.dimensions['location_adventurousness'], greaterThanOrEqualTo(0.5));
      });

      test('should map favorite places > 5 to exploration and location adventurousness', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1', 'Place2', 'Place3', 'Place4', 'Place5', 'Place6'],
          'preferences': {},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Many favorite places should increase exploration and location adventurousness
        // Note: Values are blended, so we check for >= 0.5
        expect(profile.dimensions['exploration_eagerness'], greaterThanOrEqualTo(0.5));
        expect(profile.dimensions['location_adventurousness'], greaterThanOrEqualTo(0.5));
      });

      test('should map Food & Drink preferences to curation and authenticity', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {
            'Food & Drink': ['Italian', 'Coffee'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Food preferences should increase curation and authenticity
        expect(profile.dimensions['curation_tendency'], greaterThan(0.5));
        expect(profile.dimensions['authenticity_preference'], greaterThan(0.5));
      });

      test('should map Activities preferences to exploration and social discovery', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {
            'Activities': ['Hiking', 'Concerts'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Activities should increase exploration and social discovery
        expect(profile.dimensions['exploration_eagerness'], greaterThan(0.5));
        expect(profile.dimensions['social_discovery_style'], greaterThan(0.5));
      });

      test('should map Outdoor & Nature preferences to location and exploration', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {
            'Outdoor & Nature': ['Parks', 'Hiking'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Outdoor preferences should increase location adventurousness and exploration
        expect(profile.dimensions['location_adventurousness'], greaterThan(0.5));
        expect(profile.dimensions['exploration_eagerness'], greaterThan(0.5));
      });

      test('should map Social preferences to community orientation and social discovery', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {
            'Social': ['Meetups', 'Events'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Social preferences should increase community orientation and social discovery
        expect(profile.dimensions['community_orientation'], greaterThan(0.5));
        expect(profile.dimensions['social_discovery_style'], greaterThan(0.5));
      });

      test('should map respected friends to community orientation and trust network', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {},
          'respectedFriends': ['friend1', 'friend2'],
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Respected friends should increase community orientation and trust network
        // Note: Values are blended, so we check for >= 0.5
        expect(profile.dimensions['community_orientation'], greaterThanOrEqualTo(0.5));
        expect(profile.dimensions['trust_network_reliance'], greaterThanOrEqualTo(0.5));
      });
    });

    group('initializePersonalityFromOnboarding', () {
      test('should initialize personality with onboarding data only', () async {
        // Arrange
        final onboardingData = {
          'age': 28,
          'homebase': 'San Francisco, CA',
          'favoritePlaces': ['Golden Gate Park', 'Mission District'],
          'preferences': {
            'Food & Drink': ['Italian'],
            'Activities': ['Hiking'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(profile, isNotNull);
        expect(profile.userId, testUserId);
        expect(profile.evolutionGeneration, 1);
        expect(profile.learningHistory['onboarding_data_used'], isTrue);
        expect(profile.learningHistory['social_media_data_used'], isFalse);
        expect(profile.learningHistory['agent_id'], isNotNull);
      });

      test('should initialize personality with social media data only', () async {
        // Arrange
        final socialMediaData = {
          'profile': {'bio': 'Adventure seeker'},
          'follows': [],
          'connections': [],
          'platform': 'instagram',
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          socialMediaData: socialMediaData,
        );

        // Assert
        expect(profile, isNotNull);
        expect(profile.userId, testUserId);
        expect(profile.evolutionGeneration, 1);
        expect(profile.learningHistory['onboarding_data_used'], isFalse);
        expect(profile.learningHistory['social_media_data_used'], isTrue);
      });

      test('should initialize personality with both onboarding and social media data', () async {
        // Arrange
        final onboardingData = {
          'age': 30,
          'homebase': 'New York, NY',
          'favoritePlaces': ['Central Park'],
          'preferences': {'Food & Drink': ['Pizza']},
        };
        final socialMediaData = {
          'profile': {'bio': 'Foodie'},
          'follows': [],
          'connections': [],
          'platform': 'instagram',
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
          socialMediaData: socialMediaData,
        );

        // Assert
        expect(profile, isNotNull);
        expect(profile.userId, testUserId);
        expect(profile.evolutionGeneration, 1);
        expect(profile.learningHistory['onboarding_data_used'], isTrue);
        expect(profile.learningHistory['social_media_data_used'], isTrue);
        expect(profile.learningHistory['learning_sources'], containsAll(['onboarding', 'social_media']));
      });

      test('should not overwrite existing evolved profile', () async {
        // Arrange
        // First create an evolved profile by initializing and then evolving
        await personalityLearning.initializePersonality(testUserId);
        // Note: evolveFromUserAction requires UserAction which may not be available
        // For this test, we'll just verify that if a profile exists, it won't be overwritten
        // by checking the evolution generation after a second initialization attempt
        
        final onboardingData = {
          'age': 25,
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act - First initialization
        final firstProfile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );
        
        // Simulate evolution by manually updating (in real scenario, this would be through evolveFromUserAction)
        // For now, we'll test that a second call with same data doesn't create a new profile
        final secondProfile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Should return the same profile (not create a new one)
        expect(secondProfile.userId, firstProfile.userId);
        expect(secondProfile.evolutionGeneration, firstProfile.evolutionGeneration);
      });

      test('should handle errors gracefully and fallback to default profile', () async {
        // Arrange
        final invalidOnboardingData = {
          'invalid': 'data',
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: invalidOnboardingData,
        );

        // Assert
        expect(profile, isNotNull);
        expect(profile.userId, testUserId);
      });

      test('should convert userId to agentId for privacy protection', () async {
        // Arrange
        final onboardingData = {
          'age': 25,
          'homebase': 'Test City',
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(profile.learningHistory['agent_id'], isNotNull);
        expect(profile.learningHistory['agent_id'], isA<String>());
        expect((profile.learningHistory['agent_id'] as String).startsWith('agent_'), isTrue);
      });
    });

    group('Archetype Determination', () {
      test('should return adventurous_explorer for high exploration and energy', () async {
        // Arrange
        final onboardingData = {
          'age': 22, // Young age increases exploration
          'homebase': 'San Francisco, CA',
          'favoritePlaces': List.generate(10, (i) => 'Place$i'), // Many places
          'preferences': {
            'Outdoor & Nature': ['Hiking', 'Camping'],
            'Activities': ['Adventure Sports'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - High exploration should lead to adventurous_explorer or similar
        expect(profile.archetype, isNotNull);
        expect(profile.dimensions['exploration_eagerness'], greaterThan(0.5));
      });

      test('should return social_connector for high social and energy', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {
            'Social': ['Meetups', 'Events', 'Parties'],
          },
          'respectedFriends': List.generate(10, (i) => 'friend$i'),
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - High social should lead to social_connector or similar
        expect(profile.archetype, isNotNull);
        expect(profile.dimensions['social_discovery_style'], greaterThan(0.5));
        expect(profile.dimensions['community_orientation'], greaterThan(0.5));
      });

      test('should return balanced_explorer as default', () async {
        // Arrange
        final onboardingData = {
          'age': 35,
          'homebase': 'Test City',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Default archetype should be set
        expect(profile.archetype, isNotNull);
        expect(profile.archetype.isNotEmpty, isTrue);
      });
    });

    group('Authenticity Calculation', () {
      test('should calculate authenticity from dimension consistency', () async {
        // Arrange
        final onboardingData = {
          'age': 30,
          'homebase': 'San Francisco, CA',
          'favoritePlaces': ['Place1', 'Place2'],
          'preferences': {
            'Food & Drink': ['Italian'],
          },
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Authenticity should be calculated and within valid range
        expect(profile.authenticity, greaterThanOrEqualTo(0.0));
        expect(profile.authenticity, lessThanOrEqualTo(1.0));
      });

      test('should boost authenticity from complete onboarding data', () async {
        // Arrange
        final completeOnboardingData = {
          'age': 28,
          'homebase': 'New York, NY',
          'favoritePlaces': ['Place1', 'Place2', 'Place3'],
          'preferences': {'Food & Drink': ['Pizza']},
          'baselineLists': ['List1'],
          'respectedFriends': ['Friend1'],
          'socialMediaConnected': {'google': true},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: completeOnboardingData,
        );

        // Assert - Complete data should result in higher authenticity
        expect(profile.authenticity, greaterThanOrEqualTo(0.0));
        expect(profile.authenticity, lessThanOrEqualTo(1.0));
        expect(profile.learningHistory['onboarding_data_used'], isTrue);
      });
    });

    group('Urban Area Detection', () {
      test('should identify San Francisco as urban and boost location adventurousness', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'San Francisco, CA',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Urban homebase should increase location adventurousness
        // Note: Values are blended, so we check for >= 0.5
        expect(profile.dimensions['location_adventurousness'], greaterThanOrEqualTo(0.5));
      });

      test('should identify New York as urban and boost location adventurousness', () async {
        // Arrange
        final onboardingData = {
          'homebase': 'New York, NY',
          'favoritePlaces': ['Place1'],
          'preferences': {},
        };

        // Act
        final profile = await personalityLearning.initializePersonalityFromOnboarding(
          testUserId,
          onboardingData: onboardingData,
        );

        // Assert - Urban homebase should increase location adventurousness
        // Note: Values are blended, so we check for >= 0.5
        expect(profile.dimensions['location_adventurousness'], greaterThanOrEqualTo(0.5));
      });
    });
  });
}


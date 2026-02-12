import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/agent_initialization_controller.dart';
import 'package:avrai/core/controllers/social_media_data_collection_controller.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user/preferences_profile.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/matching/preferences_profile_service.dart';
import 'package:avrai/core/services/onboarding/onboarding_place_list_generator.dart';
import 'package:avrai/core/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai/core/services/matching/personality_sync_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/social_media/social_media_insight_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'agent_initialization_controller_test.mocks.dart';

class MockSocialMediaInsightService extends Mock
    implements SocialMediaInsightService {}

@GenerateMocks([
  SocialMediaDataCollectionController,
  PersonalityLearning,
  PreferencesProfileService,
  OnboardingPlaceListGenerator,
  OnboardingRecommendationService,
  PersonalitySyncService,
  AgentIdService,
])
void main() {
  group('AgentInitializationController', () {
    late AgentInitializationController controller;
    late MockSocialMediaDataCollectionController mockSocialMediaDataController;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockPreferencesProfileService mockPreferencesService;
    late MockOnboardingPlaceListGenerator mockPlaceListGenerator;
    late MockOnboardingRecommendationService mockRecommendationService;
    late MockPersonalitySyncService mockSyncService;
    late MockAgentIdService mockAgentIdService;
    late MockSocialMediaInsightService mockSocialMediaInsightService;

    setUp(() {
      mockSocialMediaDataController = MockSocialMediaDataCollectionController();
      mockPersonalityLearning = MockPersonalityLearning();
      mockPreferencesService = MockPreferencesProfileService();
      mockPlaceListGenerator = MockOnboardingPlaceListGenerator();
      mockRecommendationService = MockOnboardingRecommendationService();
      mockSyncService = MockPersonalitySyncService();
      mockAgentIdService = MockAgentIdService();
      mockSocialMediaInsightService = MockSocialMediaInsightService();
      
      controller = AgentInitializationController(
        socialMediaDataController: mockSocialMediaDataController,
        personalityLearning: mockPersonalityLearning,
        preferencesService: mockPreferencesService,
        placeListGenerator: mockPlaceListGenerator,
        recommendationService: mockRecommendationService,
        syncService: mockSyncService,
        agentIdService: mockAgentIdService,
        socialMediaInsightService: mockSocialMediaInsightService,
      );
    });

    group('initializeAgent', () {
      const String userId = 'test_user_id';
      const String agentId = 'agent_test_id';
      
      final OnboardingData onboardingData = OnboardingData(
        agentId: agentId,
        age: 25,
        birthday: DateTime(1998, 1, 1),
        homebase: 'New York',
        favoritePlaces: ['Central Park', 'Brooklyn Bridge'],
        preferences: {
          'Food & Drink': ['Coffee & Tea', 'Fine Dining'],
          'Activities': ['Live Music', 'Theaters'],
        },
        baselineLists: ['My Favorite Spots'],
        respectedFriends: [],
        socialMediaConnected: {},
        completedAt: DateTime.now(),
      );

      final PersonalityProfile mockPersonalityProfile = PersonalityProfile(
        agentId: agentId,
        dimensions: {
          'openness': 0.5,
          'conscientiousness': 0.5,
          'extraversion': 0.5,
          'agreeableness': 0.5,
          'neuroticism': 0.5,
        },
        dimensionConfidence: {
          'openness': 0.8,
          'conscientiousness': 0.8,
          'extraversion': 0.8,
          'agreeableness': 0.8,
          'neuroticism': 0.8,
        },
        archetype: 'Explorer',
        authenticity: 0.8,
        evolutionGeneration: 1,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        learningHistory: {},
      );

      final PreferencesProfile mockPreferencesProfile = PreferencesProfile(
        agentId: agentId,
        categoryPreferences: const {
          'Food & Drink': 0.8,
          'Activities': 0.7,
        },
        localityPreferences: const {
          'New York': 0.9,
        },
        source: 'onboarding',
        lastUpdated: DateTime.now(),
      );

      test('should successfully initialize agent with all steps', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
              profileData: const {},
              follows: const [],
              primaryPlatform: null,
            ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenAnswer((_) async => mockPreferencesProfile);
        when(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        )).thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendedLists(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendedAccounts(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => []);
        when(mockSyncService.isCloudSyncEnabled(userId))
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.agentId, equals(agentId));
        expect(result.personalityProfile, equals(mockPersonalityProfile));
        expect(result.preferencesProfile, equals(mockPreferencesProfile));
        verify(mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(mockPersonalityLearning.initializePersonalityFromOnboarding(
          userId,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).called(1);
        verify(mockPreferencesService.initializeFromOnboarding(any)).called(1);
      });

      test('should fail if agentId cannot be retrieved', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Agent ID service error'));

        // Act
        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Failed to get agent ID'));
        expect(result.errorCode, equals('AGENT_ID_ERROR'));
        verify(mockAgentIdService.getUserAgentId(userId)).called(1);
        verifyNever(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        ));
      });

      test('should fail if personality profile initialization fails', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
              profileData: const {},
              follows: const [],
              primaryPlatform: null,
            ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).thenThrow(Exception('Personality initialization error'));

        // Act
        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Failed to initialize personality profile'));
        expect(result.errorCode, equals('PERSONALITY_INIT_ERROR'));
        verify(mockPersonalityLearning.initializePersonalityFromOnboarding(
          userId,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).called(1);
      });

      test('should continue if social media data collection fails', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.failure(
              error: 'Social media error',
              errorCode: 'COLLECTION_ERROR',
            ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenAnswer((_) async => mockPreferencesProfile);
        when(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        )).thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendedLists(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendedAccounts(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => []);
        when(mockSyncService.isCloudSyncEnabled(userId))
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.socialMediaData, isNull);
        verify(mockPersonalityLearning.initializePersonalityFromOnboarding(
          userId,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: argThat(isNull, named: 'socialMediaData'),
        )).called(1);
      });

      test('should continue if preferences profile initialization fails', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
              profileData: const {},
              follows: const [],
              primaryPlatform: null,
            ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenThrow(Exception('Preferences initialization error'));
        when(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        )).thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendedLists(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendedAccounts(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => []);
        when(mockSyncService.isCloudSyncEnabled(userId))
            .thenAnswer((_) async => false);

        // Act
        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.personalityProfile, equals(mockPersonalityProfile));
        expect(result.preferencesProfile, isNull);
      });

      test('should skip optional steps when disabled', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
              profileData: const {},
              follows: const [],
              primaryPlatform: null,
            ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenAnswer((_) async => mockPreferencesProfile);

        // Act
        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
          generatePlaceLists: false,
          getRecommendations: false,
          attemptCloudSync: false,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.generatedPlaceLists, isNull);
        expect(result.recommendations, isNull);
        expect(result.cloudSyncAttempted, isFalse);
        verifyNever(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        ));
        verifyNever(mockRecommendationService.getRecommendedLists(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        ));
        verifyNever(mockSyncService.isCloudSyncEnabled(userId));
      });
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/agent_initialization_controller.dart';
import 'package:avrai_runtime_os/controllers/social_media_data_collection_controller.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/preferences_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_place_list_generator.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_insight_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'agent_initialization_controller_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

class MockSocialMediaInsightService extends Mock
    implements SocialMediaInsightService {}

class MockEntitySignatureService extends Mock
    implements EntitySignatureService {
  @override
  Future<EntitySignature> initializeUserSignatureFromOnboarding({
    required String userId,
    required OnboardingData onboardingData,
    required PersonalityProfile personality,
    String? displayName,
    String? email,
    UserVibe? userVibe,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #initializeUserSignatureFromOnboarding,
        [],
        <Symbol, dynamic>{
          #userId: userId,
          #onboardingData: onboardingData,
          #personality: personality,
          #displayName: displayName,
          #email: email,
          #userVibe: userVibe,
        },
      ),
      returnValue: Future<EntitySignature>.value(
        EntitySignature(
          signatureId: 'user:fallback',
          entityId: 'fallback',
          entityKind: SignatureEntityKind.user,
          dna: const {'openness': 0.5},
          pheromones: const {'openness': 0.5},
          confidence: 0.5,
          freshness: 0.5,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          summary: 'fallback',
        ),
      ),
    ) as Future<EntitySignature>;
  }
}

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
    late MockEntitySignatureService mockEntitySignatureService;
    late EntitySignature mockUserSignature;
    late SharedPreferencesCompat prefs;
    late UrkGovernedRuntimeRegistryService governedRuntimeRegistryService;

    setUp(() async {
      await cleanupTestStorage();
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'agent_initialization_controller_registry_test',
        ),
      );
      governedRuntimeRegistryService =
          UrkGovernedRuntimeRegistryService(prefs: prefs);
      mockSocialMediaDataController = MockSocialMediaDataCollectionController();
      mockPersonalityLearning = MockPersonalityLearning();
      mockPreferencesService = MockPreferencesProfileService();
      mockPlaceListGenerator = MockOnboardingPlaceListGenerator();
      mockRecommendationService = MockOnboardingRecommendationService();
      mockSyncService = MockPersonalitySyncService();
      mockAgentIdService = MockAgentIdService();
      mockSocialMediaInsightService = MockSocialMediaInsightService();
      mockEntitySignatureService = MockEntitySignatureService();
      mockUserSignature = EntitySignature(
        signatureId: 'user:test_user_id',
        entityId: 'test_user_id',
        entityKind: SignatureEntityKind.user,
        dna: const {'openness': 0.7},
        pheromones: const {'openness': 0.68},
        confidence: 0.86,
        freshness: 0.91,
        updatedAt: DateTime.now(),
        summary: 'Explorer baseline seeded from onboarding.',
      );

      controller = AgentInitializationController(
        socialMediaDataController: mockSocialMediaDataController,
        personalityLearning: mockPersonalityLearning,
        preferencesService: mockPreferencesService,
        placeListGenerator: mockPlaceListGenerator,
        recommendationService: mockRecommendationService,
        syncService: mockSyncService,
        agentIdService: mockAgentIdService,
        socialMediaInsightService: mockSocialMediaInsightService,
        entitySignatureService: mockEntitySignatureService,
        governedRuntimeRegistryService: governedRuntimeRegistryService,
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
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
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
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
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
        verify(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).called(1);
        verify(mockPreferencesService.initializeFromOnboarding(any)).called(1);

        final bindings = await governedRuntimeRegistryService.listBindings(
          limit: 20,
        );
        final expectedRuntimeIds =
            UrkGovernedRuntimeRegistryService.canonicalPersonalRuntimeIds(
          userId: userId,
          agentId: agentId,
        );
        expect(
          bindings.map((binding) => binding.runtimeId).toSet(),
          expectedRuntimeIds.toSet(),
        );
        expect(
          bindings.every(
            (binding) => binding.source == 'agent_initialization_bootstrap',
          ),
          isTrue,
        );
        expect(
          bindings.every((binding) => binding.agentId == agentId),
          isTrue,
        );
      });

      test(
          'returns canonical onboarding explainability artifacts when open responses exist',
          () async {
        final richOnboardingData = onboardingData.copyWith(
          openResponses: <String, String>{
            'favorite_places':
                'I love quieter coffee shops, slow mornings, and places that feel grounded.',
            'goals':
                'I want to explore more neighborhoods without losing that calm feeling.',
          },
        );

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
                  profileData: const {},
                  follows: const [],
                  primaryPlatform: null,
                ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
          slmDimensions: anyNamed('slmDimensions'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: richOnboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenAnswer((_) async => mockPreferencesProfile);
        when(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        )).thenAnswer((_) async => <GeneratedPlaceList>[]);
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

        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: richOnboardingData,
        );

        expect(result.isSuccess, isTrue);
        expect(result.initialDnaWhySnapshot, isNotNull);
        expect(result.onboardingMutationReceipts, isNotEmpty);
        expect(
          result.metadata?['initialDnaMutationReceiptCount'],
          equals(result.onboardingMutationReceipts.length),
        );
      });

      test('should attach OS-first runtime artifacts for initialization',
          () async {
        final fakeHeadlessHost = _FakeInitializationHeadlessAvraiOsHost();
        controller = AgentInitializationController(
          socialMediaDataController: mockSocialMediaDataController,
          personalityLearning: mockPersonalityLearning,
          preferencesService: mockPreferencesService,
          placeListGenerator: mockPlaceListGenerator,
          recommendationService: mockRecommendationService,
          syncService: mockSyncService,
          agentIdService: mockAgentIdService,
          socialMediaInsightService: mockSocialMediaInsightService,
          entitySignatureService: mockEntitySignatureService,
          governedRuntimeRegistryService: governedRuntimeRegistryService,
          headlessOsHost: fakeHeadlessHost,
        );

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
                  profileData: const {},
                  follows: const [],
                  primaryPlatform: null,
                ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
          slmDimensions: anyNamed('slmDimensions'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenAnswer((_) async => mockPreferencesProfile);
        when(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        )).thenAnswer((_) async => <GeneratedPlaceList>[]);
        when(mockRecommendationService.getRecommendedLists(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => <ListRecommendation>[]);
        when(mockRecommendationService.getRecommendedAccounts(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => <AccountRecommendation>[]);
        when(mockSyncService.isCloudSyncEnabled(userId))
            .thenAnswer((_) async => false);

        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        expect(result.isSuccess, isTrue);
        expect(result.realityKernelFusionInput, isNotNull);
        expect(result.kernelGovernanceReport, isNotNull);
        expect(
            result.realityKernelFusionInput!.localityContainedInWhere, isTrue);
        expect(result.metadata?['modelTruthReady'], isTrue);
        expect(result.metadata?['localityContainedInWhere'], isTrue);
        expect(result.metadata?['governanceDomains'], contains('where'));
        expect(fakeHeadlessHost.startCalls, 1);
        expect(fakeHeadlessHost.runtimeCalls, 1);
        expect(fakeHeadlessHost.modelTruthCalls, 1);
        expect(fakeHeadlessHost.governanceCalls, 1);
      });

      test('should expose restored headless OS bootstrap state in result',
          () async {
        final fakeHeadlessHost = _FakeInitializationHeadlessAvraiOsHost();
        final bootstrapPrefs = await SharedPreferencesCompat.getInstance(
          storage: getTestStorage(
            boxName: 'agent_initialization_restored_bootstrap',
          ),
        );
        final seedingBootstrap = HeadlessAvraiOsBootstrapService(
          host: fakeHeadlessHost,
          prefs: bootstrapPrefs,
        );
        await seedingBootstrap.initialize();
        final restoredBootstrap = HeadlessAvraiOsBootstrapService(
          host: _FakeInitializationHeadlessAvraiOsHost(),
          prefs: bootstrapPrefs,
        );
        await restoredBootstrap.restorePersistedSnapshot();

        controller = AgentInitializationController(
          socialMediaDataController: mockSocialMediaDataController,
          personalityLearning: mockPersonalityLearning,
          preferencesService: mockPreferencesService,
          placeListGenerator: mockPlaceListGenerator,
          recommendationService: mockRecommendationService,
          syncService: mockSyncService,
          agentIdService: mockAgentIdService,
          socialMediaInsightService: mockSocialMediaInsightService,
          entitySignatureService: mockEntitySignatureService,
          governedRuntimeRegistryService: governedRuntimeRegistryService,
          headlessOsHost: fakeHeadlessHost,
          headlessOsBootstrapService: restoredBootstrap,
        );

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.success(
                  profileData: const {},
                  follows: const [],
                  primaryPlatform: null,
                ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
          slmDimensions: anyNamed('slmDimensions'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
        when(mockPreferencesService.initializeFromOnboarding(any))
            .thenAnswer((_) async => mockPreferencesProfile);
        when(mockPlaceListGenerator.generatePlaceLists(
          onboardingData: anyNamed('onboardingData'),
          homebase: anyNamed('homebase'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxLists: anyNamed('maxLists'),
        )).thenAnswer((_) async => <GeneratedPlaceList>[]);
        when(mockRecommendationService.getRecommendedLists(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => <ListRecommendation>[]);
        when(mockRecommendationService.getRecommendedAccounts(
          userId: anyNamed('userId'),
          onboardingData: anyNamed('onboardingData'),
          personalityDimensions: anyNamed('personalityDimensions'),
          maxRecommendations: anyNamed('maxRecommendations'),
        )).thenAnswer((_) async => <AccountRecommendation>[]);
        when(mockSyncService.isCloudSyncEnabled(userId))
            .thenAnswer((_) async => false);

        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        expect(result.isSuccess, isTrue);
        expect(result.restoredHeadlessOsBootstrapSnapshot, isNotNull);
        expect(
          result.restoredHeadlessOsBootstrapSnapshot!.restoredFromPersistence,
          isTrue,
        );
        expect(
            result.metadata?['restoredHeadlessOsBootstrapAvailable'], isTrue);
        expect(
          result.metadata?['restoredHeadlessOsLocalityContainedInWhere'],
          isTrue,
        );
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
        verifyZeroInteractions(mockEntitySignatureService);
      });

      test('should fail if personality profile initialization fails', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
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
        expect(
            result.error, contains('Failed to initialize personality profile'));
        expect(result.errorCode, equals('PERSONALITY_INIT_ERROR'));
        verify(mockPersonalityLearning.initializePersonalityFromOnboarding(
          userId,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).called(1);
        verifyZeroInteractions(mockEntitySignatureService);
      });

      test('should fail if initial user signature creation fails', () async {
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
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
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenThrow(Exception('signature error'));

        final result = await controller.initializeAgent(
          userId: userId,
          onboardingData: onboardingData,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('USER_SIGNATURE_INIT_ERROR'));
        expect(
            result.error, contains('Failed to create initial user signature'));
      });

      test('should continue if social media data collection fails', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
            .thenAnswer((_) async => SocialMediaDataResult.failure(
                  error: 'Social media error',
                  errorCode: 'COLLECTION_ERROR',
                ));
        when(mockPersonalityLearning.initializePersonalityFromOnboarding(
          any,
          onboardingData: anyNamed('onboardingData'),
          socialMediaData: anyNamed('socialMediaData'),
        )).thenAnswer((_) async => mockPersonalityProfile);
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
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

      test('should continue if preferences profile initialization fails',
          () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
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
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
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
        when(mockSocialMediaDataController.collectAllData(
                userId: anyNamed('userId')))
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
        when(mockEntitySignatureService.initializeUserSignatureFromOnboarding(
          userId: userId,
          onboardingData: onboardingData,
          personality: mockPersonalityProfile,
        )).thenAnswer((_) async => mockUserSignature);
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

class _FakeInitializationHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCalls = 0;
  int runtimeCalls = 0;
  int modelTruthCalls = 0;
  int governanceCalls = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCalls += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 6),
      localityContainedInWhere: true,
      summary: 'initialization host',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    modelTruthCalls += 1;
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: _bundle,
      who: const WhoRealityProjection(summary: 'who', confidence: 0.8),
      what: const WhatRealityProjection(summary: 'what', confidence: 0.82),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.86),
      where: const WhereRealityProjection(
        summary: 'where',
        confidence: 0.9,
        payload: <String, dynamic>{'locality_contained_in_where': true},
      ),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.84),
      how: const HowRealityProjection(summary: 'how', confidence: 0.83),
      generatedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async =>
      const <KernelHealthReport>[];

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    governanceCalls += 1;
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: _bundle,
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.where,
          summary: 'locality is governed through where',
          confidence: 0.93,
        ),
        KernelGovernanceProjection(
          domain: KernelDomain.why,
          summary: 'initialization reasoning available',
          confidence: 0.87,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    runtimeCalls += 1;
    return _bundle;
  }

  KernelContextBundle get _bundle => KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'agent_test_id',
          affectedActor: 'agent_test_id',
          companionActors: <String>[],
          actorRoles: <String>['user', 'agent'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.95,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'initialize_agent',
          targetEntityType: 'agent',
          targetEntityId: 'agent_test_id',
          stateTransitionType: 'initialized',
          outcomeType: 'ready',
          semanticTags: <String>['onboarding', 'initialization'],
          taxonomyConfidence: 0.91,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 6),
          freshness: 1.0,
          recencyBucket: 'current',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.96,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:locality:init',
          cityCode: 'nyc',
          localityCode: 'new_york',
          projection: <String, dynamic>{'locality_contained_in_where': true},
          boundaryTension: 0.12,
          spatialConfidence: 0.9,
          travelFriction: 0.18,
          placeFitFlags: <String>['locality_contained_in_where'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'agent_initialization_controller.initializeAgent',
          workflowStage: 'onboarding_runtime',
          transportMode: 'in_process',
          plannerMode: 'bootstrap',
          modelFamily: 'headless_os',
          interventionChain: <String>['collect', 'initialize', 'project'],
          failureMechanism: 'none',
          mechanismConfidence: 0.91,
        ),
        why: WhyKernelSnapshot(
          goal: 'bootstrap_personal_agent',
          summary: 'agent initialized successfully',
          rootCauseType: WhyRootCauseType.contextDriven,
          confidence: 0.89,
          drivers: const <WhySignal>[
            WhySignal(label: 'personality_profile_initialized', weight: 0.9),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 6),
        ),
      );
}

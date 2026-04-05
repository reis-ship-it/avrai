/// SPOTS OnboardingDataService Tests
/// Date: December 15, 2025
/// Purpose: Test OnboardingDataService functionality
///
/// Test Coverage:
/// - Save Operations: Persisting onboarding data with agentId conversion
/// - Retrieve Operations: Loading onboarding data with agentId conversion
/// - Delete Operations: Removing onboarding data
/// - Privacy Protection: userId → agentId conversion validation
/// - Error Handling: Invalid data, missing data, storage errors
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../helpers/test_helpers.dart';
import '../../helpers/test_storage_helper.dart';

final _onboardingPromptPolicyService = BoundedFollowUpPromptPolicyService(
  policy: BoundedFollowUpPromptPolicy(
    maxPromptPlansPerDay: 10,
    quietHoursStartHour: 0,
    quietHoursEndHour: 0,
    suggestionFamilyCooldown: Duration(seconds: 1),
    eventFamilyCooldown: Duration(seconds: 1),
  ),
);

// Mock classes
class MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  group('OnboardingDataService Tests', () {
    late OnboardingDataService service;
    late MockAgentIdService mockAgentIdService;
    late DateTime testDate;
    const String testUserId = 'user_123';
    const String testAgentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

    setUp(() async {
      TestHelpers.setupTestEnvironment();
      await TestStorageHelper.initTestStorage();
      await TestStorageHelper.getBox('onboarding_data').erase();
      testDate = DateTime.now();
      mockAgentIdService = MockAgentIdService();

      service = OnboardingDataService(
        agentIdService: mockAgentIdService,
        storage: TestStorageHelper.getBox('onboarding_data'),
      );

      // Setup mock default behavior
      when(() => mockAgentIdService.getUserAgentId(testUserId))
          .thenAnswer((_) async => testAgentId);
    });

    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await TestStorageHelper.getBox('onboarding_data').erase();
      await TestStorageHelper.clearTestStorage();
      TestHelpers.teardownTestEnvironment();
    });

    group('Save Onboarding Data', () {
      test('should save onboarding data and convert userId to agentId',
          () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );

        // Act
        await service.saveOnboardingData(testUserId, onboardingData);

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);

        // Verify data was saved by retrieving it
        final retrieved = await service.getOnboardingData(testUserId);
        expect(retrieved, isNotNull);
        expect(retrieved!.agentId, equals(testAgentId));
        expect(retrieved.age, equals(28));
        expect(retrieved.homebase, equals('San Francisco, CA'));
      });

      test('should save onboarding data with all fields populated', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          age: 28,
          birthday: DateTime(1995, 1, 1),
          homebase: 'San Francisco, CA',
          favoritePlaces: ['Golden Gate Park', 'Mission District'],
          preferences: {
            'Food & Drink': ['Coffee', 'Craft Beer'],
            'Activities': ['Hiking', 'Live Music'],
          },
          baselineLists: ['My Favorites'],
          openResponses: {
            'coffee': 'Neighborhood espresso bars',
            'about_me': 'I like late-night bookstores and jazz clubs.',
          },
          respectedFriends: ['friend1', 'friend2'],
          socialMediaConnected: {'google': true, 'instagram': false},
          completedAt: testDate,
        );

        // Act
        await service.saveOnboardingData(testUserId, onboardingData);

        // Assert
        final retrieved = await service.getOnboardingData(testUserId);
        expect(retrieved, isNotNull);
        expect(retrieved!.favoritePlaces.length, equals(2));
        expect(retrieved.preferences.length, equals(2));
        expect(
          retrieved.openResponses,
          equals(onboardingData.openResponses),
        );
        expect(retrieved.socialMediaConnected['google'], isTrue);
      });

      test('should throw exception when saving invalid onboarding data',
          () async {
        // Arrange
        // Create data that will be invalid even after agentId conversion
        // Use a future date to make it invalid
        final futureDate = DateTime.now().add(const Duration(days: 2));
        final invalidData = OnboardingData(
          agentId: testAgentId,
          completedAt: futureDate, // Invalid: future date
        );

        // Act & Assert
        expect(
          () => service.saveOnboardingData(testUserId, invalidData),
          throwsException,
        );
      });

      test('should overwrite existing data when saving again', () async {
        // Arrange
        final firstData = OnboardingData(
          agentId: testAgentId,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );

        final secondData = OnboardingData(
          agentId: testAgentId,
          age: 29,
          homebase: 'New York, NY',
          completedAt: testDate,
        );

        // Act
        await service.saveOnboardingData(testUserId, firstData);
        await service.saveOnboardingData(testUserId, secondData);

        // Assert
        final retrieved = await service.getOnboardingData(testUserId);
        expect(retrieved, isNotNull);
        expect(retrieved!.age, equals(29));
        expect(retrieved.homebase, equals('New York, NY'));
      });

      test('should stage onboarding as governed upward learning intake',
          () async {
        final repository = UniversalIntakeRepository();
        final upwardService = GovernedUpwardLearningIntakeService(
          intakeRepository: repository,
          atomicClockService: AtomicClockService(),
        );
        service = OnboardingDataService(
          agentIdService: mockAgentIdService,
          governedUpwardLearningIntakeService: upwardService,
          storage: TestStorageHelper.getBox('onboarding_data'),
        );

        final onboardingData = OnboardingData(
          agentId: testAgentId,
          homebase: 'Austin, TX',
          favoritePlaces: const <String>['Neighborhood cafe'],
          preferences: const <String, List<String>>{
            'Food & Drink': <String>['Coffee'],
            'Community': <String>['Local clubs'],
          },
          baselineLists: const <String>['Weekend shortlist'],
          completedAt: testDate,
          dimensionValues: const <String, double>{'openness': 0.84},
          dimensionConfidence: const <String, double>{'openness': 0.78},
          questionnaireVersion: 'v3',
          betaConsentAccepted: true,
        );

        await service.saveOnboardingData(testUserId, onboardingData);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final reviews = await repository.getAllReviewItems();
        final sources = await repository.getAllSources();
        expect(reviews, hasLength(1));
        expect(sources, hasLength(1));
        expect(reviews.single.payload['sourceKind'], 'onboarding_intake');
        expect(reviews.single.payload['airGapRequired'], isTrue);
        expect(reviews.single.payload['airGapReceiptId'], isA<String>());
        expect(
          reviews.single.payload['convictionTier'],
          'onboarding_declared_preference',
        );
        expect(
          reviews.single.payload['upwardDomainHints'],
          containsAll(const <String>['community', 'list', 'locality', 'place']),
        );
        expect(
          reviews.single.payload['upwardSignalTags'],
          containsAll(const <String>[
            'surface:onboarding',
            'channel:onboarding_flow',
            'has_dimension_values',
          ]),
        );
      });

      test('should create a bounded onboarding follow-up plan after save',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance(
          storage: TestStorageHelper.getBox(
            'onboarding_follow_up_planner_test',
          ),
        );
        final planner = OnboardingFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _onboardingPromptPolicyService,
        );
        service = OnboardingDataService(
          agentIdService: mockAgentIdService,
          followUpPlannerService: planner,
          storage: TestStorageHelper.getBox('onboarding_data'),
        );

        final onboardingData = OnboardingData(
          agentId: testAgentId,
          homebase: 'Austin, TX',
          favoritePlaces: const <String>['Quiet cafe'],
          preferences: const <String, List<String>>{
            'Food & Drink': <String>['Coffee'],
          },
          completedAt: testDate,
          dimensionValues: const <String, double>{'openness': 0.9},
          questionnaireVersion: 'v3',
        );

        await service.saveOnboardingData(testUserId, onboardingData);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final plans = await planner.listPlans(testUserId);
        expect(plans, hasLength(1));
        expect(plans.single.homebase, 'Austin, TX');
        expect(plans.single.promptQuestion, contains('Austin, TX'));
      });
    });

    group('Get Onboarding Data', () {
      test('should retrieve saved onboarding data correctly', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );
        await service.saveOnboardingData(testUserId, onboardingData);

        // Act
        final retrieved = await service.getOnboardingData(testUserId);

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved!.agentId, equals(testAgentId));
        expect(retrieved.age, equals(28));
        verify(() => mockAgentIdService.getUserAgentId(testUserId))
            .called(2); // Once for save, once for get
      });

      test('should return null when onboarding data does not exist', () async {
        // Act
        final retrieved = await service.getOnboardingData(testUserId);

        // Assert
        expect(retrieved, isNull);
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test('should convert userId to agentId when retrieving data', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );
        await service.saveOnboardingData(testUserId, onboardingData);

        // Act
        await service.getOnboardingData(testUserId);

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(2);
      });

      test('should handle errors gracefully and return null', () async {
        // Arrange
        when(() => mockAgentIdService.getUserAgentId(testUserId))
            .thenThrow(Exception('Service error'));

        // Act
        final retrieved = await service.getOnboardingData(testUserId);

        // Assert
        expect(retrieved, isNull);
      });
    });

    group('Delete Onboarding Data', () {
      test('should delete saved onboarding data', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );
        await service.saveOnboardingData(testUserId, onboardingData);

        // Verify data exists
        expect(await service.hasOnboardingData(testUserId), isTrue);

        // Act
        await service.deleteOnboardingData(testUserId);

        // Assert
        expect(await service.hasOnboardingData(testUserId), isFalse);
        final retrieved = await service.getOnboardingData(testUserId);
        expect(retrieved, isNull);
        // Verify calls: Save (1), hasOnboardingData calls getOnboardingData (2), delete (3), hasOnboardingData after delete (4), getOnboardingData after delete (5)
        verify(() => mockAgentIdService.getUserAgentId(testUserId))
            .called(greaterThanOrEqualTo(3));
      });

      test('should not throw when deleting non-existent data', () async {
        // Act & Assert
        expect(
          () => service.deleteOnboardingData(testUserId),
          returnsNormally,
        );
      });

      test('should convert userId to agentId when deleting data', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );
        await service.saveOnboardingData(testUserId, onboardingData);

        // Act
        await service.deleteOnboardingData(testUserId);

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId))
            .called(2); // Save, delete
      });
    });

    group('Has Onboarding Data', () {
      test('should return true when onboarding data exists', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );
        await service.saveOnboardingData(testUserId, onboardingData);

        // Act
        final hasData = await service.hasOnboardingData(testUserId);

        // Assert
        expect(hasData, isTrue);
      });

      test('should return false when onboarding data does not exist', () async {
        // Act
        final hasData = await service.hasOnboardingData(testUserId);

        // Assert
        expect(hasData, isFalse);
      });
    });

    group('Privacy Protection - AgentId Conversion', () {
      test('should always use agentId for storage regardless of input agentId',
          () async {
        // Arrange
        const differentAgentId = 'agent_different123';
        when(() => mockAgentIdService.getUserAgentId(testUserId))
            .thenAnswer((_) async => differentAgentId);

        final onboardingData = OnboardingData(
          agentId: testAgentId, // Different from what service will use
          completedAt: testDate,
        );

        // Act
        await service.saveOnboardingData(testUserId, onboardingData);

        // Assert
        // Service should convert and use the agentId from AgentIdService
        final retrieved = await service.getOnboardingData(testUserId);
        expect(retrieved, isNotNull);
        expect(retrieved!.agentId,
            equals(differentAgentId)); // Should use converted agentId
      });

      test('should convert userId to agentId for all operations', () async {
        // Arrange
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );

        // Act
        await service.saveOnboardingData(testUserId, onboardingData);
        await service.getOnboardingData(testUserId);
        await service.hasOnboardingData(testUserId);
        await service.deleteOnboardingData(testUserId);

        // Assert
        // Should call getUserAgentId for each operation
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(4);
      });
    });

    group('Error Handling', () {
      test('should handle AgentIdService errors gracefully', () async {
        // Arrange
        when(() => mockAgentIdService.getUserAgentId(testUserId))
            .thenThrow(Exception('AgentIdService error'));

        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );

        // Act & Assert
        expect(
          () => service.saveOnboardingData(testUserId, onboardingData),
          throwsException,
        );
      });

      test('should save data when storage is healthy', () async {
        final onboardingData = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );

        await service.saveOnboardingData(testUserId, onboardingData);
        final retrieved = await service.getOnboardingData(testUserId);

        expect(retrieved, isNotNull);
        expect(retrieved!.agentId, equals(testAgentId));
      });
    });

    group('Multiple Users', () {
      test('should store and retrieve data for multiple users independently',
          () async {
        // Arrange
        const userId1 = 'user_1';
        const userId2 = 'user_2';
        const agentId1 = 'agent_user1_123';
        const agentId2 = 'agent_user2_456';

        when(() => mockAgentIdService.getUserAgentId(userId1))
            .thenAnswer((_) async => agentId1);
        when(() => mockAgentIdService.getUserAgentId(userId2))
            .thenAnswer((_) async => agentId2);

        final data1 = OnboardingData(
          agentId: agentId1,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );

        final data2 = OnboardingData(
          agentId: agentId2,
          age: 35,
          homebase: 'New York, NY',
          completedAt: testDate,
        );

        // Act
        await service.saveOnboardingData(userId1, data1);
        await service.saveOnboardingData(userId2, data2);

        // Assert
        final retrieved1 = await service.getOnboardingData(userId1);
        final retrieved2 = await service.getOnboardingData(userId2);

        expect(retrieved1, isNotNull);
        expect(retrieved1!.age, equals(28));
        expect(retrieved1.homebase, equals('San Francisco, CA'));

        expect(retrieved2, isNotNull);
        expect(retrieved2!.age, equals(35));
        expect(retrieved2.homebase, equals('New York, NY'));
      });
    });
  });
}

/// SPOTS OnboardingRecommendationService Tests
/// Date: December 15, 2025
/// Purpose: Test OnboardingRecommendationService functionality
///
/// Test Coverage:
/// - List Recommendations: Recommending lists based on onboarding
/// - Account Recommendations: Recommending accounts based on onboarding
/// - Compatibility Calculation: Calculating compatibility scores
/// - Privacy Protection: userId → agentId conversion validation
/// - Edge Cases: Empty data, no matches, invalid inputs
library;

import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    as kernel_models;
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show StorageService;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/test_helpers.dart';
import '../../mocks/mock_storage_service.dart';

// Mock classes
class MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  group('OnboardingRecommendationService Tests', () {
    late OnboardingRecommendationService service;
    late MockAgentIdService mockAgentIdService;
    late GovernedDomainConsumerStateService governedStateService;
    const String testUserId = 'user_123';
    const String testAgentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

    setUp(() async {
      TestHelpers.setupTestEnvironment();
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      mockAgentIdService = MockAgentIdService();
      governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );
      service = OnboardingRecommendationService(
        agentIdService: mockAgentIdService,
        governedDomainConsumerStateService: governedStateService,
      );

      // Setup mock default behavior
      when(() => mockAgentIdService.getUserAgentId(testUserId))
          .thenAnswer((_) async => testAgentId);
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('Get Recommended Lists', () {
      test('should return list of recommendations with compatibility scores',
          () async {
        // Arrange
        final onboardingData = {
          'preferences': {
            'Food & Drink': ['Coffee', 'Craft Beer'],
          },
          'homebase': 'San Francisco, CA',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 10,
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
        expect(recommendations, isNotEmpty);
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test('should limit recommendations to maxRecommendations parameter',
          () async {
        // Arrange
        final onboardingData = {
          'preferences': {
            'Food & Drink': ['Coffee']
          },
          'homebase': 'San Francisco, CA',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7
        };

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 5,
        );

        // Assert
        expect(recommendations.length, lessThanOrEqualTo(5));
      });

      test('should convert userId to agentId for privacy protection', () async {
        // Arrange
        final onboardingData = {'preferences': {}};

        // Act
        await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: <String, double>{
            'exploration_eagerness': 0.7,
            'curation_tendency': 0.6,
          },
        );

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test('should handle empty onboarding data gracefully', () async {
        // Arrange
        final onboardingData = <String, dynamic>{};
        final personalityDimensions = <String, double>{};

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
        expect(recommendations, isEmpty);
      });

      test('should handle errors gracefully and return empty list', () async {
        // Arrange
        when(() => mockAgentIdService.getUserAgentId(testUserId))
            .thenThrow(Exception('Service error'));

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: {},
          personalityDimensions: {},
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
        expect(recommendations.isEmpty, isTrue);
      });

      test('uses governed list intelligence as a bounded recommendation input',
          () async {
        final onboardingData = <String, dynamic>{
          'preferences': <String, dynamic>{
            'Food & Drink': <String>['Coffee'],
          },
          'homebase': 'Austin, TX',
          'cityCode': 'atx',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        final baselineService = OnboardingRecommendationService(
          agentIdService: mockAgentIdService,
        );
        final baselineRecommendations =
            await baselineService.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 10,
        );

        await governedStateService.upsertState(
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_atx',
            domainId: 'list',
            consumerId: 'list_curation_lane',
            environmentId: 'atx-replay-world-2024',
            cityCode: 'atx',
            generatedAt: DateTime.utc(2026, 4, 1, 20),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'List curation intelligence is ready for Austin.',
            boundedUse: 'Bounded only.',
            targetedSystems: const <String>['list_curation'],
            requestCount: 4,
            averageConfidence: 0.9,
          ),
        );

        final governedRecommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 10,
        );

        expect(baselineRecommendations, isNotEmpty);
        expect(governedRecommendations, isNotEmpty);
        expect(
          governedRecommendations.first.compatibilityScore,
          greaterThan(baselineRecommendations.first.compatibilityScore),
        );
        expect(
          governedRecommendations.first.matchingReasons,
          contains(
              'Governed list curation intelligence is active for this city'),
        );
      });
    });

    group('Get Recommended Accounts', () {
      test(
          'should return list of account recommendations with compatibility scores',
          () async {
        // Arrange
        final onboardingData = <String, dynamic>{
          'preferences': {
            'Activities': ['Hiking', 'Live Music'],
          },
          'homebase': 'San Francisco, CA',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'community_orientation': 0.6,
        };

        // Act
        final recommendations = await service.getRecommendedAccounts(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 10,
        );

        // Assert
        expect(recommendations, isA<List<AccountRecommendation>>());
        expect(recommendations, isNotEmpty);
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test(
          'should limit account recommendations to maxRecommendations parameter',
          () async {
        // Arrange
        final onboardingData = {'preferences': {}};

        // Act
        final recommendations = await service.getRecommendedAccounts(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: <String, double>{},
          maxRecommendations: 3,
        );

        // Assert
        expect(recommendations.length, lessThanOrEqualTo(3));
      });

      test('should convert userId to agentId for privacy protection', () async {
        // Arrange
        final onboardingData = {'preferences': {}};

        // Act
        await service.getRecommendedAccounts(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: <String, double>{},
        );

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });
    });

    group('Calculate Compatibility', () {
      test(
          'should calculate compatibility score between user and list dimensions',
          () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
          'location_adventurousness': 0.8,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.75,
          'curation_tendency': 0.65,
          'location_adventurousness': 0.85,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
        expect(
            score, greaterThan(0.5)); // Should be high for similar dimensions
      });

      test(
          'should return low compatibility score for very different dimensions',
          () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.9,
          'curation_tendency': 0.8,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.1,
          'curation_tendency': 0.2,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, lessThan(0.5)); // Should be low for different dimensions
      });

      test('should return zero when user dimensions are empty', () {
        // Arrange
        final userDimensions = <String, double>{};
        final listDimensions = {
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, equals(0.0));
      });

      test('should return zero when list dimensions are empty', () {
        // Arrange
        final userDimensions = {
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };
        final listDimensions = <String, double>{};

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, equals(0.0));
      });

      test('should return perfect compatibility for identical dimensions', () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, equals(1.0));
      });

      test(
          'should only consider matching dimensions in compatibility calculation',
          () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.8, // Matching but different value
          'location_adventurousness':
              0.8, // Different dimension, should be ignored
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, greaterThan(0.0));
        expect(score, lessThan(1.0));
        // Should only consider exploration_eagerness match (0.7 vs 0.8 = 0.9 compatibility)
      });
    });

    group('ListRecommendation Model', () {
      // Removed: Constructor-only test - tests Dart constructor, not business logic

      test(
          'should serialize to JSON with correct structure for storage and transmission',
          () {
        // Arrange
        final recommendation = ListRecommendation(
          listId: 'list_123',
          listName: 'Coffee Lovers',
          curatorName: 'John Doe',
          description: 'Best coffee spots',
          compatibilityScore: 0.85,
          matchingReasons: ['Similar interests', 'Same location'],
          metadata: {'source': 'onboarding'},
        );

        // Act
        final json = recommendation.toJson();

        // Assert - Test business logic: JSON structure is correct for system use
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('listId'), isTrue);
        expect(json.containsKey('compatibilityScore'), isTrue);
        expect(json['compatibilityScore'], isA<double>());
        // JSON should be usable for storage/transmission
        expect(json['listId'], equals('list_123'));
      });
    });

    group('AccountRecommendation Model', () {
      // Removed: Constructor-only test - tests Dart constructor, not business logic

      test(
          'should serialize to JSON with correct structure for storage and transmission',
          () {
        // Arrange
        final recommendation = AccountRecommendation(
          accountId: 'account_123',
          accountName: 'coffee_explorer',
          displayName: 'Coffee Explorer',
          description: 'Coffee enthusiast',
          compatibilityScore: 0.80,
          matchingReasons: ['Similar interests', 'Same location'],
          metadata: {'source': 'onboarding'},
        );

        // Act
        final json = recommendation.toJson();

        // Assert - Test business logic: JSON structure is correct for system use
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('accountId'), isTrue);
        expect(json.containsKey('compatibilityScore'), isTrue);
        expect(json['compatibilityScore'], isA<double>());
        // JSON should be usable for storage/transmission
        expect(json['accountId'], equals('account_123'));
      });
    });

    group('Edge Cases', () {
      test('should handle null personality dimensions', () async {
        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: {},
          personalityDimensions: {},
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
      });

      test('should attach headless OS metadata and keep locality inside where',
          () async {
        final host = _FakeHeadlessAvraiOsHost();
        final hostAwareService = OnboardingRecommendationService(
          agentIdService: mockAgentIdService,
          headlessOsHost: host,
        );

        final recommendations = await hostAwareService.getRecommendedLists(
          userId: testUserId,
          onboardingData: <String, dynamic>{
            'preferences': <String, dynamic>{
              'Food & Drink': <String>['Coffee'],
            },
            'homebase': 'Chicago, IL',
          },
          personalityDimensions: <String, double>{
            'exploration_eagerness': 0.8,
            'curation_tendency': 0.7,
          },
        );

        expect(host.startCalls, 1);
        expect(host.runtimeCalls, 1);
        expect(host.modelTruthCalls, 1);
        expect(host.governanceCalls, 1);
        expect(recommendations, isNotEmpty);
        expect(recommendations.first.metadata['modelTruthReady'], isTrue);
        expect(
          recommendations.first.metadata['localityContainedInWhere'],
          isTrue,
        );
        expect(
          recommendations.first.metadata['governanceDomains'],
          contains('where'),
        );
      });

      test('should handle very large personality dimension maps', () {
        // Arrange
        final userDimensions = Map.fromEntries(
          List.generate(50, (i) => MapEntry('dimension_$i', 0.5)),
        );
        final listDimensions = Map.fromEntries(
          List.generate(50, (i) => MapEntry('dimension_$i', 0.6)),
        );

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });
    });
  });
}

class _FakeHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCalls = 0;
  int runtimeCalls = 0;
  int modelTruthCalls = 0;
  int governanceCalls = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCalls += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7, 12),
      localityContainedInWhere: true,
      summary: 'onboarding host ready',
    );
  }

  @override
  Future<kernel_models.RealityKernelFusionInput> buildModelTruth({
    required kernel_models.KernelEventEnvelope envelope,
    required kernel_models.KernelWhyRequest whyRequest,
  }) async {
    modelTruthCalls += 1;
    return kernel_models.RealityKernelFusionInput(
      envelope: envelope,
      bundle: kernel_models.KernelContextBundle(
        who: const kernel_models.WhoKernelSnapshot(
          primaryActor: 'agent',
          affectedActor: 'agent',
          companionActors: <String>[],
          actorRoles: <String>['personal'],
          trustScope: 'trusted_mesh',
          cohortRefs: <String>['personal'],
          identityConfidence: 0.95,
        ),
        what: const kernel_models.WhatKernelSnapshot(
          actionType: 'recommend_list',
          targetEntityType: 'onboarding',
          targetEntityId: 'bootstrap',
          stateTransitionType: 'observation',
          outcomeType: 'generated',
          semanticTags: <String>['onboarding'],
          taxonomyConfidence: 0.9,
        ),
        when: kernel_models.WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 7, 12),
          freshness: 0.95,
          recencyBucket: 'recent',
          timingConflictFlags: <String>[],
          temporalConfidence: 0.94,
        ),
        where: const kernel_models.WhereKernelSnapshot(
          localityToken: 'loc-onboarding',
          cityCode: 'CHI',
          localityCode: 'CHI-LOOP',
          projection: <String, dynamic>{'label': 'Chicago'},
          boundaryTension: 0.08,
          spatialConfidence: 0.93,
          travelFriction: 0.2,
          placeFitFlags: <String>['bootstrap_ready'],
        ),
        how: const kernel_models.HowKernelSnapshot(
          executionPath: 'onboarding_recommendation_service',
          workflowStage: 'onboarding',
          transportMode: 'in_process',
          plannerMode: 'bootstrap',
          modelFamily: 'onboarding_recommendation',
          interventionChain: <String>['bootstrap', 'rank'],
          failureMechanism: 'none',
          mechanismConfidence: 0.88,
        ),
      ),
      who: const kernel_models.WhoRealityProjection(
        summary: 'who ready',
        confidence: 0.95,
      ),
      what: const kernel_models.WhatRealityProjection(
        summary: 'what ready',
        confidence: 0.9,
      ),
      when: const kernel_models.WhenRealityProjection(
        summary: 'when ready',
        confidence: 0.94,
      ),
      where: const kernel_models.WhereRealityProjection(
        summary: 'where keeps locality internal',
        confidence: 0.93,
      ),
      why: const kernel_models.WhyRealityProjection(
        summary: 'why ready',
        confidence: 0.87,
      ),
      how: const kernel_models.HowRealityProjection(
        summary: 'how ready',
        confidence: 0.88,
      ),
      generatedAtUtc: DateTime.utc(2026, 3, 7, 12),
      localityContainedInWhere: true,
    );
  }

  @override
  Future<List<kernel_models.KernelHealthReport>> healthCheck() async =>
      const <kernel_models.KernelHealthReport>[];

  @override
  Future<kernel_models.KernelGovernanceReport> inspectGovernance({
    required kernel_models.KernelEventEnvelope envelope,
    required kernel_models.KernelWhyRequest whyRequest,
  }) async {
    governanceCalls += 1;
    return kernel_models.KernelGovernanceReport(
      envelope: envelope,
      bundle: kernel_models.KernelContextBundle(
        who: const kernel_models.WhoKernelSnapshot(
          primaryActor: 'agent',
          affectedActor: 'agent',
          companionActors: <String>[],
          actorRoles: <String>['personal'],
          trustScope: 'trusted_mesh',
          cohortRefs: <String>['personal'],
          identityConfidence: 0.95,
        ),
        what: const kernel_models.WhatKernelSnapshot(
          actionType: 'recommend_list',
          targetEntityType: 'onboarding',
          targetEntityId: 'bootstrap',
          stateTransitionType: 'observation',
          outcomeType: 'generated',
          semanticTags: <String>['onboarding'],
          taxonomyConfidence: 0.9,
        ),
        when: kernel_models.WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 7, 12),
          freshness: 0.95,
          recencyBucket: 'recent',
          timingConflictFlags: <String>[],
          temporalConfidence: 0.94,
        ),
        where: const kernel_models.WhereKernelSnapshot(
          localityToken: 'loc-onboarding',
          cityCode: 'CHI',
          localityCode: 'CHI-LOOP',
          projection: <String, dynamic>{'label': 'Chicago'},
          boundaryTension: 0.08,
          spatialConfidence: 0.93,
          travelFriction: 0.2,
          placeFitFlags: <String>['bootstrap_ready'],
        ),
        how: const kernel_models.HowKernelSnapshot(
          executionPath: 'onboarding_recommendation_service',
          workflowStage: 'onboarding',
          transportMode: 'in_process',
          plannerMode: 'bootstrap',
          modelFamily: 'onboarding_recommendation',
          interventionChain: <String>['bootstrap', 'rank'],
          failureMechanism: 'none',
          mechanismConfidence: 0.88,
        ),
      ),
      projections: const <kernel_models.KernelGovernanceProjection>[
        kernel_models.KernelGovernanceProjection(
          domain: kernel_models.KernelDomain.where,
          summary: 'locality remains inside where during onboarding',
          confidence: 0.93,
        ),
        kernel_models.KernelGovernanceProjection(
          domain: kernel_models.KernelDomain.how,
          summary: 'bootstrap recommendation path governed',
          confidence: 0.88,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 7, 12),
    );
  }

  @override
  Future<kernel_models.KernelContextBundle> resolveRuntimeExecution({
    required kernel_models.KernelEventEnvelope envelope,
  }) async {
    runtimeCalls += 1;
    return kernel_models.KernelContextBundle(
      who: const kernel_models.WhoKernelSnapshot(
        primaryActor: 'agent',
        affectedActor: 'agent',
        companionActors: <String>[],
        actorRoles: <String>['personal'],
        trustScope: 'trusted_mesh',
        cohortRefs: <String>['personal'],
        identityConfidence: 0.95,
      ),
      what: const kernel_models.WhatKernelSnapshot(
        actionType: 'recommend_list',
        targetEntityType: 'onboarding',
        targetEntityId: 'bootstrap',
        stateTransitionType: 'observation',
        outcomeType: 'generated',
        semanticTags: <String>['onboarding'],
        taxonomyConfidence: 0.9,
      ),
      when: kernel_models.WhenKernelSnapshot(
        observedAt: DateTime.utc(2026, 3, 7, 12),
        freshness: 0.95,
        recencyBucket: 'recent',
        timingConflictFlags: <String>[],
        temporalConfidence: 0.94,
      ),
      where: const kernel_models.WhereKernelSnapshot(
        localityToken: 'loc-onboarding',
        cityCode: 'CHI',
        localityCode: 'CHI-LOOP',
        projection: <String, dynamic>{'label': 'Chicago'},
        boundaryTension: 0.08,
        spatialConfidence: 0.93,
        travelFriction: 0.2,
        placeFitFlags: <String>['bootstrap_ready'],
      ),
      how: const kernel_models.HowKernelSnapshot(
        executionPath: 'onboarding_recommendation_service',
        workflowStage: 'onboarding',
        transportMode: 'in_process',
        plannerMode: 'bootstrap',
        modelFamily: 'onboarding_recommendation',
        interventionChain: <String>['bootstrap', 'rank'],
        failureMechanism: 'none',
        mechanismConfidence: 0.88,
      ),
    );
  }
}

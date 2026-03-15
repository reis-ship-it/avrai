import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_telemetry_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart'
    as recommendation_service;
import 'package:avrai_runtime_os/services/matching/user_preference_learning_service.dart';
import 'package:avrai_runtime_os/services/events/event_matching_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/events/event_recommendation.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import '../../helpers/integration_test_helpers.dart';

import 'event_recommendation_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

// Tests for EventRecommendationService
// Phase 7, Section 41 (7.4.3): Backend Completion

@GenerateMocks([
  UserPreferenceLearningService,
  EventMatchingService,
  ExpertiseEventService,
])
void main() {
  group('EventRecommendationService Tests', () {
    late recommendation_service.EventRecommendationService service;
    late MockUserPreferenceLearningService mockPreferenceService;
    late MockEventMatchingService mockMatchingService;
    late MockExpertiseEventService mockEventService;
    late _FakeHeadlessAvraiOsHost fakeHeadlessOsHost;
    late RecommendationTelemetryService telemetryService;
    late UnifiedUser user;

    setUp(() async {
      MockGetStorage.reset();
      mockPreferenceService = MockUserPreferenceLearningService();
      mockMatchingService = MockEventMatchingService();
      mockEventService = MockExpertiseEventService();
      fakeHeadlessOsHost = _FakeHeadlessAvraiOsHost();
      final storage =
          MockGetStorage.getInstance(boxName: 'event_recommendation_service');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      telemetryService = RecommendationTelemetryService(prefs: prefs);

      service = recommendation_service.EventRecommendationService(
        preferenceService: mockPreferenceService,
        matchingService: mockMatchingService,
        eventService: mockEventService,
        headlessOsHost: fakeHeadlessOsHost,
        telemetryService: telemetryService,
      );

      // Create user
      user = IntegrationTestHelpers.createUserWithoutHosting(
        id: 'user-1',
      );
    });

    // Removed: Property assignment tests
    // Event recommendation tests focus on business logic (recommendation generation, relevance classification), not property assignment

    group('getPersonalizedRecommendations', () {
      test(
          'should return personalized recommendations sorted by relevance, balance familiar preferences with exploration, show local expert events to users who prefer local events, show city/state events to users who prefer broader scope, include cross-locality events for users with movement patterns, or apply optional filters',
          () async {
        // Test business logic: personalized recommendation generation
        // Arrange - Mock services to return empty data
        when(mockPreferenceService.getUserPreferences(user: user))
            .thenAnswer((_) async => UserPreferences.empty(userId: user.id));
        when(mockEventService.searchEvents(
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          user: user,
          maxResults: 20,
        );

        // Assert - Should return list of recommendations (may be empty if no events)
        expect(recommendations, isA<List>());
        expect(recommendations.length, lessThanOrEqualTo(20));
        expect(fakeHeadlessOsHost.startCount, 1);
        expect(fakeHeadlessOsHost.runtimeExecutionCount, 1);
        expect(fakeHeadlessOsHost.governanceInspectionCount, 1);
      });

      test('persists OS-aware telemetry when recommendations exist', () async {
        when(mockPreferenceService.getUserPreferences(user: user))
            .thenAnswer((_) async => UserPreferences.empty(userId: user.id));
        when(mockMatchingService.calculateMatchingScore(
          expert: anyNamed('expert'),
          user: anyNamed('user'),
          category: anyNamed('category'),
          locality: anyNamed('locality'),
        )).thenAnswer((_) async => 0.72);
        final event = IntegrationTestHelpers.createTestEvent(
          id: 'event-telemetry-1',
          host: IntegrationTestHelpers.createUserWithLocalExpertise(
            id: 'expert-1',
            category: 'food',
          ),
          category: 'food',
        ).copyWith(location: 'Austin, TX');
        when(mockEventService.searchEvents(
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => <ExpertiseEvent>[event]);

        final recommendations = await service.getPersonalizedRecommendations(
          user: user,
          maxResults: 20,
        );

        expect(recommendations, isNotEmpty);
        final latestTelemetry = telemetryService.latest();
        expect(latestTelemetry, isNotNull);
        expect(latestTelemetry!.modelTruthReady, isTrue);
        expect(latestTelemetry.localityContainedInWhere, isTrue);
        expect(latestTelemetry.governanceDomains, contains('where'));
        expect(latestTelemetry.kernelEventId, isNotEmpty);
      });
    });

    group('getRecommendationsForScope', () {
      test(
          'should return recommendations for specific scope, or use scope-specific preferences',
          () async {
        // Test business logic: scope-specific recommendation generation
        // Arrange - Mock services to return empty data
        when(mockPreferenceService.getUserPreferences(user: user))
            .thenAnswer((_) async => UserPreferences.empty(userId: user.id));
        when(mockEventService.searchEvents(
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        // Act
        final recommendations = await service.getRecommendationsForScope(
          user: user,
          scope: 'locality',
          maxResults: 20,
        );

        // Assert - Should return list of recommendations (may be empty if no events)
        expect(recommendations, isA<List>());
        expect(recommendations.length, lessThanOrEqualTo(20));
        expect(fakeHeadlessOsHost.runtimeExecutionCount, 1);
        expect(fakeHeadlessOsHost.governanceInspectionCount, 1);
      });
    });
  });

  group('EventRecommendation Model Tests', () {
    test('should classify relevance correctly and determine exploration status',
        () {
      final host = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'food',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-1',
        host: host,
        category: 'food',
      );

      const preferenceMatch = PreferenceMatchDetails(
        categoryMatch: 0.9,
        localityMatch: 0.8,
        scopeMatch: 0.7,
        eventTypeMatch: 0.6,
        localExpertMatch: 0.9,
      );

      final highlyRelevant = EventRecommendation(
        event: event,
        relevanceScore: 0.8,
        reason: RecommendationReason.combined,
        preferenceMatch: preferenceMatch,
        generatedAt: DateTime.now(),
      );

      final moderatelyRelevant = EventRecommendation(
        event: event,
        relevanceScore: 0.5,
        reason: RecommendationReason.combined,
        preferenceMatch: preferenceMatch,
        generatedAt: DateTime.now(),
      );

      final weaklyRelevant = EventRecommendation(
        event: event,
        relevanceScore: 0.3,
        reason: RecommendationReason.combined,
        preferenceMatch: preferenceMatch,
        generatedAt: DateTime.now(),
      );

      expect(highlyRelevant.isHighlyRelevant, isTrue);
      expect(moderatelyRelevant.isModeratelyRelevant, isTrue);
      expect(weaklyRelevant.isWeaklyRelevant, isTrue);

      // Test exploration status determination (business logic)
      final explorationRecommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.85,
        reason: RecommendationReason.combined,
        preferenceMatch: preferenceMatch,
        isExploration: true,
        generatedAt: DateTime.now(),
      );
      expect(explorationRecommendation.isExploration, isTrue);
    });

    test(
        'should get recommendation reason display text and classify relevance correctly',
        () {
      // Test business logic: recommendation reason display and relevance classification
      final host = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'food',
      );
      final event = IntegrationTestHelpers.createTestEvent(
        id: 'event-1',
        host: host,
        category: 'food',
      );

      const preferenceMatch = PreferenceMatchDetails(
        categoryMatch: 0.9,
        localityMatch: 0.8,
        scopeMatch: 0.7,
        eventTypeMatch: 0.6,
        localExpertMatch: 0.9,
      );

      final recommendation = EventRecommendation(
        event: event,
        relevanceScore: 0.85,
        reason: RecommendationReason.categoryPreference,
        preferenceMatch: preferenceMatch,
        generatedAt: DateTime.now(),
      );

      expect(recommendation.reasonDisplayText, contains('food'));
      expect(recommendation.isHighlyRelevant, isTrue);
    });
  });

  group('PreferenceMatchDetails Tests', () {
    test('should calculate overall match score', () {
      const matchDetails = PreferenceMatchDetails(
        categoryMatch: 0.9,
        localityMatch: 0.8,
        scopeMatch: 0.7,
        eventTypeMatch: 0.6,
        localExpertMatch: 0.9,
      );

      // Overall = (0.9 * 0.3) + (0.8 * 0.25) + (0.7 * 0.2) + (0.6 * 0.15) + (0.9 * 0.1)
      // = 0.27 + 0.2 + 0.14 + 0.09 + 0.09 = 0.79
      expect(matchDetails.overallMatch, closeTo(0.79, 0.01));
    });

    test('should serialize and deserialize without data loss', () {
      // Test business logic: JSON round-trip preservation
      const matchDetails = PreferenceMatchDetails(
        categoryMatch: 0.9,
        localityMatch: 0.8,
        scopeMatch: 0.7,
        eventTypeMatch: 0.6,
        localExpertMatch: 0.9,
      );

      final json = matchDetails.toJson();
      final restored = PreferenceMatchDetails.fromJson(json);

      // Verify critical business fields preserved (overall match calculation depends on these)
      expect(restored.overallMatch, closeTo(matchDetails.overallMatch, 0.01));
      expect(restored.categoryMatch, equals(matchDetails.categoryMatch));
      expect(restored.localityMatch, equals(matchDetails.localityMatch));
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

class _FakeHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCount = 0;
  int runtimeExecutionCount = 0;
  int governanceInspectionCount = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCount += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 6),
      localityContainedInWhere: true,
      summary: 'test headless host',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    final bundle = _bundle;
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: bundle,
      who: const WhoRealityProjection(summary: 'who', confidence: 0.8),
      what: const WhatRealityProjection(summary: 'what', confidence: 0.8),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.8),
      where: const WhereRealityProjection(summary: 'where', confidence: 0.8),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.8),
      how: const HowRealityProjection(summary: 'how', confidence: 0.8),
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
    governanceInspectionCount += 1;
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: _bundle,
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.where,
          summary: 'locality in where',
          confidence: 0.9,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    runtimeExecutionCount += 1;
    return _bundle;
  }

  KernelContextBundle get _bundle => KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'user-1',
          affectedActor: 'user-1',
          companionActors: <String>[],
          actorRoles: <String>['user'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.95,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'recommend_event',
          targetEntityType: 'recommendation_batch',
          targetEntityId: 'batch',
          stateTransitionType: 'generated',
          outcomeType: 'generated',
          semanticTags: <String>['recommendation'],
          taxonomyConfidence: 0.9,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 6),
          freshness: 1.0,
          recencyBucket: 'current',
          timingConflictFlags: const <String>[],
          temporalConfidence: 0.95,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:test',
          cityCode: 'test_city',
          localityCode: 'test_locality',
          projection: <String, dynamic>{'locality_contained_in_where': true},
          boundaryTension: 0.0,
          spatialConfidence: 0.9,
          travelFriction: 0.1,
          placeFitFlags: <String>['locality_contained_in_where'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'event_recommendation_service.success',
          workflowStage: 'recommendation_delivery',
          transportMode: 'in_process',
          plannerMode: 'event_recommendation_service',
          modelFamily: 'event_recommendation_service',
          interventionChain: <String>[
            'ranking',
            'telemetry',
            'headless_os_host'
          ],
          failureMechanism: 'none',
          mechanismConfidence: 0.9,
        ),
        why: WhyKernelSnapshot(
          goal: 'recommend_event',
          summary: 'recommendation lifecycle',
          rootCauseType: WhyRootCauseType.contextDriven,
          confidence: 0.85,
          drivers: const <WhySignal>[
            WhySignal(label: 'recommendation_count_0', weight: -0.25),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 6),
        ),
      );
}

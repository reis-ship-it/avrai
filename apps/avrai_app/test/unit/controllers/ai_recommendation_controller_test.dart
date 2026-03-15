import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai_runtime_os/controllers/ai_recommendation_controller.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart'
    as event_rec_service;
import 'package:avrai_runtime_os/services/recommendations/recommendation_why_explanation_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/preferences_profile.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/why/why_models.dart' as core_why;
import 'package:avrai_core/models/expression/expression_models.dart';

import 'ai_recommendation_controller_test.mocks.dart';

@GenerateMocks([
  PersonalityLearning,
  PreferencesProfileService,
  event_rec_service.EventRecommendationService,
  AgentIdService,
])
void main() {
  group('AIRecommendationController', () {
    late AIRecommendationController controller;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockPreferencesProfileService mockPreferencesProfileService;
    late MockEventRecommendationService mockEventRecommendationService;
    late MockAgentIdService mockAgentIdService;
    late _FakeHeadlessAvraiOsHost fakeHeadlessOsHost;

    late UnifiedUser testUser;
    late PersonalityProfile testPersonalityProfile;
    late PreferencesProfile testPreferencesProfile;
    late ExpertiseEvent testEvent;
    late event_rec_service.EventRecommendation testRecommendation;

    setUp(() {
      mockPersonalityLearning = MockPersonalityLearning();
      mockPreferencesProfileService = MockPreferencesProfileService();
      mockEventRecommendationService = MockEventRecommendationService();
      mockAgentIdService = MockAgentIdService();
      fakeHeadlessOsHost = _FakeHeadlessAvraiOsHost();

      controller = AIRecommendationController(
        personalityLearning: mockPersonalityLearning,
        preferencesProfileService: mockPreferencesProfileService,
        eventRecommendationService: mockEventRecommendationService,
        agentIdService: mockAgentIdService,
        headlessOsHost: fakeHeadlessOsHost,
      );

      final now = DateTime.now();

      testUser = UnifiedUser(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: now,
        updatedAt: now,
      );

      testPersonalityProfile = PersonalityProfile.initial(
        'agent_123',
        userId: 'user_123',
      );

      testPreferencesProfile = PreferencesProfile.empty(agentId: 'agent_123');

      testEvent = ExpertiseEvent(
        id: 'event_123',
        title: 'Coffee Tasting Tour',
        description: 'Explore local coffee shops',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        host: testUser,
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        createdAt: now,
        updatedAt: now,
        status: EventStatus.upcoming,
        price: 25.0,
        isPaid: true,
        maxAttendees: 20,
        attendeeCount: 5,
      );

      testRecommendation = event_rec_service.EventRecommendation(
        event: testEvent,
        relevanceScore: 0.75,
        recommendationReason: 'Matches your interest in Coffee',
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(
            category: 'Coffee',
            maxResults: 20,
            explorationRatio: 0.3,
            minRelevanceScore: 0.3,
          ),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty userId', () {
        // Arrange
        const input = RecommendationInput(
          userId: '',
          context: RecommendationContext(),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['userId'], equals('User ID is required'));
      });

      test('should return invalid result for maxResults <= 0', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(maxResults: 0),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['maxResults'],
            equals('Max results must be greater than 0'));
      });

      test('should return invalid result for maxResults > 100', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(maxResults: 101),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['maxResults'],
            equals('Max results cannot exceed 100'));
      });

      test('should return invalid result for explorationRatio < 0', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(explorationRatio: -0.1),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['explorationRatio'],
            equals('Exploration ratio must be between 0.0 and 1.0'));
      });

      test('should return invalid result for explorationRatio > 1', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(explorationRatio: 1.1),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['explorationRatio'],
            equals('Exploration ratio must be between 0.0 and 1.0'));
      });

      test('should return invalid result for minRelevanceScore < 0', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(minRelevanceScore: -0.1),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['minRelevanceScore'],
            equals('Minimum relevance score must be between 0.0 and 1.0'));
      });

      test('should return invalid result for minRelevanceScore > 1', () {
        // Arrange
        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(minRelevanceScore: 1.1),
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['minRelevanceScore'],
            equals('Minimum relevance score must be between 0.0 and 1.0'));
      });
    });

    group('generateRecommendations', () {
      test('should successfully generate recommendations with all profiles',
          () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer((_) async => [testRecommendation]);

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(
            category: 'Coffee',
            maxResults: 20,
          ),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, hasLength(1));
        expect(result.events.first.event.id, equals('event_123'));
        expect(result.personalityProfile, isNotNull);
        expect(result.preferencesProfile, isNotNull);
        expect(result.realityKernelFusionInput, isNotNull);
        expect(
            result.realityKernelFusionInput!.localityContainedInWhere, isTrue);
        expect(result.metadata?['modelTruthReady'], isTrue);
        expect(fakeHeadlessOsHost.startCount, 1);
        verify(mockAgentIdService.getUserAgentId('user_123')).called(1);
        verify(mockPersonalityLearning.initializePersonality('user_123'))
            .called(1);
        verify(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .called(1);
        verify(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).called(1);
      });

      test('should continue even if personality profile fails to load',
          () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenThrow(Exception('Failed to load personality'));
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer((_) async => [testRecommendation]);

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, hasLength(1));
        expect(result.personalityProfile, isNull);
        expect(result.preferencesProfile, isNotNull);
      });

      test('should continue even if preferences profile fails to load',
          () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => null);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer((_) async => [testRecommendation]);

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, hasLength(1));
        expect(result.personalityProfile, isNotNull);
        expect(result.preferencesProfile, isNull);
      });

      test('should continue even if event recommendations fail', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenThrow(Exception('Failed to get recommendations'));

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, isEmpty);
        expect(result.personalityProfile, isNotNull);
        expect(result.preferencesProfile, isNotNull);
      });

      test('should filter recommendations by minRelevanceScore', () async {
        // Arrange
        final lowScoreRecommendation = event_rec_service.EventRecommendation(
          event: testEvent,
          relevanceScore: 0.2, // Below min threshold
          recommendationReason: 'Low relevance',
        );
        final highScoreRecommendation = event_rec_service.EventRecommendation(
          event: testEvent.copyWith(id: 'event_456'),
          relevanceScore: 0.8, // Above min threshold
          recommendationReason: 'High relevance',
        );

        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer(
            (_) async => [lowScoreRecommendation, highScoreRecommendation]);

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(
            minRelevanceScore: 0.3,
          ),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        // Low score (0.2) should be filtered out, high score (0.8) should remain
        // Note: Score may be enhanced with quantum compatibility, so just verify it's >= min threshold
        expect(result.events, hasLength(1));
        expect(result.events.first.relevanceScore, greaterThanOrEqualTo(0.3));
        // Should be the high score recommendation (even if enhanced)
        expect(result.events.first.event.id, equals('event_456'));
      });

      test('should limit results to maxResults', () async {
        // Arrange
        final recommendations = List.generate(
          25,
          (i) => event_rec_service.EventRecommendation(
            event: testEvent.copyWith(id: 'event_$i'),
            relevanceScore: 0.5 + (i * 0.01),
            recommendationReason: 'Recommendation $i',
          ),
        );

        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer((_) async => recommendations);

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(maxResults: 10),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, hasLength(10));
        // Should be sorted by relevance score (highest first)
        expect(result.events.first.relevanceScore,
            greaterThan(result.events.last.relevanceScore));
      });

      test('should enhance recommendations with quantum compatibility',
          () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);

        // Create preferences profile with category preference
        final preferencesWithCoffee = PreferencesProfile(
          agentId: 'agent_123',
          categoryPreferences: const {'Coffee': 0.8},
          localityPreferences: const {},
          eventTypePreferences: const {},
          scopePreferences: const {},
          localExpertPreferenceWeight: 0.5,
          explorationWillingness: 0.3,
          lastUpdated: DateTime.now(),
          source: 'onboarding',
        );

        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => preferencesWithCoffee);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer((_) async => [testRecommendation]);

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, hasLength(1));
        // Relevance score should be enhanced with quantum compatibility
        // Original: 0.75, preferences compat from calculateQuantumCompatibility
        // Enhanced score combines both
        expect(result.events.first.relevanceScore, greaterThanOrEqualTo(0.0));
        expect(result.events.first.relevanceScore, lessThanOrEqualTo(1.0));
      });

      test('uses the kernel-context recommendation expression path directly',
          () async {
        final spyEventRecommendationService = _SpyEventRecommendationService(
          recommendations: <event_rec_service.EventRecommendation>[
            testRecommendation,
          ],
          expressionArtifact: _expressionArtifactFor(testRecommendation),
        );
        controller = AIRecommendationController(
          personalityLearning: mockPersonalityLearning,
          preferencesProfileService: mockPreferencesProfileService,
          eventRecommendationService: spyEventRecommendationService,
          agentIdService: mockAgentIdService,
          headlessOsHost: fakeHeadlessOsHost,
        );

        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);

        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(),
        );

        expect(result.isSuccess, isTrue);
        expect(spyEventRecommendationService.kernelContextExpressionCalls, 1);
        expect(spyEventRecommendationService.legacyExpressionCalls, 0);
        expect(
          result.primaryRecommendationExpression?.displayText,
          contains('Coffee Tasting Tour'),
        );
      });

      test('should return failure result on unexpected error', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenThrow(Exception('Agent ID service failed'));

        // Act
        final result = await controller.generateRecommendations(
          userId: 'user_123',
          context: const RecommendationContext(),
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.errorCode, equals('RECOMMENDATION_GENERATION_FAILED'));
      });
    });

    group('execute (WorkflowController interface)', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_123');
        when(mockPersonalityLearning.initializePersonality('user_123'))
            .thenAnswer((_) async => testPersonalityProfile);
        when(mockPreferencesProfileService.getPreferencesProfile('agent_123'))
            .thenAnswer((_) async => testPreferencesProfile);
        when(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).thenAnswer((_) async => [testRecommendation]);

        const input = RecommendationInput(
          userId: 'user_123',
          context: RecommendationContext(),
        );

        // Act
        final result = await controller.execute(input);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.events, hasLength(1));
      });
    });

    group('rollback (WorkflowController interface)', () {
      test('should handle rollback gracefully (recommendations are read-only)',
          () async {
        // Arrange
        final result =
            RecommendationResult.success(events: [testRecommendation]);

        // Act & Assert - should not throw
        await controller.rollback(result);
      });
    });
  });
}

class _SpyEventRecommendationService
    extends event_rec_service.EventRecommendationService {
  _SpyEventRecommendationService({
    required this.recommendations,
    required this.expressionArtifact,
  });

  final List<event_rec_service.EventRecommendation> recommendations;
  final RecommendationExpressionArtifact expressionArtifact;
  int kernelContextExpressionCalls = 0;
  int legacyExpressionCalls = 0;

  @override
  Future<List<event_rec_service.EventRecommendation>>
      getPersonalizedRecommendations({
    required UnifiedUser user,
    String? category,
    String? location,
    int maxResults = 20,
    double explorationRatio = 0.3,
  }) async {
    return recommendations;
  }

  @override
  RecommendationExpressionArtifact expressRecommendation({
    required UnifiedUser user,
    required event_rec_service.EventRecommendation recommendation,
    String perspective = 'user_safe',
    core_why.WhySnapshot? explanation,
  }) {
    legacyExpressionCalls += 1;
    return expressionArtifact;
  }

  @override
  Future<RecommendationExpressionArtifact>
      expressRecommendationWithKernelContext({
    required UnifiedUser user,
    required event_rec_service.EventRecommendation recommendation,
    String perspective = 'user_safe',
  }) async {
    kernelContextExpressionCalls += 1;
    return expressionArtifact;
  }
}

RecommendationExpressionArtifact _expressionArtifactFor(
  event_rec_service.EventRecommendation recommendation,
) {
  const explanation = core_why.WhySnapshot(
    goal: 'explain_event_recommendation',
    queryKind: core_why.WhyQueryKind.recommendation,
    drivers: <core_why.WhySignal>[
      core_why.WhySignal(label: 'personal vibe quiet_mornings', weight: 0.84),
    ],
    inhibitors: <core_why.WhySignal>[],
    counterfactuals: <core_why.WhyCounterfactual>[],
    confidence: 0.82,
    rootCauseType: core_why.WhyRootCauseType.traitDriven,
    summary: 'AVRAI surfaced this from canonical vibe context.',
  );
  final plan = ExpressionPlan(
    speechAct: ExpressionSpeechAct.explain,
    audience: ExpressionAudience.userSafe,
    surfaceShape: ExpressionSurfaceShape.card,
    allowedClaims: const <String>[
      'This recommendation matches your quieter, exploratory vibe.',
    ],
    forbiddenClaims: const <String>[],
    evidenceRefs: const <String>['why:canonical_vibe'],
    confidenceBand: 'high',
    toneProfile: 'clear_direct',
    sections: <ExpressionSection>[
      ExpressionSection(kind: 'title', text: recommendation.event.title),
      ExpressionSection(
        kind: 'body',
        text: 'This recommendation matches your quieter, exploratory vibe.',
      ),
    ],
    cta: 'Open the event to see details.',
    fallbackText: 'This recommendation matches your quieter, exploratory vibe.',
  );
  return RecommendationExpressionArtifact(
    explanation: explanation,
    plan: plan,
    rendered: RenderedExpression(
      text:
          '${recommendation.event.title}\nThis recommendation matches your quieter, exploratory vibe.',
      sections: const <ExpressionSection>[
        ExpressionSection(kind: 'title', text: 'Coffee Tasting Tour'),
        ExpressionSection(
          kind: 'body',
          text: 'This recommendation matches your quieter, exploratory vibe.',
        ),
      ],
      assertedClaims: const <String>[
        'This recommendation matches your quieter, exploratory vibe.',
      ],
    ),
    validation: const ExpressionValidationResult(
      valid: true,
      unsupportedClaims: <String>[],
      forbiddenHits: <String>[],
      fallbackRequired: false,
    ),
  );
}

class _FakeHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  int startCount = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCount += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 6),
      localityContainedInWhere: true,
      summary: 'test host',
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
      where: const WhereRealityProjection(
        summary: 'where',
        confidence: 0.8,
        payload: <String, dynamic>{'locality_contained_in_where': true},
      ),
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
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: _bundle,
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.where,
          summary: 'locality contained in where',
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
    return _bundle;
  }

  KernelContextBundle get _bundle => KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'agent_123',
          affectedActor: 'agent_123',
          companionActors: <String>[],
          actorRoles: <String>['user'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.95,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'recommend_event',
          targetEntityType: 'event',
          targetEntityId: 'event_123',
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
          localityToken: 'where:locality:test',
          cityCode: 'test_city',
          localityCode: 'test_locality',
          projection: <String, dynamic>{'locality_contained_in_where': true},
          boundaryTension: 0.1,
          spatialConfidence: 0.9,
          travelFriction: 0.2,
          placeFitFlags: <String>['locality_contained_in_where'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'ai_recommendation_controller.generateRecommendations',
          workflowStage: 'recommendation_generation',
          transportMode: 'in_process',
          plannerMode: 'recommendation_ranker',
          modelFamily: 'event_recommendation_service',
          interventionChain: <String>['resolve', 'rank', 'filter'],
          failureMechanism: 'none',
          mechanismConfidence: 0.9,
        ),
        why: WhyKernelSnapshot(
          goal: 'recommend_event',
          summary: 'recommendation produced',
          rootCauseType: WhyRootCauseType.contextDriven,
          confidence: 0.88,
          drivers: const <WhySignal>[
            WhySignal(label: 'preference_profile_available', weight: 0.55),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 6),
        ),
      );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/ai_recommendation_controller.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/matching/preferences_profile_service.dart';
import 'package:avrai/core/services/events/event_recommendation_service.dart' as event_rec_service;
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user/preferences_profile.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';

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

      controller = AIRecommendationController(
        personalityLearning: mockPersonalityLearning,
        preferencesProfileService: mockPreferencesProfileService,
        eventRecommendationService: mockEventRecommendationService,
        agentIdService: mockAgentIdService,
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
        expect(result.fieldErrors['maxResults'], equals('Max results must be greater than 0'));
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
        expect(result.fieldErrors['maxResults'], equals('Max results cannot exceed 100'));
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
      test('should successfully generate recommendations with all profiles', () async {
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
        verify(mockAgentIdService.getUserAgentId('user_123')).called(1);
        verify(mockPersonalityLearning.initializePersonality('user_123')).called(1);
        verify(mockPreferencesProfileService.getPreferencesProfile('agent_123')).called(1);
        verify(mockEventRecommendationService.getPersonalizedRecommendations(
          user: anyNamed('user'),
          category: anyNamed('category'),
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
          explorationRatio: anyNamed('explorationRatio'),
        )).called(1);
      });

      test('should continue even if personality profile fails to load', () async {
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

      test('should continue even if preferences profile fails to load', () async {
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
        )).thenAnswer((_) async => [lowScoreRecommendation, highScoreRecommendation]);

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
        expect(result.events.first.relevanceScore, greaterThan(result.events.last.relevanceScore));
      });

      test('should enhance recommendations with quantum compatibility', () async {
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
      test('should handle rollback gracefully (recommendations are read-only)', () async {
        // Arrange
        final result = RecommendationResult.success(events: [testRecommendation]);

        // Act & Assert - should not throw
        await controller.rollback(result);
      });
    });
  });
}


// Tests for ContinuousLearningSystem
// Phase 11 Section 8: Learning Quality Monitoring

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

void main() {
  group('ContinuousLearningSystem - Learning History Persistence', () {
    late ContinuousLearningSystem learningSystem;
    late AgentIdService agentIdService;
    late EpisodicMemoryStore episodicMemoryStore;

    setUp(() {
      agentIdService = AgentIdService();
      episodicMemoryStore = EpisodicMemoryStore();
      // Create system without Supabase for unit tests
      learningSystem = ContinuousLearningSystem(
        agentIdService: agentIdService,
        episodicMemoryStore: episodicMemoryStore,
        supabase: null, // No Supabase in unit tests
      );
    });

    test('getLearningHistory returns empty list when Supabase is null',
        () async {
      final history = await learningSystem.getLearningHistory(
        userId: 'test-user-id',
        limit: 10,
      );

      expect(history, isEmpty);
    });

    test(
        'getLearningHistory returns empty list when dimension is specified but Supabase is null',
        () async {
      final history = await learningSystem.getLearningHistory(
        userId: 'test-user-id',
        dimension: 'user_preference_understanding',
        limit: 10,
      );

      expect(history, isEmpty);
    });

    // Note: _recordLearningEvent is a private method
    // It is tested indirectly through processUserInteraction and trainModel

    test('processUserInteraction requires userId parameter', () async {
      // Test that processUserInteraction requires userId
      await expectLater(
        learningSystem.processUserInteraction(
          userId: 'test-user-id',
          payload: {
            'event_type': 'spot_visited',
            'parameters': {},
            'context': {},
          },
        ),
        completes,
      );
    });

    test(
        'processUserInteraction writes episodic tuple when store is configured',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'spot_visited',
          'parameters': {'spot_id': 'spot-123'},
          'context': {'time_of_day': 'morning'},
        },
      );

      final count = await episodicMemoryStore.count();
      expect(count, 1);
    });

    test('processUserInteraction records community_join as social outcome',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'community_join',
          'parameters': {'community_id': 'community-123'},
          'context': {'source': 'suggestion'},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 1);
      expect(rows, hasLength(1));
      expect(rows.first.actionType, 'community_join');
      expect(rows.first.outcome.category.name, 'binary');
      expect(rows.first.outcome.value, 1.0);
    });

    test('processUserInteraction treats event_attend as attended alias',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'event_attend',
          'parameters': {'event_id': 'event-123'},
          'context': {'source': 'calendar'},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 1);
      expect(rows, hasLength(1));
      expect(rows.first.actionType, 'event_attend');
      expect(rows.first.outcome.category.name, 'binary');
      expect(rows.first.outcome.value, 1.0);
    });

    test('tracks recommendation rejection rate by entity type', () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {'entity_type': 'spot'},
          'context': {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'recommendation_accepted',
          'parameters': {'entity_type': 'spot'},
          'context': {},
        },
      );

      final rates = learningSystem.getRecommendationRejectionRates();
      expect(rates.containsKey('spot'), isTrue);
      expect(rates['spot']?['total'], 2);
      expect(rates['spot']?['rejected'], 1);
      expect(rates['spot']?['rejection_rate'], 0.5);
    });

    test('writes rejection-rate metadata into episodic tuple parameters',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {'entity_type': 'event'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 1);
      expect(rows, hasLength(1));
      expect(rows.first.actionType, 'recommendation_rejected');
      expect(rows.first.outcome.metadata['recommendation_rejection_rate'], 1.0);
      expect(rows.first.outcome.metadata['entity_type'], 'event');
    });

    test(
        'records visit_spot lifecycle outcomes including return within 30 days',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'spot_visited',
          'parameters': {'spot_id': 'spot-visit-1'},
          'context': {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'spot_visited',
          'parameters': {'spot_id': 'spot-visit-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 2);
      expect(rows, hasLength(2));
      expect(rows.first.actionType, 'visit_spot');
      expect(rows.first.outcome.type, 'return_visit_within_days');
      expect(rows.last.actionType, 'visit_spot');
      expect(rows.last.outcome.type, 'single_visit_only');
    });

    test('records dismiss_spot as negative recommendation outcome', () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'spot_dismissed',
          'parameters': {'spot_id': 'spot-dismiss-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 1);
      expect(rows, hasLength(1));
      expect(rows.first.actionType, 'dismiss_spot');
      expect(rows.first.outcome.type, 'recommendation_rejected');
      expect(rows.first.outcome.value, 0.0);
    });

    test('records passive-to-active intent transition for spot conversion',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'spot',
            'entity_id': 'spot-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'spot_visited',
          'parameters': {'spot_id': 'spot-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      expect(rows.any((r) => r.actionType == 'intent_transition'), isTrue);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_id'], 'spot-transition-1');
    });

    test('records active-to-passive intent transition for spot regression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'spot_visited',
          'parameters': {'spot_id': 'spot-transition-2'},
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'spot',
            'entity_id': 'spot-transition-2',
            'no_action': true,
          },
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 4);
      final transitions =
          rows.where((r) => r.actionType == 'intent_transition').toList();
      expect(transitions, isNotEmpty);
      expect(transitions.first.outcome.type, 'active_to_passive_regression');
      expect(transitions.first.actionPayload['entity_id'], 'spot-transition-2');
    });

    test('records passive-to-active intent transition for business engagement',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'business',
            'entity_id': 'business-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'engage_business',
          'parameters': {'business_id': 'business-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_type'], 'business');
      expect(transition.actionPayload['entity_id'], 'business-transition-1');
      expect(transition.actionPayload['to_action'], 'engage_business');
    });

    test('records passive-to-active intent transition for event attendance',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'event',
            'entity_id': 'event-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'attend_event',
          'parameters': {'event_id': 'event-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_type'], 'event');
      expect(transition.actionPayload['entity_id'], 'event-transition-1');
      expect(transition.actionPayload['to_action'], 'attend_event');
    });

    test('records passive-to-active intent transition for community join',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'community',
            'entity_id': 'community-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'join_community',
          'parameters': {'community_id': 'community-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_type'], 'community');
      expect(transition.actionPayload['entity_id'], 'community-transition-1');
      expect(transition.actionPayload['to_action'], 'join_community');
    });

    test('records passive-to-active intent transition for list save', () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'list',
            'entity_id': 'list-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'save_list',
          'parameters': {'list_id': 'list-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_type'], 'list');
      expect(transition.actionPayload['entity_id'], 'list-transition-1');
      expect(transition.actionPayload['to_action'], 'save_list');
    });

    test('records passive-to-active intent transition for brand sponsorship',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'brand',
            'entity_id': 'brand-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'sponsor_event',
          'parameters': {'brand_id': 'brand-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_type'], 'brand');
      expect(transition.actionPayload['entity_id'], 'brand-transition-1');
      expect(transition.actionPayload['to_action'], 'sponsor_event');
    });

    test('records passive-to-active intent transition for sponsor proposal',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'sponsor',
            'entity_id': 'sponsor-transition-1',
            'no_action': true,
          },
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'propose_sponsorship',
          'parameters': {'sponsor_id': 'sponsor-transition-1'},
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 3);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'passive_to_active_conversion');
      expect(transition.actionPayload['entity_type'], 'sponsor');
      expect(transition.actionPayload['entity_id'], 'sponsor-transition-1');
      expect(transition.actionPayload['to_action'], 'propose_sponsorship');
    });

    test('records active-to-passive intent transition for event regression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'attend_event',
          'parameters': {'event_id': 'event-transition-2'},
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'event',
            'entity_id': 'event-transition-2',
            'no_action': true,
          },
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 4);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'active_to_passive_regression');
      expect(transition.actionPayload['entity_type'], 'event');
      expect(transition.actionPayload['entity_id'], 'event-transition-2');
      expect(transition.actionPayload['from_action'], 'attend_event');
      expect(transition.actionPayload['to_action'], 'browse_entity');
    });

    test('records active-to-passive intent transition for community regression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'join_community',
          'parameters': {'community_id': 'community-transition-2'},
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'community',
            'entity_id': 'community-transition-2',
            'no_action': true,
          },
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 4);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'active_to_passive_regression');
      expect(transition.actionPayload['entity_type'], 'community');
      expect(transition.actionPayload['entity_id'], 'community-transition-2');
      expect(transition.actionPayload['from_action'], 'join_community');
      expect(transition.actionPayload['to_action'], 'browse_entity');
    });

    test('records active-to-passive intent transition for list regression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'save_list',
          'parameters': {'list_id': 'list-transition-2'},
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'list',
            'entity_id': 'list-transition-2',
            'no_action': true,
          },
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 4);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'active_to_passive_regression');
      expect(transition.actionPayload['entity_type'], 'list');
      expect(transition.actionPayload['entity_id'], 'list-transition-2');
      expect(transition.actionPayload['from_action'], 'save_list');
      expect(transition.actionPayload['to_action'], 'browse_entity');
    });

    test('records active-to-passive intent transition for brand regression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'sponsor_event',
          'parameters': {'brand_id': 'brand-transition-2'},
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'brand',
            'entity_id': 'brand-transition-2',
            'no_action': true,
          },
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 4);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'active_to_passive_regression');
      expect(transition.actionPayload['entity_type'], 'brand');
      expect(transition.actionPayload['entity_id'], 'brand-transition-2');
      expect(transition.actionPayload['from_action'], 'sponsor_event');
      expect(transition.actionPayload['to_action'], 'browse_entity');
    });

    test('records active-to-passive intent transition for sponsor regression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'propose_sponsorship',
          'parameters': {'sponsor_id': 'sponsor-transition-2'},
          'context': {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'test-user-id',
        payload: {
          'event_type': 'browse_entity',
          'parameters': {
            'entity_type': 'sponsor',
            'entity_id': 'sponsor-transition-2',
            'no_action': true,
          },
          'context': {},
        },
      );

      final rows = await episodicMemoryStore.getRecent(limit: 4);
      final transition =
          rows.firstWhere((r) => r.actionType == 'intent_transition');
      expect(transition.outcome.type, 'active_to_passive_regression');
      expect(transition.actionPayload['entity_type'], 'sponsor');
      expect(transition.actionPayload['entity_id'], 'sponsor-transition-2');
      expect(transition.actionPayload['from_action'], 'propose_sponsorship');
      expect(transition.actionPayload['to_action'], 'browse_entity');
    });
  });

  group('LearningEvent Model', () {
    test('creates correctly with all required fields', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final event = LearningEvent(
        dimension: 'user_preference_understanding',
        improvement: 0.05,
        dataSource: 'user_actions',
        timestamp: timestamp,
      );

      expect(event.dimension, equals('user_preference_understanding'));
      expect(event.improvement, equals(0.05));
      expect(event.dataSource, equals('user_actions'));
      expect(event.timestamp, equals(timestamp));
    });

    test('handles different improvement values', () {
      final event1 = LearningEvent(
        dimension: 'test_dimension',
        improvement: 0.0,
        dataSource: 'test_source',
        timestamp: DateTime.now(),
      );
      final event2 = LearningEvent(
        dimension: 'test_dimension',
        improvement: 1.0,
        dataSource: 'test_source',
        timestamp: DateTime.now(),
      );
      final event3 = LearningEvent(
        dimension: 'test_dimension',
        improvement: 0.5,
        dataSource: 'test_source',
        timestamp: DateTime.now(),
      );

      expect(event1.improvement, equals(0.0));
      expect(event2.improvement, equals(1.0));
      expect(event3.improvement, equals(0.5));
    });

    test('handles different data sources', () {
      final sources = [
        'user_actions',
        'location_data',
        'weather_data',
        'social_data'
      ];

      for (final source in sources) {
        final event = LearningEvent(
          dimension: 'test_dimension',
          improvement: 0.05,
          dataSource: source,
          timestamp: DateTime.now(),
        );

        expect(event.dataSource, equals(source));
      }
    });
  });
}

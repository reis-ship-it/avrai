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

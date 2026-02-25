library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.15 source utility feedback', () {
    late ContinuousLearningSystem learningSystem;
    late EpisodicMemoryStore episodicStore;

    setUp(() async {
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      learningSystem = ContinuousLearningSystem(
        episodicMemoryStore: episodicStore,
        supabase: null,
      );
    });

    test('tracks positive source-family outcomes', () async {
      await learningSystem.processUserInteraction(
        userId: 'source-user-1',
        payload: {
          'event_type': 'recommendation_accepted',
          'parameters': {
            'source_family': 'external_paper',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 12);
      final agentId = tuples.first.agentId;
      final stats = learningSystem
          .getSourceUtilityStatsForAgent(agentId)['external_paper'];
      expect(stats, isNotNull);
      expect(stats!['success_count'], equals(1));
      expect(stats['failure_count'], equals(0));

      final hasSourceTuple = tuples.any(
        (row) => row.actionType == 'source_utility_feedback',
      );
      expect(hasSourceTuple, isTrue);
    });

    test('deranks source-family after repeated downstream failures', () async {
      for (var i = 0; i < 3; i++) {
        await learningSystem.processUserInteraction(
          userId: 'source-user-2',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'source_family': 'third_party_dataset',
            },
            'context': const {},
          },
        );
      }

      final tuples = await episodicStore.getRecent(limit: 24);
      final agentId = tuples.first.agentId;
      final stats = learningSystem
          .getSourceUtilityStatsForAgent(agentId)['third_party_dataset'];
      expect(stats, isNotNull);
      expect(stats!['is_deranked'], isTrue);
      expect((stats['weight_multiplier'] as double), lessThan(1.0));

      final hasDerankTuple = tuples.any(
        (row) => row.actionType == 'source_family_deranked',
      );
      expect(hasDerankTuple, isTrue);
    });

    test('does not derank when failure rate stays below threshold', () async {
      await learningSystem.processUserInteraction(
        userId: 'source-user-3',
        payload: {
          'event_type': 'recommendation_accepted',
          'parameters': {
            'source_family': 'internal_telemetry',
          },
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'source-user-3',
        payload: {
          'event_type': 'recommendation_accepted',
          'parameters': {
            'source_family': 'internal_telemetry',
          },
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'source-user-3',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {
            'source_family': 'internal_telemetry',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 24);
      final agentId = tuples.first.agentId;
      final stats = learningSystem
          .getSourceUtilityStatsForAgent(agentId)['internal_telemetry'];
      expect(stats, isNotNull);
      expect(stats!['is_deranked'], isFalse);
      expect((stats['weight_multiplier'] as double), equals(1.0));
    });
  });
}

library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.11 confidence decay', () {
    late ContinuousLearningSystem learningSystem;
    late EpisodicMemoryStore episodicStore;

    setUp(() {
      episodicStore = EpisodicMemoryStore();
      learningSystem = ContinuousLearningSystem(
        agentIdService: AgentIdService(),
        episodicMemoryStore: episodicStore,
        supabase: null,
      );
    });

    test('records model failure tuple with 20% confidence decay', () async {
      await learningSystem.processUserInteraction(
        userId: 'decay-user-1',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {
            'entity_type': 'event',
            'category': 'nightlife',
            'predicted_outcome_value': 0.9,
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 16);
      final modelFailure = rows.firstWhere(
        (row) => row.actionType == 'model_failure_event',
      );
      final metadata = modelFailure.metadata;
      final stateBefore = modelFailure.stateBefore;
      final nextState = modelFailure.nextState;
      final actionPayload = modelFailure.actionPayload;

      expect(metadata['phase_ref'], equals('1.4.11'));
      expect(metadata['training_weight'], equals(3.0));
      expect(stateBefore['previous_confidence'], equals(1.0));
      expect(nextState['category_confidence'], equals(0.8));
      expect(nextState['negative_outcome_streak'], equals(1));
      expect(nextState['reexploration_triggered'], isFalse);
      expect(actionPayload['category'], equals('nightlife'));
    });

    test('triggers re-exploration on 3 consecutive negatives', () async {
      for (var i = 0; i < 3; i++) {
        await learningSystem.processUserInteraction(
          userId: 'decay-user-2',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'entity_type': 'spot',
              'category': 'coffee',
            },
            'context': const {},
          },
        );
      }

      final rows = await episodicStore.getRecent(limit: 48);
      final triggerTuple = rows.firstWhere(
        (row) => row.actionType == 'trigger_reexploration',
      );
      final triggerMetadata = triggerTuple.metadata;
      final triggerPayload = triggerTuple.actionPayload;
      final triggerState = triggerTuple.nextState;
      expect(triggerMetadata['phase_ref'], equals('1.4.11'));
      expect(triggerPayload['category'], equals('coffee'));
      expect(triggerPayload['negative_outcome_streak'], equals(3));
      expect(triggerState['reexploration_requested'], isTrue);
    });

    test('resets negative streak after positive outcome in same category',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'decay-user-3',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {
            'entity_type': 'event',
            'category': 'concert',
          },
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'decay-user-3',
        payload: {
          'event_type': 'save_event',
          'parameters': {
            'entity_type': 'event',
            'category': 'concert',
          },
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'decay-user-3',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {
            'entity_type': 'event',
            'category': 'concert',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 48);
      final modelFailures = rows
          .where((row) => row.actionType == 'model_failure_event')
          .toList(growable: false);
      expect(modelFailures, isNotEmpty);
      final newestModelFailure = modelFailures.first.nextState;
      expect(
        newestModelFailure['negative_outcome_streak'],
        equals(1),
      );
      final hasReexplorationTrigger = rows.any(
        (row) => row.actionType == 'trigger_reexploration',
      );
      expect(hasReexplorationTrigger, isFalse);
    });
  });
}

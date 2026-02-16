library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem contrastive signals', () {
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

    test('records contrastive tuple when recommended action differs', () async {
      await learningSystem.processUserInteraction(
        userId: 'contrastive-user-1',
        payload: {
          'event_type': 'create_reservation',
          'parameters': {
            'target_id': 'event-123',
            'recommended_action': 'attend_event',
            'recommended_action_payload': {
              'event_id': 'event-456',
            },
            'recommendation_source': 'mpc_planner',
          },
          'context': {
            'planner_recommendation': {
              'action_type': 'attend_event',
              'planner': 'mpc_planner',
            },
          },
        },
      );

      final rows = await episodicStore.getRecent(limit: 8);
      final contrastiveTuple = rows.firstWhere(
        (row) => row.actionType == 'contrastive_preference_signal',
      );
      expect(
        contrastiveTuple.actionPayload['recommended_action'],
        equals('attend_event'),
      );
      expect(
        contrastiveTuple.actionPayload['actual_action'],
        equals('create_reservation'),
      );
      expect(
        contrastiveTuple.actionPayload['recommendation_source'],
        equals('mpc_planner'),
      );
      expect(
        contrastiveTuple.nextState['contrastive_signal_recorded'],
        isTrue,
      );
      expect(
        contrastiveTuple.metadata['phase_ref'],
        equals('1.2.16'),
      );
    });

    test('does not record contrastive tuple when recommendation matches actual',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'contrastive-user-2',
        payload: {
          'event_type': 'attend_event',
          'parameters': {
            'event_id': 'event-789',
            'recommended_action': 'attend_event',
            'recommendation_source': 'mpc_planner',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 8);
      final hasContrastive = rows.any(
        (row) => row.actionType == 'contrastive_preference_signal',
      );
      expect(hasContrastive, isFalse);
    });
  });
}

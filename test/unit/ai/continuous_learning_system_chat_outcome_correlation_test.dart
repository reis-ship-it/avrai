library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem chat-outcome correlation', () {
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

    test('writes chat_to_outcome_correlation for same-community attendance',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'user-correlation-1',
        payload: {
          'event_type': 'message_community',
          'parameters': {
            'community_id': 'community-1',
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
          'context': {'source': 'community_chat'},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'user-correlation-1',
        payload: {
          'event_type': 'event_attended',
          'parameters': {
            'event_id': 'event-1',
            'community_id': 'community-1',
          },
          'context': {'source': 'event_checkin'},
        },
      );

      final rows = await episodicStore.getRecent(limit: 6);
      final correlation = rows.firstWhere(
        (row) => row.actionType == 'chat_to_outcome_correlation',
      );
      expect(correlation.actionPayload['community_id'], 'community-1');
      expect(correlation.actionPayload['event_id'], 'event-1');
      expect(correlation.outcome.type, 'chat_to_event_conversion');
      expect(correlation.actionPayload.containsKey('message'), isFalse);
    });
  });
}

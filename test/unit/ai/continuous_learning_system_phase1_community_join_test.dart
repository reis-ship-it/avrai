import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem phase 1 community_join', () {
    late ContinuousLearningSystem learningSystem;
    late EpisodicMemoryStore episodicStore;

    setUp(() async {
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      learningSystem = ContinuousLearningSystem(
        agentIdService: AgentIdService(),
        episodicMemoryStore: episodicStore,
        supabase: null,
      );
    });

    test('records community_join as a binary social outcome tuple', () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'community_join',
          'parameters': {'community_id': 'community-42'},
          'context': {'source': 'phase1_regression'},
        },
      );

      final rows = await episodicStore.getRecent(limit: 1);
      expect(rows.length, 1);
      expect(rows.first.actionType, 'community_join');
      expect(rows.first.outcome.value, 1.0);
    });
  });
}

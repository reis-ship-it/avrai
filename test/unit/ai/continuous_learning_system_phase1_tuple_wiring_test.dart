import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem phase 1 tuple wiring', () {
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

    test(
        'writes episodic tuple even when event has no mapped dimension updates',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'unmapped_observation',
          'parameters': {'entity_id': 'entity-1'},
          'context': {'source': 'phase1_regression'},
        },
      );

      final rows = await episodicStore.getRecent(limit: 1);
      expect(rows.length, 1);
      expect(rows.first.metadata['has_dimension_updates'], false);
    });
  });
}

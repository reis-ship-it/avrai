import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem phase 1 implicit feedback wiring', () {
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

    test('writes implicit feedback annotation for reopen-after-recommendation',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'reopen_after_recommendation',
          'parameters': {'recommendation_id': 'rec-1'},
          'context': const {'surface': 'notification'},
        },
      );

      final rows = await episodicStore.getRecent(limit: 1);
      expect(rows, hasLength(1));
      expect(
        rows.first.actionPayload['implicit_feedback_signal'],
        'reopenAfterRecommendation',
      );
      expect(
        rows.first.actionPayload['implicit_feedback_polarity'],
        'positive',
      );
      expect(rows.first.actionPayload['implicit_feedback_strength'], 2.0);
    });
  });
}

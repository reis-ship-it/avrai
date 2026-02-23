library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem recommendation bias signals', () {
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

    test('records bias-correction tuple when rejection pattern is systematic',
        () async {
      for (var i = 0; i < 5; i++) {
        await learningSystem.processUserInteraction(
          userId: 'bias-user-1',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'entity_type': 'event',
              'preferred_entity_type': 'spot',
            },
            'context': const {},
          },
        );
      }

      final rows = await episodicStore.getRecent(limit: 32);
      final biasTuple = rows.firstWhere(
        (row) => row.actionType == 'recommendation_bias_correction_signal',
      );

      expect(
        biasTuple.actionPayload['recommended_entity_type'],
        equals('event'),
      );
      expect(
        biasTuple.actionPayload['preferred_entity_type'],
        equals('spot'),
      );
      expect(
        biasTuple.actionPayload['recommendation_rejection_rate'],
        greaterThanOrEqualTo(0.7),
      );
      expect(biasTuple.nextState['systematic_bias_detected'], isTrue);
      expect(biasTuple.metadata['phase_ref'], equals('1.2.17'));
    });

    test('does not record bias-correction tuple below systematic threshold',
        () async {
      for (var i = 0; i < 3; i++) {
        await learningSystem.processUserInteraction(
          userId: 'bias-user-2',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'entity_type': 'community',
              'preferred_entity_type': 'event',
            },
            'context': const {},
          },
        );
      }

      final rows = await episodicStore.getRecent(limit: 24);
      final hasBiasTuple = rows.any(
        (row) => row.actionType == 'recommendation_bias_correction_signal',
      );
      expect(hasBiasTuple, isFalse);
    });
  });
}

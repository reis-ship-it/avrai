import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/recommendation_dismissal_recorder.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

void main() {
  group('RecommendationDismissalRecorder', () {
    late EpisodicMemoryStore store;
    late RecommendationDismissalRecorder recorder;

    setUp(() async {
      store = EpisodicMemoryStore();
      await store.clearForTesting();
      recorder = RecommendationDismissalRecorder(
        episodicMemoryStore: store,
        agentIdService: AgentIdService(),
      );
    });

    test('records dismiss_entity action with explicit rejection outcome',
        () async {
      final tuple = await recorder.recordDismissal(
        userId: 'phase1-user',
        entityType: 'spot',
        entityId: 'spot-123',
        entityFeatures: const {'category': 'cafe'},
      );

      expect(tuple.actionType, 'dismiss_entity');
      expect(tuple.outcome.type, 'explicit_rejection');
      expect(tuple.outcome.value, 0.0);
      expect(tuple.outcome.metadata['signal_weight'], 5.0);

      final rows = await store.getRecent(limit: 1);
      expect(rows, hasLength(1));
      expect(rows.first.metadata['phase_ref'], '1.4.6');
    });

    test('records suppress_category after threshold and user acceptance',
        () async {
      final r = RecommendationDismissalRecorder(
        episodicMemoryStore: store,
        agentIdService: AgentIdService(),
        suppressionThreshold: 3,
      );

      final first = await r.recordCategorySuppressionIfThresholdReached(
        userId: 'phase1-user',
        category: 'Nightlife',
        userAcceptedSuppressPrompt: true,
      );
      final second = await r.recordCategorySuppressionIfThresholdReached(
        userId: 'phase1-user',
        category: 'Nightlife',
        userAcceptedSuppressPrompt: true,
      );
      final third = await r.recordCategorySuppressionIfThresholdReached(
        userId: 'phase1-user',
        category: 'Nightlife',
        userAcceptedSuppressPrompt: true,
      );

      expect(first, isNull);
      expect(second, isNull);
      expect(third, isNotNull);
      expect(third!.actionType, 'suppress_category');
      expect(third.outcome.type, 'explicit_preference');
      expect(third.outcome.metadata['signal_weight'], 10.0);
    });

    test('does not record suppress_category when prompt is declined', () async {
      final r = RecommendationDismissalRecorder(
        episodicMemoryStore: store,
        agentIdService: AgentIdService(),
      );

      for (var i = 0; i < 5; i++) {
        final tuple = await r.recordCategorySuppressionIfThresholdReached(
          userId: 'phase1-user',
          category: 'Nightlife',
          userAcceptedSuppressPrompt: false,
        );
        expect(tuple, isNull);
      }
    });
  });
}

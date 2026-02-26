library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.17 first-occurrence alert', () {
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

    test('emits first_occurrence_alert for novel high-severity negative signal',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'first-occurrence-user-1',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {
            'failure_signature': 'novel_high_failure_a',
            'severity': 'high',
            'category': 'nightlife',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 16);
      final alertTuple = tuples.firstWhere(
        (row) => row.actionType == 'first_occurrence_alert',
      );
      expect(alertTuple.metadata['phase_ref'], equals('1.4.17'));
      expect(alertTuple.actionPayload['issue_signature'],
          equals('novel_high_failure_a'));

      expect(learningSystem.firstOccurrenceIssueEntries, isNotEmpty);
    });

    test('does not emit duplicate first-occurrence alert for same signature',
        () async {
      for (var i = 0; i < 2; i++) {
        await learningSystem.processUserInteraction(
          userId: 'first-occurrence-user-2',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'failure_signature': 'repeat_failure_signature',
              'severity': 'critical',
              'category': 'food',
            },
            'context': const {},
          },
        );
      }

      final tuples = await episodicStore.getRecent(limit: 32);
      final alertCount = tuples
          .where((row) => row.actionType == 'first_occurrence_alert')
          .length;
      expect(alertCount, equals(1));
    });

    test('ignores low-severity negative signal', () async {
      await learningSystem.processUserInteraction(
        userId: 'first-occurrence-user-3',
        payload: {
          'event_type': 'scroll_past_without_tap',
          'parameters': {
            'failure_signature': 'low_signal_signature',
            'signal_weight': 0.5,
            'severity': 'low',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 16);
      final hasAlert = tuples.any(
        (row) => row.actionType == 'first_occurrence_alert',
      );
      expect(hasAlert, isFalse);
      expect(learningSystem.firstOccurrenceIssueEntries, isEmpty);
    });
  });
}

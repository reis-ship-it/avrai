library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.14 delayed conviction validation', () {
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

    test('records provisional conviction increase with delayed windows',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'conviction-window-user-a',
        payload: {
          'event_type': 'conviction_confidence_update',
          'parameters': {
            'conviction_id': 'conviction-window-a',
            'previous_confidence': 0.50,
            'confidence_delta': 0.20,
            'supporting_evidence_ids': ['evidence-a'],
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 12);
      final provisionalTuple = tuples.firstWhere(
        (row) => row.actionType == 'conviction_increase_provisional',
      );
      expect(provisionalTuple.metadata['phase_ref'], equals('1.4.14'));
      expect(
        provisionalTuple.nextState['requires_delayed_validation'],
        isTrue,
      );

      final entries = learningSystem.convictionLedgerEntries;
      expect(entries, isNotEmpty);
      expect(
        entries.first.delayedValidationWindowIds,
        containsAll(<String>[
          'delayed_validation_7d',
          'delayed_validation_30d',
          'delayed_validation_90d',
        ]),
      );
    });

    test('finalizes confidence only after 7/30/90 checkpoints pass', () async {
      await learningSystem.processUserInteraction(
        userId: 'conviction-window-user-b',
        payload: {
          'event_type': 'conviction_confidence_update',
          'parameters': {
            'conviction_id': 'conviction-window-b',
            'previous_confidence': 0.40,
            'confidence_delta': 0.30,
          },
          'context': const {},
        },
      );

      for (final windowDays in [7, 30, 90]) {
        await learningSystem.processUserInteraction(
          userId: 'conviction-window-user-b',
          payload: {
            'event_type': 'conviction_validation_checkpoint',
            'parameters': {
              'conviction_id': 'conviction-window-b',
              'window_days': windowDays,
              'validation_passed': true,
            },
            'context': const {},
          },
        );
      }

      final tuples = await episodicStore.getRecent(limit: 48);
      final hasFinalizedTuple = tuples.any(
        (row) => row.actionType == 'conviction_increase_finalized',
      );
      expect(hasFinalizedTuple, isTrue);

      final entries = learningSystem.convictionLedgerEntries;
      final finalizedEntry = entries.firstWhere(
        (entry) => entry.metadata['finalized_after_delayed_validation'] == true,
      );
      expect(finalizedEntry.updatedConfidence, greaterThan(0.40));
    });

    test(
        'applies confidence decay when delayed window expires without validation',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'conviction-window-user-c',
        payload: {
          'event_type': 'conviction_confidence_update',
          'parameters': {
            'conviction_id': 'conviction-window-c',
            'previous_confidence': 0.50,
            'confidence_delta': 0.20,
          },
          'context': const {},
        },
      );

      await learningSystem.processUserInteraction(
        userId: 'conviction-window-user-c',
        payload: {
          'event_type': 'conviction_validation_window_expired',
          'parameters': {
            'conviction_id': 'conviction-window-c',
            'window_days': 7,
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 24);
      final decayTuple = tuples.firstWhere(
        (row) => row.actionType == 'conviction_missing_validation_decay',
      );
      expect(decayTuple.metadata['phase_ref'], equals('1.4.14'));
      expect(
        decayTuple.nextState['confidence_after'],
        lessThan(decayTuple.stateBefore['confidence_before'] as double),
      );

      final entries = learningSystem.convictionLedgerEntries;
      final decayEntry = entries.firstWhere(
        (entry) => entry.metadata['missing_window_decay'] == true,
      );
      expect(decayEntry.contradictionIds, isNotEmpty);
    });
  });
}

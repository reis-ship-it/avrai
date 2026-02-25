library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.13 conviction feedback', () {
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

    test('records helpful high-impact feedback tuple and ledger increase',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'conviction-user-helpful',
        payload: {
          'event_type': 'conviction_feedback_submitted',
          'parameters': {
            'high_impact': true,
            'conviction_id': 'conviction-alpha',
            'conviction_feedback': 'helpful',
            'recommendation_or_explanation': {
              'kind': 'recommendation',
              'reference_id': 'rec-1',
            },
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 12);
      final feedbackTuple = tuples.firstWhere(
        (row) => row.actionType == 'conviction_feedback',
      );
      expect(feedbackTuple.metadata['phase_ref'], equals('1.4.13'));
      expect(feedbackTuple.outcome.type, equals('conviction_feedback_helpful'));

      final ledgerEntries = learningSystem.convictionLedgerEntries;
      expect(ledgerEntries.length, equals(1));
      expect(ledgerEntries.first.previousConfidence,
          lessThan(ledgerEntries.first.updatedConfidence));
    });

    test('records unhelpful high-impact feedback with contradiction evidence',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'conviction-user-unhelpful',
        payload: {
          'event_type': 'conviction_feedback_submitted',
          'parameters': {
            'impact_level': 'high',
            'conviction_id': 'conviction-beta',
            'conviction_feedback': 'unhelpful',
            'recommendation_or_explanation': {
              'kind': 'explanation',
              'reference_id': 'exp-2',
            },
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 12);
      final feedbackTuple = tuples.firstWhere(
        (row) => row.actionType == 'conviction_feedback',
      );
      expect(
        feedbackTuple.outcome.type,
        equals('conviction_feedback_unhelpful'),
      );

      final ledgerEntries = learningSystem.convictionLedgerEntries;
      expect(ledgerEntries.length, equals(1));
      expect(ledgerEntries.first.contradictionIds, isNotEmpty);
      expect(
        ledgerEntries.first.updatedConfidence,
        lessThan(ledgerEntries.first.previousConfidence),
      );
    });

    test('ignores non-high-impact conviction feedback', () async {
      await learningSystem.processUserInteraction(
        userId: 'conviction-user-ignored',
        payload: {
          'event_type': 'conviction_feedback_submitted',
          'parameters': {
            'high_impact': false,
            'conviction_id': 'conviction-gamma',
            'conviction_feedback': 'uncertain',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 12);
      final hasFeedbackTuple = tuples.any(
        (row) => row.actionType == 'conviction_feedback',
      );
      expect(hasFeedbackTuple, isFalse);
      expect(learningSystem.convictionLedgerEntries, isEmpty);
    });
  });
}

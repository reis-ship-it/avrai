import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/search_learning_adapter.dart';

void main() {
  group('SearchLearningAdapter', () {
    const adapter = SearchLearningAdapter();

    test('returns neutral proposal when no search tuples are present', () {
      final proposal = adapter.buildProposalFromTuples(
        tuples: const [],
        now: DateTime.utc(2026, 2, 20, 12),
      );

      expect(proposal.sampleCount, 0);
      expect(proposal.rankerWeightDeltas['keyword'], 0.0);
      expect(proposal.queryRewriteDeltas['rewrite_aggressiveness'], 0.0);
    });

    test('increases rewrite aggressiveness when negative outcomes dominate',
        () {
      final tuples = [
        _searchTuple(
          outcomeType: 'bounce',
          keyword: 5,
          semantic: 1,
          structured: 1,
        ),
        _searchTuple(
          outcomeType: 'noAction',
          keyword: 4,
          semantic: 1,
          structured: 1,
        ),
        _searchTuple(
          outcomeType: 'click',
          keyword: 3,
          semantic: 2,
          structured: 1,
        ),
      ];

      final proposal = adapter.buildProposalFromTuples(
        tuples: tuples,
        now: DateTime.utc(2026, 2, 20, 12),
      );

      expect(proposal.sampleCount, 3);
      expect(
        proposal.queryRewriteDeltas['rewrite_aggressiveness']!,
        greaterThan(0),
      );
      expect(
        proposal.rankerWeightDeltas['locality']!,
        greaterThanOrEqualTo(0),
      );
    });

    test('keeps all deltas inside governance bounds', () {
      final tuples = List.generate(
        40,
        (_) => _searchTuple(
          outcomeType: 'bounce',
          keyword: 15,
          semantic: 0,
          structured: 0,
        ),
      );

      final proposal = adapter.buildProposalFromTuples(tuples: tuples);

      for (final value in proposal.rankerWeightDeltas.values) {
        expect(value, inInclusiveRange(-0.2, 0.2));
      }
      for (final value in proposal.queryRewriteDeltas.values) {
        expect(value, inInclusiveRange(-0.2, 0.2));
      }
    });
  });
}

EpisodicTuple _searchTuple({
  required String outcomeType,
  required int keyword,
  required int semantic,
  required int structured,
}) {
  return EpisodicTuple(
    agentId: 'user-1',
    stateBefore: const {
      'search_state': {'query_intent': 'discovery'}
    },
    actionType: 'search_retrieval',
    actionPayload: {
      'result_set_features': {
        'lane_candidate_counts': {
          'keyword': keyword,
          'semantic': semantic,
          'structured': structured,
        },
      },
    },
    nextState: {
      'downstream_outcome': {
        'type': outcomeType,
      },
    },
    outcome: const OutcomeSignal(
      type: 'search_result_click',
      category: OutcomeCategory.binary,
      value: 1.0,
    ),
    recordedAt: DateTime.utc(2026, 2, 20, 12),
  );
}

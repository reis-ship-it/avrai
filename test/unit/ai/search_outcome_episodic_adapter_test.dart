import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/search_outcome_episodic_adapter.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('SearchOutcomeEpisodicAdapter', () {
    late EpisodicMemoryStore store;
    late SearchOutcomeEpisodicAdapter adapter;

    setUp(() async {
      store = EpisodicMemoryStore();
      await store.clearForTesting();
      adapter = SearchOutcomeEpisodicAdapter(episodicMemoryStore: store);
    });

    test('writes retrieval tuple with required search and result-set fields',
        () async {
      const query = UnifiedRetrievalQuery(
        queryId: 'q-1',
        queryText: 'jazz near me',
        topK: 2,
      );
      const response = UnifiedRetrievalResponse(
        queryId: 'q-1',
        latencyMs: 95,
        requestedTopK: 2,
        items: [
          UnifiedRetrievedItem(
            itemId: 'spot-1',
            itemType: 'event',
            source: 'events',
            trustTier: RetrievalTrustTier.high,
            rankingTrace: RetrievalRankingTrace(
              laneScores: {'keyword': 0.8, 'semantic': 0.7, 'structured': 1.0},
              scoreContributions: {'recency': 0.1},
              finalScore: 0.88,
              rankPosition: 1,
            ),
          ),
          UnifiedRetrievedItem(
            itemId: 'spot-2',
            itemType: 'event',
            source: 'events',
            trustTier: RetrievalTrustTier.medium,
            rankingTrace: RetrievalRankingTrace(
              laneScores: {'keyword': 0.6, 'semantic': 0.65, 'structured': 0.9},
              scoreContributions: {'recency': 0.07},
              finalScore: 0.74,
              rankPosition: 2,
            ),
          ),
        ],
      );

      await adapter.recordSearchOutcome(
        agentId: 'user-1',
        searchState: const {
          'query_intent': 'local_discovery',
          'session_id': 's-1',
        },
        query: query,
        response: response,
        laneCandidateSets: const {
          'keyword': ['spot-1', 'spot-2', 'spot-3'],
          'semantic': ['spot-1', 'spot-4'],
          'structured': ['spot-1'],
        },
        downstreamOutcome: SearchDownstreamOutcome.click,
        outcomeContext: const {'selected_item_id': 'spot-1'},
        recordedAt: DateTime.utc(2026, 2, 20, 8),
      );

      final tuples = await store.replay(agentId: 'user-1');
      expect(tuples, hasLength(1));
      final tuple = tuples.first;

      expect(tuple.actionType, 'search_retrieval');
      expect(
          tuple.stateBefore['search_state']['query_intent'], 'local_discovery');
      expect(tuple.actionPayload['issued_query']['query_text'], 'jazz near me');
      expect(
          tuple.actionPayload['result_set_features']['lane_candidate_counts'], {
        'keyword': 3,
        'semantic': 2,
        'structured': 1,
      });
      expect(tuple.nextState['downstream_outcome']['type'], 'click');
      expect(tuple.outcome.type, 'search_result_click');
      expect(tuple.outcome.category, OutcomeCategory.binary);
      expect(tuple.outcome.value, 1.0);
    });

    test('records no-action as behavioral zero outcome', () async {
      const query = UnifiedRetrievalQuery(queryText: 'coffee');
      const response = UnifiedRetrievalResponse(
        items: [],
        latencyMs: 112,
        requestedTopK: 20,
      );

      await adapter.recordSearchOutcome(
        agentId: 'user-2',
        searchState: const {'query_intent': 'browse'},
        query: query,
        response: response,
        laneCandidateSets: const {},
        downstreamOutcome: SearchDownstreamOutcome.noAction,
      );

      final tuple = (await store.replay(agentId: 'user-2')).single;
      expect(tuple.outcome.type, 'search_result_no_action');
      expect(tuple.outcome.category, OutcomeCategory.behavioral);
      expect(tuple.outcome.value, 0.0);
    });
  });
}

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

enum SearchDownstreamOutcome {
  click,
  save,
  checkIn,
  bounce,
  noAction,
}

class SearchOutcomeEpisodicAdapter {
  const SearchOutcomeEpisodicAdapter({
    required EpisodicMemoryStore episodicMemoryStore,
    OutcomeTaxonomy outcomeTaxonomy = const OutcomeTaxonomy(),
  })  : _episodicMemoryStore = episodicMemoryStore,
        _outcomeTaxonomy = outcomeTaxonomy;

  final EpisodicMemoryStore _episodicMemoryStore;
  final OutcomeTaxonomy _outcomeTaxonomy;

  Future<EpisodicTuple> recordSearchOutcome({
    required String agentId,
    required Map<String, dynamic> searchState,
    required UnifiedRetrievalQuery query,
    required UnifiedRetrievalResponse response,
    required Map<String, List<String>> laneCandidateSets,
    required SearchDownstreamOutcome downstreamOutcome,
    Map<String, dynamic> outcomeContext = const {},
    DateTime? recordedAt,
  }) async {
    final now = recordedAt ?? DateTime.now().toUtc();
    final mappedOutcomeEvent = _mapOutcome(downstreamOutcome);

    final laneCandidateCounts = <String, int>{};
    laneCandidateSets.forEach((lane, ids) {
      laneCandidateCounts[lane] = ids.length;
    });

    final tuple = EpisodicTuple(
      agentId: agentId,
      stateBefore: {
        'phase_ref': '1.1D.9',
        'search_state': searchState,
      },
      actionType: 'search_retrieval',
      actionPayload: {
        'issued_query': {
          'query_id': query.queryId,
          'query_text': query.queryText,
          'top_k': query.topK,
          'has_semantic_embedding': query.semanticEmbedding != null &&
              query.semanticEmbedding!.isNotEmpty,
        },
        'result_set_features': {
          'lane_candidate_counts': laneCandidateCounts,
          'selected_top_k':
              response.items.map((item) => item.itemId).toList(growable: false),
          'selected_top_k_scores': {
            for (final item in response.items)
              item.itemId: item.rankingTrace.finalScore,
          },
          'selected_top_k_size': response.items.length,
          'retrieval_latency_ms': response.latencyMs,
        },
      },
      nextState: {
        'downstream_outcome': {
          'type': downstreamOutcome.name,
          'event': mappedOutcomeEvent,
          ...outcomeContext,
        },
      },
      outcome: _outcomeTaxonomy.classify(
        eventType: mappedOutcomeEvent,
        parameters: {
          'query_id': query.queryId ?? '',
          'query_text': query.queryText,
          'selected_top_k_size': response.items.length,
          'retrieval_latency_ms': response.latencyMs,
          ...outcomeContext,
        },
      ),
      metadata: const {
        'phase_ref': '1.1D.9',
        'pipeline': 'search_outcome_episodic_adapter',
      },
      recordedAt: now,
    );

    await _episodicMemoryStore.writeTuple(tuple);
    return tuple;
  }

  String _mapOutcome(SearchDownstreamOutcome outcome) {
    switch (outcome) {
      case SearchDownstreamOutcome.click:
        return 'search_result_click';
      case SearchDownstreamOutcome.save:
        return 'search_result_save';
      case SearchDownstreamOutcome.checkIn:
        return 'search_result_check_in';
      case SearchDownstreamOutcome.bounce:
        return 'search_result_bounce';
      case SearchDownstreamOutcome.noAction:
        return 'search_result_no_action';
    }
  }
}

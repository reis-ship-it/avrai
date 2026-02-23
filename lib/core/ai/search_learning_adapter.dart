import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';

class SearchLearningProposal {
  final int sampleCount;
  final Map<String, double> rankerWeightDeltas;
  final Map<String, double> queryRewriteDeltas;
  final DateTime generatedAt;

  const SearchLearningProposal({
    required this.sampleCount,
    required this.rankerWeightDeltas,
    required this.queryRewriteDeltas,
    required this.generatedAt,
  });
}

/// Learns suggested ranking/rewrite parameter deltas from outcomes.
///
/// This adapter is intentionally proposal-only; it does not mutate production
/// ranking/query-rewrite logic directly.
class SearchLearningAdapter {
  const SearchLearningAdapter();

  SearchLearningProposal buildProposalFromTuples({
    required List<EpisodicTuple> tuples,
    DateTime? now,
  }) {
    final relevant = tuples
        .where((t) => t.actionType == 'search_retrieval')
        .toList(growable: false);

    if (relevant.isEmpty) {
      return SearchLearningProposal(
        sampleCount: 0,
        rankerWeightDeltas: const {
          'keyword': 0.0,
          'semantic': 0.0,
          'structured': 0.0,
          'locality': 0.0,
        },
        queryRewriteDeltas: const {
          'rewrite_aggressiveness': 0.0,
          'geo_disambiguation_boost': 0.0,
          'temporal_normalization_boost': 0.0,
        },
        generatedAt: now ?? DateTime.now().toUtc(),
      );
    }

    var positive = 0;
    var negative = 0;
    var totalKeywordCandidates = 0;
    var totalSemanticCandidates = 0;
    var totalStructuredCandidates = 0;

    for (final tuple in relevant) {
      final outcomeType =
          tuple.nextState['downstream_outcome'] is Map<String, dynamic>
              ? (tuple.nextState['downstream_outcome']
                  as Map<String, dynamic>)['type'] as String?
              : null;

      switch (outcomeType) {
        case 'click':
        case 'save':
        case 'checkIn':
          positive += 1;
          break;
        case 'bounce':
        case 'noAction':
          negative += 1;
          break;
      }

      final payload = tuple.actionPayload['result_set_features'];
      if (payload is Map<String, dynamic>) {
        final laneCounts = payload['lane_candidate_counts'];
        if (laneCounts is Map<String, dynamic>) {
          totalKeywordCandidates +=
              (laneCounts['keyword'] as num?)?.toInt() ?? 0;
          totalSemanticCandidates +=
              (laneCounts['semantic'] as num?)?.toInt() ?? 0;
          totalStructuredCandidates +=
              (laneCounts['structured'] as num?)?.toInt() ?? 0;
        }
      }
    }

    final total = relevant.length;
    final positiveRate = total == 0 ? 0.0 : positive / total;
    final negativeRate = total == 0 ? 0.0 : negative / total;

    final keywordDominance = _safeRatio(
      totalKeywordCandidates.toDouble(),
      (totalSemanticCandidates + totalStructuredCandidates).toDouble(),
    );
    final semanticDominance = _safeRatio(
      totalSemanticCandidates.toDouble(),
      (totalKeywordCandidates + totalStructuredCandidates).toDouble(),
    );

    // Proposal deltas are bounded and intended for downstream governance.
    final rankerWeightDeltas = <String, double>{
      'keyword': _clamp((keywordDominance - 0.5) * 0.08),
      'semantic': _clamp((semanticDominance - 0.5) * 0.08),
      'structured':
          _clamp((0.5 - (keywordDominance - semanticDominance)) * 0.04),
      'locality': _clamp((negativeRate - positiveRate) * 0.1),
    };

    final queryRewriteDeltas = <String, double>{
      'rewrite_aggressiveness': _clamp((negativeRate - positiveRate) * 0.15),
      'geo_disambiguation_boost': _clamp((negativeRate * 0.12) - 0.03),
      'temporal_normalization_boost': _clamp((negativeRate * 0.1) - 0.02),
    };

    return SearchLearningProposal(
      sampleCount: total,
      rankerWeightDeltas: rankerWeightDeltas,
      queryRewriteDeltas: queryRewriteDeltas,
      generatedAt: now ?? DateTime.now().toUtc(),
    );
  }

  double _safeRatio(double numerator, double denominator) {
    if (numerator <= 0) return 0;
    if (denominator <= 0) return 1;
    return numerator / (numerator + denominator);
  }

  double _clamp(double value) => value.clamp(-0.2, 0.2).toDouble();
}

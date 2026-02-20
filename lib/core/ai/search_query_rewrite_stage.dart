import 'package:avrai/core/ai/unified_retrieval_contract.dart';

class QueryRewriteCandidate {
  final UnifiedRetrievalQuery query;
  final List<String> appliedRewrites;
  final double confidence;

  const QueryRewriteCandidate({
    required this.query,
    required this.appliedRewrites,
    required this.confidence,
  });
}

class QueryRewriteResult {
  final bool rewrote;
  final List<QueryRewriteCandidate> candidates;

  const QueryRewriteResult({
    required this.rewrote,
    required this.candidates,
  });
}

/// Deterministic rewrite stage for low-result/low-quality search queries.
class SearchQueryRewriteStage {
  SearchQueryRewriteStage({
    this.minResultsWithoutRewrite = 3,
    this.minAverageTopScoreWithoutRewrite = 0.55,
    DateTime Function()? nowProvider,
    Map<String, String> typoNormalization = const {
      'cofee': 'coffee',
      'restaraunt': 'restaurant',
      'tonite': 'tonight',
      'imediate': 'immediate',
    },
    Map<String, List<String>> synonyms = const {
      'coffee': ['cafe', 'espresso bar'],
      'bar': ['pub', 'lounge'],
      'restaurant': ['eatery', 'dining'],
      'gym': ['fitness center', 'workout studio'],
    },
    Map<String, List<String>> ambiguousGeoHints = const {
      'springfield': ['springfield il', 'springfield ma', 'springfield mo'],
      'portland': ['portland or', 'portland me'],
      'richmond': ['richmond va', 'richmond ca'],
    },
  })  : _nowProvider = nowProvider ?? (() => DateTime.now().toUtc()),
        _typoNormalization = typoNormalization,
        _synonyms = synonyms,
        _ambiguousGeoHints = ambiguousGeoHints;

  final int minResultsWithoutRewrite;
  final double minAverageTopScoreWithoutRewrite;
  final DateTime Function() _nowProvider;
  final Map<String, String> _typoNormalization;
  final Map<String, List<String>> _synonyms;
  final Map<String, List<String>> _ambiguousGeoHints;

  QueryRewriteResult rewriteForLowQuality({
    required UnifiedRetrievalQuery query,
    required int currentResultCount,
    required double averageTopScore,
    String? userGeoHint,
  }) {
    if (currentResultCount >= minResultsWithoutRewrite &&
        averageTopScore >= minAverageTopScoreWithoutRewrite) {
      return const QueryRewriteResult(rewrote: false, candidates: []);
    }

    final candidates = <QueryRewriteCandidate>[];

    final normalized = _applySpellingNormalization(query);
    if (normalized != null) {
      candidates.add(normalized);
    }

    final expanded = _applySynonymExpansion(query);
    if (expanded != null) {
      candidates.add(expanded);
    }

    final geoDisambiguated = _applyGeoDisambiguation(query, userGeoHint);
    if (geoDisambiguated != null) {
      candidates.add(geoDisambiguated);
    }

    final temporal = _applyTemporalNormalization(query);
    if (temporal != null) {
      candidates.add(temporal);
    }

    return QueryRewriteResult(
      rewrote: candidates.isNotEmpty,
      candidates: candidates,
    );
  }

  QueryRewriteCandidate? _applySpellingNormalization(
      UnifiedRetrievalQuery query) {
    final tokens = query.queryText
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return null;

    var changed = false;
    final normalized = <String>[];
    for (final token in tokens) {
      final replacement = _typoNormalization[token];
      if (replacement != null) {
        normalized.add(replacement);
        changed = true;
      } else {
        normalized.add(token);
      }
    }
    if (!changed) return null;

    return QueryRewriteCandidate(
      query: UnifiedRetrievalQuery(
        queryText: normalized.join(' '),
        semanticEmbedding: query.semanticEmbedding,
        filters: query.filters,
        topK: query.topK,
        queryId: query.queryId,
      ),
      appliedRewrites: const ['spelling_normalization'],
      confidence: 0.85,
    );
  }

  QueryRewriteCandidate? _applySynonymExpansion(UnifiedRetrievalQuery query) {
    final tokens = query.queryText
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    final expansions = <String>[];
    for (final token in tokens) {
      final options = _synonyms[token];
      if (options != null && options.isNotEmpty) {
        expansions.add(options.first);
      }
    }
    if (expansions.isEmpty) return null;

    return QueryRewriteCandidate(
      query: UnifiedRetrievalQuery(
        queryText: '${query.queryText} ${expansions.join(' ')}',
        semanticEmbedding: query.semanticEmbedding,
        filters: query.filters,
        topK: query.topK,
        queryId: query.queryId,
      ),
      appliedRewrites: const ['synonym_expansion'],
      confidence: 0.72,
    );
  }

  QueryRewriteCandidate? _applyGeoDisambiguation(
    UnifiedRetrievalQuery query,
    String? userGeoHint,
  ) {
    final rawHint = userGeoHint?.trim();
    if (rawHint == null || rawHint.isEmpty) return null;

    final lower = query.queryText.toLowerCase();
    for (final entry in _ambiguousGeoHints.entries) {
      if (!lower.contains(entry.key)) continue;

      final fallback = entry.value.first;
      final exactHint = '${entry.key} ${rawHint.toLowerCase()}';
      final chosen = entry.value.firstWhere(
        (option) => option == exactHint,
        orElse: () => fallback,
      );

      return QueryRewriteCandidate(
        query: UnifiedRetrievalQuery(
          queryText: '$lower near $chosen',
          semanticEmbedding: query.semanticEmbedding,
          filters: query.filters,
          topK: query.topK,
          queryId: query.queryId,
        ),
        appliedRewrites: const ['geo_disambiguation'],
        confidence: 0.78,
      );
    }

    return null;
  }

  QueryRewriteCandidate? _applyTemporalNormalization(
      UnifiedRetrievalQuery query) {
    final lower = query.queryText.toLowerCase();

    RetrievalTimeWindow? timeWindow;
    var matched = false;
    final now = _nowProvider();

    if (lower.contains('tonight')) {
      matched = true;
      final start = DateTime.utc(now.year, now.month, now.day, 18);
      final end = start.add(const Duration(hours: 12));
      timeWindow =
          RetrievalTimeWindow(startInclusive: start, endExclusive: end);
    } else if (lower.contains('tomorrow')) {
      matched = true;
      final start = DateTime.utc(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      final end = start.add(const Duration(days: 1));
      timeWindow =
          RetrievalTimeWindow(startInclusive: start, endExclusive: end);
    } else if (lower.contains('this weekend')) {
      matched = true;
      final weekday = now.weekday;
      final daysUntilSaturday = (DateTime.saturday - weekday) % 7;
      final start = DateTime.utc(now.year, now.month, now.day)
          .add(Duration(days: daysUntilSaturday));
      final end = start.add(const Duration(days: 2));
      timeWindow =
          RetrievalTimeWindow(startInclusive: start, endExclusive: end);
    }

    if (!matched || timeWindow == null) {
      return null;
    }

    return QueryRewriteCandidate(
      query: UnifiedRetrievalQuery(
        queryText: query.queryText,
        semanticEmbedding: query.semanticEmbedding,
        filters: UnifiedRetrievalFilters(
          timeWindow: timeWindow,
          geoRadius: query.filters.geoRadius,
          category: query.filters.category,
          platform: query.filters.platform,
          trustTier: query.filters.trustTier,
        ),
        topK: query.topK,
        queryId: query.queryId,
      ),
      appliedRewrites: const ['temporal_normalization'],
      confidence: 0.8,
    );
  }
}

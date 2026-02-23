import 'dart:math' as math;

import 'package:avrai/core/ai/unified_retrieval_contract.dart';

class KeywordRetrievalDocument {
  final String id;
  final String itemType;
  final String source;
  final String text;
  final RetrievalPlatform platform;
  final RetrievalTrustTier trustTier;
  final String? category;
  final DateTime? occursAt;
  final double? lat;
  final double? lng;
  final Map<String, Object?> payload;

  const KeywordRetrievalDocument({
    required this.id,
    required this.itemType,
    required this.source,
    required this.text,
    required this.platform,
    required this.trustTier,
    this.category,
    this.occursAt,
    this.lat,
    this.lng,
    this.payload = const {},
  });
}

abstract class KeywordRetrievalCorpus {
  Future<List<KeywordRetrievalDocument>> loadDocuments(
    UnifiedRetrievalQuery query,
  );
}

/// First-class keyword lane (not fallback-only) using BM25-style lexical score.
class KeywordRetrievalLane implements UnifiedRetrievalContract {
  const KeywordRetrievalLane({
    required KeywordRetrievalCorpus corpus,
  }) : _corpus = corpus;

  final KeywordRetrievalCorpus _corpus;

  @override
  Future<UnifiedRetrievalResponse> retrieve(UnifiedRetrievalQuery query) async {
    final started = DateTime.now();
    final rawDocuments = await _corpus.loadDocuments(query);
    final documents = rawDocuments.where((doc) => _matchesFilters(doc, query));
    final queryTokens = _tokenize(query.queryText);
    if (queryTokens.isEmpty) {
      return UnifiedRetrievalResponse(
        queryId: query.queryId,
        items: const [],
        latencyMs: DateTime.now().difference(started).inMilliseconds,
        requestedTopK: query.topK,
      );
    }

    final docTokenSets = <String, List<String>>{};
    for (final doc in documents) {
      docTokenSets[doc.id] = _tokenize(doc.text);
    }

    final idfByToken = <String, double>{};
    final docCount = math.max(docTokenSets.length, 1);
    for (final token in queryTokens) {
      var df = 0;
      for (final tokens in docTokenSets.values) {
        if (tokens.contains(token)) df += 1;
      }
      idfByToken[token] = math.log((docCount + 1) / (df + 1)) + 1.0;
    }

    final scored = <({KeywordRetrievalDocument doc, double score})>[];
    for (final doc in documents) {
      final tokens = docTokenSets[doc.id] ?? const <String>[];
      final score = _scoreDocument(
        queryText: query.queryText,
        queryTokens: queryTokens,
        docTokens: tokens,
        idfByToken: idfByToken,
      );
      if (score <= 0) continue;
      scored.add((doc: doc, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(query.topK).toList(growable: false);
    final items = <UnifiedRetrievedItem>[];
    for (var i = 0; i < top.length; i++) {
      final row = top[i];
      items.add(
        UnifiedRetrievedItem(
          itemId: row.doc.id,
          itemType: row.doc.itemType,
          source: row.doc.source,
          trustTier: row.doc.trustTier,
          rankingTrace: RetrievalRankingTrace(
            laneScores: {'keyword': row.score},
            scoreContributions: const {},
            finalScore: row.score,
            rankPosition: i + 1,
          ),
          payload: row.doc.payload,
        ),
      );
    }

    return UnifiedRetrievalResponse(
      queryId: query.queryId,
      items: items,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
      requestedTopK: query.topK,
    );
  }

  bool _matchesFilters(
    KeywordRetrievalDocument doc,
    UnifiedRetrievalQuery query,
  ) {
    final filters = query.filters;
    if (filters.category != null &&
        filters.category!.trim().isNotEmpty &&
        doc.category?.toLowerCase() != filters.category!.toLowerCase()) {
      return false;
    }
    if (filters.platform != null && doc.platform != filters.platform) {
      return false;
    }
    if (filters.trustTier != null &&
        doc.trustTier.index < filters.trustTier!.index) {
      return false;
    }
    final timeWindow = filters.timeWindow;
    if (timeWindow != null) {
      final occursAt = doc.occursAt;
      if (occursAt == null) return false;
      if (occursAt.isBefore(timeWindow.startInclusive)) return false;
      if (!occursAt.isBefore(timeWindow.endExclusive)) return false;
    }
    final geo = filters.geoRadius;
    if (geo != null) {
      if (doc.lat == null || doc.lng == null) return false;
      final distance = _haversineMeters(
        lat1: geo.centerLat,
        lng1: geo.centerLng,
        lat2: doc.lat!,
        lng2: doc.lng!,
      );
      if (distance > geo.radiusMeters) return false;
    }
    return true;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  double _scoreDocument({
    required String queryText,
    required List<String> queryTokens,
    required List<String> docTokens,
    required Map<String, double> idfByToken,
  }) {
    if (docTokens.isEmpty) return 0;
    final docLength = docTokens.length;
    final tokenFreq = <String, int>{};
    for (final token in docTokens) {
      tokenFreq[token] = (tokenFreq[token] ?? 0) + 1;
    }

    double score = 0;
    var matchedTerms = 0;
    for (final token in queryTokens) {
      final freq = tokenFreq[token] ?? 0;
      if (freq > 0) {
        matchedTerms += 1;
      }
      final tf = freq / docLength;
      score += (idfByToken[token] ?? 1.0) * tf;
    }

    final normalizedQuery = queryText.trim().toLowerCase();
    final normalizedDocText = docTokens.join(' ');
    if (normalizedQuery.contains(' ') &&
        normalizedDocText.contains(normalizedQuery)) {
      score += 0.2;
    }
    if (matchedTerms == queryTokens.length && matchedTerms > 0) {
      score += 0.15;
    }
    return score;
  }

  double _haversineMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _degToRad(double value) => value * math.pi / 180.0;
}

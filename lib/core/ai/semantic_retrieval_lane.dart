import 'dart:math' as math;

import 'package:avrai/core/ai/unified_retrieval_contract.dart';

class SemanticRetrievalVectorDocument {
  final String id;
  final String itemType;
  final String source;
  final List<double> embedding;
  final RetrievalPlatform platform;
  final RetrievalTrustTier trustTier;
  final String? category;
  final DateTime? occursAt;
  final double? lat;
  final double? lng;
  final Map<String, Object?> payload;

  const SemanticRetrievalVectorDocument({
    required this.id,
    required this.itemType,
    required this.source,
    required this.embedding,
    required this.platform,
    required this.trustTier,
    this.category,
    this.occursAt,
    this.lat,
    this.lng,
    this.payload = const {},
  });
}

abstract class SemanticRetrievalCorpus {
  Future<List<SemanticRetrievalVectorDocument>> loadDocuments(
    UnifiedRetrievalQuery query,
  );
}

/// Semantic retrieval lane over vector documents for intent-level matching.
class SemanticRetrievalLane implements UnifiedRetrievalContract {
  const SemanticRetrievalLane({
    required SemanticRetrievalCorpus corpus,
    this.minSimilarity = -1.0,
  }) : _corpus = corpus;

  final SemanticRetrievalCorpus _corpus;
  final double minSimilarity;

  @override
  Future<UnifiedRetrievalResponse> retrieve(UnifiedRetrievalQuery query) async {
    final started = DateTime.now();
    final queryEmbedding = query.semanticEmbedding;
    if (queryEmbedding == null || queryEmbedding.isEmpty) {
      return UnifiedRetrievalResponse(
        queryId: query.queryId,
        items: const [],
        latencyMs: DateTime.now().difference(started).inMilliseconds,
        requestedTopK: query.topK,
      );
    }

    final rawDocuments = await _corpus.loadDocuments(query);
    final documents = rawDocuments.where((doc) => _matchesFilters(doc, query));

    final scored = <({SemanticRetrievalVectorDocument doc, double score})>[];
    for (final doc in documents) {
      final similarity = _cosineSimilarity(queryEmbedding, doc.embedding);
      if (similarity < minSimilarity) continue;
      scored.add((doc: doc, score: similarity));
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
            laneScores: {'semantic': row.score},
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
    SemanticRetrievalVectorDocument doc,
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

  double _cosineSimilarity(List<double> left, List<double> right) {
    if (left.isEmpty || right.isEmpty) return -1.0;
    final length = math.min(left.length, right.length);
    if (length == 0) return -1.0;

    var dot = 0.0;
    var leftNorm = 0.0;
    var rightNorm = 0.0;
    for (var i = 0; i < length; i++) {
      dot += left[i] * right[i];
      leftNorm += left[i] * left[i];
      rightNorm += right[i] * right[i];
    }
    if (leftNorm <= 0 || rightNorm <= 0) return -1.0;
    return dot / (math.sqrt(leftNorm) * math.sqrt(rightNorm));
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

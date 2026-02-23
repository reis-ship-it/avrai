import 'dart:math' as math;

import 'package:avrai/core/ai/unified_retrieval_contract.dart';

/// Combines retrieval lanes into one ranked response with transparent scoring.
class RetrievalFusionRanker {
  const RetrievalFusionRanker({
    this.keywordWeight = 0.4,
    this.semanticWeight = 0.35,
    this.structuredWeight = 0.25,
    this.recencyWeight = 0.15,
    this.sourceTrustWeight = 0.1,
    this.localityWeight = 0.15,
  });

  final double keywordWeight;
  final double semanticWeight;
  final double structuredWeight;
  final double recencyWeight;
  final double sourceTrustWeight;
  final double localityWeight;

  UnifiedRetrievalResponse fuse({
    required UnifiedRetrievalQuery query,
    List<UnifiedRetrievedItem> keywordItems = const [],
    List<UnifiedRetrievedItem> semanticItems = const [],
    List<UnifiedRetrievedItem> structuredItems = const [],
    DateTime? now,
  }) {
    final started = DateTime.now();
    final merged = <String, _FusedCandidate>{};

    void ingest(List<UnifiedRetrievedItem> items, String laneName) {
      for (final item in items) {
        final existing = merged[item.itemId];
        if (existing == null) {
          merged[item.itemId] = _FusedCandidate.seed(item, laneName);
          continue;
        }
        existing.ingest(item, laneName);
      }
    }

    ingest(keywordItems, 'keyword');
    ingest(semanticItems, 'semantic');
    ingest(structuredItems, 'structured');

    final evaluationNow = now ?? DateTime.now().toUtc();
    final scored = merged.values.map((candidate) {
      final keyword = _normalizeKeywordScore(candidate.laneScores['keyword']);
      final semantic =
          _normalizeSemanticScore(candidate.laneScores['semantic']);
      final structured =
          _normalizeStructuredScore(candidate.laneScores['structured']);

      final recency = _computeRecencyScore(candidate.payload, evaluationNow);
      final trust = _computeTrustScore(candidate.item.trustTier);
      final locality = _computeLocalityScore(query, candidate.payload);

      final laneScore = (keywordWeight * keyword) +
          (semanticWeight * semantic) +
          (structuredWeight * structured);

      final finalScore = laneScore +
          (recencyWeight * recency) +
          (sourceTrustWeight * trust) +
          (localityWeight * locality);

      return (
        candidate: candidate,
        laneScores: <String, double>{
          if (candidate.laneScores.containsKey('keyword')) 'keyword': keyword,
          if (candidate.laneScores.containsKey('semantic'))
            'semantic': semantic,
          if (candidate.laneScores.containsKey('structured'))
            'structured': structured,
        },
        scoreContributions: <String, double>{
          'recency': recencyWeight * recency,
          'source_trust': sourceTrustWeight * trust,
          'locality_relevance': localityWeight * locality,
        },
        finalScore: finalScore,
      );
    }).toList(growable: false)
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    final boundedTopK = query.topK <= 0 ? 0 : query.topK;
    final top = scored.take(boundedTopK).toList(growable: false);

    final items = <UnifiedRetrievedItem>[];
    for (var i = 0; i < top.length; i++) {
      final row = top[i];
      items.add(
        UnifiedRetrievedItem(
          itemId: row.candidate.item.itemId,
          itemType: row.candidate.item.itemType,
          source: row.candidate.item.source,
          trustTier: row.candidate.item.trustTier,
          payload: row.candidate.payload,
          rankingTrace: RetrievalRankingTrace(
            laneScores: row.laneScores,
            scoreContributions: row.scoreContributions,
            finalScore: row.finalScore,
            rankPosition: i + 1,
          ),
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

  double _normalizeKeywordScore(double? value) {
    if (value == null || value.isNaN || value <= 0) return 0;
    return (value / (1.0 + value)).clamp(0, 1).toDouble();
  }

  double _normalizeSemanticScore(double? value) {
    if (value == null || value.isNaN) return 0;
    return ((value + 1.0) / 2.0).clamp(0, 1).toDouble();
  }

  double _normalizeStructuredScore(double? value) {
    if (value == null || value.isNaN) return 0;
    return value.clamp(0, 1).toDouble();
  }

  double _computeRecencyScore(Map<String, Object?> payload, DateTime nowUtc) {
    final raw = payload['occurs_at'];
    DateTime? occursAt;
    if (raw is DateTime) {
      occursAt = raw.toUtc();
    } else if (raw is String) {
      occursAt = DateTime.tryParse(raw)?.toUtc();
    }
    if (occursAt == null) return 0;

    final hours = nowUtc.difference(occursAt).inMinutes.abs() / 60.0;
    return (1.0 / (1.0 + (hours / 24.0))).clamp(0, 1).toDouble();
  }

  double _computeTrustScore(RetrievalTrustTier trustTier) {
    switch (trustTier) {
      case RetrievalTrustTier.high:
        return 1.0;
      case RetrievalTrustTier.medium:
        return 0.7;
      case RetrievalTrustTier.low:
        return 0.35;
      case RetrievalTrustTier.unknown:
        return 0.1;
    }
  }

  double _computeLocalityScore(
    UnifiedRetrievalQuery query,
    Map<String, Object?> payload,
  ) {
    final directDistance = _asDouble(payload['distance_meters']);
    final geo = query.filters.geoRadius;

    if (directDistance != null && geo != null && geo.radiusMeters > 0) {
      final normalized = 1.0 - (directDistance / geo.radiusMeters);
      return normalized.clamp(0, 1).toDouble();
    }

    if (geo == null || geo.radiusMeters <= 0) {
      return 0;
    }

    final lat = _asDouble(payload['lat']);
    final lng = _asDouble(payload['lng']);
    if (lat == null || lng == null) return 0;

    final distance = _haversineMeters(
      lat1: geo.centerLat,
      lng1: geo.centerLng,
      lat2: lat,
      lng2: lng,
    );
    final normalized = 1.0 - (distance / geo.radiusMeters);
    return normalized.clamp(0, 1).toDouble();
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

class _FusedCandidate {
  _FusedCandidate._({
    required this.item,
    required this.payload,
    required this.laneScores,
  });

  UnifiedRetrievedItem item;
  Map<String, Object?> payload;
  final Map<String, double> laneScores;

  factory _FusedCandidate.seed(UnifiedRetrievedItem item, String laneName) {
    return _FusedCandidate._(
      item: item,
      payload: Map<String, Object?>.from(item.payload),
      laneScores: {
        laneName: item.rankingTrace.laneScores[laneName] ??
            item.rankingTrace.finalScore,
      },
    );
  }

  void ingest(UnifiedRetrievedItem incoming, String laneName) {
    final score = incoming.rankingTrace.laneScores[laneName] ??
        incoming.rankingTrace.finalScore;
    final current = laneScores[laneName];
    if (current == null || score > current) {
      laneScores[laneName] = score;
    }

    // Prefer higher-trust source representation for shared item IDs.
    if (incoming.trustTier.index > item.trustTier.index) {
      item = incoming;
    }

    payload = {...payload, ...incoming.payload};
  }
}

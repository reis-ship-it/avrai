import 'dart:math' as math;

import 'package:avrai/core/ai/unified_retrieval_contract.dart';

class StructuredRetrievalDocument {
  final String id;
  final String itemType;
  final String source;
  final RetrievalPlatform platform;
  final RetrievalTrustTier trustTier;
  final String? category;
  final DateTime? occursAt;
  final double? lat;
  final double? lng;
  final bool isOpenNow;
  final int minimumAgeRequirement;
  final bool safetyEligible;
  final Map<String, Object?> payload;

  const StructuredRetrievalDocument({
    required this.id,
    required this.itemType,
    required this.source,
    required this.platform,
    required this.trustTier,
    this.category,
    this.occursAt,
    this.lat,
    this.lng,
    this.isOpenNow = true,
    this.minimumAgeRequirement = 0,
    this.safetyEligible = true,
    this.payload = const {},
  });
}

abstract class StructuredRetrievalCorpus {
  Future<List<StructuredRetrievalDocument>> loadDocuments(
    UnifiedRetrievalQuery query,
  );
}

/// Structured retrieval lane for hard constraints and compliance filtering.
class StructuredRetrievalLane implements UnifiedRetrievalContract {
  const StructuredRetrievalLane({
    required StructuredRetrievalCorpus corpus,
  }) : _corpus = corpus;

  final StructuredRetrievalCorpus _corpus;

  @override
  Future<UnifiedRetrievalResponse> retrieve(UnifiedRetrievalQuery query) async {
    final started = DateTime.now();
    final docs = await _corpus.loadDocuments(query);
    final filtered = docs.where((doc) => _matchesHardConstraints(doc, query));

    final scored = filtered
        .map((doc) => (doc: doc, score: _structuredScore(doc, query)))
        .toList(growable: true)
      ..sort((a, b) => b.score.compareTo(a.score));

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
            laneScores: {'structured': row.score},
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

  bool _matchesHardConstraints(
    StructuredRetrievalDocument doc,
    UnifiedRetrievalQuery query,
  ) {
    final filters = query.filters;
    if (filters.platform != null && doc.platform != filters.platform) {
      return false;
    }
    if (filters.category != null &&
        filters.category!.trim().isNotEmpty &&
        doc.category?.toLowerCase() != filters.category!.toLowerCase()) {
      return false;
    }
    if (filters.trustTier != null &&
        doc.trustTier.index < filters.trustTier!.index) {
      return false;
    }
    if (filters.openNowOnly && !doc.isOpenNow) {
      return false;
    }
    final userAge = filters.userAge;
    if (userAge != null && userAge < doc.minimumAgeRequirement) {
      return false;
    }
    if (filters.safetyEligibleOnly && !doc.safetyEligible) {
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

  double _structuredScore(
    StructuredRetrievalDocument doc,
    UnifiedRetrievalQuery query,
  ) {
    final filters = query.filters;
    var criteria = 0;
    var satisfied = 0.0;

    if (filters.platform != null) {
      criteria += 1;
      if (doc.platform == filters.platform) satisfied += 1;
    }
    if (filters.category != null && filters.category!.trim().isNotEmpty) {
      criteria += 1;
      if (doc.category?.toLowerCase() == filters.category!.toLowerCase()) {
        satisfied += 1;
      }
    }
    if (filters.trustTier != null) {
      criteria += 1;
      if (doc.trustTier.index >= filters.trustTier!.index) satisfied += 1;
    }
    if (filters.openNowOnly) {
      criteria += 1;
      if (doc.isOpenNow) satisfied += 1;
    }
    if (filters.userAge != null) {
      criteria += 1;
      if (filters.userAge! >= doc.minimumAgeRequirement) satisfied += 1;
    }
    if (filters.safetyEligibleOnly) {
      criteria += 1;
      if (doc.safetyEligible) satisfied += 1;
    }
    if (filters.timeWindow != null) {
      criteria += 1;
      if (doc.occursAt != null &&
          !doc.occursAt!.isBefore(filters.timeWindow!.startInclusive) &&
          doc.occursAt!.isBefore(filters.timeWindow!.endExclusive)) {
        satisfied += 1;
      }
    }
    if (filters.geoRadius != null) {
      criteria += 1;
      final hasCoords = doc.lat != null && doc.lng != null;
      if (hasCoords) {
        final distance = _haversineMeters(
          lat1: filters.geoRadius!.centerLat,
          lng1: filters.geoRadius!.centerLng,
          lat2: doc.lat!,
          lng2: doc.lng!,
        );
        if (distance <= filters.geoRadius!.radiusMeters) {
          satisfied += 1;
        }
      }
    }

    if (criteria == 0) return 1.0;
    return (satisfied / criteria).clamp(0.0, 1.0);
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

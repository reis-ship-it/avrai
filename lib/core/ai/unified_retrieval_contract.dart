/// Phase 1.1D.1 unified retrieval contract for local events/places/platforms.
///
/// This is a lane-agnostic request/response model used by keyword, semantic,
/// and structured retrieval stages plus fusion ranking.
enum RetrievalPlatform {
  events,
  places,
  platforms,
}

enum RetrievalTrustTier {
  unknown,
  low,
  medium,
  high,
}

class RetrievalTimeWindow {
  final DateTime startInclusive;
  final DateTime endExclusive;

  const RetrievalTimeWindow({
    required this.startInclusive,
    required this.endExclusive,
  });
}

class RetrievalGeoRadius {
  final double centerLat;
  final double centerLng;
  final double radiusMeters;

  const RetrievalGeoRadius({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
  });
}

class UnifiedRetrievalFilters {
  final RetrievalTimeWindow? timeWindow;
  final RetrievalGeoRadius? geoRadius;
  final String? category;
  final RetrievalPlatform? platform;
  final RetrievalTrustTier? trustTier;
  final bool openNowOnly;
  final int? userAge;
  final bool safetyEligibleOnly;

  const UnifiedRetrievalFilters({
    this.timeWindow,
    this.geoRadius,
    this.category,
    this.platform,
    this.trustTier,
    this.openNowOnly = false,
    this.userAge,
    this.safetyEligibleOnly = false,
  });
}

class UnifiedRetrievalQuery {
  final String queryText;
  final List<double>? semanticEmbedding;
  final UnifiedRetrievalFilters filters;
  final int topK;
  final String? queryId;

  const UnifiedRetrievalQuery({
    required this.queryText,
    this.semanticEmbedding,
    this.filters = const UnifiedRetrievalFilters(),
    this.topK = 20,
    this.queryId,
  });
}

class RetrievalRankingTrace {
  /// Per-lane score contributions, for example:
  /// `{keyword: 0.81, semantic: 0.73, structured: 1.0}`.
  final Map<String, double> laneScores;

  /// Additional scoring terms applied by fusion ranker.
  /// Example keys: `recency`, `source_trust`, `locality_relevance`.
  final Map<String, double> scoreContributions;
  final double finalScore;
  final int rankPosition;

  const RetrievalRankingTrace({
    required this.laneScores,
    required this.scoreContributions,
    required this.finalScore,
    required this.rankPosition,
  });
}

class UnifiedRetrievedItem {
  final String itemId;
  final String itemType;
  final String source;
  final RetrievalTrustTier trustTier;
  final RetrievalRankingTrace rankingTrace;
  final Map<String, Object?> payload;

  const UnifiedRetrievedItem({
    required this.itemId,
    required this.itemType,
    required this.source,
    required this.trustTier,
    required this.rankingTrace,
    this.payload = const {},
  });
}

class UnifiedRetrievalResponse {
  final String? queryId;
  final List<UnifiedRetrievedItem> items;
  final int latencyMs;
  final int requestedTopK;

  const UnifiedRetrievalResponse({
    required this.items,
    required this.latencyMs,
    required this.requestedTopK,
    this.queryId,
  });
}

abstract class UnifiedRetrievalContract {
  Future<UnifiedRetrievalResponse> retrieve(UnifiedRetrievalQuery query);
}

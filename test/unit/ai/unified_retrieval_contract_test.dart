import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('UnifiedRetrievalContract models', () {
    test('captures query text, embedding, and required filters', () {
      final query = UnifiedRetrievalQuery(
        queryText: 'late night jazz',
        semanticEmbedding: const [0.1, 0.4, 0.9],
        filters: UnifiedRetrievalFilters(
          timeWindow: RetrievalTimeWindow(
            startInclusive: DateTime.utc(2026, 2, 20, 20),
            endExclusive: DateTime.utc(2026, 2, 21, 2),
          ),
          geoRadius: const RetrievalGeoRadius(
            centerLat: 37.7749,
            centerLng: -122.4194,
            radiusMeters: 4500,
          ),
          category: 'music',
          platform: RetrievalPlatform.events,
          trustTier: RetrievalTrustTier.medium,
        ),
        topK: 12,
        queryId: 'query-1',
      );

      expect(query.queryText, 'late night jazz');
      expect(query.semanticEmbedding, isNotNull);
      expect(query.filters.timeWindow, isNotNull);
      expect(query.filters.geoRadius, isNotNull);
      expect(query.filters.category, 'music');
      expect(query.filters.platform, RetrievalPlatform.events);
      expect(query.filters.trustTier, RetrievalTrustTier.medium);
      expect(query.topK, 12);
      expect(query.queryId, 'query-1');
    });

    test('captures ranking trace fields for fused retrieval', () {
      const trace = RetrievalRankingTrace(
        laneScores: {
          'keyword': 0.82,
          'semantic': 0.77,
          'structured': 1.0,
        },
        scoreContributions: {
          'recency': 0.08,
          'source_trust': 0.11,
          'locality_relevance': 0.09,
        },
        finalScore: 0.89,
        rankPosition: 1,
      );
      const item = UnifiedRetrievedItem(
        itemId: 'event_42',
        itemType: 'event',
        source: 'local_events_index',
        trustTier: RetrievalTrustTier.high,
        rankingTrace: trace,
      );
      const response = UnifiedRetrievalResponse(
        queryId: 'query-1',
        items: [item],
        latencyMs: 38,
        requestedTopK: 12,
      );

      expect(item.rankingTrace.laneScores['keyword'], 0.82);
      expect(item.rankingTrace.scoreContributions['source_trust'], 0.11);
      expect(item.rankingTrace.finalScore, 0.89);
      expect(response.items.single.itemId, 'event_42');
      expect(response.requestedTopK, 12);
      expect(response.latencyMs, 38);
    });
  });
}

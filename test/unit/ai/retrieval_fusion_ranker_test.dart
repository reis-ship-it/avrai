import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/retrieval_fusion_ranker.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('RetrievalFusionRanker', () {
    test('blends lane scores with recency, trust, and locality contributions',
        () {
      const ranker = RetrievalFusionRanker();
      final now = DateTime.utc(2026, 2, 20, 12);

      final response = ranker.fuse(
        query: UnifiedRetrievalQuery(
          queryText: 'coffee and music nearby',
          topK: 3,
          filters: const UnifiedRetrievalFilters(
            geoRadius: RetrievalGeoRadius(
              centerLat: 37.7749,
              centerLng: -122.4194,
              radiusMeters: 4000,
            ),
          ),
        ),
        keywordItems: [
          _item(
            id: 'balanced',
            trustTier: RetrievalTrustTier.high,
            laneScores: const {'keyword': 3.8},
            payload: {
              'occurs_at':
                  now.subtract(const Duration(hours: 2)).toIso8601String(),
              'lat': 37.7750,
              'lng': -122.4195,
            },
          ),
        ],
        semanticItems: [
          _item(
            id: 'balanced',
            trustTier: RetrievalTrustTier.high,
            laneScores: const {'semantic': 0.9},
          ),
          _item(
            id: 'semantic_only',
            trustTier: RetrievalTrustTier.medium,
            laneScores: const {'semantic': 0.95},
            payload: {
              'occurs_at':
                  now.subtract(const Duration(days: 6)).toIso8601String(),
              'lat': 37.8044,
              'lng': -122.2711,
            },
          ),
        ],
        structuredItems: [
          _item(
            id: 'balanced',
            trustTier: RetrievalTrustTier.high,
            laneScores: const {'structured': 1.0},
          ),
        ],
        now: now,
      );

      expect(response.items.first.itemId, 'balanced');
      final trace = response.items.first.rankingTrace;
      expect(trace.laneScores['keyword'], greaterThan(0.7));
      expect(trace.laneScores['semantic'], greaterThan(0.9));
      expect(trace.laneScores['structured'], 1.0);
      expect(trace.scoreContributions['recency'], greaterThan(0.05));
      expect(trace.scoreContributions['source_trust'], 0.1);
      expect(trace.scoreContributions['locality_relevance'], greaterThan(0.14));
    });

    test('deduplicates by item id and keeps strongest lane-specific score', () {
      const ranker = RetrievalFusionRanker();

      final response = ranker.fuse(
        query: const UnifiedRetrievalQuery(queryText: 'late food', topK: 5),
        keywordItems: [
          _item(
            id: 'same',
            trustTier: RetrievalTrustTier.low,
            laneScores: const {'keyword': 1.2},
          ),
          _item(
            id: 'same',
            trustTier: RetrievalTrustTier.low,
            laneScores: const {'keyword': 2.2},
          ),
        ],
        semanticItems: [
          _item(
            id: 'same',
            trustTier: RetrievalTrustTier.medium,
            laneScores: const {'semantic': 0.8},
          ),
        ],
      );

      expect(response.items, hasLength(1));
      final trace = response.items.single.rankingTrace;
      expect(trace.laneScores['keyword'], closeTo(2.2 / 3.2, 0.0001));
      expect(trace.laneScores['semantic'], closeTo(0.9, 0.0001));
      expect(response.items.single.trustTier, RetrievalTrustTier.medium);
    });

    test('respects topK and sets stable rank positions', () {
      const ranker = RetrievalFusionRanker();

      final response = ranker.fuse(
        query: const UnifiedRetrievalQuery(queryText: 'parks', topK: 2),
        semanticItems: [
          _item(
            id: 'a',
            trustTier: RetrievalTrustTier.high,
            laneScores: const {'semantic': 0.99},
          ),
          _item(
            id: 'b',
            trustTier: RetrievalTrustTier.high,
            laneScores: const {'semantic': 0.8},
          ),
          _item(
            id: 'c',
            trustTier: RetrievalTrustTier.high,
            laneScores: const {'semantic': 0.7},
          ),
        ],
      );

      expect(response.items.map((e) => e.itemId).toList(), ['a', 'b']);
      expect(response.items[0].rankingTrace.rankPosition, 1);
      expect(response.items[1].rankingTrace.rankPosition, 2);
      expect(response.requestedTopK, 2);
    });
  });
}

UnifiedRetrievedItem _item({
  required String id,
  required RetrievalTrustTier trustTier,
  required Map<String, double> laneScores,
  Map<String, Object?> payload = const {},
}) {
  return UnifiedRetrievedItem(
    itemId: id,
    itemType: 'event',
    source: 'test_source',
    trustTier: trustTier,
    payload: payload,
    rankingTrace: RetrievalRankingTrace(
      laneScores: laneScores,
      scoreContributions: const {},
      finalScore: laneScores.values.fold(0.0, (sum, value) => sum + value),
      rankPosition: 1,
    ),
  );
}

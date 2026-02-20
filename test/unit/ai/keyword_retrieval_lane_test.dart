import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/keyword_retrieval_lane.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('KeywordRetrievalLane', () {
    test('ranks exact lexical matches first', () async {
      final lane = KeywordRetrievalLane(
        corpus: _InMemoryKeywordRetrievalCorpus(const [
          KeywordRetrievalDocument(
            id: '1',
            itemType: 'event',
            source: 'events_local',
            text: 'Late night jazz and soul sessions',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
          ),
          KeywordRetrievalDocument(
            id: '2',
            itemType: 'event',
            source: 'events_local',
            text: 'Live indie rock showcase',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
          ),
          KeywordRetrievalDocument(
            id: '3',
            itemType: 'place',
            source: 'places_local',
            text: 'Jazz bar with late dinner options',
            platform: RetrievalPlatform.places,
            trustTier: RetrievalTrustTier.medium,
          ),
        ]),
      );

      final result = await lane.retrieve(
        const UnifiedRetrievalQuery(
          queryText: 'late night jazz',
          topK: 3,
        ),
      );

      expect(result.items, hasLength(2));
      expect(result.items.first.itemId, '1');
      expect(result.items.first.rankingTrace.laneScores['keyword'], isNotNull);
    });

    test('applies time, geo, category, platform, and trust-tier filters',
        () async {
      final lane = KeywordRetrievalLane(
        corpus: _InMemoryKeywordRetrievalCorpus([
          KeywordRetrievalDocument(
            id: 'near',
            itemType: 'event',
            source: 'events_local',
            text: 'Jazz night downtown',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'music',
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
          KeywordRetrievalDocument(
            id: 'far',
            itemType: 'event',
            source: 'events_local',
            text: 'Jazz night far away',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'music',
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 34.0522,
            lng: -118.2437,
          ),
          KeywordRetrievalDocument(
            id: 'wrong-platform',
            itemType: 'place',
            source: 'places_local',
            text: 'Jazz night downtown',
            platform: RetrievalPlatform.places,
            trustTier: RetrievalTrustTier.high,
            category: 'music',
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
        ]),
      );

      final result = await lane.retrieve(
        UnifiedRetrievalQuery(
          queryText: 'jazz night',
          topK: 10,
          filters: UnifiedRetrievalFilters(
            timeWindow: RetrievalTimeWindow(
              startInclusive: DateTime.utc(2026, 2, 20, 20),
              endExclusive: DateTime.utc(2026, 2, 21, 3),
            ),
            geoRadius: const RetrievalGeoRadius(
              centerLat: 37.7749,
              centerLng: -122.4194,
              radiusMeters: 3000,
            ),
            category: 'music',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.medium,
          ),
        ),
      );

      expect(result.items.map((e) => e.itemId).toList(), ['near']);
    });
  });
}

class _InMemoryKeywordRetrievalCorpus implements KeywordRetrievalCorpus {
  final List<KeywordRetrievalDocument> _documents;

  const _InMemoryKeywordRetrievalCorpus(this._documents);

  @override
  Future<List<KeywordRetrievalDocument>> loadDocuments(
    UnifiedRetrievalQuery query,
  ) async {
    return _documents;
  }
}

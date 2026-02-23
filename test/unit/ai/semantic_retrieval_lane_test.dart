import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/semantic_retrieval_lane.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('SemanticRetrievalLane', () {
    test('ranks documents by vector similarity', () async {
      final lane = SemanticRetrievalLane(
        corpus: _InMemorySemanticRetrievalCorpus(const [
          SemanticRetrievalVectorDocument(
            id: 'close',
            itemType: 'event',
            source: 'events_vector',
            embedding: [0.92, 0.08, 0.11],
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
          ),
          SemanticRetrievalVectorDocument(
            id: 'mid',
            itemType: 'event',
            source: 'events_vector',
            embedding: [0.61, 0.32, 0.21],
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
          ),
          SemanticRetrievalVectorDocument(
            id: 'far',
            itemType: 'event',
            source: 'events_vector',
            embedding: [0.04, 0.95, 0.07],
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
          ),
        ]),
      );

      final result = await lane.retrieve(
        const UnifiedRetrievalQuery(
          queryText: 'late night jazz',
          semanticEmbedding: [1.0, 0.0, 0.0],
          topK: 3,
        ),
      );

      expect(
          result.items.map((e) => e.itemId).toList(), ['close', 'mid', 'far']);
      expect(result.items.first.rankingTrace.laneScores['semantic'], isNotNull);
    });

    test('returns empty when semantic embedding is missing', () async {
      final lane = SemanticRetrievalLane(
        corpus: _InMemorySemanticRetrievalCorpus(const [
          SemanticRetrievalVectorDocument(
            id: 'x',
            itemType: 'event',
            source: 'events_vector',
            embedding: [0.5, 0.5],
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.medium,
          ),
        ]),
      );

      final result = await lane.retrieve(
        const UnifiedRetrievalQuery(
          queryText: 'query without embedding',
        ),
      );

      expect(result.items, isEmpty);
    });

    test('applies unified filters before semantic ranking', () async {
      final lane = SemanticRetrievalLane(
        corpus: _InMemorySemanticRetrievalCorpus([
          SemanticRetrievalVectorDocument(
            id: 'eligible',
            itemType: 'event',
            source: 'events_vector',
            embedding: const [0.9, 0.1],
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'music',
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
          SemanticRetrievalVectorDocument(
            id: 'wrong-platform',
            itemType: 'place',
            source: 'places_vector',
            embedding: const [0.95, 0.05],
            platform: RetrievalPlatform.places,
            trustTier: RetrievalTrustTier.high,
            category: 'music',
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
          SemanticRetrievalVectorDocument(
            id: 'far-geo',
            itemType: 'event',
            source: 'events_vector',
            embedding: const [0.95, 0.05],
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'music',
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 34.0522,
            lng: -118.2437,
          ),
        ]),
      );

      final result = await lane.retrieve(
        UnifiedRetrievalQuery(
          queryText: 'jazz tonight',
          semanticEmbedding: const [1.0, 0.0],
          filters: UnifiedRetrievalFilters(
            platform: RetrievalPlatform.events,
            category: 'music',
            trustTier: RetrievalTrustTier.medium,
            timeWindow: RetrievalTimeWindow(
              startInclusive: DateTime.utc(2026, 2, 20, 20),
              endExclusive: DateTime.utc(2026, 2, 21, 3),
            ),
            geoRadius: const RetrievalGeoRadius(
              centerLat: 37.7749,
              centerLng: -122.4194,
              radiusMeters: 3000,
            ),
          ),
          topK: 10,
        ),
      );

      expect(result.items.map((e) => e.itemId).toList(), ['eligible']);
    });
  });
}

class _InMemorySemanticRetrievalCorpus implements SemanticRetrievalCorpus {
  final List<SemanticRetrievalVectorDocument> _documents;

  const _InMemorySemanticRetrievalCorpus(this._documents);

  @override
  Future<List<SemanticRetrievalVectorDocument>> loadDocuments(
    UnifiedRetrievalQuery query,
  ) async {
    return _documents;
  }
}

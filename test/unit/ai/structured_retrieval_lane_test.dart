import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/structured_retrieval_lane.dart';
import 'package:avrai/core/ai/unified_retrieval_contract.dart';

void main() {
  group('StructuredRetrievalLane', () {
    test('filters by open-now, age, and safety hard constraints', () async {
      final lane = StructuredRetrievalLane(
        corpus: _InMemoryStructuredRetrievalCorpus([
          StructuredRetrievalDocument(
            id: 'eligible',
            itemType: 'event',
            source: 'events_structured',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'nightlife',
            isOpenNow: true,
            minimumAgeRequirement: 21,
            safetyEligible: true,
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
          StructuredRetrievalDocument(
            id: 'closed',
            itemType: 'event',
            source: 'events_structured',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'nightlife',
            isOpenNow: false,
            minimumAgeRequirement: 21,
            safetyEligible: true,
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
          StructuredRetrievalDocument(
            id: 'unsafe',
            itemType: 'event',
            source: 'events_structured',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            category: 'nightlife',
            isOpenNow: true,
            minimumAgeRequirement: 21,
            safetyEligible: false,
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
        ]),
      );

      final result = await lane.retrieve(
        UnifiedRetrievalQuery(
          queryText: 'nightlife now',
          topK: 10,
          filters: UnifiedRetrievalFilters(
            platform: RetrievalPlatform.events,
            category: 'nightlife',
            trustTier: RetrievalTrustTier.medium,
            openNowOnly: true,
            userAge: 27,
            safetyEligibleOnly: true,
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
        ),
      );

      expect(result.items.map((e) => e.itemId).toList(), ['eligible']);
    });

    test('enforces geo and time window bounds', () async {
      final lane = StructuredRetrievalLane(
        corpus: _InMemoryStructuredRetrievalCorpus([
          StructuredRetrievalDocument(
            id: 'in-window',
            itemType: 'event',
            source: 'events_structured',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 37.7750,
            lng: -122.4195,
          ),
          StructuredRetrievalDocument(
            id: 'out-window',
            itemType: 'event',
            source: 'events_structured',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            occursAt: DateTime.utc(2026, 2, 21, 10),
            lat: 37.7750,
            lng: -122.4195,
          ),
          StructuredRetrievalDocument(
            id: 'far-away',
            itemType: 'event',
            source: 'events_structured',
            platform: RetrievalPlatform.events,
            trustTier: RetrievalTrustTier.high,
            occursAt: DateTime.utc(2026, 2, 21, 1),
            lat: 34.0522,
            lng: -118.2437,
          ),
        ]),
      );

      final result = await lane.retrieve(
        UnifiedRetrievalQuery(
          queryText: 'events',
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
          ),
          topK: 10,
        ),
      );

      expect(result.items.map((e) => e.itemId).toList(), ['in-window']);
    });
  });
}

class _InMemoryStructuredRetrievalCorpus implements StructuredRetrievalCorpus {
  final List<StructuredRetrievalDocument> _documents;

  const _InMemoryStructuredRetrievalCorpus(this._documents);

  @override
  Future<List<StructuredRetrievalDocument>> loadDocuments(
    UnifiedRetrievalQuery query,
  ) async {
    return _documents;
  }
}

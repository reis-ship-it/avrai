import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/facts_journal_retrieval.dart';
import 'package:avrai/core/ai/memory/journal/facts_journal_schema.dart';

void main() {
  group('FactsJournalDeterministicRetrieval', () {
    const retrieval = FactsJournalDeterministicRetrieval();

    final entries = [
      FactsJournalEntry(
        entryId: '1',
        factKey: 'spot.category',
        factValue: 'jazz',
        source: 'user_feedback',
        confidence: 0.9,
        timestamp: DateTime.utc(2026, 2, 20, 8),
        provenanceId: 'p1',
        metadata: const {'city': 'sf', 'tier': 'high'},
      ),
      FactsJournalEntry(
        entryId: '2',
        factKey: 'spot.category',
        factValue: 'coffee',
        source: 'google_places_sync',
        confidence: 0.8,
        timestamp: DateTime.utc(2026, 2, 20, 9),
        provenanceId: 'p2',
        metadata: const {'city': 'sf', 'tier': 'medium'},
      ),
      FactsJournalEntry(
        entryId: '3',
        factKey: 'business.hours',
        factValue: 'open late for jazz nights',
        source: 'business_profile',
        confidence: 0.7,
        timestamp: DateTime.utc(2026, 2, 20, 10),
        provenanceId: 'p3',
        metadata: const {'city': 'la', 'tier': 'high'},
      ),
    ];

    test('retrieves by keyword with deterministic ranking', () {
      final result = retrieval.retrieve(
        entries: entries,
        query: const FactsJournalRetrievalQuery(keyword: 'jazz', topK: 10),
      );

      expect(result.map((r) => r.entry.entryId).toList(), ['1', '3']);
      expect(result.first.score, greaterThan(result.last.score));
    });

    test('applies metadata filters before scoring', () {
      final result = retrieval.retrieve(
        entries: entries,
        query: const FactsJournalRetrievalQuery(
          keyword: 'spot',
          metadataFilters: {'city': 'sf', 'tier': 'medium'},
          topK: 10,
        ),
      );

      expect(result, hasLength(1));
      expect(result.single.entry.entryId, '2');
    });

    test('supports empty keyword with confidence-based ordering', () {
      final result = retrieval.retrieve(
        entries: entries,
        query: const FactsJournalRetrievalQuery(
          keyword: '',
          metadataFilters: {'city': 'sf'},
          topK: 10,
        ),
      );

      expect(result.map((r) => r.entry.entryId).toList(), ['1', '2']);
    });

    test('respects topK bounds', () {
      final result = retrieval.retrieve(
        entries: entries,
        query: const FactsJournalRetrievalQuery(keyword: 'spot', topK: 1),
      );

      expect(result, hasLength(1));
    });
  });
}

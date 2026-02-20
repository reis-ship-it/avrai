import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/facts_journal_schema.dart';

void main() {
  group('FactsJournalEntry', () {
    test('round-trips json with append-only factual fields', () {
      final entry = FactsJournalEntry(
        entryId: 'fact-1',
        factKey: 'business.hours.friday',
        factValue: '17:00-23:00',
        source: 'google_places_sync',
        confidence: 0.91,
        timestamp: DateTime.utc(2026, 2, 20, 10, 15),
        provenanceId: 'src-places-abc-123',
        metadata: const {'locality': 'sf'},
      );

      final decoded = FactsJournalEntry.fromJson(entry.toJson());

      expect(decoded.entryId, 'fact-1');
      expect(decoded.factKey, 'business.hours.friday');
      expect(decoded.factValue, '17:00-23:00');
      expect(decoded.source, 'google_places_sync');
      expect(decoded.confidence, closeTo(0.91, 0.0001));
      expect(decoded.timestamp, DateTime.utc(2026, 2, 20, 10, 15));
      expect(decoded.provenanceId, 'src-places-abc-123');
      expect(decoded.metadata['locality'], 'sf');
      expect(decoded.isValid, isTrue);
    });

    test('normalizes confidence to [0,1]', () {
      final low = FactsJournalEntry.fromJson({
        'entry_id': 'a',
        'fact_key': 'x',
        'fact_value': 'y',
        'source': 'z',
        'confidence': -2,
        'timestamp': DateTime.utc(2026, 2, 20).toIso8601String(),
        'provenance_id': 'p',
      });
      final high = FactsJournalEntry.fromJson({
        'entry_id': 'b',
        'fact_key': 'x',
        'fact_value': 'y',
        'source': 'z',
        'confidence': 42,
        'timestamp': DateTime.utc(2026, 2, 20).toIso8601String(),
        'provenance_id': 'p',
      });

      expect(low.confidence, 0.0);
      expect(high.confidence, 1.0);
    });

    test('rejects invalid required fields', () {
      final invalid = FactsJournalEntry(
        entryId: '',
        factKey: '',
        factValue: '',
        source: '',
        confidence: 0.5,
        timestamp: DateTime.utc(2026, 2, 20),
        provenanceId: '',
      );

      expect(invalid.isValid, isFalse);
    });
  });

  group('FactsJournalSnapshot', () {
    test('stores schema version and entry list', () {
      final snapshot = FactsJournalSnapshot(
        schemaVersion: '1.0',
        entries: [
          FactsJournalEntry(
            entryId: 'fact-1',
            factKey: 'spot.category',
            factValue: 'jazz',
            source: 'user_feedback',
            confidence: 0.8,
            timestamp: DateTime.utc(2026, 2, 20),
            provenanceId: 'feedback-1',
          ),
        ],
      );

      final decoded = FactsJournalSnapshot.fromJson(snapshot.toJson());

      expect(decoded.schemaVersion, '1.0');
      expect(decoded.entries, hasLength(1));
      expect(decoded.entries.first.factKey, 'spot.category');
    });
  });
}

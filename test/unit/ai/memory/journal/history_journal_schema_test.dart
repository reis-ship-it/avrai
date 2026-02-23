import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/history_journal_schema.dart';

void main() {
  group('HistoryJournalEntry', () {
    test('round-trips hypothesis/experiment/rollout/rollback/outcome records',
        () {
      final entry = HistoryJournalEntry(
        entryId: 'hist-1',
        contractId: 'exp-contract-42',
        eventType: HistoryJournalEventType.rollback,
        summary: 'Rolled back ranker weights after KPI regression.',
        timestamp: DateTime.utc(2026, 2, 20, 22),
        actor: 'autonomous_research_lane',
        metadata: const {
          'rollback_trigger': 'ctr_drop',
          'kpi_delta': -0.08,
        },
      );

      final decoded = HistoryJournalEntry.fromJson(entry.toJson());

      expect(decoded.entryId, 'hist-1');
      expect(decoded.contractId, 'exp-contract-42');
      expect(decoded.eventType, HistoryJournalEventType.rollback);
      expect(decoded.summary, contains('Rolled back'));
      expect(decoded.actor, 'autonomous_research_lane');
      expect(decoded.metadata['rollback_trigger'], 'ctr_drop');
      expect(decoded.isValid, isTrue);
    });

    test('defaults unknown event type to outcome', () {
      final decoded = HistoryJournalEntry.fromJson({
        'entry_id': 'hist-2',
        'contract_id': 'exp-2',
        'event_type': 'unknown_type',
        'summary': 'fallback',
        'timestamp': DateTime.utc(2026, 2, 20).toIso8601String(),
        'actor': 'system',
      });

      expect(decoded.eventType, HistoryJournalEventType.outcome);
    });

    test('rejects missing required fields', () {
      final invalid = HistoryJournalEntry(
        entryId: '',
        contractId: '',
        eventType: HistoryJournalEventType.hypothesis,
        summary: '',
        timestamp: DateTime.utc(2026, 2, 20),
        actor: '',
      );

      expect(invalid.isValid, isFalse);
    });
  });

  group('HistoryJournalSnapshot', () {
    test('preserves schema version and ordered entries', () {
      final snapshot = HistoryJournalSnapshot(
        schemaVersion: '1.0',
        entries: [
          HistoryJournalEntry(
            entryId: 'h1',
            contractId: 'c1',
            eventType: HistoryJournalEventType.hypothesis,
            summary: 'Test hypothesis',
            timestamp: DateTime.utc(2026, 2, 20, 9),
            actor: 'planner',
          ),
        ],
      );

      final decoded = HistoryJournalSnapshot.fromJson(snapshot.toJson());
      expect(decoded.schemaVersion, '1.0');
      expect(decoded.entries, hasLength(1));
      expect(
          decoded.entries.first.eventType, HistoryJournalEventType.hypothesis);
    });
  });
}

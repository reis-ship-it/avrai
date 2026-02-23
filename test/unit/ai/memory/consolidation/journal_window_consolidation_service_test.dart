import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/consolidation/journal_window_consolidation_service.dart';

void main() {
  group('JournalWindowConsolidationService', () {
    const service = JournalWindowConsolidationService(
      recentWindow: Duration(days: 10),
    );

    test('summarizes older non-critical facts and preserves critical facts',
        () {
      final result = service.consolidate(
        windowStart: DateTime.utc(2026, 1, 1),
        windowEnd: DateTime.utc(2026, 2, 20),
        facts: [
          FactsJournalWindowEntry(
            entryId: 'f1',
            factKey: 'spot.category',
            factValue: 'jazz',
            source: 'source_a',
            confidence: 0.8,
            timestamp: DateTime.utc(2026, 1, 10),
            provenanceId: 'p1',
          ),
          FactsJournalWindowEntry(
            entryId: 'f2',
            factKey: 'spot.category',
            factValue: 'live_jazz',
            source: 'source_b',
            confidence: 0.9,
            timestamp: DateTime.utc(2026, 1, 18),
            provenanceId: 'p2',
          ),
          FactsJournalWindowEntry(
            entryId: 'f3',
            factKey: 'safety.advisory',
            factValue: 'always_verify_id',
            source: 'policy',
            confidence: 1.0,
            timestamp: DateTime.utc(2026, 1, 5),
            provenanceId: 'p3',
            metadata: const {'critical_fact': true},
          ),
        ],
        history: const [],
      );

      expect(result.factSummaries, hasLength(1));
      expect(result.factSummaries.single.factKey, 'spot.category');
      expect(result.factSummaries.single.count, 2);
      expect(result.factSummaries.single.latestValue, 'live_jazz');
      expect(result.preservedCriticalFacts.map((e) => e.entryId), ['f3']);
    });

    test('preserves failure signatures and summarizes non-failure history', () {
      final result = service.consolidate(
        windowStart: DateTime.utc(2026, 1, 1),
        windowEnd: DateTime.utc(2026, 2, 20),
        facts: const [],
        history: [
          HistoryJournalWindowEntry(
            entryId: 'h1',
            eventType: 'experiment',
            summary: 'test variant A',
            timestamp: DateTime.utc(2026, 1, 2),
          ),
          HistoryJournalWindowEntry(
            entryId: 'h2',
            eventType: 'rollback_failure',
            summary: 'rolled back due to regression',
            timestamp: DateTime.utc(2026, 1, 3),
            metadata: const {'failure_signature_id': 'sig-7'},
          ),
          HistoryJournalWindowEntry(
            entryId: 'h3',
            eventType: 'experiment',
            summary: 'test variant B',
            timestamp: DateTime.utc(2026, 1, 4),
          ),
        ],
      );

      expect(result.preservedFailureSignatures.map((e) => e.entryId), ['h2']);
      expect(result.historySummaries, hasLength(1));
      expect(result.historySummaries.single.eventType, 'experiment');
      expect(result.historySummaries.single.count, 2);
      expect(result.historySummaries.single.latestSummary, 'test variant B');
    });

    test('does not summarize entries inside recent window', () {
      final result = service.consolidate(
        windowStart: DateTime.utc(2026, 1, 1),
        windowEnd: DateTime.utc(2026, 2, 20),
        facts: [
          FactsJournalWindowEntry(
            entryId: 'f_recent',
            factKey: 'spot.category',
            factValue: 'coffee',
            source: 'source_recent',
            confidence: 0.7,
            timestamp: DateTime.utc(2026, 2, 15),
            provenanceId: 'p_recent',
          ),
        ],
        history: [
          HistoryJournalWindowEntry(
            entryId: 'h_recent',
            eventType: 'experiment',
            summary: 'recent test',
            timestamp: DateTime.utc(2026, 2, 18),
          ),
        ],
      );

      expect(result.factSummaries, isEmpty);
      expect(result.historySummaries, isEmpty);
      expect(result.preservedCriticalFacts, isEmpty);
      expect(result.preservedFailureSignatures, isEmpty);
    });
  });
}

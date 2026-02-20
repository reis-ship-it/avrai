import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/model_lifecycle_history_journal_adapter.dart';

void main() {
  group('ModelLifecycleHistoryJournalAdapter', () {
    test('records deterministic promotion rationale entry', () async {
      final sink = _InMemoryLifecycleSink();
      final adapter = ModelLifecycleHistoryJournalAdapter(historyJournal: sink);

      await adapter.recordDecision(
        ModelLifecycleDecisionRecord(
          modelFamily: 'world_model',
          modelVersion: 'v5.2.11',
          eventType: ModelLifecycleEventType.promotion_rationale,
          rationale: 'Canary uplift +4.8% without safety regressions.',
          decidedAt: DateTime.utc(2026, 2, 20, 12),
          evidence: const {
            'canary_uplift': 0.048,
            'safety_regressions': 0,
          },
        ),
      );

      expect(sink.entries, hasLength(1));
      final entry = sink.entries.single;
      expect(entry['event_type'], 'rollout');
      expect(entry['summary'], contains('Canary uplift'));
      expect((entry['metadata'] as Map)['phase_ref'], '1.1E.6');
      expect((entry['metadata'] as Map)['model_family'], 'world_model');
      expect((entry['metadata'] as Map)['canary_uplift'], 0.048);
    });

    test('records deterministic rollback trigger entry', () async {
      final sink = _InMemoryLifecycleSink();
      final adapter = ModelLifecycleHistoryJournalAdapter(historyJournal: sink);

      await adapter.recordDecision(
        ModelLifecycleDecisionRecord(
          modelFamily: 'reality_model',
          modelVersion: 'v5.2.11',
          eventType: ModelLifecycleEventType.rollback_trigger,
          rationale: 'Rollback due to early-online instability in cohort-3.',
          decidedAt: DateTime.utc(2026, 2, 20, 13),
          evidence: const {
            'handoff_dip': 0.19,
            'cohort': 'cohort-3',
          },
        ),
      );

      final entry = sink.entries.single;
      expect(entry['event_type'], 'rollback');
      expect(entry['summary'],
          contains('Rollback due to early-online instability'));
      expect((entry['metadata'] as Map)['lifecycle_event_type'],
          'rollback_trigger');
      expect((entry['metadata'] as Map)['handoff_dip'], 0.19);
    });
  });
}

class _InMemoryLifecycleSink implements ModelLifecycleHistoryJournalSink {
  final List<Map<String, dynamic>> entries = [];

  @override
  Future<void> writeEntry(Map<String, dynamic> entry) async {
    entries.add(Map<String, dynamic>.from(entry));
  }
}

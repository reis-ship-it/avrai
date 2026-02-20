import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/journal/autonomous_research_history_journal_adapter.dart';

void main() {
  group('AutonomousResearchHistoryJournalAdapter', () {
    test('writes experiment contract and outcome entries to history journal',
        () async {
      final sink = _InMemoryHistoryJournalSink();
      final adapter = AutonomousResearchHistoryJournalAdapter(
        historyJournal: sink,
      );

      await adapter.recordExperiment(
        AutonomousResearchExperimentRecord(
          experimentId: 'exp-01',
          contractId: 'contract-42',
          hypothesis: 'Semi-online bridge reduces handoff dip.',
          methodClass: 'ablation',
          startedAt: DateTime.utc(2026, 2, 20, 1),
          endedAt: DateTime.utc(2026, 2, 20, 3),
          outcomeSummary: 'Bridge policy reduced handoff dip by 11%.',
          adoptionVerdict: 'canary',
          metadata: const {'cohort': 'tier2_city'},
        ),
      );

      expect(sink.entries, hasLength(2));

      final contract = sink.entries.first;
      expect(contract['entry_id'], 'exp-01:contract');
      expect(contract['contract_id'], 'contract-42');
      expect(contract['event_type'], 'experiment');
      expect((contract['summary'] as String), contains('Experiment contract'));
      expect((contract['metadata'] as Map)['method_class'], 'ablation');

      final outcome = sink.entries.last;
      expect(outcome['entry_id'], 'exp-01:outcome');
      expect(outcome['event_type'], 'outcome');
      expect(outcome['summary'], 'Bridge policy reduced handoff dip by 11%.');
      expect((outcome['metadata'] as Map)['adoption_verdict'], 'canary');
      expect((outcome['metadata'] as Map)['cohort'], 'tier2_city');
    });
  });
}

class _InMemoryHistoryJournalSink implements HistoryJournalSink {
  final List<Map<String, dynamic>> entries = [];

  @override
  Future<void> writeEntry(Map<String, dynamic> entry) async {
    entries.add(Map<String, dynamic>.from(entry));
  }
}

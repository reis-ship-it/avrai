abstract class HistoryJournalSink {
  Future<void> writeEntry(Map<String, dynamic> entry);
}

class AutonomousResearchExperimentRecord {
  final String experimentId;
  final String contractId;
  final String hypothesis;
  final String methodClass;
  final DateTime startedAt;
  final DateTime endedAt;
  final String outcomeSummary;
  final String adoptionVerdict;
  final Map<String, Object?> metadata;

  const AutonomousResearchExperimentRecord({
    required this.experimentId,
    required this.contractId,
    required this.hypothesis,
    required this.methodClass,
    required this.startedAt,
    required this.endedAt,
    required this.outcomeSummary,
    required this.adoptionVerdict,
    this.metadata = const {},
  });
}

/// Phase 1.1E.5 adapter: writes autonomous research experiment contracts and
/// outcomes to HistoryJournal.
class AutonomousResearchHistoryJournalAdapter {
  const AutonomousResearchHistoryJournalAdapter({
    required HistoryJournalSink historyJournal,
  }) : _historyJournal = historyJournal;

  final HistoryJournalSink _historyJournal;

  Future<void> recordExperiment(
    AutonomousResearchExperimentRecord record,
  ) async {
    final startedUtc = record.startedAt.toUtc();
    final endedUtc = record.endedAt.toUtc();

    final contractEntry = <String, dynamic>{
      'entry_id': '${record.experimentId}:contract',
      'contract_id': record.contractId,
      'event_type': 'experiment',
      'summary': 'Experiment contract: ${record.hypothesis}',
      'timestamp': startedUtc.toIso8601String(),
      'actor': 'autonomous_research_lane',
      'metadata': {
        'phase_ref': '1.1E.5',
        'experiment_id': record.experimentId,
        'method_class': record.methodClass,
        ...record.metadata,
      },
    };

    final outcomeEntry = <String, dynamic>{
      'entry_id': '${record.experimentId}:outcome',
      'contract_id': record.contractId,
      'event_type': 'outcome',
      'summary': record.outcomeSummary,
      'timestamp': endedUtc.toIso8601String(),
      'actor': 'autonomous_research_lane',
      'metadata': {
        'phase_ref': '1.1E.5',
        'experiment_id': record.experimentId,
        'adoption_verdict': record.adoptionVerdict,
        'method_class': record.methodClass,
        ...record.metadata,
      },
    };

    await _historyJournal.writeEntry(contractEntry);
    await _historyJournal.writeEntry(outcomeEntry);
  }
}

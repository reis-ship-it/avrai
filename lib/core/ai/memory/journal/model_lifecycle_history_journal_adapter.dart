enum ModelLifecycleEventType {
  promotion_rationale,
  rollback_trigger,
}

abstract class ModelLifecycleHistoryJournalSink {
  Future<void> writeEntry(Map<String, dynamic> entry);
}

class ModelLifecycleDecisionRecord {
  final String modelFamily;
  final String modelVersion;
  final ModelLifecycleEventType eventType;
  final String rationale;
  final DateTime decidedAt;
  final Map<String, Object?> evidence;

  const ModelLifecycleDecisionRecord({
    required this.modelFamily,
    required this.modelVersion,
    required this.eventType,
    required this.rationale,
    required this.decidedAt,
    this.evidence = const {},
  });
}

/// Phase 1.1E.6 deterministic lifecycle journaling adapter.
class ModelLifecycleHistoryJournalAdapter {
  const ModelLifecycleHistoryJournalAdapter({
    required ModelLifecycleHistoryJournalSink historyJournal,
  }) : _historyJournal = historyJournal;

  final ModelLifecycleHistoryJournalSink _historyJournal;

  Future<void> recordDecision(ModelLifecycleDecisionRecord record) async {
    final eventType = switch (record.eventType) {
      ModelLifecycleEventType.promotion_rationale => 'rollout',
      ModelLifecycleEventType.rollback_trigger => 'rollback',
    };

    final entry = <String, dynamic>{
      'entry_id':
          '${record.modelFamily}:${record.modelVersion}:${record.eventType.name}',
      'contract_id':
          'model_lifecycle:${record.modelFamily}:${record.modelVersion}',
      'event_type': eventType,
      'summary': record.rationale,
      'timestamp': record.decidedAt.toUtc().toIso8601String(),
      'actor': 'model_lifecycle_manager',
      'metadata': {
        'phase_ref': '1.1E.6',
        'model_family': record.modelFamily,
        'model_version': record.modelVersion,
        'lifecycle_event_type': record.eventType.name,
        ...record.evidence,
      },
    };

    await _historyJournal.writeEntry(entry);
  }
}

enum HistoryJournalEventType {
  hypothesis,
  experiment,
  rollout,
  rollback,
  outcome,
}

class HistoryJournalEntry {
  final String entryId;
  final String contractId;
  final HistoryJournalEventType eventType;
  final String summary;
  final DateTime timestamp;
  final String actor;
  final Map<String, Object?> metadata;

  const HistoryJournalEntry({
    required this.entryId,
    required this.contractId,
    required this.eventType,
    required this.summary,
    required this.timestamp,
    required this.actor,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'contract_id': contractId,
      'event_type': eventType.name,
      'summary': summary,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'actor': actor,
      'metadata': metadata,
    };
  }

  factory HistoryJournalEntry.fromJson(Map<String, dynamic> json) {
    final rawType = json['event_type'] as String?;
    final eventType = HistoryJournalEventType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => HistoryJournalEventType.outcome,
    );

    return HistoryJournalEntry(
      entryId: json['entry_id'] as String? ?? '',
      contractId: json['contract_id'] as String? ?? '',
      eventType: eventType,
      summary: json['summary'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      actor: json['actor'] as String? ?? 'system',
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }

  bool get isValid {
    if (entryId.trim().isEmpty) return false;
    if (contractId.trim().isEmpty) return false;
    if (summary.trim().isEmpty) return false;
    if (actor.trim().isEmpty) return false;
    return true;
  }
}

class HistoryJournalSnapshot {
  final String schemaVersion;
  final List<HistoryJournalEntry> entries;

  const HistoryJournalSnapshot({
    this.schemaVersion = '1.0',
    this.entries = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory HistoryJournalSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as List? ?? const [];
    return HistoryJournalSnapshot(
      schemaVersion: json['schema_version'] as String? ?? '1.0',
      entries: raw
          .whereType<Map>()
          .map(
              (e) => HistoryJournalEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}

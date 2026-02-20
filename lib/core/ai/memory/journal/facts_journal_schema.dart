class FactsJournalEntry {
  final String entryId;
  final String factKey;
  final String factValue;
  final String source;
  final double confidence;
  final DateTime timestamp;
  final String provenanceId;
  final Map<String, Object?> metadata;

  const FactsJournalEntry({
    required this.entryId,
    required this.factKey,
    required this.factValue,
    required this.source,
    required this.confidence,
    required this.timestamp,
    required this.provenanceId,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'fact_key': factKey,
      'fact_value': factValue,
      'source': source,
      'confidence': confidence,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'provenance_id': provenanceId,
      'metadata': metadata,
    };
  }

  factory FactsJournalEntry.fromJson(Map<String, dynamic> json) {
    return FactsJournalEntry(
      entryId: json['entry_id'] as String? ?? '',
      factKey: json['fact_key'] as String? ?? '',
      factValue: json['fact_value'] as String? ?? '',
      source: json['source'] as String? ?? 'unknown',
      confidence:
          _normalizeConfidence((json['confidence'] as num?)?.toDouble()),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      provenanceId: json['provenance_id'] as String? ?? '',
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }

  bool get isValid {
    if (entryId.trim().isEmpty) return false;
    if (factKey.trim().isEmpty) return false;
    if (factValue.trim().isEmpty) return false;
    if (source.trim().isEmpty) return false;
    if (provenanceId.trim().isEmpty) return false;
    if (confidence < 0 || confidence > 1) return false;
    return true;
  }

  static double _normalizeConfidence(double? value) {
    if (value == null || value.isNaN) return 0.0;
    return value.clamp(0, 1).toDouble();
  }
}

class FactsJournalSnapshot {
  final String schemaVersion;
  final List<FactsJournalEntry> entries;

  const FactsJournalSnapshot({
    this.schemaVersion = '1.0',
    this.entries = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'entries': entries.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory FactsJournalSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as List? ?? const [];
    return FactsJournalSnapshot(
      schemaVersion: json['schema_version'] as String? ?? '1.0',
      entries: raw
          .whereType<Map>()
          .map((e) => FactsJournalEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}

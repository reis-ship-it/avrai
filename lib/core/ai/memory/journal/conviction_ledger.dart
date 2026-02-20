class ConvictionLedgerEntry {
  final String entryId;
  final String convictionId;
  final double previousConfidence;
  final double updatedConfidence;
  final List<String> supportingEvidenceIds;
  final List<String> contradictionIds;
  final List<String> delayedValidationWindowIds;
  final DateTime recordedAt;
  final Map<String, Object?> metadata;

  const ConvictionLedgerEntry({
    required this.entryId,
    required this.convictionId,
    required this.previousConfidence,
    required this.updatedConfidence,
    required this.supportingEvidenceIds,
    required this.contradictionIds,
    required this.delayedValidationWindowIds,
    required this.recordedAt,
    this.metadata = const {},
  });

  bool get isValid {
    if (entryId.trim().isEmpty) return false;
    if (convictionId.trim().isEmpty) return false;
    if (previousConfidence < 0 || previousConfidence > 1) return false;
    if (updatedConfidence < 0 || updatedConfidence > 1) return false;
    if (supportingEvidenceIds.isEmpty && contradictionIds.isEmpty) return false;
    if (delayedValidationWindowIds.isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'conviction_id': convictionId,
      'previous_confidence': previousConfidence,
      'updated_confidence': updatedConfidence,
      'supporting_evidence_ids': supportingEvidenceIds,
      'contradiction_ids': contradictionIds,
      'delayed_validation_window_ids': delayedValidationWindowIds,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ConvictionLedgerEntry.fromJson(Map<String, dynamic> json) {
    return ConvictionLedgerEntry(
      entryId: json['entry_id'] as String? ?? '',
      convictionId: json['conviction_id'] as String? ?? '',
      previousConfidence:
          (json['previous_confidence'] as num?)?.toDouble() ?? 0,
      updatedConfidence: (json['updated_confidence'] as num?)?.toDouble() ?? 0,
      supportingEvidenceIds:
          (json['supporting_evidence_ids'] as List? ?? const [])
              .map((e) => '$e')
              .toList(growable: false),
      contradictionIds: (json['contradiction_ids'] as List? ?? const [])
          .map((e) => '$e')
          .toList(growable: false),
      delayedValidationWindowIds:
          (json['delayed_validation_window_ids'] as List? ?? const [])
              .map((e) => '$e')
              .toList(growable: false),
      recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      metadata: Map<String, Object?>.from(
        json['metadata'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}

class ConvictionLedger {
  final List<ConvictionLedgerEntry> _entries = [];

  List<ConvictionLedgerEntry> entries() {
    return List<ConvictionLedgerEntry>.unmodifiable(_entries);
  }

  void append(ConvictionLedgerEntry entry) {
    if (!entry.isValid) {
      throw ArgumentError('Invalid conviction ledger entry');
    }
    _entries.add(entry);
  }

  List<ConvictionLedgerEntry> byConvictionId(String convictionId) {
    final filtered = _entries
        .where((entry) => entry.convictionId == convictionId)
        .toList(growable: false)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtered;
  }
}

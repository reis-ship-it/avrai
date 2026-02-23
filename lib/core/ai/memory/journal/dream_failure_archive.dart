class DreamFailureRecord {
  final String dreamPathId;
  final String failureSignature;
  final Set<String> suppressionTags;
  final DateTime invalidatedAt;
  final String invalidationReason;
  final String? clearedByEvidenceId;

  const DreamFailureRecord({
    required this.dreamPathId,
    required this.failureSignature,
    required this.suppressionTags,
    required this.invalidatedAt,
    required this.invalidationReason,
    this.clearedByEvidenceId,
  });

  bool get isValid {
    if (dreamPathId.trim().isEmpty) return false;
    if (failureSignature.trim().isEmpty) return false;
    if (suppressionTags.isEmpty) return false;
    if (invalidationReason.trim().isEmpty) return false;
    return true;
  }

  bool get isCleared => (clearedByEvidenceId?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'dream_path_id': dreamPathId,
      'failure_signature': failureSignature,
      'suppression_tags': suppressionTags.toList(growable: false)..sort(),
      'invalidated_at': invalidatedAt.toUtc().toIso8601String(),
      'invalidation_reason': invalidationReason,
      'cleared_by_evidence_id': clearedByEvidenceId,
    };
  }

  factory DreamFailureRecord.fromJson(Map<String, dynamic> json) {
    return DreamFailureRecord(
      dreamPathId: json['dream_path_id'] as String? ?? '',
      failureSignature: json['failure_signature'] as String? ?? '',
      suppressionTags: (json['suppression_tags'] as List? ?? const [])
          .map((item) => '$item')
          .toSet(),
      invalidatedAt:
          DateTime.tryParse(json['invalidated_at'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      invalidationReason: json['invalidation_reason'] as String? ?? '',
      clearedByEvidenceId: json['cleared_by_evidence_id'] as String?,
    );
  }
}

class DreamFailureArchive {
  final Map<String, DreamFailureRecord> _byPath =
      <String, DreamFailureRecord>{};

  void archive(DreamFailureRecord record) {
    if (!record.isValid) {
      throw ArgumentError.value(
          record, 'record', 'Invalid dream failure record.');
    }
    _byPath[record.dreamPathId] = record;
  }

  DreamFailureRecord? lookup(String dreamPathId) => _byPath[dreamPathId];

  List<DreamFailureRecord> bySuppressionTag(String tag) {
    final needle = tag.trim();
    return _byPath.values
        .where((record) => record.suppressionTags.contains(needle))
        .toList(growable: false);
  }

  bool isPromotionBlocked(String dreamPathId) {
    final record = _byPath[dreamPathId];
    if (record == null) return false;
    return !record.isCleared;
  }

  void clearSuppression({
    required String dreamPathId,
    required String contradictionClearingEvidenceId,
  }) {
    final record = _byPath[dreamPathId];
    if (record == null) return;
    final evidenceId = contradictionClearingEvidenceId.trim();
    if (evidenceId.isEmpty) {
      throw ArgumentError.value(
        contradictionClearingEvidenceId,
        'contradictionClearingEvidenceId',
        'Clearing evidence id cannot be empty.',
      );
    }
    _byPath[dreamPathId] = DreamFailureRecord(
      dreamPathId: record.dreamPathId,
      failureSignature: record.failureSignature,
      suppressionTags: record.suppressionTags,
      invalidatedAt: record.invalidatedAt,
      invalidationReason: record.invalidationReason,
      clearedByEvidenceId: evidenceId,
    );
  }

  List<DreamFailureRecord> snapshot() {
    final records = _byPath.values.toList(growable: false);
    records.sort((a, b) => a.invalidatedAt.compareTo(b.invalidatedAt));
    return records;
  }
}

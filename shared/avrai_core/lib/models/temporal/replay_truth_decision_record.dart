class ReplayTruthDecisionRecord {
  const ReplayTruthDecisionRecord({
    required this.recordId,
    required this.subjectId,
    required this.subjectType,
    required this.monthKey,
    required this.localityAnchor,
    required this.decisionKind,
    required this.decisionStatus,
    required this.reason,
    required this.sourceRefs,
    this.metadata = const <String, dynamic>{},
  });

  final String recordId;
  final String subjectId;
  final String subjectType;
  final String monthKey;
  final String localityAnchor;
  final String decisionKind;
  final String decisionStatus;
  final String reason;
  final List<String> sourceRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordId': recordId,
      'subjectId': subjectId,
      'subjectType': subjectType,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'decisionKind': decisionKind,
      'decisionStatus': decisionStatus,
      'reason': reason,
      'sourceRefs': sourceRefs,
      'metadata': metadata,
    };
  }

  factory ReplayTruthDecisionRecord.fromJson(Map<String, dynamic> json) {
    return ReplayTruthDecisionRecord(
      recordId: json['recordId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectType: json['subjectType'] as String? ?? 'unknown',
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      decisionKind: json['decisionKind'] as String? ?? '',
      decisionStatus: json['decisionStatus'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

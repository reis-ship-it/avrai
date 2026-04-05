class ReplayHigherAgentInterventionTrace {
  const ReplayHigherAgentInterventionTrace({
    required this.traceId,
    required this.actorId,
    required this.actionRecordId,
    required this.localityAnchor,
    required this.monthKey,
    required this.guidanceState,
    required this.guidanceIds,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  final String traceId;
  final String actorId;
  final String actionRecordId;
  final String localityAnchor;
  final String monthKey;
  final String guidanceState;
  final List<String> guidanceIds;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'traceId': traceId,
      'actorId': actorId,
      'actionRecordId': actionRecordId,
      'localityAnchor': localityAnchor,
      'monthKey': monthKey,
      'guidanceState': guidanceState,
      'guidanceIds': guidanceIds,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayHigherAgentInterventionTrace.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplayHigherAgentInterventionTrace(
      traceId: json['traceId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      actionRecordId: json['actionRecordId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      guidanceState: json['guidanceState'] as String? ?? '',
      guidanceIds: (json['guidanceIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

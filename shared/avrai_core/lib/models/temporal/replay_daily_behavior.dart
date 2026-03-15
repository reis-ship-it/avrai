class ReplayDailyAgenda {
  const ReplayDailyAgenda({
    required this.agendaId,
    required this.actorId,
    required this.localityAnchor,
    required this.weekdayPattern,
    required this.weekendPattern,
    required this.scheduleAnchorIds,
    this.metadata = const <String, dynamic>{},
  });

  final String agendaId;
  final String actorId;
  final String localityAnchor;
  final String weekdayPattern;
  final String weekendPattern;
  final List<String> scheduleAnchorIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agendaId': agendaId,
      'actorId': actorId,
      'localityAnchor': localityAnchor,
      'weekdayPattern': weekdayPattern,
      'weekendPattern': weekendPattern,
      'scheduleAnchorIds': scheduleAnchorIds,
      'metadata': metadata,
    };
  }

  factory ReplayDailyAgenda.fromJson(Map<String, dynamic> json) {
    return ReplayDailyAgenda(
      agendaId: json['agendaId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      weekdayPattern: json['weekdayPattern'] as String? ?? 'routine',
      weekendPattern: json['weekendPattern'] as String? ?? 'social',
      scheduleAnchorIds: (json['scheduleAnchorIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayDestinationChoice {
  const ReplayDestinationChoice({
    required this.entityId,
    required this.entityType,
    required this.localityAnchor,
    required this.reason,
    required this.sourceRefs,
    this.metadata = const <String, dynamic>{},
  });

  final String entityId;
  final String entityType;
  final String localityAnchor;
  final String reason;
  final List<String> sourceRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entityId': entityId,
      'entityType': entityType,
      'localityAnchor': localityAnchor,
      'reason': reason,
      'sourceRefs': sourceRefs,
      'metadata': metadata,
    };
  }

  factory ReplayDestinationChoice.fromJson(Map<String, dynamic> json) {
    return ReplayDestinationChoice(
      entityId: json['entityId'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'unknown',
      localityAnchor: json['localityAnchor'] as String? ?? '',
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

class ReplayAttendanceDecision {
  const ReplayAttendanceDecision({
    required this.decisionId,
    required this.actorId,
    required this.eventId,
    required this.status,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  final String decisionId;
  final String actorId;
  final String eventId;
  final String status;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'decisionId': decisionId,
      'actorId': actorId,
      'eventId': eventId,
      'status': status,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayAttendanceDecision.fromJson(Map<String, dynamic> json) {
    return ReplayAttendanceDecision(
      decisionId: json['decisionId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      status: json['status'] as String? ?? 'deferred',
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayClosureOverrideRecord {
  const ReplayClosureOverrideRecord({
    required this.recordId,
    required this.entityId,
    required this.status,
    required this.reason,
    required this.sourceRefs,
    this.metadata = const <String, dynamic>{},
  });

  final String recordId;
  final String entityId;
  final String status;
  final String reason;
  final List<String> sourceRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordId': recordId,
      'entityId': entityId,
      'status': status,
      'reason': reason,
      'sourceRefs': sourceRefs,
      'metadata': metadata,
    };
  }

  factory ReplayClosureOverrideRecord.fromJson(Map<String, dynamic> json) {
    return ReplayClosureOverrideRecord(
      recordId: json['recordId'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
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

class ReplayActorAction {
  const ReplayActorAction({
    required this.actionId,
    required this.actorId,
    required this.monthKey,
    required this.actionType,
    required this.localityAnchor,
    required this.destinationChoice,
    required this.attendanceDecision,
    required this.kernelLanes,
    required this.guidedByAgentIds,
    required this.status,
    this.metadata = const <String, dynamic>{},
  });

  final String actionId;
  final String actorId;
  final String monthKey;
  final String actionType;
  final String localityAnchor;
  final ReplayDestinationChoice destinationChoice;
  final ReplayAttendanceDecision attendanceDecision;
  final List<String> kernelLanes;
  final List<String> guidedByAgentIds;
  final String status;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actionId': actionId,
      'actorId': actorId,
      'monthKey': monthKey,
      'actionType': actionType,
      'localityAnchor': localityAnchor,
      'destinationChoice': destinationChoice.toJson(),
      'attendanceDecision': attendanceDecision.toJson(),
      'kernelLanes': kernelLanes,
      'guidedByAgentIds': guidedByAgentIds,
      'status': status,
      'metadata': metadata,
    };
  }

  factory ReplayActorAction.fromJson(Map<String, dynamic> json) {
    return ReplayActorAction(
      actionId: json['actionId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      actionType: json['actionType'] as String? ?? 'routine_visit',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      destinationChoice: ReplayDestinationChoice.fromJson(
        Map<String, dynamic>.from(
          json['destinationChoice'] as Map? ?? const {},
        ),
      ),
      attendanceDecision: ReplayAttendanceDecision.fromJson(
        Map<String, dynamic>.from(
          json['attendanceDecision'] as Map? ?? const {},
        ),
      ),
      kernelLanes: (json['kernelLanes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      guidedByAgentIds: (json['guidedByAgentIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      status: json['status'] as String? ?? 'scheduled',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayDailyBehaviorBatch {
  const ReplayDailyBehaviorBatch({
    required this.environmentId,
    required this.replayYear,
    required this.agendas,
    required this.actions,
    required this.closureOverrides,
    required this.actionCountsByType,
    required this.actionCountsByLocality,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final List<ReplayDailyAgenda> agendas;
  final List<ReplayActorAction> actions;
  final List<ReplayClosureOverrideRecord> closureOverrides;
  final Map<String, int> actionCountsByType;
  final Map<String, int> actionCountsByLocality;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'agendas': agendas.map((entry) => entry.toJson()).toList(),
      'actions': actions.map((entry) => entry.toJson()).toList(),
      'closureOverrides':
          closureOverrides.map((entry) => entry.toJson()).toList(),
      'actionCountsByType': actionCountsByType,
      'actionCountsByLocality': actionCountsByLocality,
      'metadata': metadata,
    };
  }

  factory ReplayDailyBehaviorBatch.fromJson(Map<String, dynamic> json) {
    Map<String, int> readCounts(Object? raw) {
      return (raw as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{};
    }

    return ReplayDailyBehaviorBatch(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      agendas: (json['agendas'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayDailyAgenda.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayDailyAgenda>[],
      actions: (json['actions'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayActorAction.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayActorAction>[],
      closureOverrides: (json['closureOverrides'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayClosureOverrideRecord.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayClosureOverrideRecord>[],
      actionCountsByType: readCounts(json['actionCountsByType']),
      actionCountsByLocality: readCounts(json['actionCountsByLocality']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

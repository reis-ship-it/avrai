import 'package:avrai_core/models/temporal/replay_connectivity_profile.dart';

enum ReplayExchangeThreadKind {
  personalAgent,
  admin,
  matchedDirect,
  club,
  community,
  event,
  announcement,
}

class ReplayExchangeThread {
  const ReplayExchangeThread({
    required this.threadId,
    required this.kind,
    required this.localityAnchor,
    required this.associatedEntityId,
    required this.participantActorIds,
    this.metadata = const <String, dynamic>{},
  });

  final String threadId;
  final ReplayExchangeThreadKind kind;
  final String localityAnchor;
  final String? associatedEntityId;
  final List<String> participantActorIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'threadId': threadId,
      'kind': kind.name,
      'localityAnchor': localityAnchor,
      'associatedEntityId': associatedEntityId,
      'participantActorIds': participantActorIds,
      'metadata': metadata,
    };
  }

  factory ReplayExchangeThread.fromJson(Map<String, dynamic> json) {
    return ReplayExchangeThread(
      threadId: json['threadId'] as String? ?? '',
      kind: ReplayExchangeThreadKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => ReplayExchangeThreadKind.community,
      ),
      localityAnchor: json['localityAnchor'] as String? ?? '',
      associatedEntityId: json['associatedEntityId'] as String?,
      participantActorIds: (json['participantActorIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayExchangeParticipation {
  const ReplayExchangeParticipation({
    required this.actorId,
    required this.threadId,
    required this.participationState,
    required this.accessGranted,
    required this.messageCount,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String threadId;
  final String participationState;
  final bool accessGranted;
  final int messageCount;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'threadId': threadId,
      'participationState': participationState,
      'accessGranted': accessGranted,
      'messageCount': messageCount,
      'metadata': metadata,
    };
  }

  factory ReplayExchangeParticipation.fromJson(Map<String, dynamic> json) {
    return ReplayExchangeParticipation(
      actorId: json['actorId'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      participationState: json['participationState'] as String? ?? 'inactive',
      accessGranted: json['accessGranted'] as bool? ?? false,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayExchangeEvent {
  const ReplayExchangeEvent({
    required this.eventId,
    required this.threadId,
    required this.kind,
    required this.monthKey,
    required this.localityAnchor,
    required this.senderActorId,
    required this.recipientActorIds,
    required this.interactionType,
    required this.connectivityReceipt,
    required this.activatedKernelIds,
    required this.higherAgentGuidanceIds,
    this.metadata = const <String, dynamic>{},
  });

  final String eventId;
  final String threadId;
  final ReplayExchangeThreadKind kind;
  final String monthKey;
  final String localityAnchor;
  final String senderActorId;
  final List<String> recipientActorIds;
  final String interactionType;
  final ReplayConnectivityReceipt connectivityReceipt;
  final List<String> activatedKernelIds;
  final List<String> higherAgentGuidanceIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'threadId': threadId,
      'kind': kind.name,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'senderActorId': senderActorId,
      'recipientActorIds': recipientActorIds,
      'interactionType': interactionType,
      'connectivityReceipt': connectivityReceipt.toJson(),
      'activatedKernelIds': activatedKernelIds,
      'higherAgentGuidanceIds': higherAgentGuidanceIds,
      'metadata': metadata,
    };
  }

  factory ReplayExchangeEvent.fromJson(Map<String, dynamic> json) {
    return ReplayExchangeEvent(
      eventId: json['eventId'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      kind: ReplayExchangeThreadKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => ReplayExchangeThreadKind.community,
      ),
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      senderActorId: json['senderActorId'] as String? ?? '',
      recipientActorIds: (json['recipientActorIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      interactionType: json['interactionType'] as String? ?? 'message',
      connectivityReceipt: ReplayConnectivityReceipt.fromJson(
        Map<String, dynamic>.from(
          json['connectivityReceipt'] as Map? ?? const {},
        ),
      ),
      activatedKernelIds: (json['activatedKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      higherAgentGuidanceIds: (json['higherAgentGuidanceIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayAi2AiExchangeRecord {
  const ReplayAi2AiExchangeRecord({
    required this.recordId,
    required this.actorId,
    required this.threadId,
    required this.monthKey,
    required this.localityAnchor,
    required this.routeMode,
    required this.status,
    required this.queuedOffline,
    this.metadata = const <String, dynamic>{},
  });

  final String recordId;
  final String actorId;
  final String threadId;
  final String monthKey;
  final String localityAnchor;
  final ReplayConnectivityMode routeMode;
  final String status;
  final bool queuedOffline;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordId': recordId,
      'actorId': actorId,
      'threadId': threadId,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'routeMode': routeMode.name,
      'status': status,
      'queuedOffline': queuedOffline,
      'metadata': metadata,
    };
  }

  factory ReplayAi2AiExchangeRecord.fromJson(Map<String, dynamic> json) {
    return ReplayAi2AiExchangeRecord(
      recordId: json['recordId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      threadId: json['threadId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      routeMode: ReplayConnectivityMode.values.firstWhere(
        (value) => value.name == json['routeMode'],
        orElse: () => ReplayConnectivityMode.offline,
      ),
      status: json['status'] as String? ?? 'queued',
      queuedOffline: json['queuedOffline'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayExchangeSummary {
  const ReplayExchangeSummary({
    required this.environmentId,
    required this.replayYear,
    required this.totalThreads,
    required this.totalExchangeEvents,
    required this.totalAi2AiRecords,
    required this.threadCountsByKind,
    required this.eventCountsByKind,
    required this.actorsWithAnyExchange,
    required this.actorsWithPersonalAiThreads,
    required this.actorsWithAdminSupport,
    required this.actorsWithGroupThreads,
    required this.offlineQueuedExchangeCount,
    required this.connectivityModeCounts,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final int totalThreads;
  final int totalExchangeEvents;
  final int totalAi2AiRecords;
  final Map<String, int> threadCountsByKind;
  final Map<String, int> eventCountsByKind;
  final int actorsWithAnyExchange;
  final int actorsWithPersonalAiThreads;
  final int actorsWithAdminSupport;
  final int actorsWithGroupThreads;
  final int offlineQueuedExchangeCount;
  final Map<String, int> connectivityModeCounts;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'totalThreads': totalThreads,
      'totalExchangeEvents': totalExchangeEvents,
      'totalAi2AiRecords': totalAi2AiRecords,
      'threadCountsByKind': threadCountsByKind,
      'eventCountsByKind': eventCountsByKind,
      'actorsWithAnyExchange': actorsWithAnyExchange,
      'actorsWithPersonalAiThreads': actorsWithPersonalAiThreads,
      'actorsWithAdminSupport': actorsWithAdminSupport,
      'actorsWithGroupThreads': actorsWithGroupThreads,
      'offlineQueuedExchangeCount': offlineQueuedExchangeCount,
      'connectivityModeCounts': connectivityModeCounts,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayExchangeSummary.fromJson(Map<String, dynamic> json) {
    Map<String, int> readCounts(Object? raw) {
      return (raw as Map?)
              ?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
          const <String, int>{};
    }

    return ReplayExchangeSummary(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      totalThreads: (json['totalThreads'] as num?)?.toInt() ?? 0,
      totalExchangeEvents: (json['totalExchangeEvents'] as num?)?.toInt() ?? 0,
      totalAi2AiRecords: (json['totalAi2AiRecords'] as num?)?.toInt() ?? 0,
      threadCountsByKind: readCounts(json['threadCountsByKind']),
      eventCountsByKind: readCounts(json['eventCountsByKind']),
      actorsWithAnyExchange:
          (json['actorsWithAnyExchange'] as num?)?.toInt() ?? 0,
      actorsWithPersonalAiThreads:
          (json['actorsWithPersonalAiThreads'] as num?)?.toInt() ?? 0,
      actorsWithAdminSupport:
          (json['actorsWithAdminSupport'] as num?)?.toInt() ?? 0,
      actorsWithGroupThreads:
          (json['actorsWithGroupThreads'] as num?)?.toInt() ?? 0,
      offlineQueuedExchangeCount:
          (json['offlineQueuedExchangeCount'] as num?)?.toInt() ?? 0,
      connectivityModeCounts: readCounts(json['connectivityModeCounts']),
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

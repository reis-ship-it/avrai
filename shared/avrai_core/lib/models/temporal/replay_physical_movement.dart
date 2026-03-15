enum ReplayLocationTrackingState {
  tracked,
  untracked,
}

enum ReplayMovementMode {
  stayPut,
  walk,
  drive,
  transit,
  rideshare,
  bleMesh,
  flight,
  offGraph,
}

class ReplayTrackedLocationRecord {
  const ReplayTrackedLocationRecord({
    required this.locationRecordId,
    required this.actorId,
    required this.monthKey,
    required this.localityAnchor,
    required this.trackingState,
    required this.locationKind,
    required this.physicalRef,
    this.entityId,
    this.entityType,
    this.placeNodeId,
    this.reason = '',
    this.metadata = const <String, dynamic>{},
  });

  final String locationRecordId;
  final String actorId;
  final String monthKey;
  final String localityAnchor;
  final ReplayLocationTrackingState trackingState;
  final String locationKind;
  final String physicalRef;
  final String? entityId;
  final String? entityType;
  final String? placeNodeId;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'locationRecordId': locationRecordId,
      'actorId': actorId,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'trackingState': trackingState.name,
      'locationKind': locationKind,
      'physicalRef': physicalRef,
      'entityId': entityId,
      'entityType': entityType,
      'placeNodeId': placeNodeId,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayTrackedLocationRecord.fromJson(Map<String, dynamic> json) {
    return ReplayTrackedLocationRecord(
      locationRecordId: json['locationRecordId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      trackingState: ReplayLocationTrackingState.values.firstWhere(
        (value) => value.name == json['trackingState'],
        orElse: () => ReplayLocationTrackingState.tracked,
      ),
      locationKind: json['locationKind'] as String? ?? 'tracked_place',
      physicalRef: json['physicalRef'] as String? ?? '',
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      placeNodeId: json['placeNodeId'] as String?,
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayUntrackedLocationWindow {
  const ReplayUntrackedLocationWindow({
    required this.windowId,
    required this.actorId,
    required this.monthKey,
    required this.localityAnchor,
    required this.windowLabel,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  final String windowId;
  final String actorId;
  final String monthKey;
  final String localityAnchor;
  final String windowLabel;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'windowId': windowId,
      'actorId': actorId,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'windowLabel': windowLabel,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayUntrackedLocationWindow.fromJson(Map<String, dynamic> json) {
    return ReplayUntrackedLocationWindow(
      windowId: json['windowId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      windowLabel: json['windowLabel'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayMovementRecord {
  const ReplayMovementRecord({
    required this.movementId,
    required this.actorId,
    required this.monthKey,
    required this.originPhysicalRef,
    required this.destinationPhysicalRef,
    required this.originLocalityAnchor,
    required this.destinationLocalityAnchor,
    required this.mode,
    required this.tracked,
    this.sourceActionId,
    this.metadata = const <String, dynamic>{},
  });

  final String movementId;
  final String actorId;
  final String monthKey;
  final String originPhysicalRef;
  final String destinationPhysicalRef;
  final String originLocalityAnchor;
  final String destinationLocalityAnchor;
  final ReplayMovementMode mode;
  final bool tracked;
  final String? sourceActionId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'movementId': movementId,
      'actorId': actorId,
      'monthKey': monthKey,
      'originPhysicalRef': originPhysicalRef,
      'destinationPhysicalRef': destinationPhysicalRef,
      'originLocalityAnchor': originLocalityAnchor,
      'destinationLocalityAnchor': destinationLocalityAnchor,
      'mode': mode.name,
      'tracked': tracked,
      'sourceActionId': sourceActionId,
      'metadata': metadata,
    };
  }

  factory ReplayMovementRecord.fromJson(Map<String, dynamic> json) {
    return ReplayMovementRecord(
      movementId: json['movementId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      originPhysicalRef: json['originPhysicalRef'] as String? ?? '',
      destinationPhysicalRef: json['destinationPhysicalRef'] as String? ?? '',
      originLocalityAnchor: json['originLocalityAnchor'] as String? ?? '',
      destinationLocalityAnchor:
          json['destinationLocalityAnchor'] as String? ?? '',
      mode: ReplayMovementMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => ReplayMovementMode.offGraph,
      ),
      tracked: json['tracked'] as bool? ?? false,
      sourceActionId: json['sourceActionId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayFlightRecord {
  const ReplayFlightRecord({
    required this.flightId,
    required this.actorId,
    required this.monthKey,
    required this.airportNodeId,
    required this.airportPhysicalRef,
    required this.destinationRegion,
    required this.reason,
    this.sourceActionId,
    this.metadata = const <String, dynamic>{},
  });

  final String flightId;
  final String actorId;
  final String monthKey;
  final String airportNodeId;
  final String airportPhysicalRef;
  final String destinationRegion;
  final String reason;
  final String? sourceActionId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'flightId': flightId,
      'actorId': actorId,
      'monthKey': monthKey,
      'airportNodeId': airportNodeId,
      'airportPhysicalRef': airportPhysicalRef,
      'destinationRegion': destinationRegion,
      'reason': reason,
      'sourceActionId': sourceActionId,
      'metadata': metadata,
    };
  }

  factory ReplayFlightRecord.fromJson(Map<String, dynamic> json) {
    return ReplayFlightRecord(
      flightId: json['flightId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      airportNodeId: json['airportNodeId'] as String? ?? '',
      airportPhysicalRef: json['airportPhysicalRef'] as String? ?? '',
      destinationRegion: json['destinationRegion'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      sourceActionId: json['sourceActionId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayPhysicalMovementReport {
  const ReplayPhysicalMovementReport({
    required this.environmentId,
    required this.replayYear,
    required this.trackedLocations,
    required this.untrackedWindows,
    required this.movements,
    required this.flights,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final List<ReplayTrackedLocationRecord> trackedLocations;
  final List<ReplayUntrackedLocationWindow> untrackedWindows;
  final List<ReplayMovementRecord> movements;
  final List<ReplayFlightRecord> flights;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'trackedLocations': trackedLocations.map((entry) => entry.toJson()).toList(),
      'untrackedWindows':
          untrackedWindows.map((entry) => entry.toJson()).toList(),
      'movements': movements.map((entry) => entry.toJson()).toList(),
      'flights': flights.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayPhysicalMovementReport.fromJson(Map<String, dynamic> json) {
    return ReplayPhysicalMovementReport(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      trackedLocations: (json['trackedLocations'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayTrackedLocationRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayTrackedLocationRecord>[],
      untrackedWindows: (json['untrackedWindows'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayUntrackedLocationWindow.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayUntrackedLocationWindow>[],
      movements: (json['movements'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayMovementRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayMovementRecord>[],
      flights: (json['flights'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayFlightRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayFlightRecord>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

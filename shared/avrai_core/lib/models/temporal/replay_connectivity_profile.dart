enum ReplayConnectivityMode {
  wifi,
  cellular,
  offline,
  ble,
  mixed,
}

enum ReplayBatteryPressureBand {
  low,
  moderate,
  high,
}

class ReplayDeviceProfile {
  const ReplayDeviceProfile({
    required this.actorId,
    required this.deviceClass,
    required this.wifiEnabled,
    required this.cellularEnabled,
    required this.bleAvailable,
    required this.backgroundSensingEnabled,
    required this.offlinePreference,
    required this.batteryPressureBand,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String deviceClass;
  final bool wifiEnabled;
  final bool cellularEnabled;
  final bool bleAvailable;
  final bool backgroundSensingEnabled;
  final bool offlinePreference;
  final ReplayBatteryPressureBand batteryPressureBand;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'deviceClass': deviceClass,
      'wifiEnabled': wifiEnabled,
      'cellularEnabled': cellularEnabled,
      'bleAvailable': bleAvailable,
      'backgroundSensingEnabled': backgroundSensingEnabled,
      'offlinePreference': offlinePreference,
      'batteryPressureBand': batteryPressureBand.name,
      'metadata': metadata,
    };
  }

  factory ReplayDeviceProfile.fromJson(Map<String, dynamic> json) {
    return ReplayDeviceProfile(
      actorId: json['actorId'] as String? ?? '',
      deviceClass: json['deviceClass'] as String? ?? 'phone',
      wifiEnabled: json['wifiEnabled'] as bool? ?? true,
      cellularEnabled: json['cellularEnabled'] as bool? ?? true,
      bleAvailable: json['bleAvailable'] as bool? ?? true,
      backgroundSensingEnabled:
          json['backgroundSensingEnabled'] as bool? ?? true,
      offlinePreference: json['offlinePreference'] as bool? ?? false,
      batteryPressureBand: ReplayBatteryPressureBand.values.firstWhere(
        (value) => value.name == json['batteryPressureBand'],
        orElse: () => ReplayBatteryPressureBand.moderate,
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayConnectivityStateTransition {
  const ReplayConnectivityStateTransition({
    required this.transitionId,
    required this.actorId,
    required this.scheduleSurface,
    required this.windowLabel,
    required this.localityAnchor,
    required this.mode,
    required this.reachable,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  final String transitionId;
  final String actorId;
  final String scheduleSurface;
  final String windowLabel;
  final String localityAnchor;
  final ReplayConnectivityMode mode;
  final bool reachable;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transitionId': transitionId,
      'actorId': actorId,
      'scheduleSurface': scheduleSurface,
      'windowLabel': windowLabel,
      'localityAnchor': localityAnchor,
      'mode': mode.name,
      'reachable': reachable,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayConnectivityStateTransition.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplayConnectivityStateTransition(
      transitionId: json['transitionId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      scheduleSurface: json['scheduleSurface'] as String? ?? 'routine',
      windowLabel: json['windowLabel'] as String? ?? 'unknown',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      mode: ReplayConnectivityMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => ReplayConnectivityMode.offline,
      ),
      reachable: json['reachable'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayConnectivityProfile {
  const ReplayConnectivityProfile({
    required this.actorId,
    required this.localityAnchor,
    required this.dominantMode,
    required this.deviceProfile,
    required this.transitions,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String localityAnchor;
  final ReplayConnectivityMode dominantMode;
  final ReplayDeviceProfile deviceProfile;
  final List<ReplayConnectivityStateTransition> transitions;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'localityAnchor': localityAnchor,
      'dominantMode': dominantMode.name,
      'deviceProfile': deviceProfile.toJson(),
      'transitions': transitions.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayConnectivityProfile.fromJson(Map<String, dynamic> json) {
    return ReplayConnectivityProfile(
      actorId: json['actorId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      dominantMode: ReplayConnectivityMode.values.firstWhere(
        (value) => value.name == json['dominantMode'],
        orElse: () => ReplayConnectivityMode.offline,
      ),
      deviceProfile: ReplayDeviceProfile.fromJson(
        Map<String, dynamic>.from(json['deviceProfile'] as Map? ?? const {}),
      ),
      transitions: (json['transitions'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayConnectivityStateTransition.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayConnectivityStateTransition>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayConnectivityReceipt {
  const ReplayConnectivityReceipt({
    required this.receiptId,
    required this.actorId,
    required this.preferredMode,
    required this.actualMode,
    required this.reachable,
    required this.queuedOffline,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  final String receiptId;
  final String actorId;
  final ReplayConnectivityMode preferredMode;
  final ReplayConnectivityMode actualMode;
  final bool reachable;
  final bool queuedOffline;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiptId': receiptId,
      'actorId': actorId,
      'preferredMode': preferredMode.name,
      'actualMode': actualMode.name,
      'reachable': reachable,
      'queuedOffline': queuedOffline,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayConnectivityReceipt.fromJson(Map<String, dynamic> json) {
    return ReplayConnectivityReceipt(
      receiptId: json['receiptId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      preferredMode: ReplayConnectivityMode.values.firstWhere(
        (value) => value.name == json['preferredMode'],
        orElse: () => ReplayConnectivityMode.offline,
      ),
      actualMode: ReplayConnectivityMode.values.firstWhere(
        (value) => value.name == json['actualMode'],
        orElse: () => ReplayConnectivityMode.offline,
      ),
      reachable: json['reachable'] as bool? ?? false,
      queuedOffline: json['queuedOffline'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

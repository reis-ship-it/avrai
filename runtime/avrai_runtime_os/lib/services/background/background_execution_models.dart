enum BackgroundWakeReason {
  bootCompleted,
  backgroundTaskWindow,
  connectivityWifi,
  bleEncounter,
  trustedAnnounceRefresh,
  significantLocation,
  segmentRefreshWindow,
}

extension BackgroundWakeReasonWireFormat on BackgroundWakeReason {
  String get wireName => switch (this) {
        BackgroundWakeReason.bootCompleted => 'boot_completed',
        BackgroundWakeReason.backgroundTaskWindow => 'background_task_window',
        BackgroundWakeReason.connectivityWifi => 'connectivity_wifi',
        BackgroundWakeReason.bleEncounter => 'ble_encounter',
        BackgroundWakeReason.trustedAnnounceRefresh =>
          'trusted_announce_refresh',
        BackgroundWakeReason.significantLocation => 'significant_location',
        BackgroundWakeReason.segmentRefreshWindow => 'segment_refresh_window',
      };

  static BackgroundWakeReason? fromWireName(String value) {
    return switch (value) {
      'boot_completed' => BackgroundWakeReason.bootCompleted,
      'background_task_window' => BackgroundWakeReason.backgroundTaskWindow,
      'connectivity_wifi' => BackgroundWakeReason.connectivityWifi,
      'ble_encounter' => BackgroundWakeReason.bleEncounter,
      'trusted_announce_refresh' => BackgroundWakeReason.trustedAnnounceRefresh,
      'significant_location' => BackgroundWakeReason.significantLocation,
      'segment_refresh_window' => BackgroundWakeReason.segmentRefreshWindow,
      _ => null,
    };
  }
}

class BackgroundWakeInvocationPayload {
  const BackgroundWakeInvocationPayload({
    required this.reason,
    required this.platformSource,
    required this.wakeTimestampUtc,
    this.isWifiAvailable,
    this.isIdle,
  });

  final BackgroundWakeReason reason;
  final String platformSource;
  final DateTime wakeTimestampUtc;
  final bool? isWifiAvailable;
  final bool? isIdle;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reason': reason.wireName,
        'platform_source': platformSource,
        'wake_timestamp_utc': wakeTimestampUtc.toUtc().toIso8601String(),
        if (isWifiAvailable != null) 'is_wifi_available': isWifiAvailable,
        if (isIdle != null) 'is_idle': isIdle,
      };

  factory BackgroundWakeInvocationPayload.fromJson(Map<String, dynamic> json) {
    final reason = BackgroundWakeReasonWireFormat.fromWireName(
      json['reason'] as String? ?? '',
    );
    if (reason == null) {
      throw ArgumentError.value(
        json['reason'],
        'reason',
        'Unsupported background wake reason',
      );
    }
    return BackgroundWakeInvocationPayload(
      reason: reason,
      platformSource: json['platform_source'] as String? ?? 'unknown',
      wakeTimestampUtc:
          DateTime.tryParse(json['wake_timestamp_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isWifiAvailable: json['is_wifi_available'] as bool?,
      isIdle: json['is_idle'] as bool?,
    );
  }
}

class BackgroundCapabilitySnapshot {
  const BackgroundCapabilitySnapshot({
    required this.observedAtUtc,
    required this.wakeReason,
    required this.privacyMode,
    required this.isWifiAvailable,
    required this.isIdle,
    required this.reticulumTransportControlPlaneEnabled,
    required this.trustedMeshAnnounceEnforcementEnabled,
  });

  final DateTime observedAtUtc;
  final BackgroundWakeReason wakeReason;
  final String privacyMode;
  final bool isWifiAvailable;
  final bool isIdle;
  final bool reticulumTransportControlPlaneEnabled;
  final bool trustedMeshAnnounceEnforcementEnabled;
}

class BackgroundWakeExecutionRunRecord {
  const BackgroundWakeExecutionRunRecord({
    required this.reason,
    required this.platformSource,
    required this.wakeTimestampUtc,
    required this.startedAtUtc,
    required this.completedAtUtc,
    required this.bootstrapSuccess,
    required this.meshDueReplayCount,
    required this.meshRecoveredReplayCount,
    required this.meshDiscoveredPeerCount,
    required this.ai2aiReleasedCount,
    required this.ai2aiBlockedCount,
    required this.ai2aiTrustedRouteUnavailableBlockCount,
    required this.passiveIngestedDwellEventCount,
    required this.ambientCandidateObservationDeltaCount,
    required this.ambientConfirmedPromotionDeltaCount,
    required this.segmentRefreshCount,
    this.failureSummary,
  });

  final BackgroundWakeReason reason;
  final String platformSource;
  final DateTime wakeTimestampUtc;
  final DateTime startedAtUtc;
  final DateTime completedAtUtc;
  final bool bootstrapSuccess;
  final int meshDueReplayCount;
  final int meshRecoveredReplayCount;
  final int meshDiscoveredPeerCount;
  final int ai2aiReleasedCount;
  final int ai2aiBlockedCount;
  final int ai2aiTrustedRouteUnavailableBlockCount;
  final int passiveIngestedDwellEventCount;
  final int ambientCandidateObservationDeltaCount;
  final int ambientConfirmedPromotionDeltaCount;
  final int segmentRefreshCount;
  final String? failureSummary;

  Duration get duration => completedAtUtc.difference(startedAtUtc);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reason': reason.wireName,
        'platform_source': platformSource,
        'wake_timestamp_utc': wakeTimestampUtc.toUtc().toIso8601String(),
        'started_at_utc': startedAtUtc.toUtc().toIso8601String(),
        'completed_at_utc': completedAtUtc.toUtc().toIso8601String(),
        'bootstrap_success': bootstrapSuccess,
        'mesh_due_replay_count': meshDueReplayCount,
        'mesh_recovered_replay_count': meshRecoveredReplayCount,
        'mesh_discovered_peer_count': meshDiscoveredPeerCount,
        'ai2ai_released_count': ai2aiReleasedCount,
        'ai2ai_blocked_count': ai2aiBlockedCount,
        'ai2ai_trusted_route_unavailable_block_count':
            ai2aiTrustedRouteUnavailableBlockCount,
        'passive_ingested_dwell_event_count': passiveIngestedDwellEventCount,
        'ambient_candidate_observation_delta_count':
            ambientCandidateObservationDeltaCount,
        'ambient_confirmed_promotion_delta_count':
            ambientConfirmedPromotionDeltaCount,
        'segment_refresh_count': segmentRefreshCount,
        if (failureSummary != null) 'failure_summary': failureSummary,
      };

  factory BackgroundWakeExecutionRunRecord.fromJson(Map<String, dynamic> json) {
    final reason = BackgroundWakeReasonWireFormat.fromWireName(
      json['reason'] as String? ?? '',
    );
    if (reason == null) {
      throw ArgumentError.value(
        json['reason'],
        'reason',
        'Unsupported background wake reason',
      );
    }
    return BackgroundWakeExecutionRunRecord(
      reason: reason,
      platformSource: json['platform_source'] as String? ?? 'unknown',
      wakeTimestampUtc:
          DateTime.tryParse(json['wake_timestamp_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      startedAtUtc:
          DateTime.tryParse(json['started_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      completedAtUtc: DateTime.tryParse(
            json['completed_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      bootstrapSuccess: json['bootstrap_success'] as bool? ?? false,
      meshDueReplayCount: json['mesh_due_replay_count'] as int? ?? 0,
      meshRecoveredReplayCount:
          json['mesh_recovered_replay_count'] as int? ?? 0,
      meshDiscoveredPeerCount: json['mesh_discovered_peer_count'] as int? ?? 0,
      ai2aiReleasedCount: json['ai2ai_released_count'] as int? ?? 0,
      ai2aiBlockedCount: json['ai2ai_blocked_count'] as int? ?? 0,
      ai2aiTrustedRouteUnavailableBlockCount:
          json['ai2ai_trusted_route_unavailable_block_count'] as int? ?? 0,
      passiveIngestedDwellEventCount:
          json['passive_ingested_dwell_event_count'] as int? ?? 0,
      ambientCandidateObservationDeltaCount:
          json['ambient_candidate_observation_delta_count'] as int? ?? 0,
      ambientConfirmedPromotionDeltaCount:
          json['ambient_confirmed_promotion_delta_count'] as int? ?? 0,
      segmentRefreshCount: json['segment_refresh_count'] as int? ?? 0,
      failureSummary: json['failure_summary'] as String?,
    );
  }
}

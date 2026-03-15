import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';

enum MeshAnnounceSourceType {
  directDiscovery,
  forwardSuccess,
  heardForward,
  cloudAvailable,
}

class MeshAnnounceRecord {
  const MeshAnnounceRecord({
    required this.announceId,
    required this.destinationId,
    required this.nextHopPeerId,
    required this.interfaceId,
    required this.hopCount,
    required this.geographicScope,
    required this.confidence,
    required this.observedAtUtc,
    required this.lastConfirmedAtUtc,
    required this.expiresAtUtc,
    required this.supportsCustody,
    required this.sourceType,
    this.nextHopNodeId,
    this.segmentProfileId,
    this.segmentCredentialId,
    this.attestationId,
    this.attestationAccepted = true,
    this.rejectionReason,
  });

  final String announceId;
  final String destinationId;
  final String nextHopPeerId;
  final String? nextHopNodeId;
  final String interfaceId;
  final int hopCount;
  final String geographicScope;
  final double confidence;
  final DateTime observedAtUtc;
  final DateTime lastConfirmedAtUtc;
  final DateTime expiresAtUtc;
  final bool supportsCustody;
  final MeshAnnounceSourceType sourceType;
  final String? segmentProfileId;
  final String? segmentCredentialId;
  final String? attestationId;
  final bool attestationAccepted;
  final String? rejectionReason;

  bool isActiveAt(DateTime nowUtc) =>
      expiresAtUtc.isAfter(nowUtc) || expiresAtUtc.isAtSameMomentAs(nowUtc);

  MeshAnnounceRecord refresh({
    required DateTime nowUtc,
    required DateTime expiresAtUtc,
    required double confidence,
    required int hopCount,
    required bool supportsCustody,
    required MeshAnnounceSourceType sourceType,
    String? nextHopNodeId,
    String? geographicScope,
    String? segmentProfileId,
    String? segmentCredentialId,
    String? attestationId,
    bool? attestationAccepted,
    String? rejectionReason,
  }) {
    return MeshAnnounceRecord(
      announceId: announceId,
      destinationId: destinationId,
      nextHopPeerId: nextHopPeerId,
      nextHopNodeId: nextHopNodeId ?? this.nextHopNodeId,
      interfaceId: interfaceId,
      hopCount: hopCount,
      geographicScope: geographicScope ?? this.geographicScope,
      confidence: confidence,
      observedAtUtc: observedAtUtc,
      lastConfirmedAtUtc: nowUtc,
      expiresAtUtc: expiresAtUtc,
      supportsCustody: supportsCustody,
      sourceType: sourceType,
      segmentProfileId: segmentProfileId ?? this.segmentProfileId,
      segmentCredentialId: segmentCredentialId ?? this.segmentCredentialId,
      attestationId: attestationId ?? this.attestationId,
      attestationAccepted: attestationAccepted ?? this.attestationAccepted,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'announce_id': announceId,
        'destination_id': destinationId,
        'next_hop_peer_id': nextHopPeerId,
        'next_hop_node_id': nextHopNodeId,
        'interface_id': interfaceId,
        'hop_count': hopCount,
        'geographic_scope': geographicScope,
        'confidence': confidence,
        'observed_at_utc': observedAtUtc.toUtc().toIso8601String(),
        'last_confirmed_at_utc': lastConfirmedAtUtc.toUtc().toIso8601String(),
        'expires_at_utc': expiresAtUtc.toUtc().toIso8601String(),
        'supports_custody': supportsCustody,
        'source_type': sourceType.name,
        'segment_profile_id': segmentProfileId,
        'segment_credential_id': segmentCredentialId,
        'attestation_id': attestationId,
        'attestation_accepted': attestationAccepted,
        'rejection_reason': rejectionReason,
      };

  factory MeshAnnounceRecord.fromJson(Map<String, dynamic> json) {
    return MeshAnnounceRecord(
      announceId: json['announce_id'] as String? ?? 'unknown_announce',
      destinationId: json['destination_id'] as String? ?? 'unknown_destination',
      nextHopPeerId: json['next_hop_peer_id'] as String? ?? 'unknown_peer',
      nextHopNodeId: json['next_hop_node_id'] as String?,
      interfaceId: json['interface_id'] as String? ?? 'unknown',
      hopCount: (json['hop_count'] as num?)?.toInt() ?? 1,
      geographicScope: json['geographic_scope'] as String? ?? 'local',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      observedAtUtc: DateTime.tryParse(
            json['observed_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastConfirmedAtUtc: DateTime.tryParse(
            json['last_confirmed_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAtUtc: DateTime.tryParse(
            json['expires_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      supportsCustody: json['supports_custody'] as bool? ?? false,
      sourceType: MeshAnnounceSourceType.values.firstWhere(
        (value) => value.name == json['source_type'],
        orElse: () => MeshAnnounceSourceType.heardForward,
      ),
      segmentProfileId: json['segment_profile_id'] as String?,
      segmentCredentialId: json['segment_credential_id'] as String?,
      attestationId: json['attestation_id'] as String?,
      attestationAccepted: json['attestation_accepted'] as bool? ?? true,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

class MeshAnnounceObservation {
  const MeshAnnounceObservation({
    required this.destinationId,
    required this.nextHopPeerId,
    required this.interfaceId,
    required this.hopCount,
    required this.geographicScope,
    required this.confidence,
    required this.supportsCustody,
    required this.sourceType,
    this.nextHopNodeId,
    this.segmentProfile,
    this.segmentCredential,
    this.attestation,
  });

  final String destinationId;
  final String nextHopPeerId;
  final String? nextHopNodeId;
  final String interfaceId;
  final int hopCount;
  final String geographicScope;
  final double confidence;
  final bool supportsCustody;
  final MeshAnnounceSourceType sourceType;
  final MeshSegmentProfile? segmentProfile;
  final MeshSegmentCredential? segmentCredential;
  final MeshAnnounceAttestation? attestation;
}

class MeshAnnounceUpdateResult {
  const MeshAnnounceUpdateResult({
    required this.record,
    required this.triggerReason,
    required this.becameActive,
    this.accepted = true,
    this.rejectionReason,
  });

  final MeshAnnounceRecord record;
  final String? triggerReason;
  final bool becameActive;
  final bool accepted;
  final String? rejectionReason;
}

class MeshAnnounceTelemetry {
  const MeshAnnounceTelemetry({
    required this.announceTriggeredReplayCount,
    required this.announceRefreshReplayCount,
    required this.interfaceRecoveredReplayCount,
    required this.trustedReplayTriggerCount,
    this.trustedReplayTriggerSourceCounts = const <String, int>{},
  });

  final int announceTriggeredReplayCount;
  final int announceRefreshReplayCount;
  final int interfaceRecoveredReplayCount;
  final int trustedReplayTriggerCount;
  final Map<String, int> trustedReplayTriggerSourceCounts;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'announce_triggered_replay_count': announceTriggeredReplayCount,
        'announce_refresh_replay_count': announceRefreshReplayCount,
        'interface_recovered_replay_count': interfaceRecoveredReplayCount,
        'trusted_replay_trigger_count': trustedReplayTriggerCount,
        'trusted_replay_trigger_source_counts': trustedReplayTriggerSourceCounts,
      };

  factory MeshAnnounceTelemetry.fromJson(Map<String, dynamic> json) {
    return MeshAnnounceTelemetry(
      announceTriggeredReplayCount:
          (json['announce_triggered_replay_count'] as num?)?.toInt() ?? 0,
      announceRefreshReplayCount:
          (json['announce_refresh_replay_count'] as num?)?.toInt() ?? 0,
      interfaceRecoveredReplayCount:
          (json['interface_recovered_replay_count'] as num?)?.toInt() ?? 0,
      trustedReplayTriggerCount:
          (json['trusted_replay_trigger_count'] as num?)?.toInt() ?? 0,
      trustedReplayTriggerSourceCounts:
          (json['trusted_replay_trigger_source_counts'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
              const <String, int>{},
    );
  }
}

class MeshAnnounceLedger {
  MeshAnnounceLedger({
    MeshRuntimeStateStore? store,
    MeshAnnounceValidator? announceValidator,
    DateTime Function()? nowUtc,
  })  : _store = store ?? GetStorageMeshRuntimeStateStore(),
        _announceValidator = announceValidator,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const String _recordsKey = 'mesh_announce_ledger_records_v1';
  static const String _telemetryKey = 'mesh_announce_ledger_telemetry_v1';
  static const Duration _retentionWindow = Duration(hours: 24);

  final MeshRuntimeStateStore _store;
  final MeshAnnounceValidator? _announceValidator;
  final DateTime Function() _nowUtc;

  List<MeshAnnounceRecord> allRecords() => _readRecords();

  List<MeshAnnounceRecord> activeRecords({
    String? destinationId,
    String? geographicScope,
    DateTime? nowUtc,
  }) {
    final now = nowUtc ?? _nowUtc();
    return _readRecords()
        .where((record) =>
            destinationId == null || record.destinationId == destinationId)
        .where((record) =>
            geographicScope == null ||
            record.geographicScope == geographicScope)
        .where((record) => record.attestationAccepted && record.isActiveAt(now))
        .toList()
      ..sort((left, right) =>
          right.lastConfirmedAtUtc.compareTo(left.lastConfirmedAtUtc));
  }

  List<MeshAnnounceRecord> rejectedRecords({
    String? destinationId,
  }) {
    return _readRecords()
        .where((record) =>
            destinationId == null || record.destinationId == destinationId)
        .where(
          (record) =>
              !record.attestationAccepted || record.rejectionReason != null,
        )
        .toList()
      ..sort((left, right) =>
          right.lastConfirmedAtUtc.compareTo(left.lastConfirmedAtUtc));
  }

  Map<String, int> rejectionReasonCounts() {
    final counts = <String, int>{};
    for (final record in rejectedRecords()) {
      final reason = record.rejectionReason ?? 'unknown_rejection';
      counts[reason] = (counts[reason] ?? 0) + 1;
    }
    return counts;
  }

  List<MeshAnnounceRecord> expiredRecords({
    DateTime? nowUtc,
  }) {
    final now = nowUtc ?? _nowUtc();
    return _readRecords().where((record) => !record.isActiveAt(now)).toList()
      ..sort((left, right) => right.expiresAtUtc.compareTo(left.expiresAtUtc));
  }

  Future<MeshAnnounceUpdateResult> observe({
    required MeshAnnounceObservation observation,
    MeshInterfaceProfile? interfaceProfile,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    DateTime? nowUtc,
  }) async {
    final now = nowUtc ?? _nowUtc();
    final entries = _readRecords();
    final existingIndex = entries.indexWhere(
      (record) =>
          record.destinationId == observation.destinationId &&
          record.nextHopPeerId == observation.nextHopPeerId &&
          record.interfaceId == observation.interfaceId,
    );
    final existing = existingIndex >= 0 ? entries[existingIndex] : null;
    final resolvedInterfaceProfile = interfaceProfile ??
        const MeshInterfaceProfile(
          interfaceId: 'unknown',
          kind: MeshInterfaceKind.unknown,
          enabled: false,
          supportsDiscovery: false,
          supportsCustody: false,
          reachabilityScope: MeshInterfaceReachabilityScope.local,
          costClass: MeshInterfaceCostClass.high,
          energyCostClass: MeshInterfaceEnergyCostClass.high,
          trustClass: MeshInterfaceTrustClass.untrusted,
          allowedPrivacyModes: <String>{},
          defaultAnnounceTtl: Duration(minutes: 1),
          maxHopCount: 1,
        );
    final validation = _announceValidator?.validate(
      observation: observation,
      interfaceProfile: resolvedInterfaceProfile,
      privacyMode: privacyMode,
    );
    if (validation != null && !validation.accepted) {
      final rejectedRecord = existing == null
          ? MeshAnnounceRecord(
              announceId: 'rejected-announce-${now.microsecondsSinceEpoch}',
              destinationId: observation.destinationId,
              nextHopPeerId: observation.nextHopPeerId,
              nextHopNodeId: observation.nextHopNodeId,
              interfaceId: observation.interfaceId,
              hopCount: observation.hopCount,
              geographicScope: observation.geographicScope,
              confidence: 0.0,
              observedAtUtc: now,
              lastConfirmedAtUtc: now,
              expiresAtUtc: now,
              supportsCustody: observation.supportsCustody,
              sourceType: observation.sourceType,
              segmentProfileId: validation.segmentProfileId ??
                  observation.segmentProfile?.segmentProfileId,
              segmentCredentialId: validation.credentialId ??
                  observation.segmentCredential?.credentialId,
              attestationId: validation.attestationId ??
                  observation.attestation?.attestationId,
              attestationAccepted: false,
              rejectionReason: validation.reason,
            )
          : existing.refresh(
              nowUtc: now,
              expiresAtUtc: now,
              confidence: 0.0,
              hopCount: observation.hopCount,
              supportsCustody: observation.supportsCustody,
              sourceType: observation.sourceType,
              nextHopNodeId: observation.nextHopNodeId,
              geographicScope: observation.geographicScope,
              segmentProfileId: validation.segmentProfileId ??
                  observation.segmentProfile?.segmentProfileId,
              segmentCredentialId: validation.credentialId ??
                  observation.segmentCredential?.credentialId,
              attestationId: validation.attestationId ??
                  observation.attestation?.attestationId,
              attestationAccepted: false,
              rejectionReason: validation.reason,
            );
      if (existingIndex >= 0) {
        entries[existingIndex] = rejectedRecord;
      } else {
        entries.add(rejectedRecord);
      }
      await _writeRecords(entries);
      return MeshAnnounceUpdateResult(
        record: rejectedRecord,
        triggerReason: null,
        becameActive: false,
        accepted: false,
        rejectionReason: validation.reason,
      );
    }
    final wasActive = existing?.isActiveAt(now) ?? false;
    final expiry = now.add(
      _ttlFor(
        observation.sourceType,
        interfaceProfile: resolvedInterfaceProfile,
      ),
    );
    final record = existing == null
        ? MeshAnnounceRecord(
            announceId:
                'mesh-announce-${now.microsecondsSinceEpoch}-${entries.length + 1}',
            destinationId: observation.destinationId,
            nextHopPeerId: observation.nextHopPeerId,
            nextHopNodeId: observation.nextHopNodeId,
            interfaceId: observation.interfaceId,
            hopCount: observation.hopCount,
            geographicScope: observation.geographicScope,
            confidence: observation.confidence.clamp(0.0, 1.0).toDouble(),
            observedAtUtc: now,
            lastConfirmedAtUtc: now,
            expiresAtUtc: expiry,
            supportsCustody: observation.supportsCustody,
            sourceType: observation.sourceType,
            segmentProfileId: validation?.segmentProfileId ??
                observation.segmentProfile?.segmentProfileId,
            segmentCredentialId: validation?.credentialId ??
                observation.segmentCredential?.credentialId,
            attestationId: validation?.attestationId ??
                observation.attestation?.attestationId,
            attestationAccepted: validation?.accepted ?? true,
            rejectionReason: null,
          )
        : existing.refresh(
            nowUtc: now,
            expiresAtUtc: expiry,
            confidence: observation.confidence.clamp(0.0, 1.0).toDouble(),
            hopCount: observation.hopCount,
            supportsCustody: observation.supportsCustody,
            sourceType: observation.sourceType,
            nextHopNodeId: observation.nextHopNodeId,
            geographicScope: observation.geographicScope,
            segmentProfileId: validation?.segmentProfileId ??
                observation.segmentProfile?.segmentProfileId,
            segmentCredentialId: validation?.credentialId ??
                observation.segmentCredential?.credentialId,
            attestationId: validation?.attestationId ??
                observation.attestation?.attestationId,
            attestationAccepted: validation?.accepted ?? true,
            rejectionReason: null,
          );
    if (existingIndex >= 0) {
      entries[existingIndex] = record;
    } else {
      entries.add(record);
    }
    await _writeRecords(entries);

    final triggerReason = existing == null
        ? 'announce_arrival'
        : (!wasActive ? 'interface_recovered' : 'announce_refresh');
    return MeshAnnounceUpdateResult(
      record: record,
      triggerReason: triggerReason,
      becameActive: !wasActive,
      accepted: true,
    );
  }

  Future<void> recordReplayTrigger(
    String reason, {
    bool trusted = false,
    String? sourceKey,
  }) async {
    final telemetry = replayTelemetry();
    final trustedSourceCounts = Map<String, int>.from(
      telemetry.trustedReplayTriggerSourceCounts,
    );
    if (trusted && sourceKey != null && sourceKey.isNotEmpty) {
      trustedSourceCounts[sourceKey] =
          (trustedSourceCounts[sourceKey] ?? 0) + 1;
    }
    final next = switch (reason) {
      'announce_arrival' => MeshAnnounceTelemetry(
          announceTriggeredReplayCount:
              telemetry.announceTriggeredReplayCount + 1,
          announceRefreshReplayCount: telemetry.announceRefreshReplayCount,
          interfaceRecoveredReplayCount:
              telemetry.interfaceRecoveredReplayCount,
          trustedReplayTriggerCount:
              telemetry.trustedReplayTriggerCount + (trusted ? 1 : 0),
          trustedReplayTriggerSourceCounts: trustedSourceCounts,
        ),
      'announce_refresh' => MeshAnnounceTelemetry(
          announceTriggeredReplayCount: telemetry.announceTriggeredReplayCount,
          announceRefreshReplayCount: telemetry.announceRefreshReplayCount + 1,
          interfaceRecoveredReplayCount:
              telemetry.interfaceRecoveredReplayCount,
          trustedReplayTriggerCount:
              telemetry.trustedReplayTriggerCount + (trusted ? 1 : 0),
          trustedReplayTriggerSourceCounts: trustedSourceCounts,
        ),
      'interface_recovered' => MeshAnnounceTelemetry(
          announceTriggeredReplayCount: telemetry.announceTriggeredReplayCount,
          announceRefreshReplayCount: telemetry.announceRefreshReplayCount,
          interfaceRecoveredReplayCount:
              telemetry.interfaceRecoveredReplayCount + 1,
          trustedReplayTriggerCount:
              telemetry.trustedReplayTriggerCount + (trusted ? 1 : 0),
          trustedReplayTriggerSourceCounts: trustedSourceCounts,
        ),
      _ => telemetry,
    };
    await _store.write(_telemetryKey, next.toJson());
  }

  MeshAnnounceTelemetry replayTelemetry() {
    final json = _store.read<Map>(_telemetryKey);
    if (json == null) {
      return const MeshAnnounceTelemetry(
        announceTriggeredReplayCount: 0,
        announceRefreshReplayCount: 0,
        interfaceRecoveredReplayCount: 0,
        trustedReplayTriggerCount: 0,
        trustedReplayTriggerSourceCounts: <String, int>{},
      );
    }
    return MeshAnnounceTelemetry.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> pruneExpiredHistory({DateTime? nowUtc}) async {
    final now = nowUtc ?? _nowUtc();
    final cutoff = now.subtract(_retentionWindow);
    final retained = _readRecords()
        .where((record) => record.expiresAtUtc.isAfter(cutoff))
        .toList();
    await _writeRecords(retained);
  }

  Duration _ttlFor(
    MeshAnnounceSourceType sourceType, {
    MeshInterfaceProfile? interfaceProfile,
  }) {
    return switch (sourceType) {
      MeshAnnounceSourceType.directDiscovery =>
        interfaceProfile?.defaultAnnounceTtl ?? const Duration(minutes: 5),
      MeshAnnounceSourceType.cloudAvailable => const Duration(minutes: 15),
      MeshAnnounceSourceType.forwardSuccess => const Duration(minutes: 3),
      MeshAnnounceSourceType.heardForward => const Duration(minutes: 3),
    };
  }

  List<MeshAnnounceRecord> _readRecords() {
    final json = _store.read<List>(_recordsKey);
    if (json == null) {
      return <MeshAnnounceRecord>[];
    }
    return json
        .whereType<Map>()
        .map(
          (entry) => MeshAnnounceRecord.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  Future<void> _writeRecords(List<MeshAnnounceRecord> records) {
    return _store.write(
      _recordsKey,
      records.map((entry) => entry.toJson()).toList(),
    );
  }
}

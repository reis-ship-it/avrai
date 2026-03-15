import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';

class MeshRuntimeDestinationState {
  const MeshRuntimeDestinationState({
    required this.destinationId,
    required this.knownRouteCount,
    required this.pendingCustodyCount,
    required this.bestSuccessRate,
    required this.totalSuccessCount,
    required this.totalFailureCount,
    required this.payloadKinds,
    required this.peerIds,
    required this.activeAnnounceCount,
    required this.expiredAnnounceCount,
    required this.queuedInterfaceIds,
    this.lastRouteUpdateAtUtc,
    this.lastQueuedAtUtc,
  });

  final String destinationId;
  final int knownRouteCount;
  final int pendingCustodyCount;
  final double bestSuccessRate;
  final int totalSuccessCount;
  final int totalFailureCount;
  final List<String> payloadKinds;
  final List<String> peerIds;
  final int activeAnnounceCount;
  final int expiredAnnounceCount;
  final List<String> queuedInterfaceIds;
  final DateTime? lastRouteUpdateAtUtc;
  final DateTime? lastQueuedAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'destination_id': destinationId,
        'known_route_count': knownRouteCount,
        'pending_custody_count': pendingCustodyCount,
        'best_success_rate': bestSuccessRate,
        'total_success_count': totalSuccessCount,
        'total_failure_count': totalFailureCount,
        'payload_kinds': payloadKinds,
        'peer_ids': peerIds,
        'active_announce_count': activeAnnounceCount,
        'expired_announce_count': expiredAnnounceCount,
        'queued_interface_ids': queuedInterfaceIds,
        'last_route_update_at_utc':
            lastRouteUpdateAtUtc?.toUtc().toIso8601String(),
        'last_queued_at_utc': lastQueuedAtUtc?.toUtc().toIso8601String(),
      };

  factory MeshRuntimeDestinationState.fromJson(Map<String, dynamic> json) {
    return MeshRuntimeDestinationState(
      destinationId: json['destination_id'] as String? ?? 'unknown_destination',
      knownRouteCount: (json['known_route_count'] as num?)?.toInt() ?? 0,
      pendingCustodyCount:
          (json['pending_custody_count'] as num?)?.toInt() ?? 0,
      bestSuccessRate: (json['best_success_rate'] as num?)?.toDouble() ?? 0.0,
      totalSuccessCount: (json['total_success_count'] as num?)?.toInt() ?? 0,
      totalFailureCount: (json['total_failure_count'] as num?)?.toInt() ?? 0,
      payloadKinds: (json['payload_kinds'] as List? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      peerIds: (json['peer_ids'] as List? ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      activeAnnounceCount:
          (json['active_announce_count'] as num?)?.toInt() ?? 0,
      expiredAnnounceCount:
          (json['expired_announce_count'] as num?)?.toInt() ?? 0,
      queuedInterfaceIds:
          (json['queued_interface_ids'] as List? ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      lastRouteUpdateAtUtc: DateTime.tryParse(
        json['last_route_update_at_utc'] as String? ?? '',
      )?.toUtc(),
      lastQueuedAtUtc: DateTime.tryParse(
        json['last_queued_at_utc'] as String? ?? '',
      )?.toUtc(),
    );
  }
}

class MeshRuntimeStateFrame {
  const MeshRuntimeStateFrame({
    required this.capturedAtUtc,
    required this.routeDestinationCount,
    required this.routeEntryCount,
    required this.interfaceEnabledCounts,
    required this.interfaceTotalCounts,
    required this.activeAnnounceCount,
    required this.trustedActiveAnnounceCount,
    required this.expiredAnnounceCount,
    required this.rejectedAnnounceCount,
    required this.pendingCustodyCount,
    required this.dueCustodyCount,
    required this.encryptedAtRest,
    required this.announceTriggeredReplayCount,
    required this.announceRefreshReplayCount,
    required this.interfaceRecoveredReplayCount,
    required this.trustedReplayTriggerCount,
    required this.trustedReplayTriggerSourceCounts,
    required this.rejectionReasonCounts,
    required this.activeCredentialCount,
    required this.expiringSoonCredentialCount,
    required this.revokedCredentialCount,
    required this.queuedPayloadKindCounts,
    required this.destinations,
    this.activeAnnounceSourceCounts = const <String, int>{},
    this.rejectedAnnounceSourceCounts = const <String, int>{},
  });

  final DateTime capturedAtUtc;
  final int routeDestinationCount;
  final int routeEntryCount;
  final Map<String, int> interfaceEnabledCounts;
  final Map<String, int> interfaceTotalCounts;
  final int activeAnnounceCount;
  final int trustedActiveAnnounceCount;
  final int expiredAnnounceCount;
  final int rejectedAnnounceCount;
  final int pendingCustodyCount;
  final int dueCustodyCount;
  final bool encryptedAtRest;
  final int announceTriggeredReplayCount;
  final int announceRefreshReplayCount;
  final int interfaceRecoveredReplayCount;
  final int trustedReplayTriggerCount;
  final Map<String, int> trustedReplayTriggerSourceCounts;
  final Map<String, int> rejectionReasonCounts;
  final int activeCredentialCount;
  final int expiringSoonCredentialCount;
  final int revokedCredentialCount;
  final Map<String, int> queuedPayloadKindCounts;
  final List<MeshRuntimeDestinationState> destinations;
  final Map<String, int> activeAnnounceSourceCounts;
  final Map<String, int> rejectedAnnounceSourceCounts;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'captured_at_utc': capturedAtUtc.toUtc().toIso8601String(),
        'route_destination_count': routeDestinationCount,
        'route_entry_count': routeEntryCount,
        'interface_enabled_counts': interfaceEnabledCounts,
        'interface_total_counts': interfaceTotalCounts,
        'active_announce_count': activeAnnounceCount,
        'trusted_active_announce_count': trustedActiveAnnounceCount,
        'expired_announce_count': expiredAnnounceCount,
        'rejected_announce_count': rejectedAnnounceCount,
        'pending_custody_count': pendingCustodyCount,
        'due_custody_count': dueCustodyCount,
        'encrypted_at_rest': encryptedAtRest,
        'announce_triggered_replay_count': announceTriggeredReplayCount,
        'announce_refresh_replay_count': announceRefreshReplayCount,
        'interface_recovered_replay_count': interfaceRecoveredReplayCount,
        'trusted_replay_trigger_count': trustedReplayTriggerCount,
        'trusted_replay_trigger_source_counts':
            trustedReplayTriggerSourceCounts,
        'rejection_reason_counts': rejectionReasonCounts,
        'active_credential_count': activeCredentialCount,
        'expiring_soon_credential_count': expiringSoonCredentialCount,
        'revoked_credential_count': revokedCredentialCount,
        'queued_payload_kind_counts': queuedPayloadKindCounts,
        'active_announce_source_counts': activeAnnounceSourceCounts,
        'rejected_announce_source_counts': rejectedAnnounceSourceCounts,
        'destinations': destinations.map((entry) => entry.toJson()).toList(),
      };

  factory MeshRuntimeStateFrame.fromJson(Map<String, dynamic> json) {
    return MeshRuntimeStateFrame(
      capturedAtUtc: DateTime.tryParse(json['captured_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      routeDestinationCount:
          (json['route_destination_count'] as num?)?.toInt() ?? 0,
      routeEntryCount: (json['route_entry_count'] as num?)?.toInt() ?? 0,
      interfaceEnabledCounts: (json['interface_enabled_counts'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{},
      interfaceTotalCounts: (json['interface_total_counts'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{},
      activeAnnounceCount:
          (json['active_announce_count'] as num?)?.toInt() ?? 0,
      trustedActiveAnnounceCount:
          (json['trusted_active_announce_count'] as num?)?.toInt() ?? 0,
      expiredAnnounceCount:
          (json['expired_announce_count'] as num?)?.toInt() ?? 0,
      rejectedAnnounceCount:
          (json['rejected_announce_count'] as num?)?.toInt() ?? 0,
      pendingCustodyCount:
          (json['pending_custody_count'] as num?)?.toInt() ?? 0,
      dueCustodyCount: (json['due_custody_count'] as num?)?.toInt() ?? 0,
      encryptedAtRest: json['encrypted_at_rest'] as bool? ?? false,
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
      rejectionReasonCounts: (json['rejection_reason_counts'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
          ) ??
          const <String, int>{},
      activeCredentialCount:
          (json['active_credential_count'] as num?)?.toInt() ?? 0,
      expiringSoonCredentialCount:
          (json['expiring_soon_credential_count'] as num?)?.toInt() ?? 0,
      revokedCredentialCount:
          (json['revoked_credential_count'] as num?)?.toInt() ?? 0,
      queuedPayloadKindCounts:
          (json['queued_payload_kind_counts'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
              const <String, int>{},
      activeAnnounceSourceCounts:
          (json['active_announce_source_counts'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
              const <String, int>{},
      rejectedAnnounceSourceCounts:
          (json['rejected_announce_source_counts'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
              const <String, int>{},
      destinations: (json['destinations'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (entry) => MeshRuntimeDestinationState.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toSimulationTopology() => <String, dynamic>{
        'mesh_runtime_state_frame': toJson(),
      };
}

class MeshRuntimeStateFrameService {
  const MeshRuntimeStateFrameService();

  MeshRuntimeStateFrame buildFrame({
    required MeshRouteLedger routeLedger,
    MeshCustodyOutbox? custodyOutbox,
    MeshAnnounceLedger? announceLedger,
    MeshInterfaceRegistry? interfaceRegistry,
    MeshSegmentCredentialRefreshService? credentialRefreshService,
    MeshSegmentRevocationStore? revocationStore,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    DateTime? capturedAtUtc,
  }) {
    final now = capturedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    final routeEntries = routeLedger.allEntries();
    final outboxEntries =
        custodyOutbox?.allEntries() ?? const <MeshCustodyOutboxEntry>[];
    final activeAnnounces = announceLedger?.activeRecords(nowUtc: now) ??
        const <MeshAnnounceRecord>[];
    final rejectedAnnounces =
        announceLedger?.rejectedRecords() ?? const <MeshAnnounceRecord>[];
    final expiredAnnounces = announceLedger?.expiredRecords(nowUtc: now) ??
        const <MeshAnnounceRecord>[];
    final announceTelemetry = announceLedger?.replayTelemetry();
    final rejectionReasonCounts =
        announceLedger?.rejectionReasonCounts() ?? const <String, int>{};
    final routeDestinationIds = routeEntries
        .map((entry) => entry.destinationId)
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final queuedPayloadKindCounts = <String, int>{};
    for (final entry in outboxEntries) {
      queuedPayloadKindCounts[entry.payloadKind] =
          (queuedPayloadKindCounts[entry.payloadKind] ?? 0) + 1;
    }
    final activeAnnounceSourceCounts = _countBySource(activeAnnounces);
    final rejectedAnnounceSourceCounts = _countBySource(rejectedAnnounces);

    final destinationIds = <String>{
      ...routeDestinationIds,
      ...outboxEntries.map((entry) => entry.destinationId),
      ...activeAnnounces.map((entry) => entry.destinationId),
      ...expiredAnnounces.map((entry) => entry.destinationId),
    };
    final destinations = destinationIds
        .map(
          (destinationId) => _buildDestinationState(
            destinationId: destinationId,
            routeEntries: routeEntries
                .where((entry) => entry.destinationId == destinationId)
                .toList(),
            outboxEntries: outboxEntries
                .where((entry) => entry.destinationId == destinationId)
                .toList(),
            activeAnnounces: activeAnnounces
                .where((entry) => entry.destinationId == destinationId)
                .toList(),
            expiredAnnounces: expiredAnnounces
                .where((entry) => entry.destinationId == destinationId)
                .toList(),
          ),
        )
        .toList()
      ..sort((left, right) {
        final custodyOrder =
            right.pendingCustodyCount.compareTo(left.pendingCustodyCount);
        if (custodyOrder != 0) {
          return custodyOrder;
        }
        final routeOrder =
            right.knownRouteCount.compareTo(left.knownRouteCount);
        if (routeOrder != 0) {
          return routeOrder;
        }
        return left.destinationId.compareTo(right.destinationId);
      });

    final dueCustodyCount = outboxEntries
        .where(
          (entry) =>
              entry.nextAttemptAtUtc.isBefore(now) ||
              entry.nextAttemptAtUtc.isAtSameMomentAs(now),
        )
        .length;
    final profiles = interfaceRegistry?.allProfiles(privacyMode: privacyMode) ??
        const <MeshInterfaceProfile>[];
    final interfaceEnabledCounts = <String, int>{};
    final interfaceTotalCounts = <String, int>{};
    for (final profile in profiles) {
      interfaceTotalCounts[profile.kind.name] =
          (interfaceTotalCounts[profile.kind.name] ?? 0) + 1;
      if (profile.enabled) {
        interfaceEnabledCounts[profile.kind.name] =
            (interfaceEnabledCounts[profile.kind.name] ?? 0) + 1;
      }
    }

    return MeshRuntimeStateFrame(
      capturedAtUtc: now,
      routeDestinationCount: routeDestinationIds.length,
      routeEntryCount: routeEntries.length,
      interfaceEnabledCounts: _sortedCounts(interfaceEnabledCounts),
      interfaceTotalCounts: _sortedCounts(interfaceTotalCounts),
      activeAnnounceCount: activeAnnounces.length,
      trustedActiveAnnounceCount:
          activeAnnounces.where((entry) => entry.attestationId != null).length,
      expiredAnnounceCount: expiredAnnounces.length,
      rejectedAnnounceCount: rejectedAnnounces.length,
      pendingCustodyCount: outboxEntries.length,
      dueCustodyCount: dueCustodyCount,
      encryptedAtRest: outboxEntries.isEmpty ||
          outboxEntries.every((entry) => entry.hasEncryptedPayload),
      announceTriggeredReplayCount:
          announceTelemetry?.announceTriggeredReplayCount ?? 0,
      announceRefreshReplayCount:
          announceTelemetry?.announceRefreshReplayCount ?? 0,
      interfaceRecoveredReplayCount:
          announceTelemetry?.interfaceRecoveredReplayCount ?? 0,
      trustedReplayTriggerCount:
          announceTelemetry?.trustedReplayTriggerCount ?? 0,
      trustedReplayTriggerSourceCounts: _sortedCounts(
        announceTelemetry?.trustedReplayTriggerSourceCounts ??
            const <String, int>{},
      ),
      rejectionReasonCounts: _sortedCounts(rejectionReasonCounts),
      activeCredentialCount:
          credentialRefreshService?.activeCredentialCount(nowUtc: now) ?? 0,
      expiringSoonCredentialCount:
          credentialRefreshService?.expiringSoonCredentialCount(nowUtc: now) ??
              0,
      revokedCredentialCount: revocationStore?.credentialRevocationCount() ?? 0,
      queuedPayloadKindCounts: _sortedCounts(queuedPayloadKindCounts),
      activeAnnounceSourceCounts: _sortedCounts(activeAnnounceSourceCounts),
      rejectedAnnounceSourceCounts: _sortedCounts(rejectedAnnounceSourceCounts),
      destinations: destinations,
    );
  }

  MeshRuntimeStateFrame buildFrameFromContext(
    MeshForwardingContext context, {
    DateTime? capturedAtUtc,
  }) {
    final now = capturedAtUtc?.toUtc() ?? DateTime.now().toUtc();
    final routeLedger = context.routeLedger;
    if (routeLedger == null) {
      final outboxEntries = context.custodyOutbox?.allEntries() ??
          const <MeshCustodyOutboxEntry>[];
      return MeshRuntimeStateFrame(
        capturedAtUtc: now,
        routeDestinationCount: 0,
        routeEntryCount: 0,
        interfaceEnabledCounts: const <String, int>{},
        interfaceTotalCounts: const <String, int>{},
        activeAnnounceCount: 0,
        trustedActiveAnnounceCount: 0,
        expiredAnnounceCount: 0,
        rejectedAnnounceCount: 0,
        pendingCustodyCount: outboxEntries.length,
        dueCustodyCount: outboxEntries
            .where(
              (entry) =>
                  entry.nextAttemptAtUtc.isBefore(now) ||
                  entry.nextAttemptAtUtc.isAtSameMomentAs(now),
            )
            .length,
        encryptedAtRest: outboxEntries.isEmpty ||
            outboxEntries.every((entry) => entry.hasEncryptedPayload),
        announceTriggeredReplayCount: 0,
        announceRefreshReplayCount: 0,
        interfaceRecoveredReplayCount: 0,
        trustedReplayTriggerCount: 0,
        trustedReplayTriggerSourceCounts: const <String, int>{},
        rejectionReasonCounts: const <String, int>{},
        activeCredentialCount: 0,
        expiringSoonCredentialCount: 0,
        revokedCredentialCount: 0,
        queuedPayloadKindCounts: const <String, int>{},
        activeAnnounceSourceCounts: const <String, int>{},
        rejectedAnnounceSourceCounts: const <String, int>{},
        destinations: const <MeshRuntimeDestinationState>[],
      );
    }
    return buildFrame(
      routeLedger: routeLedger,
      custodyOutbox: context.custodyOutbox,
      announceLedger: context.announceLedger,
      interfaceRegistry: context.interfaceRegistry,
      credentialRefreshService: context.segmentCredentialRefreshService,
      revocationStore: context.segmentRevocationStore,
      privacyMode: context.privacyMode,
      capturedAtUtc: capturedAtUtc,
    );
  }

  MeshRuntimeDestinationState _buildDestinationState({
    required String destinationId,
    required List<MeshRouteLedgerEntry> routeEntries,
    required List<MeshCustodyOutboxEntry> outboxEntries,
    required List<MeshAnnounceRecord> activeAnnounces,
    required List<MeshAnnounceRecord> expiredAnnounces,
  }) {
    final payloadKinds = <String>{
      for (final entry in routeEntries) ...entry.payloadKinds,
      for (final entry in outboxEntries) entry.payloadKind,
    }.toList()
      ..sort();
    final peerIds = <String>{
      ...routeEntries.map((entry) => entry.peerId),
      ...activeAnnounces.map((entry) => entry.nextHopPeerId),
    }.toList()
      ..sort();
    final totalSuccessCount = routeEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.successCount,
    );
    final totalFailureCount = routeEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.failureCount,
    );
    final bestSuccessRate = routeEntries.isEmpty
        ? 0.0
        : routeEntries
            .map((entry) => entry.successRate)
            .reduce((best, value) => value > best ? value : best);
    final lastRouteUpdateAtUtc = routeEntries.isEmpty
        ? null
        : routeEntries
            .map((entry) => entry.updatedAtUtc)
            .reduce((left, right) => left.isAfter(right) ? left : right);
    final lastQueuedAtUtc = outboxEntries.isEmpty
        ? null
        : outboxEntries
            .map((entry) => entry.queuedAtUtc)
            .reduce((left, right) => left.isAfter(right) ? left : right);

    return MeshRuntimeDestinationState(
      destinationId: destinationId,
      knownRouteCount: routeEntries.length,
      pendingCustodyCount: outboxEntries.length,
      bestSuccessRate: bestSuccessRate,
      totalSuccessCount: totalSuccessCount,
      totalFailureCount: totalFailureCount,
      payloadKinds: payloadKinds,
      peerIds: peerIds,
      activeAnnounceCount: activeAnnounces.length,
      expiredAnnounceCount: expiredAnnounces.length,
      queuedInterfaceIds: outboxEntries
          .map(
            (entry) => entry.sourceRouteReceiptJson?['metadata']
                    ?['mesh_interface_id']
                ?.toString(),
          )
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
      lastRouteUpdateAtUtc: lastRouteUpdateAtUtc,
      lastQueuedAtUtc: lastQueuedAtUtc,
    );
  }

  Map<String, int> _sortedCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }

  Map<String, int> _countBySource(List<MeshAnnounceRecord> records) {
    final counts = <String, int>{};
    for (final record in records) {
      final sourceName = _sourceLabel(record.sourceType);
      counts[sourceName] = (counts[sourceName] ?? 0) + 1;
    }
    return counts;
  }

  String _sourceLabel(MeshAnnounceSourceType sourceType) {
    return switch (sourceType) {
      MeshAnnounceSourceType.directDiscovery => 'direct_discovery',
      MeshAnnounceSourceType.forwardSuccess => 'forward_success',
      MeshAnnounceSourceType.heardForward => 'heard_forward',
      MeshAnnounceSourceType.cloudAvailable => 'cloud_available',
    };
  }
}

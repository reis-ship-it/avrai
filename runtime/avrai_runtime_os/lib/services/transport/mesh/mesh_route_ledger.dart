import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';

class MeshRouteLedgerEntry {
  const MeshRouteLedgerEntry({
    required this.destinationId,
    required this.peerId,
    required this.channel,
    required this.updatedAtUtc,
    this.peerNodeId,
    this.geographicScope,
    this.payloadKinds = const <String>[],
    this.successCount = 0,
    this.failureCount = 0,
    this.custodyAcceptedCount = 0,
    this.lastConfidence = 0.0,
    this.lastSignalStrengthDbm,
    this.lastLatencyMs,
    this.lastAttemptAtUtc,
    this.lastSuccessAtUtc,
    this.lastFailureAtUtc,
  });

  final String destinationId;
  final String peerId;
  final String? peerNodeId;
  final String channel;
  final String? geographicScope;
  final List<String> payloadKinds;
  final int successCount;
  final int failureCount;
  final int custodyAcceptedCount;
  final double lastConfidence;
  final int? lastSignalStrengthDbm;
  final int? lastLatencyMs;
  final DateTime? lastAttemptAtUtc;
  final DateTime? lastSuccessAtUtc;
  final DateTime? lastFailureAtUtc;
  final DateTime updatedAtUtc;

  int get totalAttempts => successCount + failureCount;

  double get successRate {
    if (totalAttempts == 0) {
      return 0.5;
    }
    return (successCount / totalAttempts).clamp(0.0, 1.0).toDouble();
  }

  MeshRouteLedgerEntry recordAttempt({
    required DateTime occurredAtUtc,
    required bool successful,
    required bool custodyAccepted,
    required String channel,
    required String? peerNodeId,
    required String? geographicScope,
    required String payloadKind,
    required double confidence,
    required int? signalStrengthDbm,
    required int? latencyMs,
  }) {
    final nextPayloadKinds = <String>{
      ...payloadKinds,
      payloadKind,
    }.toList()
      ..sort();

    return MeshRouteLedgerEntry(
      destinationId: destinationId,
      peerId: peerId,
      peerNodeId: peerNodeId ?? this.peerNodeId,
      channel: channel,
      geographicScope: geographicScope ?? this.geographicScope,
      payloadKinds: nextPayloadKinds,
      successCount: successCount + (successful ? 1 : 0),
      failureCount: failureCount + (successful ? 0 : 1),
      custodyAcceptedCount: custodyAcceptedCount + (custodyAccepted ? 1 : 0),
      lastConfidence: confidence,
      lastSignalStrengthDbm: signalStrengthDbm ?? lastSignalStrengthDbm,
      lastLatencyMs: latencyMs ?? lastLatencyMs,
      lastAttemptAtUtc: occurredAtUtc,
      lastSuccessAtUtc: successful ? occurredAtUtc : lastSuccessAtUtc,
      lastFailureAtUtc: successful ? lastFailureAtUtc : occurredAtUtc,
      updatedAtUtc: occurredAtUtc,
    );
  }

  double scoreAt({
    required DateTime nowUtc,
    double? liveProximityScore,
    int? liveSignalStrengthDbm,
    String? requestedGeographicScope,
  }) {
    final liveSignalScore = _signalStrengthScore(
      liveSignalStrengthDbm ?? lastSignalStrengthDbm,
    );
    final liveScore = liveProximityScore ?? liveSignalScore;
    final freshnessAnchor =
        lastSuccessAtUtc ?? lastAttemptAtUtc ?? updatedAtUtc;
    final freshnessMinutes =
        nowUtc.difference(freshnessAnchor).inMinutes.abs().toDouble();
    final freshnessScore =
        (1.0 - (freshnessMinutes / 180.0)).clamp(0.0, 1.0).toDouble();
    final localityScore = requestedGeographicScope == null ||
            geographicScope == null ||
            requestedGeographicScope == geographicScope
        ? 1.0
        : 0.68;
    final latencyScore = lastLatencyMs == null
        ? 0.55
        : (1.0 - (lastLatencyMs!.clamp(40, 800) / 800.0))
            .clamp(0.0, 1.0)
            .toDouble();
    final recentFailurePenalty = lastFailureAtUtc != null &&
            nowUtc.difference(lastFailureAtUtc!).inMinutes < 10
        ? 0.12
        : 0.0;

    final score = (successRate * 0.38) +
        (freshnessScore * 0.22) +
        (liveScore * 0.22) +
        (latencyScore * 0.10) +
        (localityScore * 0.08) -
        recentFailurePenalty;
    return score.clamp(0.0, 1.0).toDouble();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'destination_id': destinationId,
        'peer_id': peerId,
        'peer_node_id': peerNodeId,
        'channel': channel,
        'geographic_scope': geographicScope,
        'payload_kinds': payloadKinds,
        'success_count': successCount,
        'failure_count': failureCount,
        'custody_accepted_count': custodyAcceptedCount,
        'last_confidence': lastConfidence,
        'last_signal_strength_dbm': lastSignalStrengthDbm,
        'last_latency_ms': lastLatencyMs,
        'last_attempt_at_utc': lastAttemptAtUtc?.toUtc().toIso8601String(),
        'last_success_at_utc': lastSuccessAtUtc?.toUtc().toIso8601String(),
        'last_failure_at_utc': lastFailureAtUtc?.toUtc().toIso8601String(),
        'updated_at_utc': updatedAtUtc.toUtc().toIso8601String(),
      };

  factory MeshRouteLedgerEntry.fromJson(Map<String, dynamic> json) {
    return MeshRouteLedgerEntry(
      destinationId: json['destination_id'] as String? ?? 'unknown_destination',
      peerId: json['peer_id'] as String? ?? 'unknown_peer',
      peerNodeId: json['peer_node_id'] as String?,
      channel: json['channel'] as String? ?? 'mesh_ble_forward',
      geographicScope: json['geographic_scope'] as String?,
      payloadKinds: (json['payload_kinds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      successCount: (json['success_count'] as num?)?.toInt() ?? 0,
      failureCount: (json['failure_count'] as num?)?.toInt() ?? 0,
      custodyAcceptedCount:
          (json['custody_accepted_count'] as num?)?.toInt() ?? 0,
      lastConfidence: (json['last_confidence'] as num?)?.toDouble() ?? 0.0,
      lastSignalStrengthDbm:
          (json['last_signal_strength_dbm'] as num?)?.toInt(),
      lastLatencyMs: (json['last_latency_ms'] as num?)?.toInt(),
      lastAttemptAtUtc: DateTime.tryParse(
        json['last_attempt_at_utc'] as String? ?? '',
      )?.toUtc(),
      lastSuccessAtUtc: DateTime.tryParse(
        json['last_success_at_utc'] as String? ?? '',
      )?.toUtc(),
      lastFailureAtUtc: DateTime.tryParse(
        json['last_failure_at_utc'] as String? ?? '',
      )?.toUtc(),
      updatedAtUtc: DateTime.tryParse(
            json['updated_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static double _signalStrengthScore(int? signalStrengthDbm) {
    if (signalStrengthDbm == null) {
      return 0.45;
    }
    final normalized = (signalStrengthDbm + 100) / 70;
    return normalized.clamp(0.0, 1.0).toDouble();
  }
}

class MeshRouteLedger {
  MeshRouteLedger({
    MeshRuntimeStateStore? store,
    DateTime Function()? nowUtc,
  })  : _store = store ?? GetStorageMeshRuntimeStateStore(),
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const String _entriesKey = 'mesh_route_ledger_entries_v1';

  final MeshRuntimeStateStore _store;
  final DateTime Function() _nowUtc;

  List<MeshRouteLedgerEntry> allEntries() => _readEntries();

  List<MeshRouteLedgerEntry> entriesForDestination(
    String destinationId, {
    String? geographicScope,
  }) {
    return _readEntries()
        .where((entry) => entry.destinationId == destinationId)
        .where(
          (entry) =>
              geographicScope == null ||
              entry.geographicScope == null ||
              entry.geographicScope == geographicScope,
        )
        .toList();
  }

  List<MeshRouteLedgerEntry> entriesForPeer(String peerId) {
    return _readEntries().where((entry) => entry.peerId == peerId).toList();
  }

  MeshRouteLedgerEntry? entryForPeer({
    required String destinationId,
    required String peerId,
  }) {
    try {
      return _readEntries().firstWhere(
        (entry) =>
            entry.destinationId == destinationId && entry.peerId == peerId,
      );
    } catch (_) {
      return null;
    }
  }

  int knownRouteCount(String destinationId) =>
      entriesForDestination(destinationId).length;

  double scoreCandidate({
    required String destinationId,
    required String peerId,
    required DiscoveredDevice? device,
    String? geographicScope,
  }) {
    final liveProximityScore = device?.proximityScore ?? 0.35;
    final entry = entryForPeer(destinationId: destinationId, peerId: peerId);
    if (entry == null) {
      return liveProximityScore;
    }
    return entry.scoreAt(
      nowUtc: _nowUtc(),
      liveProximityScore: liveProximityScore,
      liveSignalStrengthDbm: device?.signalStrength,
      requestedGeographicScope: geographicScope,
    );
  }

  List<String> rankCandidates({
    required String destinationId,
    required Iterable<String> candidatePeerIds,
    required DeviceDiscoveryService discovery,
    String? geographicScope,
    int maxCandidates = 2,
  }) {
    final ranked = <_RankedMeshPeer>[
      for (final peerId in candidatePeerIds.toSet())
        _RankedMeshPeer(
          peerId: peerId,
          score: scoreCandidate(
            destinationId: destinationId,
            peerId: peerId,
            device: discovery.getDevice(peerId),
            geographicScope: geographicScope,
          ),
          liveProximityScore:
              discovery.getDevice(peerId)?.proximityScore ?? 0.0,
        ),
    ]..sort((left, right) {
        final scoreCompare = right.score.compareTo(left.score);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return right.liveProximityScore.compareTo(left.liveProximityScore);
      });

    return ranked.take(maxCandidates).map((peer) => peer.peerId).toList();
  }

  Future<void> recordForwardOutcome({
    required String destinationId,
    required String channel,
    required String payloadKind,
    required List<TransportRouteCandidate> attemptedRoutes,
    required TransportRouteCandidate? winningRoute,
    required DateTime occurredAtUtc,
    String? geographicScope,
  }) async {
    if (attemptedRoutes.isEmpty) {
      return;
    }

    final entries = _readEntries();
    final indexByKey = <String, int>{
      for (var i = 0; i < entries.length; i++)
        '${entries[i].destinationId}:${entries[i].peerId}': i,
    };

    for (final route in attemptedRoutes) {
      final peerId = route.metadata['peer_id']?.toString();
      if (peerId == null || peerId.isEmpty) {
        continue;
      }

      final key = '$destinationId:$peerId';
      final existing = indexByKey.containsKey(key)
          ? entries[indexByKey[key]!]
          : MeshRouteLedgerEntry(
              destinationId: destinationId,
              peerId: peerId,
              peerNodeId: route.metadata['peer_node_id']?.toString(),
              channel: channel,
              geographicScope: geographicScope,
              updatedAtUtc: occurredAtUtc,
            );
      final successful = winningRoute?.routeId == route.routeId;
      final updated = existing.recordAttempt(
        occurredAtUtc: occurredAtUtc,
        successful: successful,
        custodyAccepted: successful,
        channel: channel,
        peerNodeId: route.metadata['peer_node_id']?.toString(),
        geographicScope: geographicScope,
        payloadKind: payloadKind,
        confidence: route.confidence,
        signalStrengthDbm:
            (route.metadata['signal_strength_dbm'] as num?)?.toInt(),
        latencyMs: route.estimatedLatencyMs,
      );

      final index = indexByKey[key];
      if (index == null) {
        indexByKey[key] = entries.length;
        entries.add(updated);
      } else {
        entries[index] = updated;
      }
    }

    await _writeEntries(entries);
  }

  List<MeshRouteLedgerEntry> _readEntries() {
    return (_store.read<List<dynamic>>(_entriesKey) ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (entry) => MeshRouteLedgerEntry.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  Future<void> _writeEntries(List<MeshRouteLedgerEntry> entries) {
    return _store.write(
      _entriesKey,
      entries.map((entry) => entry.toJson()).toList(),
    );
  }
}

class _RankedMeshPeer {
  const _RankedMeshPeer({
    required this.peerId,
    required this.score,
    required this.liveProximityScore,
  });

  final String peerId;
  final double score;
  final double liveProximityScore;
}

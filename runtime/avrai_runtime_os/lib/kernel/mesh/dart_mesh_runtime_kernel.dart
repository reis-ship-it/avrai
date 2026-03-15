import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';

class DartMeshRuntimeKernel extends MeshKernelFallbackSurface {
  DartMeshRuntimeKernel({
    required MeshRouteLedger routeLedger,
    MeshCustodyOutbox? custodyOutbox,
    MeshAnnounceLedger? announceLedger,
    MeshInterfaceRegistry? interfaceRegistry,
    MeshRuntimeStateFrameService? stateFrameService,
    DateTime Function()? nowUtc,
    Map<String, MeshKernelSnapshot>? seededSnapshots,
  })  : _routeLedger = routeLedger,
        _custodyOutbox = custodyOutbox,
        _announceLedger = announceLedger,
        _interfaceRegistry = interfaceRegistry,
        _stateFrameService =
            stateFrameService ?? const MeshRuntimeStateFrameService(),
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _snapshots = seededSnapshots ?? <String, MeshKernelSnapshot>{};

  final MeshRouteLedger _routeLedger;
  final MeshCustodyOutbox? _custodyOutbox;
  final MeshAnnounceLedger? _announceLedger;
  final MeshInterfaceRegistry? _interfaceRegistry;
  final MeshRuntimeStateFrameService _stateFrameService;
  final DateTime Function() _nowUtc;
  final Map<String, MeshKernelSnapshot> _snapshots;

  @override
  Future<MeshTransportPlan> planTransport(
    MeshRoutePlanningRequest request,
  ) async {
    final legacyPlan = await planMesh(request);
    return legacyPlan.toTransportPlan();
  }

  @override
  Future<MeshTransportReceipt> commitTransport(
    MeshTransportCommit request,
  ) async {
    final legacyReceipt = await commitMesh(request.toLegacyCommitRequest());
    return legacyReceipt.toTransportReceipt(
      subjectId: request.plan.destinationId,
    );
  }

  @override
  Future<MeshTransportReceipt> observeTransport(
    MeshObservation observation,
  ) async {
    final legacyReceipt = await observeMesh(observation);
    return legacyReceipt.toTransportReceipt(subjectId: observation.subjectId);
  }

  @override
  MeshTransportSnapshot? snapshotTransport(String subjectId) {
    return snapshotMesh(subjectId)?.toTransportSnapshot();
  }

  @override
  Future<MeshRoutePlan> planMesh(MeshRoutePlanningRequest request) async {
    final now = _nowUtc();
    final routeReceipt = request.routeReceipt ??
        _buildRouteReceiptFromLedger(
          planningId: request.planningId,
          destinationId: request.destinationId,
          geographicScope:
              request.runtimeContext['geographic_scope']?.toString(),
          nowUtc: now,
        );
    final hasRoutes = routeReceipt.plannedRoutes.isNotEmpty;
    final queued = !hasRoutes && request.storeCarryForwardAllowed;
    final allowed = !_isQuarantined(routeReceipt);
    final lifecycleState = !allowed
        ? MeshLifecycleState.failed
        : queued
            ? MeshLifecycleState.queued
            : MeshLifecycleState.planned;
    final reason = !allowed
        ? 'mesh_route_quarantined'
        : queued
            ? 'awaiting_custody_release'
            : (routeReceipt.metadata['mesh_route_resolution_mode']
                    ?.toString() ??
                'mesh_candidates_available');
    final snapshot = _snapshotFromRouteReceipt(
      subjectId: request.planningId,
      destinationId: request.destinationId,
      lifecycleState: lifecycleState,
      routeReceipt: routeReceipt,
      nowUtc: now,
      diagnostics: <String, dynamic>{
        'planning_id': request.planningId,
        'allowed': allowed,
        'store_carry_forward_allowed': request.storeCarryForwardAllowed,
        'reason': reason,
      },
    );
    _storeSnapshot(snapshot);
    return MeshRoutePlan(
      planningId: request.planningId,
      destinationId: request.destinationId,
      plannedAtUtc: now,
      lifecycleState: lifecycleState,
      allowed: allowed,
      queued: queued,
      reason: reason,
      routeReceipt: routeReceipt,
      context: <String, dynamic>{
        ...request.runtimeContext,
        'queue_depth': snapshot.queueDepth,
        'known_route_count':
            _routeLedger.knownRouteCount(request.destinationId),
      },
    );
  }

  @override
  Future<MeshCommitReceipt> commitMesh(MeshCommitRequest request) async {
    final now = _nowUtc();
    final plan = request.plan;
    final routeReceipt = plan.routeReceipt;
    final lifecycleState = !plan.allowed
        ? MeshLifecycleState.failed
        : plan.queued
            ? MeshLifecycleState.queued
            : switch (routeReceipt?.lifecycleStage) {
                TransportReceiptLifecycleStage.custodyAccepted =>
                  MeshLifecycleState.custodyAccepted,
                TransportReceiptLifecycleStage.delivered =>
                  MeshLifecycleState.delivered,
                TransportReceiptLifecycleStage.failed =>
                  MeshLifecycleState.failed,
                TransportReceiptLifecycleStage.queued =>
                  MeshLifecycleState.queued,
                _ => MeshLifecycleState.forwarded,
              };
    final snapshot = _snapshotFromRouteReceipt(
      subjectId: request.attemptId,
      destinationId: plan.destinationId,
      lifecycleState: lifecycleState,
      routeReceipt: routeReceipt,
      nowUtc: now,
      diagnostics: <String, dynamic>{
        'attempt_id': request.attemptId,
        ...request.commitContext,
      },
    );
    _storeSnapshot(snapshot);
    return MeshCommitReceipt(
      attemptId: request.attemptId,
      lifecycleState: lifecycleState,
      committedAtUtc: now,
      routeReceipt: routeReceipt,
      context: <String, dynamic>{
        ...request.commitContext,
        'queue_depth': snapshot.queueDepth,
      },
    );
  }

  @override
  Future<MeshObservationReceipt> observeMesh(
      MeshObservation observation) async {
    final now = _nowUtc();
    final snapshot = _snapshotFromRouteReceipt(
      subjectId: observation.subjectId,
      destinationId:
          observation.routeReceipt?.metadata['destination_id']?.toString() ??
              observation.subjectId,
      lifecycleState: observation.lifecycleState,
      routeReceipt: observation.routeReceipt,
      nowUtc: now,
      diagnostics: <String, dynamic>{
        'observation_id': observation.observationId,
        ...observation.outcomeContext,
      },
    );
    _storeSnapshot(snapshot);
    return MeshObservationReceipt(
      observationId: observation.observationId,
      accepted: true,
      lifecycleState: observation.lifecycleState,
      recordedAtUtc: now,
      routeReceipt: observation.routeReceipt,
      learnableTuple: <String, dynamic>{
        'subject_id': observation.subjectId,
        'destination_id': snapshot.destinationId,
        'lifecycle_state': observation.lifecycleState.name,
        'queue_depth': snapshot.queueDepth,
        'privacy_mode': observation.envelope.privacyMode,
        'policy_lineage': observation.envelope.policyRef,
      },
    );
  }

  @override
  MeshKernelSnapshot? snapshotMesh(String subjectId) {
    final existing = _snapshots[subjectId];
    if (existing != null) {
      return existing;
    }
    return _snapshotFromCurrentState(subjectId);
  }

  @override
  Future<List<MeshReplayRecord>> replayMesh(KernelReplayRequest request) async {
    final snapshot = snapshotMesh(request.subjectId);
    if (snapshot == null) {
      return const <MeshReplayRecord>[];
    }
    final records = <MeshReplayRecord>[
      MeshReplayRecord(
        recordId: 'mesh:${request.subjectId}:snapshot',
        subjectId: request.subjectId,
        occurredAtUtc: snapshot.savedAtUtc,
        lifecycleState: snapshot.lifecycleState,
        summary: 'Mesh snapshot replay for ${snapshot.destinationId}',
        routeReceipt: snapshot.routeReceipt,
        payload: snapshot.toJson(),
      ),
    ];
    for (final entry in _routeLedger
        .entriesForDestination(snapshot.destinationId)
        .take(request.limit.saturatingSub(1))) {
      records.add(
        MeshReplayRecord(
          recordId: 'mesh:${snapshot.destinationId}:${entry.peerId}',
          subjectId: snapshot.destinationId,
          occurredAtUtc: entry.updatedAtUtc,
          lifecycleState: entry.failureCount > entry.successCount
              ? MeshLifecycleState.failed
              : MeshLifecycleState.forwarded,
          summary: 'Mesh route evidence via ${entry.peerId}',
          payload: entry.toJson(),
        ),
      );
    }
    return records;
  }

  @override
  Future<MeshRecoveryReport> recoverMesh(KernelRecoveryRequest request) async {
    final now = _nowUtc();
    final persistedSnapshot = request.persistedEnvelope == null
        ? null
        : MeshKernelSnapshot(
            subjectId: request.persistedEnvelope!['subject_id'] as String? ??
                request.subjectId,
            destinationId:
                request.persistedEnvelope!['destination_id'] as String? ??
                    request.subjectId,
            lifecycleState: MeshLifecycleState.values.byName(
              request.persistedEnvelope!['lifecycle_state'] as String? ??
                  MeshLifecycleState.queued.name,
            ),
            savedAtUtc: DateTime.tryParse(
                  request.persistedEnvelope!['saved_at_utc'] as String? ?? '',
                )?.toUtc() ??
                now,
            queueDepth:
                (request.persistedEnvelope!['queue_depth'] as num?)?.toInt() ??
                    0,
            diagnostics: Map<String, dynamic>.from(
              request.persistedEnvelope!['diagnostics'] as Map? ??
                  const <String, dynamic>{},
            ),
          );
    if (persistedSnapshot != null) {
      _storeSnapshot(persistedSnapshot);
    }
    return MeshRecoveryReport(
      subjectId: request.subjectId,
      restoredCount: persistedSnapshot == null ? 0 : 1,
      droppedCount: 0,
      recoveredAtUtc: now,
      summary: persistedSnapshot == null
          ? 'no persisted mesh snapshot to recover'
          : 'mesh snapshot restored into runtime kernel',
      diagnostics: <String, dynamic>{
        'queue_depth': persistedSnapshot?.queueDepth ?? 0,
        ...request.hints,
      },
    );
  }

  @override
  Future<MeshKernelHealthSnapshot> diagnoseMesh() async {
    final frame = _stateFrameService.buildFrame(
      routeLedger: _routeLedger,
      custodyOutbox: _custodyOutbox,
      announceLedger: _announceLedger,
      interfaceRegistry: _interfaceRegistry,
    );
    final hasRoutingTruth = frame.routeDestinationCount > 0 ||
        frame.pendingCustodyCount > 0 ||
        frame.activeAnnounceCount > 0;
    final status = frame.encryptedAtRest || frame.pendingCustodyCount == 0
        ? MeshHealthStatus.healthy
        : MeshHealthStatus.degraded;
    return MeshKernelHealthSnapshot(
      kernelId: 'mesh_runtime_governance',
      status: status,
      nativeBacked: false,
      headlessReady: true,
      summary:
          'mesh runtime kernel is bound to route, announce, interface, and custody services',
      diagnostics: <String, dynamic>{
        'route_destination_count': frame.routeDestinationCount,
        'route_entry_count': frame.routeEntryCount,
        'active_announce_count': frame.activeAnnounceCount,
        'expired_announce_count': frame.expiredAnnounceCount,
        'pending_custody_count': frame.pendingCustodyCount,
        'encrypted_at_rest': frame.encryptedAtRest,
        'route_receipt_truth_present': hasRoutingTruth,
        'replay_supported': _custodyOutbox != null,
        'snapshot_supported': true,
      },
    );
  }

  MeshKernelSnapshot _snapshotFromRouteReceipt({
    required String subjectId,
    required String destinationId,
    required MeshLifecycleState lifecycleState,
    required DateTime nowUtc,
    TransportRouteReceipt? routeReceipt,
    Map<String, dynamic> diagnostics = const <String, dynamic>{},
  }) {
    return MeshKernelSnapshot(
      subjectId: subjectId,
      destinationId: destinationId,
      lifecycleState: lifecycleState,
      savedAtUtc: nowUtc,
      queueDepth:
          _custodyOutbox?.pendingCount(destinationId: destinationId) ?? 0,
      routeReceipt: routeReceipt,
      diagnostics: diagnostics,
    );
  }

  void _storeSnapshot(MeshKernelSnapshot snapshot) {
    _snapshots[snapshot.subjectId] = snapshot;
    _snapshots[snapshot.destinationId] = snapshot;
    final receiptId = snapshot.routeReceipt?.receiptId;
    if (receiptId != null && receiptId.isNotEmpty) {
      _snapshots[receiptId] = snapshot;
    }
  }

  MeshKernelSnapshot? _snapshotFromCurrentState(String subjectId) {
    final routeEntries = _routeLedger.entriesForDestination(subjectId);
    final custodyCount =
        _custodyOutbox?.pendingCount(destinationId: subjectId) ?? 0;
    if (routeEntries.isEmpty && custodyCount == 0) {
      return null;
    }
    final latestEntry = routeEntries.isEmpty
        ? null
        : (routeEntries.toList()
              ..sort((left, right) =>
                  right.updatedAtUtc.compareTo(left.updatedAtUtc)))
            .first;
    return MeshKernelSnapshot(
      subjectId: subjectId,
      destinationId: subjectId,
      lifecycleState: custodyCount > 0
          ? MeshLifecycleState.queued
          : latestEntry == null ||
                  latestEntry.failureCount > latestEntry.successCount
              ? MeshLifecycleState.failed
              : MeshLifecycleState.forwarded,
      savedAtUtc: latestEntry?.updatedAtUtc ?? _nowUtc(),
      queueDepth: custodyCount,
      diagnostics: <String, dynamic>{
        'route_entry_count': routeEntries.length,
      },
    );
  }

  TransportRouteReceipt _buildRouteReceiptFromLedger({
    required String planningId,
    required String destinationId,
    required DateTime nowUtc,
    String? geographicScope,
  }) {
    final entries = _routeLedger.entriesForDestination(
      destinationId,
      geographicScope: geographicScope,
    );
    final plannedRoutes = entries
        .map(
          (entry) => TransportRouteCandidate(
            routeId:
                '${entry.channel}:${entry.peerId}:${entry.peerNodeId ?? entry.peerId}',
            mode: _modeForChannel(entry.channel),
            confidence: entry.lastConfidence > 0.0
                ? entry.lastConfidence
                : entry.successRate,
            estimatedLatencyMs: entry.lastLatencyMs ?? 180,
            localityFit: geographicScope == null ||
                    entry.geographicScope == geographicScope
                ? 1.0
                : 0.68,
            availabilityScore: entry.scoreAt(
              nowUtc: nowUtc,
              requestedGeographicScope: geographicScope,
            ),
            rationale: 'historical_route_memory',
            metadata: <String, dynamic>{
              'peer_id': entry.peerId,
              if (entry.peerNodeId != null) 'peer_node_id': entry.peerNodeId,
              'mesh_interface_kind': entry.channel.contains('cloud')
                  ? MeshInterfaceKind.federatedCloud.name
                  : MeshInterfaceKind.ble.name,
            },
          ),
        )
        .toList();
    return TransportRouteReceipt(
      receiptId: planningId,
      channel: 'mesh_runtime_kernel',
      status: plannedRoutes.isEmpty ? 'no_candidate' : 'planned',
      recordedAtUtc: nowUtc,
      plannedRoutes: plannedRoutes,
      queuedAtUtc: nowUtc,
      metadata: <String, dynamic>{
        'destination_id': destinationId,
        'mesh_route_resolution_mode':
            plannedRoutes.isEmpty ? 'historical_fallback_none' : 'announce',
      },
    );
  }

  bool _isQuarantined(TransportRouteReceipt receipt) {
    return receipt.quarantined ||
        receipt.metadata['quarantined'] == true ||
        receipt.status == 'quarantined';
  }

  TransportMode _modeForChannel(String channel) {
    if (channel.contains('cloud')) {
      return TransportMode.cloudAssist;
    }
    if (channel.contains('wifi')) {
      return TransportMode.localWifi;
    }
    return TransportMode.ble;
  }
}

extension on int {
  int saturatingSub(int other) {
    final value = this - other;
    return value < 0 ? 0 : value;
  }
}

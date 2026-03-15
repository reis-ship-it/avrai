import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_priority.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

class NativeBackedMeshKernel extends MeshKernelContract {
  const NativeBackedMeshKernel({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const MeshNativeExecutionPolicy(),
    this.audit,
  });

  final MeshNativeInvocationBridge nativeBridge;
  final MeshKernelFallbackSurface fallback;
  final MeshNativeExecutionPolicy policy;
  final MeshNativeFallbackAudit? audit;

  Map<String, dynamic>? _invokeHandled({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (!nativeBridge.isAvailable) {
      audit?.recordFallback(MeshNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: MeshNativeFallbackReason.unavailable,
      );
      return null;
    }
    final response = nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] == true) {
      final nativePayload = response['payload'];
      if (nativePayload is Map<String, dynamic>) {
        audit?.recordNativeHandled();
        return nativePayload;
      }
    }
    audit?.recordFallback(MeshNativeFallbackReason.deferred);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: MeshNativeFallbackReason.deferred,
    );
    return null;
  }

  @override
  Future<MeshTransportPlan> planTransport(
    MeshRoutePlanningRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'plan_mesh',
      payload: request.toJson(),
    );
    final legacyPlan = payload != null
        ? MeshRoutePlan.fromJson(payload)
        : (await fallback.planTransport(request)).toLegacyRoutePlan();
    return legacyPlan.toTransportPlan();
  }

  @override
  Future<MeshTransportReceipt> commitTransport(
    MeshTransportCommit request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'commit_mesh',
      payload: <String, dynamic>{
        'attempt_id': request.attemptId,
        'plan': request.plan.toLegacyRoutePlan().toJson(),
        'envelope': request.envelope.toJson(),
        'commit_context': request.commitContext,
      },
    );
    final legacyReceipt = payload != null
        ? MeshCommitReceipt(
            attemptId: payload['attempt_id'] as String? ?? request.attemptId,
            lifecycleState: MeshLifecycleState.values.byName(
              payload['lifecycle_state'] as String? ??
                  MeshLifecycleState.failed.name,
            ),
            committedAtUtc: DateTime.tryParse(
                      payload['committed_at_utc'] as String? ?? '',
                    )?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            routeReceipt: payload['route_receipt'] is Map
                ? TransportRouteReceipt.fromJson(
                    Map<String, dynamic>.from(payload['route_receipt'] as Map),
                  )
                : null,
            context: Map<String, dynamic>.from(
              payload['context'] as Map? ?? const <String, dynamic>{},
            ),
          )
        : (await fallback.commitTransport(request)).toLegacyCommitReceipt();
    return legacyReceipt.toTransportReceipt(
      subjectId: request.plan.destinationId,
    );
  }

  @override
  Future<MeshTransportReceipt> observeTransport(
    MeshObservation observation,
  ) async {
    final payload = _invokeHandled(
      syscall: 'observe_mesh',
      payload: observation.toJson(),
    );
    final legacyReceipt = payload != null
        ? MeshObservationReceipt(
            observationId:
                payload['observation_id'] as String? ?? observation.observationId,
            accepted: payload['accepted'] as bool? ?? true,
            lifecycleState: MeshLifecycleState.values.byName(
              payload['lifecycle_state'] as String? ??
                  observation.lifecycleState.name,
            ),
            recordedAtUtc: DateTime.tryParse(
                      payload['recorded_at_utc'] as String? ?? '',
                    )?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            routeReceipt: payload['route_receipt'] is Map
                ? TransportRouteReceipt.fromJson(
                    Map<String, dynamic>.from(payload['route_receipt'] as Map),
                  )
                : null,
            learnableTuple: Map<String, dynamic>.from(
              payload['learnable_tuple'] as Map? ??
                  const <String, dynamic>{},
            ),
          )
        : (await fallback.observeTransport(observation))
            .toLegacyObservationReceipt();
    return legacyReceipt.toTransportReceipt(subjectId: observation.subjectId);
  }

  @override
  MeshTransportSnapshot? snapshotTransport(String subjectId) {
    final payload = _invokeHandled(
      syscall: 'snapshot_mesh',
      payload: <String, dynamic>{'subject_id': subjectId},
    );
    final legacySnapshot = payload != null
        ? MeshKernelSnapshot(
            subjectId: payload['subject_id'] as String? ?? subjectId,
            destinationId: payload['destination_id'] as String? ?? subjectId,
            lifecycleState: MeshLifecycleState.values.byName(
              payload['lifecycle_state'] as String? ??
                  MeshLifecycleState.queued.name,
            ),
            savedAtUtc: DateTime.tryParse(
                      payload['saved_at_utc'] as String? ?? '',
                    )?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            queueDepth: (payload['queue_depth'] as num?)?.toInt() ?? 0,
            routeReceipt: payload['route_receipt'] is Map
                ? TransportRouteReceipt.fromJson(
                    Map<String, dynamic>.from(payload['route_receipt'] as Map),
                  )
                : null,
            diagnostics: Map<String, dynamic>.from(
              payload['diagnostics'] as Map? ?? const <String, dynamic>{},
            ),
          )
        : fallback.snapshotTransport(subjectId)?.toLegacySnapshot();
    return legacySnapshot?.toTransportSnapshot();
  }

  @override
  Future<MeshRoutePlan> planMesh(MeshRoutePlanningRequest request) async {
    final payload = _invokeHandled(
      syscall: 'plan_mesh',
      payload: request.toJson(),
    );
    if (payload != null) {
      return MeshRoutePlan.fromJson(payload);
    }
    final plan = await fallback.planTransport(request);
    return plan.toLegacyRoutePlan();
  }

  @override
  Future<MeshCommitReceipt> commitMesh(MeshCommitRequest request) async {
    final payload = _invokeHandled(
      syscall: 'commit_mesh',
      payload: <String, dynamic>{
        'attempt_id': request.attemptId,
        'plan': request.plan.toJson(),
        'envelope': request.envelope.toJson(),
        'commit_context': request.commitContext,
      },
    );
    if (payload != null) {
      return MeshCommitReceipt(
        attemptId: payload['attempt_id'] as String? ?? request.attemptId,
        lifecycleState: MeshLifecycleState.values.byName(
          payload['lifecycle_state'] as String? ??
              MeshLifecycleState.failed.name,
        ),
        committedAtUtc: DateTime.tryParse(
              payload['committed_at_utc'] as String? ?? '',
            )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        routeReceipt: payload['route_receipt'] is Map
            ? TransportRouteReceipt.fromJson(
                Map<String, dynamic>.from(payload['route_receipt'] as Map),
              )
            : null,
        context: Map<String, dynamic>.from(
          payload['context'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    final receipt = await fallback.commitTransport(request.toTransportCommit());
    return receipt.toLegacyCommitReceipt();
  }

  @override
  Future<MeshObservationReceipt> observeMesh(
      MeshObservation observation) async {
    final payload = _invokeHandled(
      syscall: 'observe_mesh',
      payload: observation.toJson(),
    );
    if (payload != null) {
      return MeshObservationReceipt(
        observationId:
            payload['observation_id'] as String? ?? observation.observationId,
        accepted: payload['accepted'] as bool? ?? true,
        lifecycleState: MeshLifecycleState.values.byName(
          payload['lifecycle_state'] as String? ??
              observation.lifecycleState.name,
        ),
        recordedAtUtc: DateTime.tryParse(
              payload['recorded_at_utc'] as String? ?? '',
            )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        routeReceipt: payload['route_receipt'] is Map
            ? TransportRouteReceipt.fromJson(
                Map<String, dynamic>.from(payload['route_receipt'] as Map),
              )
            : null,
        learnableTuple: Map<String, dynamic>.from(
          payload['learnable_tuple'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    final receipt = await fallback.observeTransport(observation);
    return receipt.toLegacyObservationReceipt();
  }

  @override
  MeshKernelSnapshot? snapshotMesh(String subjectId) {
    final payload = _invokeHandled(
      syscall: 'snapshot_mesh',
      payload: <String, dynamic>{'subject_id': subjectId},
    );
    if (payload != null) {
      return MeshKernelSnapshot(
        subjectId: payload['subject_id'] as String? ?? subjectId,
        destinationId: payload['destination_id'] as String? ?? subjectId,
        lifecycleState: MeshLifecycleState.values.byName(
          payload['lifecycle_state'] as String? ??
              MeshLifecycleState.queued.name,
        ),
        savedAtUtc: DateTime.tryParse(
              payload['saved_at_utc'] as String? ?? '',
            )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        queueDepth: (payload['queue_depth'] as num?)?.toInt() ?? 0,
        routeReceipt: payload['route_receipt'] is Map
            ? TransportRouteReceipt.fromJson(
                Map<String, dynamic>.from(payload['route_receipt'] as Map),
              )
            : null,
        diagnostics: Map<String, dynamic>.from(
          payload['diagnostics'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    return fallback.snapshotTransport(subjectId)?.toLegacySnapshot();
  }

  @override
  Future<List<MeshReplayRecord>> replayMesh(KernelReplayRequest request) async {
    final payload = _invokeHandled(
      syscall: 'replay_mesh',
      payload: <String, dynamic>{
        'subject_id': request.subjectId,
        'limit': request.limit,
        if (request.sinceUtc != null)
          'since_utc': request.sinceUtc!.toUtc().toIso8601String(),
        if (request.untilUtc != null)
          'until_utc': request.untilUtc!.toUtc().toIso8601String(),
        'filters': request.filters,
      },
    );
    if (payload != null) {
      return ((payload['records'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .map(
            (entry) => MeshReplayRecord(
              recordId: entry['record_id'] as String? ?? 'mesh:unknown',
              subjectId: entry['subject_id'] as String? ?? request.subjectId,
              occurredAtUtc: DateTime.tryParse(
                    entry['occurred_at_utc'] as String? ?? '',
                  )?.toUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              lifecycleState: MeshLifecycleState.values.byName(
                entry['lifecycle_state'] as String? ??
                    MeshLifecycleState.queued.name,
              ),
              summary: entry['summary'] as String? ?? 'Mesh replay',
              routeReceipt: entry['route_receipt'] is Map
                  ? TransportRouteReceipt.fromJson(
                      Map<String, dynamic>.from(
                        entry['route_receipt'] as Map,
                      ),
                    )
                  : null,
              payload: Map<String, dynamic>.from(
                entry['payload'] as Map? ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList();
    }
    return fallback.replayMesh(request);
  }

  @override
  Future<MeshRecoveryReport> recoverMesh(KernelRecoveryRequest request) async {
    final payload = _invokeHandled(
      syscall: 'recover_mesh',
      payload: <String, dynamic>{
        'subject_id': request.subjectId,
        if (request.persistedEnvelope != null)
          'persisted_envelope': request.persistedEnvelope,
        'hints': request.hints,
      },
    );
    if (payload != null) {
      return MeshRecoveryReport(
        subjectId: payload['subject_id'] as String? ?? request.subjectId,
        restoredCount: (payload['restored_count'] as num?)?.toInt() ?? 0,
        droppedCount: (payload['dropped_count'] as num?)?.toInt() ?? 0,
        recoveredAtUtc: DateTime.tryParse(
              payload['recovered_at_utc'] as String? ?? '',
            )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        summary: payload['summary'] as String? ?? 'mesh recovery completed',
        diagnostics: Map<String, dynamic>.from(
          payload['diagnostics'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    return fallback.recoverMesh(request);
  }

  @override
  Future<MeshKernelHealthSnapshot> diagnoseMesh() async {
    final payload = _invokeHandled(
      syscall: 'diagnose_mesh_kernel',
      payload: const <String, dynamic>{},
    );
    if (payload != null) {
      return MeshKernelHealthSnapshot(
        kernelId: 'mesh_runtime_governance',
        status: MeshHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        summary: 'mesh kernel native bridge is available',
        diagnostics: <String, dynamic>{
          ...payload,
          'native_required': policy.requireNative,
          if (audit != null)
            'fallback_audit': <String, dynamic>{
              'native_handled_count': audit!.nativeHandledCount,
              'fallback_unavailable_count': audit!.fallbackUnavailableCount,
              'fallback_deferred_count': audit!.fallbackDeferredCount,
            },
        },
      );
    }
    final fallbackHealth = await fallback.diagnoseMesh();
    return MeshKernelHealthSnapshot(
      kernelId: fallbackHealth.kernelId,
      status: fallbackHealth.status,
      nativeBacked: false,
      headlessReady: fallbackHealth.headlessReady,
      summary: fallbackHealth.summary,
      diagnostics: <String, dynamic>{
        ...fallbackHealth.diagnostics,
        'native_required': policy.requireNative,
        if (audit != null)
          'fallback_audit': <String, dynamic>{
            'native_handled_count': audit!.nativeHandledCount,
            'fallback_unavailable_count': audit!.fallbackUnavailableCount,
            'fallback_deferred_count': audit!.fallbackDeferredCount,
          },
      },
    );
  }
}

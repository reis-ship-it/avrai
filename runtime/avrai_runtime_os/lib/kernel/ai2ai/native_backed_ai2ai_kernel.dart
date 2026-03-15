import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_priority.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

class NativeBackedAi2AiKernel extends Ai2AiKernelContract {
  const NativeBackedAi2AiKernel({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const Ai2AiNativeExecutionPolicy(),
    this.audit,
  });

  final Ai2AiNativeInvocationBridge nativeBridge;
  final Ai2AiKernelFallbackSurface fallback;
  final Ai2AiNativeExecutionPolicy policy;
  final Ai2AiNativeFallbackAudit? audit;

  Map<String, dynamic>? _invokeHandled({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (!nativeBridge.isAvailable) {
      audit?.recordFallback(Ai2AiNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: Ai2AiNativeFallbackReason.unavailable,
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
    audit?.recordFallback(Ai2AiNativeFallbackReason.deferred);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: Ai2AiNativeFallbackReason.deferred,
    );
    return null;
  }

  @override
  Future<Ai2AiExchangePlan> planExchange(
    Ai2AiExchangeCandidate candidate,
  ) async {
    final payload = _invokeHandled(
      syscall: 'plan_ai2ai',
      payload: candidate.toLegacyCandidate().toJson(),
    );
    final legacyPlan = payload != null
        ? Ai2AiLifecyclePlan.fromJson(payload)
        : (await fallback.planExchange(candidate)).toLegacyLifecyclePlan();
    Ai2AiRendezvousTicket? rendezvousTicket;
    if (candidate.decision != Ai2AiExchangeDecision.exchangeNow &&
        candidate.rendezvousPolicy != null) {
      rendezvousTicket = Ai2AiRendezvousTicket(
        ticketId: 'exchange-rendezvous-${candidate.exchangeId}',
        peerId: candidate.peerId,
        decision: candidate.decision,
        policy: candidate.rendezvousPolicy!,
        createdAtUtc: legacyPlan.plannedAtUtc,
        exchangeId: candidate.exchangeId,
        artifactClass: candidate.artifactClass,
        context: candidate.context,
      );
    }
    return legacyPlan.toExchangePlan(
      decision: candidate.decision,
      rendezvousTicket: rendezvousTicket,
    );
  }

  @override
  Future<Ai2AiExchangeReceipt> commitExchange(
    Ai2AiExchangeCommit request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'commit_ai2ai',
      payload: <String, dynamic>{
        'attempt_id': request.attemptId,
        'plan': request.plan.toLegacyLifecyclePlan().toJson(),
        'envelope': request.envelope.toJson(),
        'commit_context': request.commitContext,
      },
    );
    final legacyReceipt = payload != null
        ? Ai2AiCommitReceipt(
            attemptId: payload['attempt_id'] as String? ?? request.attemptId,
            lifecycleState: Ai2AiLifecycleState.values.byName(
              payload['lifecycle_state'] as String? ??
                  Ai2AiLifecycleState.failed.name,
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
        : (await fallback.commitExchange(request)).toLegacyCommitReceipt();
    return legacyReceipt.toExchangeReceipt(
      exchangeId: request.plan.exchangeId,
    );
  }

  @override
  Future<Ai2AiExchangeReceipt> observeExchange(
    Ai2AiExchangeObservation observation,
  ) async {
    final payload = _invokeHandled(
      syscall: 'observe_ai2ai',
      payload: observation.toLegacyObservation().toJson(),
    );
    final legacyReceipt = payload != null
        ? Ai2AiObservationReceipt(
            observationId:
                payload['observation_id'] as String? ?? observation.observationId,
            accepted: payload['accepted'] as bool? ?? true,
            lifecycleState: Ai2AiLifecycleState.values.byName(
              payload['lifecycle_state'] as String? ??
                  observation.lifecycleState.toLegacyLifecycleState().name,
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
        : (await fallback.observeExchange(observation))
            .toLegacyObservationReceipt();
    return legacyReceipt.toExchangeReceipt(
      exchangeId: observation.exchangeId,
    );
  }

  @override
  Ai2AiExchangeSnapshot? snapshotExchange(String subjectId) {
    final payload = _invokeHandled(
      syscall: 'snapshot_ai2ai',
      payload: <String, dynamic>{'subject_id': subjectId},
    );
    final legacySnapshot = payload != null
        ? Ai2AiKernelSnapshot(
            subjectId: payload['subject_id'] as String? ?? subjectId,
            conversationId:
                payload['conversation_id'] as String? ?? 'unknown_conversation',
            lifecycleState: Ai2AiLifecycleState.values.byName(
              payload['lifecycle_state'] as String? ??
                  Ai2AiLifecycleState.queued.name,
            ),
            savedAtUtc: DateTime.tryParse(
                      payload['saved_at_utc'] as String? ?? '',
                    )?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            payloadClass: payload['payload_class'] == null
                ? null
                : Ai2AiPayloadClass.values.byName(
                    payload['payload_class'] as String,
                  ),
            routeReceipt: payload['route_receipt'] is Map
                ? TransportRouteReceipt.fromJson(
                    Map<String, dynamic>.from(payload['route_receipt'] as Map),
                  )
                : null,
            diagnostics: Map<String, dynamic>.from(
              payload['diagnostics'] as Map? ?? const <String, dynamic>{},
            ),
          )
        : fallback.snapshotExchange(subjectId)?.toLegacySnapshot();
    return legacySnapshot?.toExchangeSnapshot();
  }

  @override
  Future<Ai2AiLifecyclePlan> planAi2Ai(Ai2AiMessageCandidate candidate) async {
    final payload = _invokeHandled(
      syscall: 'plan_ai2ai',
      payload: candidate.toJson(),
    );
    if (payload != null) {
      return Ai2AiLifecyclePlan.fromJson(payload);
    }
    final plan = await fallback.planExchange(candidate.toExchangeCandidate());
    return plan.toLegacyLifecyclePlan();
  }

  @override
  Future<Ai2AiCommitReceipt> commitAi2Ai(Ai2AiCommitRequest request) async {
    final payload = _invokeHandled(
      syscall: 'commit_ai2ai',
      payload: <String, dynamic>{
        'attempt_id': request.attemptId,
        'plan': request.plan.toJson(),
        'envelope': request.envelope.toJson(),
        'commit_context': request.commitContext,
      },
    );
    if (payload != null) {
      return Ai2AiCommitReceipt(
        attemptId: payload['attempt_id'] as String? ?? request.attemptId,
        lifecycleState: Ai2AiLifecycleState.values.byName(
          payload['lifecycle_state'] as String? ??
              Ai2AiLifecycleState.failed.name,
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
    final receipt = await fallback.commitExchange(request.toExchangeCommit());
    return receipt.toLegacyCommitReceipt();
  }

  @override
  Future<Ai2AiObservationReceipt> observeAi2Ai(
    Ai2AiObservation observation,
  ) async {
    final payload = _invokeHandled(
      syscall: 'observe_ai2ai',
      payload: observation.toJson(),
    );
    if (payload != null) {
      return Ai2AiObservationReceipt(
        observationId:
            payload['observation_id'] as String? ?? observation.observationId,
        accepted: payload['accepted'] as bool? ?? true,
        lifecycleState: Ai2AiLifecycleState.values.byName(
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
    final receipt =
        await fallback.observeExchange(observation.toExchangeObservation());
    return receipt.toLegacyObservationReceipt();
  }

  @override
  Ai2AiKernelSnapshot? snapshotAi2Ai(String subjectId) {
    final payload = _invokeHandled(
      syscall: 'snapshot_ai2ai',
      payload: <String, dynamic>{'subject_id': subjectId},
    );
    if (payload != null) {
      return Ai2AiKernelSnapshot(
        subjectId: payload['subject_id'] as String? ?? subjectId,
        conversationId:
            payload['conversation_id'] as String? ?? 'unknown_conversation',
        lifecycleState: Ai2AiLifecycleState.values.byName(
          payload['lifecycle_state'] as String? ??
              Ai2AiLifecycleState.queued.name,
        ),
        savedAtUtc: DateTime.tryParse(
                  payload['saved_at_utc'] as String? ?? '',
                )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        payloadClass: payload['payload_class'] == null
            ? null
            : Ai2AiPayloadClass.values.byName(
                payload['payload_class'] as String,
              ),
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
    return fallback.snapshotExchange(subjectId)?.toLegacySnapshot();
  }

  @override
  Future<List<Ai2AiReplayRecord>> replayAi2Ai(
    KernelReplayRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'replay_ai2ai',
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
            (entry) => Ai2AiReplayRecord(
              recordId: entry['record_id'] as String? ?? 'ai2ai:unknown',
              subjectId: entry['subject_id'] as String? ?? request.subjectId,
              occurredAtUtc: DateTime.tryParse(
                        entry['occurred_at_utc'] as String? ?? '',
                      )?.toUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              lifecycleState: Ai2AiLifecycleState.values.byName(
                entry['lifecycle_state'] as String? ??
                    Ai2AiLifecycleState.queued.name,
              ),
              summary: entry['summary'] as String? ?? 'AI2AI replay',
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
    return fallback.replayAi2Ai(request);
  }

  @override
  Future<Ai2AiRecoveryReport> recoverAi2Ai(
    KernelRecoveryRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'recover_ai2ai',
      payload: <String, dynamic>{
        'subject_id': request.subjectId,
        if (request.persistedEnvelope != null)
          'persisted_envelope': request.persistedEnvelope,
        'hints': request.hints,
      },
    );
    if (payload != null) {
      return Ai2AiRecoveryReport(
        subjectId: payload['subject_id'] as String? ?? request.subjectId,
        restoredCount: (payload['restored_count'] as num?)?.toInt() ?? 0,
        droppedCount: (payload['dropped_count'] as num?)?.toInt() ?? 0,
        recoveredAtUtc: DateTime.tryParse(
                  payload['recovered_at_utc'] as String? ?? '',
                )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        summary: payload['summary'] as String? ?? 'AI2AI recovery completed',
        diagnostics: Map<String, dynamic>.from(
          payload['diagnostics'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    return fallback.recoverAi2Ai(request);
  }

  @override
  Future<Ai2AiKernelHealthSnapshot> diagnoseAi2Ai() async {
    final payload = _invokeHandled(
      syscall: 'diagnose_ai2ai_kernel',
      payload: const <String, dynamic>{},
    );
    if (payload != null) {
      return Ai2AiKernelHealthSnapshot(
        kernelId: 'ai2ai_runtime_governance',
        status: Ai2AiHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        summary: 'AI2AI kernel native bridge is available',
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
    final fallbackHealth = await fallback.diagnoseAi2Ai();
    return Ai2AiKernelHealthSnapshot(
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

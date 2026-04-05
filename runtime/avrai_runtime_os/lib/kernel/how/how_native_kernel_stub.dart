import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_priority.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

class HowNativeKernelStub extends HowKernelContract {
  const HowNativeKernelStub({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const HowNativeExecutionPolicy(),
    this.audit,
  });

  final HowNativeInvocationBridge nativeBridge;
  final HowKernelFallbackSurface fallback;
  final HowNativeExecutionPolicy policy;
  final HowNativeFallbackAudit? audit;

  Map<String, dynamic>? _invokeHandled({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (!nativeBridge.isAvailable) {
      audit?.recordFallback(HowNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: HowNativeFallbackReason.unavailable,
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
    audit?.recordFallback(HowNativeFallbackReason.deferred);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: HowNativeFallbackReason.deferred,
    );
    return null;
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) async {
    final payload = _invokeHandled(
      syscall: 'resolve_how',
      payload: envelope.toJson(),
    );
    if (payload != null) {
      return HowKernelSnapshot.fromJson(payload);
    }
    return fallback.resolveHow(envelope);
  }

  @override
  Future<HowExecutionPlan> planHow(HowPlanningRequest request) async {
    final payload = _invokeHandled(
      syscall: 'classify_execution_path',
      payload: <String, dynamic>{
        'prediction_context': request.context,
        'runtime_context': <String, dynamic>{
          'execution_path': request.context['execution_path'],
          'workflow_stage': request.context['workflow_stage'],
        },
      },
    );
    if (payload != null) {
      return HowExecutionPlan(
        executionId: request.executionId,
        path: payload['execution_path'] as String? ?? 'native_orchestrated',
        workflowStage:
            payload['workflow_stage'] as String? ?? 'planned_execution',
        capabilityChain: ((request.context['capability_chain'] as List?) ??
                const <dynamic>['resolve', 'rank', 'respond'])
            .map((entry) => entry.toString())
            .toList(),
      );
    }
    return fallback.planHow(request);
  }

  @override
  Future<HowExecutionTrace> executeHow(HowExecutionPlan plan) async {
    final payload = _invokeHandled(
      syscall: 'execute_how',
      payload: <String, dynamic>{
        'execution_id': plan.executionId,
        'path': plan.path,
        'workflow_stage': plan.workflowStage,
        'capability_chain': plan.capabilityChain,
      },
    );
    if (payload != null) {
      return HowExecutionTrace(
        executionId: payload['execution_id'] as String? ?? plan.executionId,
        path: payload['path'] as String? ?? plan.path,
        completedAtUtc:
            DateTime.tryParse(payload['completed_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        status: payload['status'] as String? ?? 'executed',
        capabilityChain: ((payload['capability_chain'] as List?) ??
                plan.capabilityChain)
            .map((entry) => entry.toString())
            .toList(),
      );
    }
    return fallback.executeHow(plan);
  }

  @override
  Future<HowExecutionTrace> traceHow(String executionId) async {
    final payload = _invokeHandled(
      syscall: 'trace_how',
      payload: <String, dynamic>{'execution_id': executionId},
    );
    if (payload != null) {
      return HowExecutionTrace(
        executionId: payload['execution_id'] as String? ?? executionId,
        path: payload['path'] as String? ?? 'native_orchestrated',
        completedAtUtc:
            DateTime.tryParse(payload['completed_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        status: payload['status'] as String? ?? 'traced',
        capabilityChain: ((payload['capability_chain'] as List?) ??
                const <dynamic>[])
            .map((entry) => entry.toString())
            .toList(),
      );
    }
    return fallback.traceHow(executionId);
  }

  @override
  Future<HowRollbackReceipt> rollbackHow(HowRollbackRequest request) async {
    final payload = _invokeHandled(
      syscall: 'rollback_how',
      payload: <String, dynamic>{
        'execution_id': request.executionId,
        if (request.reason != null) 'reason': request.reason,
      },
    );
    if (payload != null) {
      return HowRollbackReceipt(
        executionId: payload['execution_id'] as String? ?? request.executionId,
        rolledBack: payload['rolled_back'] as bool? ?? true,
        recordedAtUtc:
            DateTime.tryParse(payload['recorded_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }
    return fallback.rollbackHow(request);
  }

  @override
  Future<HowInterventionReceipt> interveneHow(
    HowInterventionDirective directive,
  ) async {
    final payload = _invokeHandled(
      syscall: 'intervene_how',
      payload: <String, dynamic>{
        'execution_id': directive.executionId,
        'directive': directive.directive,
        if (directive.reason != null) 'reason': directive.reason,
      },
    );
    if (payload != null) {
      return HowInterventionReceipt(
        executionId: payload['execution_id'] as String? ?? directive.executionId,
        directive: payload['directive'] as String? ?? directive.directive,
        accepted: payload['accepted'] as bool? ?? true,
        recordedAtUtc:
            DateTime.tryParse(payload['recorded_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }
    return fallback.interveneHow(directive);
  }

  @override
  Future<HowKernelSnapshot?> snapshotHow(String subjectId) async {
    final payload = _invokeHandled(
      syscall: 'snapshot_how',
      payload: <String, dynamic>{'subject_id': subjectId},
    );
    if (payload != null) {
      return HowKernelSnapshot.fromJson(payload);
    }
    return fallback.snapshotHow(subjectId);
  }

  @override
  Future<List<KernelReplayRecord>> replayHow(KernelReplayRequest request) async {
    final payload = _invokeHandled(
      syscall: 'replay_how',
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
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map(
            (entry) => KernelReplayRecord(
              domain: KernelDomain.values.byName(
                entry['domain'] as String? ?? KernelDomain.how.name,
              ),
              recordId: entry['record_id'] as String? ?? 'how:unknown',
              occurredAtUtc:
                  DateTime.tryParse(entry['occurred_at_utc'] as String? ?? '')
                          ?.toUtc() ??
                      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              summary: entry['summary'] as String? ?? 'Execution replay',
              payload: Map<String, dynamic>.from(
                entry['payload'] as Map? ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList();
    }
    return fallback.replayHow(request);
  }

  @override
  Future<HowRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'project_how_reality',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ??
            request.envelope?.agentId ??
            request.envelope?.eventId ??
            'unknown_execution',
        if (request.how != null) 'snapshot': request.how!.toJson(),
      },
    );
    if (payload != null) {
      return HowRealityProjection(
        summary:
            payload['summary'] as String? ?? 'Execution projection unavailable',
        confidence: (payload['confidence'] as num?)?.toDouble() ?? 0.0,
        features: Map<String, dynamic>.from(
          payload['features'] as Map? ?? const <String, dynamic>{},
        ),
        payload: Map<String, dynamic>.from(
          payload['payload'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    return fallback.projectForRealityModel(request);
  }

  @override
  Future<KernelHealthReport> diagnoseHow() async {
    final payload = _invokeHandled(
      syscall: 'diagnose_how_kernel',
      payload: const <String, dynamic>{},
    );
    if (payload != null) {
      return KernelHealthReport(
        domain: KernelDomain.how,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'how kernel native bridge is available',
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
    return fallback.diagnoseHow();
  }

  @override
  Future<KernelGovernanceProjection> projectForGovernance(
    KernelProjectionRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'project_how_governance',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ??
            request.envelope?.agentId ??
            request.envelope?.eventId ??
            'unknown_execution',
        if (request.how != null) 'snapshot': request.how!.toJson(),
      },
    );
    if (payload != null) {
      return KernelGovernanceProjection(
        domain: KernelDomain.values.byName(
          payload['domain'] as String? ?? KernelDomain.how.name,
        ),
        summary:
            payload['summary'] as String? ?? 'Governance execution view',
        confidence: (payload['confidence'] as num?)?.toDouble() ?? 0.0,
        highlights: ((payload['highlights'] as List?) ?? const <dynamic>[])
            .map((entry) => entry.toString())
            .toList(),
        payload: Map<String, dynamic>.from(
          payload['payload'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }
    return fallback.projectForGovernance(request);
  }
}

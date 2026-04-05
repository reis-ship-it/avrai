import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_priority.dart';

class WhyNativeKernelStub extends WhyKernelContract {
  const WhyNativeKernelStub({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const WhyNativeExecutionPolicy(),
    this.audit,
  });

  final WhyNativeInvocationBridge nativeBridge;
  final WhyKernelFallbackSurface fallback;
  final WhyNativeExecutionPolicy policy;
  final WhyNativeFallbackAudit? audit;

  Map<String, dynamic>? _invokeHandled({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (!nativeBridge.isAvailable) {
      audit?.recordFallback(WhyNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhyNativeFallbackReason.unavailable,
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
    audit?.recordFallback(WhyNativeFallbackReason.deferred);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: WhyNativeFallbackReason.deferred,
    );
    return null;
  }

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    final payload = _invokeHandled(
      syscall: 'explain_why',
      payload: request.toJson(),
    );
    if (payload != null) {
      return WhyKernelSnapshot.fromJson(payload);
    }
    return fallback.explainWhy(request);
  }

  @override
  WhyConviction convictionWhy(KernelWhyRequest request) {
    final payload = _invokeHandled(
      syscall: 'conviction_why',
      payload: request.toJson(),
    );
    if (payload != null) {
      return WhyConviction(
        goal: payload['goal'] as String? ?? request.goal ?? 'explain_outcome',
        convictionTier: payload['conviction_tier'] as String? ?? 'medium',
        confidence: (payload['confidence'] as num?)?.toDouble() ?? 0.0,
        summary:
            payload['summary'] as String? ?? 'No causal attribution available.',
      );
    }
    return fallback.convictionWhy(request);
  }

  @override
  WhyCounterfactual counterfactualWhy(WhyCounterfactualRequest request) {
    final payload = _invokeHandled(
      syscall: 'counterfactual_why',
      payload: <String, dynamic>{
        'request': request.request.toJson(),
        'condition': request.condition,
      },
    );
    if (payload != null) {
      return WhyCounterfactual.fromJson(payload);
    }
    return fallback.counterfactualWhy(request);
  }

  @override
  WhyAnomalyInterpretation anomalyWhy(KernelWhyRequest request) {
    final payload = _invokeHandled(
      syscall: 'anomaly_why',
      payload: request.toJson(),
    );
    if (payload != null) {
      return WhyAnomalyInterpretation(
        anomalous: payload['anomalous'] as bool? ?? false,
        summary: payload['summary'] as String? ??
            'why kernel did not detect abnormal reasoning',
        severity: payload['severity'] as String? ?? 'none',
      );
    }
    return fallback.anomalyWhy(request);
  }

  @override
  Future<WhyKernelSnapshot> snapshotWhy(String goalId) async {
    final payload = _invokeHandled(
      syscall: 'snapshot_why',
      payload: <String, dynamic>{'goal_id': goalId},
    );
    if (payload != null) {
      return WhyKernelSnapshot.fromJson(payload);
    }
    return fallback.snapshotWhy(goalId);
  }

  @override
  Future<List<KernelReplayRecord>> replayWhy(KernelReplayRequest request) async {
    final payload = _invokeHandled(
      syscall: 'replay_why',
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
                entry['domain'] as String? ?? KernelDomain.why.name,
              ),
              recordId: entry['record_id'] as String? ?? 'why:unknown',
              occurredAtUtc:
                  DateTime.tryParse(entry['occurred_at_utc'] as String? ?? '')
                          ?.toUtc() ??
                      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              summary: entry['summary'] as String? ?? 'Reasoning replay',
              payload: Map<String, dynamic>.from(
                entry['payload'] as Map? ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList();
    }
    return fallback.replayWhy(request);
  }

  @override
  Future<KernelRecoveryReport> recoverWhy(KernelRecoveryRequest request) async {
    final payload = _invokeHandled(
      syscall: 'recover_why',
      payload: <String, dynamic>{
        'subject_id': request.subjectId,
        if (request.persistedEnvelope != null)
          'persisted_envelope': request.persistedEnvelope,
        'hints': request.hints,
      },
    );
    if (payload != null) {
      return KernelRecoveryReport(
        domain: KernelDomain.values.byName(
          payload['domain'] as String? ?? KernelDomain.why.name,
        ),
        subjectId: payload['subject_id'] as String? ?? request.subjectId,
        restoredCount: (payload['restored_count'] as num?)?.toInt() ?? 0,
        droppedCount: (payload['dropped_count'] as num?)?.toInt() ?? 0,
        recoveredAtUtc:
            DateTime.tryParse(payload['recovered_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        summary: payload['summary'] as String? ?? 'why recovery completed',
      );
    }
    return fallback.recoverWhy(request);
  }

  @override
  Future<WhyRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'project_why_reality',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ?? request.summaryFocus ?? 'why',
        if (request.why != null) 'snapshot': request.why!.toJson(),
      },
    );
    if (payload != null) {
      return WhyRealityProjection(
        summary: payload['summary'] as String? ?? 'Reasoning unavailable',
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
  Future<KernelGovernanceProjection> projectForGovernance(
    KernelProjectionRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'project_why_governance',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ?? request.summaryFocus ?? 'why',
        if (request.why != null) 'snapshot': request.why!.toJson(),
      },
    );
    if (payload != null) {
      return KernelGovernanceProjection(
        domain: KernelDomain.values.byName(
          payload['domain'] as String? ?? KernelDomain.why.name,
        ),
        summary: payload['summary'] as String? ?? 'Governance reasoning view',
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

  @override
  Future<KernelHealthReport> diagnoseWhy() async {
    final payload = _invokeHandled(
      syscall: 'diagnose_why_kernel',
      payload: const <String, dynamic>{},
    );
    if (payload != null) {
      return KernelHealthReport(
        domain: KernelDomain.why,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'why kernel native bridge is available',
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
    return fallback.diagnoseWhy();
  }
}

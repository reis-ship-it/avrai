import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_priority.dart';

class WhoNativeKernelStub extends WhoKernelContract {
  const WhoNativeKernelStub({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const WhoNativeExecutionPolicy(),
    this.audit,
  });

  final WhoNativeInvocationBridge nativeBridge;
  final WhoKernelFallbackSurface fallback;
  final WhoNativeExecutionPolicy policy;
  final WhoNativeFallbackAudit? audit;

  Map<String, dynamic>? _invokeHandled({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (!nativeBridge.isAvailable) {
      audit?.recordFallback(WhoNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhoNativeFallbackReason.unavailable,
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
    audit?.recordFallback(WhoNativeFallbackReason.deferred);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: WhoNativeFallbackReason.deferred,
    );
    return null;
  }

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) async {
    final payload = _invokeHandled(
      syscall: 'resolve_who',
      payload: envelope.toJson(),
    );
    if (payload != null) {
      return WhoKernelSnapshot.fromJson(payload);
    }
    return fallback.resolveWho(envelope);
  }

  @override
  Future<WhoRuntimeBindingReceipt> bindRuntime(
    WhoRuntimeBindingRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'bind_runtime',
      payload: request.toJson(),
    );
    if (payload != null) {
      return WhoRuntimeBindingReceipt(
        runtimeId: payload['runtime_id'] as String? ?? request.runtimeId,
        actorId: payload['actor_id'] as String? ?? request.actorId,
        boundAtUtc:
            DateTime.tryParse(payload['bound_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        continuityRef: payload['continuity_ref'] as String? ??
            'who:${request.actorId}:${request.runtimeId}',
      );
    }
    return fallback.bindRuntime(request);
  }

  @override
  Future<WhoSignatureRecord> sign(WhoSigningRequest request) async {
    final payload = _invokeHandled(
      syscall: 'sign_who',
      payload: <String, dynamic>{
        'actor_id': request.actorId,
        'payload': request.payload,
        'algorithm': request.algorithm,
      },
    );
    if (payload != null) {
      return WhoSignatureRecord(
        actorId: payload['actor_id'] as String? ?? request.actorId,
        algorithm: payload['algorithm'] as String? ?? request.algorithm,
        signature: payload['signature'] as String? ?? '',
        issuedAtUtc:
            DateTime.tryParse(payload['issued_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }
    return fallback.sign(request);
  }

  @override
  Future<WhoVerificationResult> verify(WhoVerificationRequest request) async {
    final payload = _invokeHandled(
      syscall: 'verify_who',
      payload: <String, dynamic>{
        'actor_id': request.actorId,
        'payload': request.payload,
        'signature': request.signature,
        'algorithm': request.algorithm,
      },
    );
    if (payload != null) {
      return WhoVerificationResult(
        valid: payload['valid'] as bool? ?? false,
        reason: payload['reason'] as String? ?? 'signature_mismatch',
      );
    }
    return fallback.verify(request);
  }

  @override
  Future<WhoKernelSnapshot?> snapshotWho(String actorId) async {
    final payload = _invokeHandled(
      syscall: 'snapshot_who',
      payload: <String, dynamic>{'subject_id': actorId},
    );
    if (payload != null) {
      return WhoKernelSnapshot.fromJson(payload);
    }
    return fallback.snapshotWho(actorId);
  }

  @override
  Future<List<KernelReplayRecord>> replayWho(KernelReplayRequest request) async {
    final payload = _invokeHandled(
      syscall: 'replay_who',
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
                entry['domain'] as String? ?? KernelDomain.who.name,
              ),
              recordId: entry['record_id'] as String? ?? 'who:unknown',
              occurredAtUtc:
                  DateTime.tryParse(entry['occurred_at_utc'] as String? ?? '')
                          ?.toUtc() ??
                      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              summary: entry['summary'] as String? ?? 'Identity replay',
              payload: Map<String, dynamic>.from(
                entry['payload'] as Map? ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList();
    }
    return fallback.replayWho(request);
  }

  @override
  Future<KernelRecoveryReport> recoverWho(KernelRecoveryRequest request) async {
    final payload = _invokeHandled(
      syscall: 'recover_who',
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
          payload['domain'] as String? ?? KernelDomain.who.name,
        ),
        subjectId: payload['subject_id'] as String? ?? request.subjectId,
        restoredCount: (payload['restored_count'] as num?)?.toInt() ?? 0,
        droppedCount: (payload['dropped_count'] as num?)?.toInt() ?? 0,
        recoveredAtUtc:
            DateTime.tryParse(payload['recovered_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        summary: payload['summary'] as String? ?? 'who recovery completed',
      );
    }
    return fallback.recoverWho(request);
  }

  @override
  Future<WhoRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'project_who_reality',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ??
            request.envelope?.agentId ??
            request.envelope?.userId ??
            'unknown_actor',
        if (request.who != null) 'snapshot': request.who!.toJson(),
      },
    );
    if (payload != null) {
      return WhoRealityProjection(
        summary: payload['summary'] as String? ?? 'Identity projection unavailable',
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
      syscall: 'project_who_governance',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ??
            request.envelope?.agentId ??
            request.envelope?.userId ??
            'unknown_actor',
        if (request.who != null) 'snapshot': request.who!.toJson(),
      },
    );
    if (payload != null) {
      return KernelGovernanceProjection(
        domain: KernelDomain.values.byName(
          payload['domain'] as String? ?? KernelDomain.who.name,
        ),
        summary: payload['summary'] as String? ?? 'Governance identity view',
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
  Future<KernelHealthReport> diagnoseWho() async {
    final payload = _invokeHandled(
      syscall: 'diagnose_who_kernel',
      payload: const <String, dynamic>{},
    );
    if (payload != null) {
      return KernelHealthReport(
        domain: KernelDomain.who,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'who kernel native bridge is available',
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
    return fallback.diagnoseWho();
  }
}

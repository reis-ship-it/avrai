import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';

class WhenNativeKernelStub extends WhenKernelContract {
  const WhenNativeKernelStub({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const WhenNativeExecutionPolicy(),
    this.audit,
  });

  final WhenNativeInvocationBridge nativeBridge;
  final WhenKernelFallbackSurface fallback;
  final WhenNativeExecutionPolicy policy;
  final WhenNativeFallbackAudit? audit;

  Map<String, dynamic>? _invokeHandled({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (!nativeBridge.isAvailable) {
      audit?.recordFallback(WhenNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhenNativeFallbackReason.unavailable,
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
    audit?.recordFallback(WhenNativeFallbackReason.deferred);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: WhenNativeFallbackReason.deferred,
    );
    return null;
  }

  DateTime _parseReferenceTime(
    Map<String, dynamic>? instant, {
    required DateTime fallbackTime,
  }) {
    return DateTime.tryParse(instant?['referenceTime'] as String? ?? '')
            ?.toUtc() ??
        fallbackTime.toUtc();
  }

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    final payload = _invokeHandled(
      syscall: 'now',
      payload: envelope.toJson(),
    );
    if (payload != null) {
      final instant = Map<String, dynamic>.from(
        payload['instant'] as Map? ?? const <String, dynamic>{},
      );
      final observedAt = _parseReferenceTime(
        instant,
        fallbackTime: envelope.occurredAtUtc,
      );
      return WhenKernelSnapshot(
        observedAt: observedAt,
        effectiveAt: envelope.occurredAtUtc.toUtc(),
        expiresAt: envelope.occurredAtUtc.toUtc().add(
              const Duration(hours: 4),
            ),
        freshness: 1.0,
        cadence: envelope.context['cadence'] as String?,
        recencyBucket: 'immediate',
        timingConflictFlags: const <String>[],
        temporalConfidence: 0.94,
      );
    }
    return fallback.resolveWhen(envelope);
  }

  @override
  Future<WhenTimestamp> issueTimestamp(WhenTimestampRequest request) async {
    final payload = _invokeHandled(
      syscall: 'now',
      payload: <String, dynamic>{
        'referenceId': request.referenceId,
        'occurred_at_utc': request.occurredAtUtc.toUtc().toIso8601String(),
        'runtime_id': request.runtimeId,
        'context': request.context,
      },
    );
    if (payload != null) {
      final instant = Map<String, dynamic>.from(
        payload['instant'] as Map? ?? const <String, dynamic>{},
      );
      final observedAt = _parseReferenceTime(
        instant,
        fallbackTime: request.occurredAtUtc,
      );
      return WhenTimestamp(
        referenceId: request.referenceId,
        observedAtUtc: observedAt,
        quantumAtomicTick: observedAt.microsecondsSinceEpoch,
        confidence: 0.95,
      );
    }
    return fallback.issueTimestamp(request);
  }

  @override
  Future<WhenComparisonResult> compareWhen(
    WhenTimestamp left,
    WhenTimestamp right,
  ) async {
    final payload = _invokeHandled(
      syscall: 'compare_when',
      payload: <String, dynamic>{
        'left': left.toJson(),
        'right': right.toJson(),
      },
    );
    if (payload != null) {
      return WhenComparisonResult(
        orderedAscending: (payload['ordered_ascending'] as bool?) ??
            ((payload['relation'] as String?) != 'after'),
        deltaMs: (payload['delta_ms'] as num?)?.toInt() ??
            (((payload['deltaMicros'] as num?)?.toInt() ?? 0) ~/ 1000),
      );
    }
    return fallback.compareWhen(left, right);
  }

  @override
  Future<WhenValidationResult> validateWhen(WhenValidityWindow window) async {
    final payload = _invokeHandled(
      syscall: 'validate_window',
      payload: <String, dynamic>{
        'timestamp': window.timestamp.toJson(),
        if (window.effectiveAtUtc != null)
          'effective_at_utc': window.effectiveAtUtc!.toUtc().toIso8601String(),
        if (window.expiresAtUtc != null)
          'expires_at_utc': window.expiresAtUtc!.toUtc().toIso8601String(),
        'allowed_drift_ms': window.allowedDriftMs,
      },
    );
    if (payload != null) {
      return WhenValidationResult(
        valid: payload['valid'] as bool? ?? false,
        reason: payload['reason'] as String? ?? 'unknown_validation_state',
        observedDriftMs: (payload['observed_drift_ms'] as num?)?.toInt() ??
            (payload['observedDriftMs'] as num?)?.toInt() ??
            0,
      );
    }
    return fallback.validateWhen(window);
  }

  @override
  Future<WhenKernelSnapshot?> snapshotWhen(String subjectId) async {
    final payload = _invokeHandled(
      syscall: 'snapshot_when',
      payload: <String, dynamic>{'subject_id': subjectId},
    );
    if (payload != null) {
      return WhenKernelSnapshot.fromJson(payload);
    }
    return fallback.snapshotWhen(subjectId);
  }

  @override
  Future<List<KernelReplayRecord>> replayWhen(KernelReplayRequest request) async {
    final payload = _invokeHandled(
      syscall: 'replay_when',
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
                entry['domain'] as String? ?? KernelDomain.when.name,
              ),
              recordId: entry['record_id'] as String? ?? 'when:unknown',
              occurredAtUtc:
                  DateTime.tryParse(entry['occurred_at_utc'] as String? ?? '')
                          ?.toUtc() ??
                      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              summary: entry['summary'] as String? ?? 'Temporal replay',
              payload: Map<String, dynamic>.from(
                entry['payload'] as Map? ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList();
    }
    return fallback.replayWhen(request);
  }

  @override
  Future<WhenReconciliationResult> reconcileWhen(
    List<WhenTimestamp> timestamps,
  ) async {
    final payload = _invokeHandled(
      syscall: 'reconcile_timestamps',
      payload: <String, dynamic>{
        'timestamps': timestamps.map((entry) => entry.toJson()).toList(),
      },
    );
    if (payload != null) {
      final canonical = Map<String, dynamic>.from(
        payload['canonical_timestamp'] as Map? ?? const <String, dynamic>{},
      );
      return WhenReconciliationResult(
        canonicalTimestamp: WhenTimestamp(
          referenceId: canonical['reference_id'] as String? ?? 'when:bootstrap',
          observedAtUtc:
              DateTime.tryParse(canonical['observed_at_utc'] as String? ?? '')
                      ?.toUtc() ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          quantumAtomicTick:
              (canonical['quantum_atomic_tick'] as num?)?.toInt() ?? 0,
          confidence: (canonical['confidence'] as num?)?.toDouble() ?? 0.0,
        ),
        conflictCount: (payload['conflict_count'] as num?)?.toInt() ?? 0,
        summary: payload['summary'] as String? ?? 'no reconciliation required',
      );
    }
    return fallback.reconcileWhen(timestamps);
  }

  @override
  Future<WhenEventRecord> recordRuntimeEvent(WhenEventRecord record) async {
    final payload = _invokeHandled(
      syscall: 'record_when_event',
      payload: record.toJson(),
    );
    if (payload != null) {
      return WhenEventRecord(
        eventId: payload['event_id'] as String? ?? record.eventId,
        runtimeId: payload['runtime_id'] as String? ?? record.runtimeId,
        occurredAtUtc:
            DateTime.tryParse(payload['occurred_at_utc'] as String? ?? '')
                    ?.toUtc() ??
                record.occurredAtUtc,
        stratum: payload['stratum'] as String? ?? record.stratum,
        payload: Map<String, dynamic>.from(
          payload['payload'] as Map? ?? record.payload,
        ),
      );
    }
    return fallback.recordRuntimeEvent(record);
  }

  @override
  Future<List<WhenEventRecord>> queryRuntimeEvents(
    KernelReplayRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'query_when_events',
      payload: <String, dynamic>{
        'runtime_id': request.subjectId,
        'limit': request.limit,
        'filters': request.filters,
      },
    );
    if (payload != null) {
      return ((payload['events'] as List?) ?? const <dynamic>[])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map(
            (entry) => WhenEventRecord(
              eventId: entry['event_id'] as String? ?? 'unknown_event',
              runtimeId: entry['runtime_id'] as String? ?? request.subjectId,
              occurredAtUtc: DateTime.tryParse(
                    entry['occurred_at_utc'] as String? ?? '',
                  )?.toUtc() ??
                  DateTime.now().toUtc(),
              stratum: entry['stratum'] as String? ?? 'personal',
              payload: Map<String, dynamic>.from(
                entry['payload'] as Map? ?? const <String, dynamic>{},
              ),
            ),
          )
          .toList();
    }
    return fallback.queryRuntimeEvents(request);
  }

  @override
  Future<WhenRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final payload = _invokeHandled(
      syscall: 'project_when_reality',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ??
            request.envelope?.agentId ??
            request.envelope?.eventId ??
            'unknown_runtime',
        if (request.when != null) 'snapshot': request.when!.toJson(),
      },
    );
    if (payload != null) {
      return WhenRealityProjection(
        summary: payload['summary'] as String? ?? 'Temporal ordering unavailable',
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
      syscall: 'project_when_governance',
      payload: <String, dynamic>{
        'subject_id': request.subjectId ??
            request.envelope?.agentId ??
            request.envelope?.eventId ??
            'runtime',
        if (request.when != null) 'snapshot': request.when!.toJson(),
      },
    );
    if (payload != null) {
      return KernelGovernanceProjection(
        domain: KernelDomain.values.byName(
          payload['domain'] as String? ?? KernelDomain.when.name,
        ),
        summary: payload['summary'] as String? ?? 'Temporal governance view',
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
  Future<KernelHealthReport> diagnoseWhen() async {
    final payload = _invokeHandled(
      syscall: 'snapshot',
      payload: const <String, dynamic>{},
    );
    if (payload != null) {
      return KernelHealthReport(
        domain: KernelDomain.when,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'when kernel native bridge is available',
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
    return fallback.diagnoseWhen();
  }
}

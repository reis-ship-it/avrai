import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';

class NativeBackedTemporalKernel implements TemporalKernel {
  NativeBackedTemporalKernel({
    required WhenNativeInvocationBridge nativeBridge,
    required SystemTemporalKernel fallbackKernel,
    WhenNativeExecutionPolicy? policy,
    WhenNativeFallbackAudit? audit,
  })  : _nativeBridge = nativeBridge,
        _fallbackKernel = fallbackKernel,
        _policy = policy ?? const WhenNativeExecutionPolicy(),
        _audit = audit;

  final WhenNativeInvocationBridge _nativeBridge;
  final SystemTemporalKernel _fallbackKernel;
  final WhenNativeExecutionPolicy _policy;
  final WhenNativeFallbackAudit? _audit;

  @override
  Future<TemporalOrderingResult> compare(
    TemporalSnapshot left,
    TemporalSnapshot right,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'compare',
      payload: {
        'left': left.toJson(),
        'right': right.toJson(),
      },
    );
    if (payload == null) {
      return _fallbackKernel.compare(left, right);
    }
    final ordering = Map<String, dynamic>.from(
      payload['ordering'] as Map? ?? const {},
    );
    return TemporalOrderingResult(
      relation: TemporalOrderingRelation.values.firstWhere(
        (value) => value.name == ordering['relation'],
        orElse: () => TemporalOrderingRelation.incomparable,
      ),
      delta: Duration(
        microseconds: (ordering['deltaMicros'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  Future<TemporalFreshnessResult> freshnessOf(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'freshness_of',
      payload: {
        'snapshot': snapshot.toJson(),
        'policy': policy.toJson(),
      },
    );
    if (payload == null) {
      return _fallbackKernel.freshnessOf(snapshot, policy);
    }
    final freshness = Map<String, dynamic>.from(
      payload['freshness'] as Map? ?? const {},
    );
    return TemporalFreshnessResult(
      age: Duration(
        microseconds: (freshness['ageMicros'] as num?)?.toInt() ?? 0,
      ),
      isFresh: freshness['isFresh'] as bool? ?? false,
      isFromFuture: freshness['isFromFuture'] as bool? ?? false,
    );
  }

  @override
  Future<bool> isExpired(
    TemporalSnapshot snapshot,
    TemporalFreshnessPolicy policy,
  ) {
    return _fallbackKernel.isExpired(snapshot, policy);
  }

  @override
  Future<HistoricalTemporalEvidenceReceipt> recordHistoricalEvidence(
    HistoricalTemporalEvidence evidence,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'record_historical_evidence',
      payload: {
        'evidence': evidence.toJson(),
      },
    );
    if (payload == null) {
      return _fallbackKernel.recordHistoricalEvidence(evidence);
    }
    return HistoricalTemporalEvidenceReceipt(
      evidenceId: payload['evidenceId'] as String? ?? evidence.evidenceId,
      recordedAt: _instantFromPayload(payload),
    );
  }

  @override
  Future<ForecastTemporalClaimReceipt> recordForecast(
    ForecastTemporalClaim claim,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'record_forecast',
      payload: {
        'claim': claim.toJson(),
      },
    );
    if (payload == null) {
      return _fallbackKernel.recordForecast(claim);
    }
    return ForecastTemporalClaimReceipt(
      claimId: payload['claimId'] as String? ?? claim.claimId,
      recordedAt: _instantFromPayload(payload),
    );
  }

  @override
  Future<HistoricalTemporalEvidenceLookup?> getHistoricalEvidence(
    String evidenceId,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'get_historical_evidence',
      payload: {'evidenceId': evidenceId},
    );
    if (payload == null) {
      return _fallbackKernel.getHistoricalEvidence(evidenceId);
    }
    if (payload['found'] != true) {
      return null;
    }
    return HistoricalTemporalEvidenceLookup(
      evidence: HistoricalTemporalEvidence.fromJson(
        Map<String, dynamic>.from(payload['evidence'] as Map? ?? const {}),
      ),
      recordedAt: _instantFromPayload(payload),
    );
  }

  @override
  Future<ForecastTemporalClaimLookup?> getForecast(String claimId) async {
    final payload = _nativePayloadOrNull(
      syscall: 'get_forecast',
      payload: {'claimId': claimId},
    );
    if (payload == null) {
      return _fallbackKernel.getForecast(claimId);
    }
    if (payload['found'] != true) {
      return null;
    }
    return ForecastTemporalClaimLookup(
      claim: ForecastTemporalClaim.fromJson(
        Map<String, dynamic>.from(payload['claim'] as Map? ?? const {}),
      ),
      recordedAt: _instantFromPayload(payload),
    );
  }

  @override
  Future<RuntimeTemporalEventReceipt> recordRuntimeEvent(
    RuntimeTemporalEvent event,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'record_runtime_event',
      payload: {
        'event': event.toJson(),
      },
    );
    if (payload == null) {
      return _fallbackKernel.recordRuntimeEvent(event);
    }
    return RuntimeTemporalEventReceipt(
      eventId: payload['eventId'] as String? ?? event.eventId,
      recordedAt: _instantFromPayload(payload),
    );
  }

  @override
  Future<RuntimeTemporalEventLookup?> getRuntimeEvent(String eventId) async {
    final payload = _nativePayloadOrNull(
      syscall: 'get_runtime_event',
      payload: {'eventId': eventId},
    );
    if (payload == null) {
      return _fallbackKernel.getRuntimeEvent(eventId);
    }
    if (payload['found'] != true) {
      return null;
    }
    return RuntimeTemporalEventLookup(
      event: RuntimeTemporalEvent.fromJson(
        Map<String, dynamic>.from(payload['event'] as Map? ?? const {}),
      ),
      recordedAt: _instantFromPayload(payload),
    );
  }

  @override
  Future<List<RuntimeTemporalEventLookup>> queryRuntimeEvents(
    RuntimeTemporalEventQuery query,
  ) async {
    final payload = _nativePayloadOrNull(
      syscall: 'query_runtime_events',
      payload: query.toJson(),
    );
    if (payload == null) {
      return _fallbackKernel.queryRuntimeEvents(query);
    }
    final events = (payload['events'] as List?)
            ?.map((entry) => Map<String, dynamic>.from(entry as Map))
            .map(
              (entry) => RuntimeTemporalEventLookup(
                event: RuntimeTemporalEvent.fromJson(
                  Map<String, dynamic>.from(entry['event'] as Map? ?? const {}),
                ),
                recordedAt: TemporalInstant.fromJson(
                  Map<String, dynamic>.from(
                    entry['recordedAt'] as Map? ?? const {},
                  ),
                ),
              ),
            )
            .toList() ??
        <RuntimeTemporalEventLookup>[];
    return events;
  }

  @override
  Future<TemporalInstant> nowCivil() async {
    final payload = _nativePayloadOrNull(syscall: 'now', payload: const {});
    if (payload == null) {
      return _fallbackKernel.nowCivil();
    }
    return _instantFromPayload(payload);
  }

  @override
  Future<TemporalInstant> nowMonotonic() async {
    final payload = _nativePayloadOrNull(syscall: 'now', payload: const {});
    if (payload == null) {
      return _fallbackKernel.nowMonotonic();
    }
    return _instantFromPayload(payload);
  }

  @override
  Future<TemporalSnapshot> snapshot(TemporalSnapshotRequest request) async {
    final payload = _nativePayloadOrNull(
      syscall: 'snapshot',
      payload: {
        if (request.effectiveAt != null)
          'effectiveAt': request.effectiveAt!.toJson(),
        if (request.expiresAt != null) 'expiresAt': request.expiresAt!.toJson(),
        if (request.lineageRef != null) 'lineageRef': request.lineageRef,
        if (request.cadence != null) 'cadence': request.cadence!.toJson(),
      },
    );
    if (payload == null) {
      return _fallbackKernel.snapshot(request);
    }
    return TemporalSnapshot.fromJson(
      Map<String, dynamic>.from(payload['snapshot'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic>? _nativePayloadOrNull({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      _audit?.recordFallback(WhenNativeFallbackReason.unavailable);
      _policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhenNativeFallbackReason.unavailable,
      );
      return null;
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      _audit?.recordFallback(WhenNativeFallbackReason.deferred);
      _policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhenNativeFallbackReason.deferred,
      );
      return null;
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      _audit?.recordNativeHandled();
      return nativePayload;
    }
    if (nativePayload is Map) {
      _audit?.recordNativeHandled();
      return Map<String, dynamic>.from(nativePayload);
    }
    _audit?.recordFallback(WhenNativeFallbackReason.deferred);
    _policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: WhenNativeFallbackReason.deferred,
    );
    return null;
  }

  TemporalInstant _instantFromPayload(Map<String, dynamic> payload) {
    final instantPayload = payload['instant'];
    if (instantPayload is Map<String, dynamic>) {
      return TemporalInstant.fromJson(instantPayload);
    }
    if (instantPayload is Map) {
      return TemporalInstant.fromJson(
          Map<String, dynamic>.from(instantPayload));
    }
    throw StateError('Native when payload missing instant.');
  }
}

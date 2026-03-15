import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

abstract class WhenKernelContract {
  const WhenKernelContract();

  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope);

  Future<WhenTimestamp> issueTimestamp(WhenTimestampRequest request) async {
    return WhenTimestamp(
      referenceId: request.referenceId,
      observedAtUtc: request.occurredAtUtc.toUtc(),
      quantumAtomicTick: request.occurredAtUtc.toUtc().microsecondsSinceEpoch,
      confidence: 0.95,
    );
  }

  Future<WhenValidationResult> validateWhen(WhenValidityWindow window) async {
    final observed = window.timestamp.observedAtUtc.toUtc();
    final effective = (window.effectiveAtUtc ?? observed).toUtc();
    final expires = (window.expiresAtUtc ??
            observed.add(
              const Duration(hours: 4),
            ))
        .toUtc();
    final driftMs = observed.difference(effective).inMilliseconds.abs();
    final valid = !observed.isBefore(effective) &&
        !observed.isAfter(expires) &&
        driftMs <= window.allowedDriftMs;
    return WhenValidationResult(
      valid: valid,
      reason: valid ? 'within_validity_window' : 'outside_validity_window',
      observedDriftMs: driftMs,
    );
  }

  Future<WhenComparisonResult> compareWhen(
    WhenTimestamp left,
    WhenTimestamp right,
  ) async {
    return WhenComparisonResult(
      orderedAscending: left.observedAtUtc.compareTo(right.observedAtUtc) <= 0,
      deltaMs:
          right.observedAtUtc.difference(left.observedAtUtc).inMilliseconds,
    );
  }

  Future<WhenKernelSnapshot?> snapshotWhen(String subjectId) async {
    return resolveWhen(
      KernelEventEnvelope(
        eventId: 'when_snapshot:$subjectId',
        occurredAtUtc: DateTime.now().toUtc(),
        agentId: subjectId,
        sourceSystem: 'when_kernel_snapshot',
        eventType: 'snapshot',
        actionType: 'resolve_time',
      ),
    );
  }

  Future<List<KernelReplayRecord>> replayWhen(
    KernelReplayRequest request,
  ) async {
    final snapshot = await snapshotWhen(request.subjectId);
    if (snapshot == null) {
      return const <KernelReplayRecord>[];
    }
    return <KernelReplayRecord>[
      KernelReplayRecord(
        domain: KernelDomain.when,
        recordId: 'when:${request.subjectId}',
        occurredAtUtc: snapshot.observedAt,
        summary: 'Temporal replay for ${request.subjectId}',
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<WhenReconciliationResult> reconcileWhen(
    List<WhenTimestamp> timestamps,
  ) async {
    final canonical = (timestamps.isEmpty
            ? WhenTimestamp(
                referenceId: 'when:bootstrap',
                observedAtUtc: DateTime.now().toUtc(),
                quantumAtomicTick:
                    DateTime.now().toUtc().microsecondsSinceEpoch,
                confidence: 0.0,
              )
            : timestamps.reduce(
                (left, right) => left.observedAtUtc.isAfter(right.observedAtUtc)
                    ? left
                    : right,
              ))
        .toJson();
    return WhenReconciliationResult(
      canonicalTimestamp: WhenTimestamp(
        referenceId: canonical['reference_id']! as String,
        observedAtUtc:
            DateTime.parse(canonical['observed_at_utc']! as String).toUtc(),
        quantumAtomicTick: canonical['quantum_atomic_tick']! as int,
        confidence: (canonical['confidence']! as num).toDouble(),
      ),
      conflictCount: timestamps.length <= 1 ? 0 : timestamps.length - 1,
      summary: timestamps.length <= 1
          ? 'no reconciliation required'
          : 'selected latest timestamp as canonical reference',
    );
  }

  Future<WhenEventRecord> recordRuntimeEvent(WhenEventRecord record) async {
    return record;
  }

  Future<List<WhenEventRecord>> queryRuntimeEvents(
    KernelReplayRequest request,
  ) async {
    final snapshot = await snapshotWhen(request.subjectId);
    if (snapshot == null) {
      return const <WhenEventRecord>[];
    }
    return <WhenEventRecord>[
      WhenEventRecord(
        eventId: 'when_event:${request.subjectId}',
        runtimeId: request.subjectId,
        occurredAtUtc: snapshot.observedAt,
        stratum: request.filters['stratum'] as String? ?? 'personal',
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<WhenRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.when ??
        await snapshotWhen(
          request.subjectId ??
              request.envelope?.agentId ??
              request.envelope?.eventId ??
              'unknown_runtime',
        );
    return WhenRealityProjection(
      summary:
          'Temporal ordering at ${snapshot?.observedAt.toUtc().toIso8601String() ?? 'unknown_time'}',
      confidence: snapshot?.temporalConfidence ?? 0.0,
      features: <String, dynamic>{
        'recency_bucket': snapshot?.recencyBucket,
        'freshness': snapshot?.freshness,
        'conflict_flags': snapshot?.timingConflictFlags ?? const <String>[],
      },
      payload: snapshot?.toJson() ?? const <String, dynamic>{},
    );
  }

  Future<KernelGovernanceProjection> projectForGovernance(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.when ??
        await snapshotWhen(
          request.subjectId ??
              request.envelope?.agentId ??
              request.envelope?.eventId ??
              'unknown_runtime',
        );
    return KernelGovernanceProjection(
      domain: KernelDomain.when,
      summary: 'Temporal governance view for ${request.subjectId ?? 'runtime'}',
      confidence: snapshot?.temporalConfidence ?? 0.0,
      highlights: snapshot?.timingConflictFlags ?? const <String>[],
      payload: snapshot?.toJson() ?? const <String, dynamic>{},
    );
  }

  Future<KernelHealthReport> diagnoseWhen() async {
    final now = DateTime.now().toUtc();
    return KernelHealthReport(
      domain: KernelDomain.when,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary: 'when kernel is providing canonical temporal ordering',
      diagnostics: <String, dynamic>{
        'checked_at_utc': now.toIso8601String(),
        'quantum_atomic_time_required': true,
      },
    );
  }
}

abstract class WhenKernelFallbackSurface extends WhenKernelContract {
  const WhenKernelFallbackSurface();
}

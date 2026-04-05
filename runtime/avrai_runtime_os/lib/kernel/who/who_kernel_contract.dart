import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

abstract class WhoKernelContract {
  const WhoKernelContract();

  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope);

  Future<WhoRuntimeBindingReceipt> bindRuntime(
    WhoRuntimeBindingRequest request,
  ) async {
    return WhoRuntimeBindingReceipt(
      runtimeId: request.runtimeId,
      actorId: request.actorId,
      boundAtUtc: DateTime.now().toUtc(),
      continuityRef: 'who:${request.actorId}:${request.runtimeId}',
    );
  }

  Future<WhoSignatureRecord> sign(WhoSigningRequest request) async {
    final entries = request.payload.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList()
      ..sort();
    return WhoSignatureRecord(
      actorId: request.actorId,
      algorithm: request.algorithm,
      signature: '${request.actorId}:${request.algorithm}:${entries.join('|')}',
      issuedAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<WhoVerificationResult> verify(WhoVerificationRequest request) async {
    final expected = await sign(
      WhoSigningRequest(
        actorId: request.actorId,
        payload: request.payload,
        algorithm: request.algorithm,
      ),
    );
    final valid = expected.signature == request.signature;
    return WhoVerificationResult(
      valid: valid,
      reason: valid ? 'signature_match' : 'signature_mismatch',
    );
  }

  Future<WhoKernelSnapshot?> snapshotWho(String actorId) async {
    return resolveWho(
      KernelEventEnvelope(
        eventId: 'who_snapshot:$actorId',
        occurredAtUtc: DateTime.now().toUtc(),
        agentId: actorId,
        userId: actorId,
        sourceSystem: 'who_kernel_snapshot',
        eventType: 'snapshot',
        actionType: 'resolve_identity',
        entityId: actorId,
        entityType: 'actor',
      ),
    );
  }

  Future<List<KernelReplayRecord>> replayWho(
      KernelReplayRequest request) async {
    final snapshot = await snapshotWho(request.subjectId);
    if (snapshot == null) {
      return const <KernelReplayRecord>[];
    }
    return <KernelReplayRecord>[
      KernelReplayRecord(
        domain: KernelDomain.who,
        recordId: 'who:${request.subjectId}',
        occurredAtUtc: DateTime.now().toUtc(),
        summary: 'Identity replay for ${request.subjectId}',
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<KernelRecoveryReport> recoverWho(KernelRecoveryRequest request) async {
    return KernelRecoveryReport(
      domain: KernelDomain.who,
      subjectId: request.subjectId,
      restoredCount: request.persistedEnvelope == null ? 0 : 1,
      droppedCount: 0,
      recoveredAtUtc: DateTime.now().toUtc(),
      summary: 'who recovery baseline completed for ${request.subjectId}',
    );
  }

  Future<WhoRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.who ??
        await snapshotWho(
          request.subjectId ??
              request.envelope?.agentId ??
              request.envelope?.userId ??
              'unknown_actor',
        );
    return WhoRealityProjection(
      summary:
          'Actor ${snapshot?.primaryActor ?? 'unknown_actor'} in ${snapshot?.trustScope ?? 'unknown_scope'} scope',
      confidence: snapshot?.identityConfidence ?? 0.0,
      features: <String, dynamic>{
        'primary_actor': snapshot?.primaryActor,
        'affected_actor': snapshot?.affectedActor,
        'trust_scope': snapshot?.trustScope,
        'cohort_refs': snapshot?.cohortRefs ?? const <String>[],
      },
      payload: snapshot?.toJson() ?? const <String, dynamic>{},
    );
  }

  Future<KernelGovernanceProjection> projectForGovernance(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.who ??
        await snapshotWho(
          request.subjectId ??
              request.envelope?.agentId ??
              request.envelope?.userId ??
              'unknown_actor',
        );
    return KernelGovernanceProjection(
      domain: KernelDomain.who,
      summary:
          'Governance identity view for ${snapshot?.primaryActor ?? 'unknown_actor'}',
      confidence: snapshot?.identityConfidence ?? 0.0,
      highlights: <String>[
        if (snapshot != null) snapshot.trustScope,
        if (snapshot != null && snapshot.actorRoles.isNotEmpty)
          snapshot.actorRoles.first,
      ],
      payload: snapshot?.toJson() ?? const <String, dynamic>{},
    );
  }

  Future<KernelHealthReport> diagnoseWho() async {
    return const KernelHealthReport(
      domain: KernelDomain.who,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary: 'who kernel is enforcing canonical identity resolution surfaces',
    );
  }
}

abstract class WhoKernelFallbackSurface extends WhoKernelContract {
  const WhoKernelFallbackSurface();
}

import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

abstract class WhyKernelContract {
  const WhyKernelContract();

  WhyKernelSnapshot explainWhy(KernelWhyRequest request);

  WhyConviction convictionWhy(KernelWhyRequest request) {
    final snapshot = explainWhy(request);
    final convictionTier = snapshot.confidence >= 0.85
        ? 'high'
        : snapshot.confidence >= 0.6
            ? 'medium'
            : 'low';
    return WhyConviction(
      goal: snapshot.goal,
      convictionTier: convictionTier,
      confidence: snapshot.confidence,
      summary: snapshot.summary,
    );
  }

  WhyCounterfactual counterfactualWhy(WhyCounterfactualRequest request) {
    final snapshot = explainWhy(request.request);
    return snapshot.counterfactuals.firstWhere(
      (entry) => entry.condition == request.condition,
      orElse: () => WhyCounterfactual(
        condition: request.condition,
        expectedEffect: 'Outcome may shift if the condition is applied',
        confidenceDelta: (snapshot.confidence * 0.2).clamp(0.0, 0.25),
      ),
    );
  }

  WhyAnomalyInterpretation anomalyWhy(KernelWhyRequest request) {
    final snapshot = explainWhy(request);
    final anomalous = snapshot.failureSignature != null ||
        (request.actualOutcomeScore ?? 0.0) < 0.0 ||
        snapshot.confidence < 0.35;
    return WhyAnomalyInterpretation(
      anomalous: anomalous,
      summary: anomalous
          ? 'why kernel detected a potentially abnormal reasoning pattern'
          : 'why kernel did not detect abnormal reasoning',
      severity: anomalous ? (request.severity ?? 'medium') : 'none',
    );
  }

  Future<WhyKernelSnapshot> snapshotWhy(String goalId) async {
    return explainWhy(
      KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: goalId,
      ),
    );
  }

  Future<List<KernelReplayRecord>> replayWhy(
      KernelReplayRequest request) async {
    final snapshot = await snapshotWhy(request.subjectId);
    return <KernelReplayRecord>[
      KernelReplayRecord(
        domain: KernelDomain.why,
        recordId: 'why:${request.subjectId}',
        occurredAtUtc: snapshot.createdAtUtc,
        summary: snapshot.summary,
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<KernelRecoveryReport> recoverWhy(KernelRecoveryRequest request) async {
    return KernelRecoveryReport(
      domain: KernelDomain.why,
      subjectId: request.subjectId,
      restoredCount: request.persistedEnvelope == null ? 0 : 1,
      droppedCount: 0,
      recoveredAtUtc: DateTime.now().toUtc(),
      summary: 'why recovery baseline completed for ${request.subjectId}',
    );
  }

  Future<WhyRealityProjection> projectForRealityModel(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.why ??
        await snapshotWhy(request.subjectId ?? request.summaryFocus ?? 'why');
    return WhyRealityProjection(
      summary: snapshot.summary,
      confidence: snapshot.confidence,
      features: <String, dynamic>{
        'goal': snapshot.goal,
        'root_cause_type': snapshot.rootCauseType.toWireValue(),
        'recommendation_action': snapshot.recommendationAction,
      },
      payload: snapshot.toJson(),
    );
  }

  Future<KernelGovernanceProjection> projectForGovernance(
    KernelProjectionRequest request,
  ) async {
    final snapshot = request.why ??
        await snapshotWhy(request.subjectId ?? request.summaryFocus ?? 'why');
    return KernelGovernanceProjection(
      domain: KernelDomain.why,
      summary: snapshot.summary,
      confidence: snapshot.confidence,
      highlights: <String>[
        snapshot.rootCauseType.toWireValue(),
        if (snapshot.recommendationAction != null)
          snapshot.recommendationAction!,
      ],
      payload: snapshot.toJson(),
    );
  }

  Future<KernelHealthReport> diagnoseWhy() async {
    return const KernelHealthReport(
      domain: KernelDomain.why,
      status: KernelHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      authorityLevel: KernelAuthorityLevel.authoritative,
      summary:
          'why kernel is providing canonical explanation and conviction reasoning',
    );
  }
}

abstract class WhyKernelFallbackSurface extends WhyKernelContract {
  const WhyKernelFallbackSurface();
}

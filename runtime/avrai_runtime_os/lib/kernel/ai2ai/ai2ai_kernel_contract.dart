import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show KernelRecoveryRequest, KernelReplayRequest, TransportRouteReceipt;

abstract class Ai2AiKernelContract {
  const Ai2AiKernelContract();

  Future<Ai2AiExchangePlan> planExchange(Ai2AiExchangeCandidate candidate);

  Future<Ai2AiExchangeReceipt> commitExchange(Ai2AiExchangeCommit request);

  Future<Ai2AiExchangeReceipt> observeExchange(
    Ai2AiExchangeObservation observation,
  );

  Ai2AiExchangeSnapshot? snapshotExchange(String subjectId);

  @Deprecated('Use planExchange()')
  Future<Ai2AiLifecyclePlan> planAi2Ai(Ai2AiMessageCandidate candidate) async {
    final plan = await planExchange(candidate.toExchangeCandidate());
    return plan.toLegacyLifecyclePlan();
  }

  @Deprecated('Use commitExchange()')
  Future<Ai2AiCommitReceipt> commitAi2Ai(Ai2AiCommitRequest request) async {
    final receipt = await commitExchange(request.toExchangeCommit());
    return receipt.toLegacyCommitReceipt();
  }

  @Deprecated('Use observeExchange()')
  Future<Ai2AiObservationReceipt> observeAi2Ai(
    Ai2AiObservation observation,
  ) async {
    final receipt = await observeExchange(observation.toExchangeObservation());
    return receipt.toLegacyObservationReceipt();
  }

  @Deprecated('Use snapshotExchange()')
  Ai2AiKernelSnapshot? snapshotAi2Ai(String subjectId) {
    return snapshotExchange(subjectId)?.toLegacySnapshot();
  }

  Future<List<Ai2AiReplayRecord>> replayAi2Ai(
    KernelReplayRequest request,
  ) async {
    final snapshot = snapshotExchange(request.subjectId);
    if (snapshot == null) {
      return const <Ai2AiReplayRecord>[];
    }
    return <Ai2AiReplayRecord>[
      Ai2AiReplayRecord(
        recordId: 'ai2ai:${request.subjectId}',
        subjectId: request.subjectId,
        occurredAtUtc: snapshot.savedAtUtc,
        lifecycleState: snapshot.lifecycleState.toLegacyLifecycleState(),
        summary: 'AI2AI replay for ${snapshot.conversationId}',
        routeReceipt: snapshot.routeReceipt,
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<Ai2AiRecoveryReport> recoverAi2Ai(
      KernelRecoveryRequest request) async {
    return Ai2AiRecoveryReport(
      subjectId: request.subjectId,
      restoredCount: 0,
      droppedCount: 0,
      recoveredAtUtc: DateTime.now().toUtc(),
      summary: 'ai2ai recovery requires concrete runtime implementation',
      diagnostics: Map<String, dynamic>.from(request.hints),
    );
  }

  Future<Ai2AiRealityProjectionBundle> projectAi2AiForRealityModel(
    Ai2AiProjectionRequest request,
  ) async {
    final snapshot = request.snapshot ?? snapshotExchange(request.subjectId)?.toLegacySnapshot();
    return projectAi2AiSnapshotForRealityModel(
      snapshot,
      envelope: request.envelope,
      whenSnapshot: request.whenSnapshot,
      context: request.context,
    );
  }

  Future<Ai2AiKernelHealthSnapshot> diagnoseAi2Ai() async {
    return const Ai2AiKernelHealthSnapshot(
      kernelId: 'ai2ai_runtime_governance',
      status: Ai2AiHealthStatus.degraded,
      nativeBacked: false,
      headlessReady: true,
      summary:
          'ai2ai kernel contract is defined, but runtime execution is not yet bound to a concrete native or fallback implementation',
    );
  }

  Future<Ai2AiSimulationResult> simulateAi2Ai(
    Ai2AiSimulationRequest request,
  ) async {
    final ai2aiRuntimeStateFrame =
        request.topology['ai2ai_runtime_state_frame'] is Map
            ? Map<String, dynamic>.from(
                request.topology['ai2ai_runtime_state_frame'] as Map,
              )
            : null;
    return Ai2AiSimulationResult(
      simulationId: request.simulationId,
      generatedReceipts: <TransportRouteReceipt>[],
      acceptedEvents: 0,
      droppedEvents: 0,
      telemetry: <String, dynamic>{
        'seed_candidate_count': request.seedCandidates.length,
        if (ai2aiRuntimeStateFrame != null)
          'ai2ai_runtime_state_frame': ai2aiRuntimeStateFrame,
      },
    );
  }
}

abstract class Ai2AiKernelFallbackSurface extends Ai2AiKernelContract {
  const Ai2AiKernelFallbackSurface();
}

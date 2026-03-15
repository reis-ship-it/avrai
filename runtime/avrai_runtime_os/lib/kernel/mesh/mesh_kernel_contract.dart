import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show KernelRecoveryRequest, KernelReplayRequest, TransportRouteReceipt;

abstract class MeshKernelContract {
  const MeshKernelContract();

  Future<MeshTransportPlan> planTransport(MeshRoutePlanningRequest request);

  Future<MeshTransportReceipt> commitTransport(MeshTransportCommit request);

  Future<MeshTransportReceipt> observeTransport(MeshObservation observation);

  MeshTransportSnapshot? snapshotTransport(String subjectId);

  @Deprecated('Use planTransport()')
  Future<MeshRoutePlan> planMesh(MeshRoutePlanningRequest request) async {
    final plan = await planTransport(request);
    return plan.toLegacyRoutePlan();
  }

  @Deprecated('Use commitTransport()')
  Future<MeshCommitReceipt> commitMesh(MeshCommitRequest request) async {
    final receipt = await commitTransport(request.toTransportCommit());
    return receipt.toLegacyCommitReceipt();
  }

  @Deprecated('Use observeTransport()')
  Future<MeshObservationReceipt> observeMesh(
    MeshObservation observation,
  ) async {
    final receipt = await observeTransport(observation);
    return receipt.toLegacyObservationReceipt();
  }

  @Deprecated('Use snapshotTransport()')
  MeshKernelSnapshot? snapshotMesh(String subjectId) {
    return snapshotTransport(subjectId)?.toLegacySnapshot();
  }

  Future<List<MeshReplayRecord>> replayMesh(KernelReplayRequest request) async {
    final snapshot = snapshotTransport(request.subjectId);
    if (snapshot == null) {
      return const <MeshReplayRecord>[];
    }
    return <MeshReplayRecord>[
      MeshReplayRecord(
        recordId: 'mesh:${request.subjectId}',
        subjectId: request.subjectId,
        occurredAtUtc: snapshot.savedAtUtc,
        lifecycleState: snapshot.lifecycleState.toLegacyLifecycleState(),
        summary: 'Mesh replay for ${snapshot.destinationId}',
        routeReceipt: snapshot.routeReceipt,
        payload: snapshot.toJson(),
      ),
    ];
  }

  Future<MeshRecoveryReport> recoverMesh(KernelRecoveryRequest request) async {
    return MeshRecoveryReport(
      subjectId: request.subjectId,
      restoredCount: 0,
      droppedCount: 0,
      recoveredAtUtc: DateTime.now().toUtc(),
      summary: 'mesh recovery requires concrete runtime implementation',
      diagnostics: Map<String, dynamic>.from(request.hints),
    );
  }

  Future<MeshRealityProjectionBundle> projectMeshForRealityModel(
    MeshProjectionRequest request,
  ) async {
    final snapshot = request.snapshot ?? snapshotTransport(request.subjectId)?.toLegacySnapshot();
    return projectMeshSnapshotForRealityModel(
      snapshot,
      envelope: request.envelope,
      whenSnapshot: request.whenSnapshot,
      context: request.context,
    );
  }

  Future<MeshKernelHealthSnapshot> diagnoseMesh() async {
    return const MeshKernelHealthSnapshot(
      kernelId: 'mesh_runtime_governance',
      status: MeshHealthStatus.degraded,
      nativeBacked: false,
      headlessReady: true,
      summary:
          'mesh kernel contract is defined, but runtime execution is not yet bound to a concrete native or fallback implementation',
    );
  }

  Future<MeshSimulationResult> simulateMesh(
    MeshSimulationRequest request,
  ) async {
    final meshRuntimeStateFrame =
        request.topology['mesh_runtime_state_frame'] is Map
            ? Map<String, dynamic>.from(
                request.topology['mesh_runtime_state_frame'] as Map,
              )
            : null;
    return MeshSimulationResult(
      simulationId: request.simulationId,
      generatedReceipts: <TransportRouteReceipt>[],
      acceptedEvents: 0,
      droppedEvents: 0,
      telemetry: <String, dynamic>{
        'seed_envelope_count': request.seedEnvelopes.length,
        if (meshRuntimeStateFrame != null)
          'mesh_runtime_state_frame': meshRuntimeStateFrame,
      },
    );
  }
}

abstract class MeshKernelFallbackSurface extends MeshKernelContract {
  const MeshKernelFallbackSurface();
}

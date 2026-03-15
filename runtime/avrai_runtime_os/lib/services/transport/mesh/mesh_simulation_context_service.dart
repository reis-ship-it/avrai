import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';

class MeshSimulationContextService {
  const MeshSimulationContextService();

  MonteCarloRunContext attachRuntimeStateFrame({
    required MonteCarloRunContext runContext,
    MeshRuntimeStateFrame? frame,
  }) {
    if (frame == null) {
      return runContext;
    }

    return MonteCarloRunContext(
      canonicalReplayYear: runContext.canonicalReplayYear,
      replayYear: runContext.replayYear,
      branchId: runContext.branchId,
      runId: runContext.runId,
      seed: runContext.seed,
      divergencePolicy: runContext.divergencePolicy,
      branchPurpose: runContext.branchPurpose,
      parentRunId: runContext.parentRunId,
      parentBranchId: runContext.parentBranchId,
      metadata: <String, dynamic>{
        ...runContext.metadata,
        'mesh_runtime_state_frame': frame.toJson(),
        'mesh_runtime_state_summary': buildRuntimeStateSummary(frame),
      },
    );
  }

  Map<String, dynamic>? extractRuntimeStateFrameJson(
    MonteCarloRunContext runContext,
  ) {
    final raw = runContext.metadata['mesh_runtime_state_frame'];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  MeshRuntimeStateFrame? extractRuntimeStateFrame(
    MonteCarloRunContext runContext,
  ) {
    final json = extractRuntimeStateFrameJson(runContext);
    if (json == null) {
      return null;
    }
    return MeshRuntimeStateFrame.fromJson(json);
  }

  Map<String, dynamic>? extractRuntimeStateSummary(
    MonteCarloRunContext runContext,
  ) {
    final raw = runContext.metadata['mesh_runtime_state_summary'];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    final frame = extractRuntimeStateFrame(runContext);
    if (frame == null) {
      return null;
    }
    return buildRuntimeStateSummary(frame);
  }

  Map<String, dynamic> buildRuntimeStateSummary(MeshRuntimeStateFrame frame) {
    return <String, dynamic>{
      'route_destination_count': frame.routeDestinationCount,
      'route_entry_count': frame.routeEntryCount,
      'pending_custody_count': frame.pendingCustodyCount,
      'due_custody_count': frame.dueCustodyCount,
      'encrypted_at_rest': frame.encryptedAtRest,
      'queued_payload_kind_counts': frame.queuedPayloadKindCounts,
    };
  }

  Map<String, dynamic> buildSimulationTopology(MeshRuntimeStateFrame frame) {
    return frame.toSimulationTopology();
  }
}

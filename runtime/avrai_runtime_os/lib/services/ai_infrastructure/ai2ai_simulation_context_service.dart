import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';

class Ai2AiSimulationContextService {
  const Ai2AiSimulationContextService();

  MonteCarloRunContext attachRuntimeStateFrame({
    required MonteCarloRunContext runContext,
    Ai2AiRuntimeStateFrame? frame,
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
        'ai2ai_runtime_state_frame': frame.toJson(),
        'ai2ai_runtime_state_summary': buildRuntimeStateSummary(frame),
      },
    );
  }

  Map<String, dynamic>? extractRuntimeStateFrameJson(
    MonteCarloRunContext runContext,
  ) {
    final raw = runContext.metadata['ai2ai_runtime_state_frame'];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Ai2AiRuntimeStateFrame? extractRuntimeStateFrame(
    MonteCarloRunContext runContext,
  ) {
    final json = extractRuntimeStateFrameJson(runContext);
    if (json == null) {
      return null;
    }
    return Ai2AiRuntimeStateFrame.fromJson(json);
  }

  Map<String, dynamic>? extractRuntimeStateSummary(
    MonteCarloRunContext runContext,
  ) {
    final raw = runContext.metadata['ai2ai_runtime_state_summary'];
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

  Map<String, dynamic> buildRuntimeStateSummary(Ai2AiRuntimeStateFrame frame) {
    return <String, dynamic>{
      'recent_event_count': frame.recentEventCount,
      'active_connection_count': frame.activeConnectionCount,
      'distinct_connection_count': frame.distinctConnectionCount,
      'distinct_remote_node_count': frame.distinctRemoteNodeCount,
      'routing_attempt_count': frame.routingAttemptCount,
      'custody_accepted_count': frame.custodyAcceptedCount,
      'delivery_success_count': frame.deliverySuccessCount,
      'delivery_failure_count': frame.deliveryFailureCount,
      'read_confirmed_count': frame.readConfirmedCount,
      'learning_applied_count': frame.learningAppliedCount,
      'learning_buffered_count': frame.learningBufferedCount,
      'encryption_failure_count': frame.encryptionFailureCount,
      'anomaly_count': frame.anomalyCount,
      'event_type_counts': frame.eventTypeCounts,
    };
  }

  Map<String, dynamic> buildSimulationTopology(Ai2AiRuntimeStateFrame frame) {
    return frame.toSimulationTopology();
  }
}

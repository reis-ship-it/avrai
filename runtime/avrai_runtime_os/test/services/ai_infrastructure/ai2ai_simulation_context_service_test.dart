import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_simulation_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attaches and extracts an AI2AI runtime state frame', () {
    final frame = Ai2AiRuntimeStateFrame(
      capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
      recentEventCount: 5,
      activeConnectionCount: 1,
      distinctConnectionCount: 2,
      distinctRemoteNodeCount: 2,
      routingAttemptCount: 1,
      custodyAcceptedCount: 1,
      deliverySuccessCount: 1,
      deliveryFailureCount: 1,
      readConfirmedCount: 1,
      learningAppliedCount: 1,
      learningBufferedCount: 0,
      encryptionFailureCount: 0,
      anomalyCount: 0,
      eventTypeCounts: const <String, int>{
        'ai2ai_delivery_success': 1,
      },
      peers: const <Ai2AiRuntimePeerState>[],
    );
    const runContext = MonteCarloRunContext(
      canonicalReplayYear: 2023,
      replayYear: 2023,
      branchId: 'canonical',
      runId: 'run-ai2ai-ctx-1',
      seed: 2023,
      divergencePolicy: 'none',
    );

    final service = const Ai2AiSimulationContextService();
    final enriched = service.attachRuntimeStateFrame(
      runContext: runContext,
      frame: frame,
    );

    expect(service.extractRuntimeStateFrame(enriched)?.recentEventCount, 5);
    expect(
      service.extractRuntimeStateSummary(enriched)?['delivery_success_count'],
      1,
    );
    expect(
      service.buildSimulationTopology(frame)['ai2ai_runtime_state_frame'],
      isA<Map>(),
    );
  });
}

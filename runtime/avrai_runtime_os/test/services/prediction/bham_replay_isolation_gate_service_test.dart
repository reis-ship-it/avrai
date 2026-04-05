import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_isolation_gate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const runContext = MonteCarloRunContext(
    canonicalReplayYear: 2023,
    replayYear: 2023,
    branchId: 'canonical',
    runId: 'run-1',
    seed: 2023,
    divergencePolicy: 'none',
  );

  BhamReplayExecutionPlan buildExecutionPlan({Map<String, dynamic>? metadata}) {
    return BhamReplayExecutionPlan(
      packId: 'pack-1',
      replayYear: 2023,
      runContext: MonteCarloRunContext(
        canonicalReplayYear: runContext.canonicalReplayYear,
        replayYear: runContext.replayYear,
        branchId: runContext.branchId,
        runId: runContext.runId,
        seed: runContext.seed,
        divergencePolicy: runContext.divergencePolicy,
        metadata: metadata ?? const <String, dynamic>{},
      ),
      entries: const <BhamReplayExecutionEntry>[],
      sourceCounts: const <String, int>{},
      entityTypeCounts: const <String, int>{},
      dayCounts: const <String, int>{},
      skippedSources: const <String>[],
    );
  }

  BhamReplayForecastBatchResult buildForecastBatch() {
    return const BhamReplayForecastBatchResult(
      runContext: runContext,
      evaluatedCount: 0,
      dispositionCounts: <String, int>{},
      entityTypeCounts: <String, int>{},
      sourceCounts: <String, int>{},
      items: <BhamReplayForecastBatchItem>[],
    );
  }

  ReplayVirtualWorldEnvironment buildEnvironment({Map<String, dynamic>? metadata}) {
    return ReplayVirtualWorldEnvironment(
      environmentId: 'env-1',
      replayYear: 2023,
      runContext: runContext,
      isolationBoundary: const ReplayWorldIsolationBoundary(
        environmentNamespace: 'replay-world/bham/2023/run-1',
        sourceArtifactRefs: <String>['36', '37', '39'],
        runtimeMutationPolicy: ReplayWorldAccessPolicy.blocked,
        liveDataIngressPolicy: ReplayWorldAccessPolicy.blocked,
        appSurfacePolicy: ReplayWorldAccessPolicy.blocked,
        adminInspectionPolicy: ReplayWorldAccessPolicy.adminOnly,
        higherAgentPolicy: ReplayWorldAccessPolicy.replayOnlyInternal,
      ),
      nodeCount: 0,
      observationCount: 0,
      forecastEvaluatedCount: 0,
      sourceCounts: const <String, int>{},
      entityTypeCounts: const <String, int>{},
      localityCounts: const <String, int>{},
      forecastDispositionCounts: const <String, int>{},
      nodes: const <ReplayVirtualWorldNode>[],
      metadata: metadata ?? const <String, dynamic>{},
    );
  }

  test('passes when replay metadata is isolated from live runtime state', () {
    final report = const BhamReplayIsolationGateService().buildReport(
      executionPlan: buildExecutionPlan(),
      forecastBatch: buildForecastBatch(),
      environment: buildEnvironment(
        metadata: const <String, dynamic>{
          'selected_forecast_kernel_id': 'native_forecast_kernel',
        },
      ),
    );

    expect(report.passed, isTrue);
    expect(report.violations, isEmpty);
  });

  test('fails when forbidden mesh state leaks into replay metadata', () {
    final report = const BhamReplayIsolationGateService().buildReport(
      executionPlan: buildExecutionPlan(
        metadata: const <String, dynamic>{
          'mesh_runtime_state_summary': <String, dynamic>{'active': true},
        },
      ),
      forecastBatch: buildForecastBatch(),
      environment: buildEnvironment(),
    );

    expect(report.passed, isFalse);
    expect(report.violations.single, contains('mesh_runtime_state_summary'));
  });
}

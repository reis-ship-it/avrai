import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';

class BhamReplayIsolationGateService {
  const BhamReplayIsolationGateService();

  ReplayIsolationReport buildReport({
    required BhamReplayExecutionPlan executionPlan,
    required BhamReplayForecastBatchResult forecastBatch,
    required ReplayVirtualWorldEnvironment environment,
  }) {
    final violations = <String>[];
    void scanMap(String scope, Map<String, dynamic> metadata) {
      for (final key in metadata.keys) {
        if (key.contains('mesh_runtime_state') ||
            key.contains('ai2ai_runtime_state') ||
            key.contains('live_runtime') ||
            key.contains('transport_state')) {
          violations.add('$scope metadata contains forbidden key `$key`.');
        }
      }
    }

    scanMap('executionPlan.runContext', executionPlan.runContext.metadata);
    scanMap('forecastBatch.runContext', forecastBatch.runContext.metadata);
    scanMap('environment.metadata', environment.metadata);

    if (environment.isolationBoundary.runtimeMutationPolicy !=
        ReplayWorldAccessPolicy.blocked) {
      violations.add('runtimeMutationPolicy must be blocked.');
    }
    if (environment.isolationBoundary.liveDataIngressPolicy !=
        ReplayWorldAccessPolicy.blocked) {
      violations.add('liveDataIngressPolicy must be blocked.');
    }
    if (environment.isolationBoundary.appSurfacePolicy !=
        ReplayWorldAccessPolicy.blocked) {
      violations.add('appSurfacePolicy must be blocked.');
    }
    if (environment.isolationBoundary.adminInspectionPolicy !=
        ReplayWorldAccessPolicy.adminOnly) {
      violations.add('adminInspectionPolicy must be adminOnly.');
    }
    if (environment.isolationBoundary.higherAgentPolicy !=
        ReplayWorldAccessPolicy.replayOnlyInternal) {
      violations.add('higherAgentPolicy must be replayOnlyInternal.');
    }

    return ReplayIsolationReport(
      environmentId: environment.environmentId,
      passed: violations.isEmpty,
      violations: violations,
      policySnapshot: <String, String>{
        'runtimeMutationPolicy':
            environment.isolationBoundary.runtimeMutationPolicy.name,
        'liveDataIngressPolicy':
            environment.isolationBoundary.liveDataIngressPolicy.name,
        'appSurfacePolicy': environment.isolationBoundary.appSurfacePolicy.name,
        'adminInspectionPolicy':
            environment.isolationBoundary.adminInspectionPolicy.name,
        'higherAgentPolicy':
            environment.isolationBoundary.higherAgentPolicy.name,
      },
      notes: const <String>[
        'Replay must remain isolated from live runtime mutation and transport state.',
      ],
      metadata: <String, dynamic>{
        'environmentNamespace':
            environment.isolationBoundary.environmentNamespace,
      },
    );
  }
}

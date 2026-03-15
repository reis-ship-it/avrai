import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';

class BhamSingleYearReplayPassService {
  const BhamSingleYearReplayPassService();

  ReplaySingleYearPassSummary buildSummary({
    required BhamReplayExecutionPlan executionPlan,
    required BhamReplayForecastBatchResult forecastBatch,
    required ReplayVirtualWorldEnvironment environment,
    required ReplayHigherAgentRollupBatch rollupBatch,
    required ReplayHigherAgentBehaviorPass behaviorPass,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayIsolationReport isolationReport,
    required ReplayKernelParticipationReport kernelParticipationReport,
    ReplayActorKernelCoverageReport? actorKernelCoverageReport,
    ReplayExchangeSummary? exchangeSummary,
    List<ReplayConnectivityProfile> connectivityProfiles =
        const <ReplayConnectivityProfile>[],
    required ReplayRealismGateReport realismGateReport,
    required ReplayCalibrationReport calibrationReport,
    required List<ReplayActionExplanation> actionExplanations,
    BhamReplayActionTrainingBundle? trainingBundle,
    ReplayHoldoutEvaluationReport? holdoutEvaluationReport,
  }) {
    final unresolvedGaps = realismGateReport.unresolvedGaps;
    return ReplaySingleYearPassSummary(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      runContext: environment.runContext,
      executedObservationCount: executionPlan.entries.length,
      forecastEvaluatedCount: forecastBatch.evaluatedCount,
      virtualNodeCount: environment.nodeCount,
      rollupCount: rollupBatch.rollups.length,
      behaviorActionCount: behaviorPass.actions.length,
      dailyAgendaCount: dailyBehaviorBatch.agendas.length,
      dailyActorActionCount: dailyBehaviorBatch.actions.length,
      closureOverrideCount: dailyBehaviorBatch.closureOverrides.length,
      monthCounts: Map<String, int>.from(behaviorPass.monthCounts),
      entityTypeCounts: Map<String, int>.from(environment.entityTypeCounts),
      forecastDispositionCounts:
          Map<String, int>.from(environment.forecastDispositionCounts),
      actionExplanationCount: actionExplanations.length,
      actionTrainingRecordCount: trainingBundle?.records.length ?? 0,
      counterfactualChoiceCount: trainingBundle?.records.fold<int>(
            0,
            (sum, record) => sum + record.counterfactuals.length,
          ) ??
          0,
      outcomeLabelCount: trainingBundle?.outcomeLabels.length ?? 0,
      truthDecisionRecordCount: trainingBundle?.truthDecisionRecords.length ?? 0,
      higherAgentInterventionTraceCount:
          trainingBundle?.higherAgentInterventionTraces.length ?? 0,
      notes: <String>[
        'This is a replay-only single-year pass summary inside the isolated BHAM virtual world.',
        'No live runtime mutation or app-facing surface is allowed from this pass.',
        'Higher-agent behavior remains bounded and replay-internal.',
        if (actorKernelCoverageReport != null)
          'Every modeled actor is evaluated for full attached kernel coverage.',
        if (exchangeSummary != null)
          'Replay-only exchange, AI2AI, and connectivity behavior are simulated without live runtime reuse.',
        if (unresolvedGaps.isEmpty)
          'All current realism gates are passed for the 2023 truth-year.'
        else
          'Open realism gaps remain: ${unresolvedGaps.join(', ')}.',
      ],
      populationProfile: populationProfile,
      placeGraph: placeGraph,
      isolationReport: isolationReport,
      kernelParticipationReport: kernelParticipationReport,
      actorKernelCoverageReport: actorKernelCoverageReport,
      exchangeSummary: exchangeSummary,
      realismGateReport: realismGateReport,
      calibrationReport: calibrationReport,
      stochasticRunConfig: trainingBundle?.variationProfile.runConfig,
      variationProfile: trainingBundle?.variationProfile,
      holdoutEvaluationReport: holdoutEvaluationReport,
      metadata: <String, dynamic>{
        'namespace': environment.isolationBoundary.environmentNamespace,
        'adminInspectionPolicy':
            environment.isolationBoundary.adminInspectionPolicy.name,
        'appSurfacePolicy': environment.isolationBoundary.appSurfacePolicy.name,
        'replayIsolationPassed': isolationReport.passed,
        'readyForMonteCarloBaseYear':
            realismGateReport.readyForMonteCarloBaseYear,
        'calibrationPassed': calibrationReport.passed,
        'unresolvedRealismGapCount': unresolvedGaps.length,
        'actorsWithConnectivityProfiles': connectivityProfiles.length,
        'connectivityTransitionCount': connectivityProfiles.fold<int>(
          0,
          (sum, profile) => sum + profile.transitions.length,
        ),
        'actorsWithFullKernelBundle':
            actorKernelCoverageReport?.actorsWithFullBundle ?? 0,
        'simulatedExchangeThreadCount': exchangeSummary?.totalThreads ?? 0,
        'simulatedExchangeEventCount':
            exchangeSummary?.totalExchangeEvents ?? 0,
        'simulatedAi2AiExchangeCount':
            exchangeSummary?.totalAi2AiRecords ?? 0,
        'offlineQueuedExchangeCount':
            exchangeSummary?.offlineQueuedExchangeCount ?? 0,
        'actorsWithAnyExchange': exchangeSummary?.actorsWithAnyExchange ?? 0,
        'actionTrainingRecordCount': trainingBundle?.records.length ?? 0,
        'counterfactualChoiceCount': trainingBundle?.records.fold<int>(
              0,
              (sum, record) => sum + record.counterfactuals.length,
            ) ??
            0,
        'outcomeLabelCount': trainingBundle?.outcomeLabels.length ?? 0,
        'truthDecisionRecordCount':
            trainingBundle?.truthDecisionRecords.length ?? 0,
        'higherAgentInterventionTraceCount':
            trainingBundle?.higherAgentInterventionTraces.length ?? 0,
        'variationProfileIncluded': trainingBundle != null,
        'holdoutEvaluationPassed': holdoutEvaluationReport?.passed ?? false,
        if (forecastBatch.metadata['selected_forecast_kernel_id'] != null)
          'selected_forecast_kernel_id':
              forecastBatch.metadata['selected_forecast_kernel_id'],
        if (forecastBatch.metadata['selected_forecast_kernel_execution_mode'] !=
            null)
          'selected_forecast_kernel_execution_mode': forecastBatch
              .metadata['selected_forecast_kernel_execution_mode'],
      },
    );
  }
}

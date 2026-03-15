import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_single_year_replay_pass_service.dart';

const _defaultExecutionPlanInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json';
const _defaultForecastBatchInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json';
const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultRollupInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json';
const _defaultBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultIsolationReportInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/52_BHAM_REPLAY_ISOLATION_REPORT_2023.json';
const _defaultKernelParticipationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.json';
const _defaultRealismGateInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json';
const _defaultActionExplanationsInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/55_BHAM_REPLAY_ACTION_EXPLANATIONS_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultCalibrationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json';
const _defaultActorKernelCoverageInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json';
const _defaultConnectivityInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json';
const _defaultExchangeSummaryInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.json';
const _defaultTrainingSignalsInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json';
const _defaultHoldoutEvaluationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json';

Future<void> main(List<String> args) async {
  final executionPlanInput = _readFlag(args, '--execution-plan-input') ??
      _defaultExecutionPlanInputPath;
  final forecastBatchInput = _readFlag(args, '--forecast-batch-input') ??
      _defaultForecastBatchInputPath;
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final rollupInput =
      _readFlag(args, '--rollup-input') ?? _defaultRollupInputPath;
  final behaviorInput =
      _readFlag(args, '--behavior-input') ?? _defaultBehaviorInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final isolationReportInput =
      _readFlag(args, '--isolation-report-input') ??
          _defaultIsolationReportInputPath;
  final kernelParticipationInput =
      _readFlag(args, '--kernel-participation-input') ??
          _defaultKernelParticipationInputPath;
  final realismGateInput =
      _readFlag(args, '--realism-gate-input') ?? _defaultRealismGateInputPath;
  final actionExplanationsInput =
      _readFlag(args, '--action-explanations-input') ??
          _defaultActionExplanationsInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ?? _defaultDailyBehaviorInputPath;
  final calibrationInput =
      _readFlag(args, '--calibration-input') ?? _defaultCalibrationInputPath;
  final actorKernelCoverageInput =
      _readFlag(args, '--actor-kernel-coverage-input') ??
          _defaultActorKernelCoverageInputPath;
  final connectivityInput =
      _readFlag(args, '--connectivity-input') ?? _defaultConnectivityInputPath;
  final exchangeSummaryInput =
      _readFlag(args, '--exchange-summary-input') ??
          _defaultExchangeSummaryInputPath;
  final trainingSignalsInput =
      _readFlag(args, '--training-signals-input') ??
          _defaultTrainingSignalsInputPath;
  final holdoutEvaluationInput =
      _readFlag(args, '--holdout-evaluation-input') ??
          _defaultHoldoutEvaluationInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final executionPlan = BhamReplayExecutionPlan.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(executionPlanInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final forecastBatch = BhamReplayForecastBatchResult.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(forecastBatchInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final environment = ReplayVirtualWorldEnvironment.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(environmentInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final rollups = ReplayHigherAgentRollupBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(rollupInput).readAsStringSync()) as Map<String, dynamic>,
    ),
  );
  final behaviorPass = ReplayHigherAgentBehaviorPass.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(behaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final populationProfile = ReplayPopulationProfile.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(populationProfileInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final placeGraph = ReplayPlaceGraph.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(placeGraphInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final isolationReport = ReplayIsolationReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(isolationReportInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final kernelParticipationReport = ReplayKernelParticipationReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(kernelParticipationInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final realismGateReport = ReplayRealismGateReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(realismGateInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final actionExplanations = (jsonDecode(
    File(actionExplanationsInput).readAsStringSync(),
  ) as List)
      .whereType<Map>()
      .map((entry) => ReplayActionExplanation.fromJson(
            Map<String, dynamic>.from(entry),
          ))
      .toList(growable: false);
  final dailyBehaviorBatch = ReplayDailyBehaviorBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(dailyBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final calibrationReport = ReplayCalibrationReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(calibrationInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final actorKernelCoverageReport = ReplayActorKernelCoverageReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(actorKernelCoverageInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final connectivityProfiles = (jsonDecode(
    File(connectivityInput).readAsStringSync(),
  ) as List)
      .whereType<Map>()
      .map(
        (entry) =>
            ReplayConnectivityProfile.fromJson(Map<String, dynamic>.from(entry)),
      )
      .toList(growable: false);
  final exchangeSummary = ReplayExchangeSummary.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(exchangeSummaryInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final trainingSignalsFile = File(trainingSignalsInput);
  final trainingBundle = trainingSignalsFile.existsSync()
      ? BhamReplayActionTrainingBundle.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(trainingSignalsFile.readAsStringSync())
                as Map<String, dynamic>,
          ),
        )
      : null;
  final holdoutEvaluationFile = File(holdoutEvaluationInput);
  final holdoutEvaluationReport = holdoutEvaluationFile.existsSync()
      ? ReplayHoldoutEvaluationReport.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(holdoutEvaluationFile.readAsStringSync())
                as Map<String, dynamic>,
          ),
        )
      : null;

  final summary = const BhamSingleYearReplayPassService().buildSummary(
    executionPlan: executionPlan,
    forecastBatch: forecastBatch,
    environment: environment,
    rollupBatch: rollups,
    behaviorPass: behaviorPass,
    dailyBehaviorBatch: dailyBehaviorBatch,
    populationProfile: populationProfile,
    placeGraph: placeGraph,
    isolationReport: isolationReport,
    kernelParticipationReport: kernelParticipationReport,
    actorKernelCoverageReport: actorKernelCoverageReport,
    exchangeSummary: exchangeSummary,
    connectivityProfiles: connectivityProfiles,
    realismGateReport: realismGateReport,
    calibrationReport: calibrationReport,
    actionExplanations: actionExplanations,
    trainingBundle: trainingBundle,
    holdoutEvaluationReport: holdoutEvaluationReport,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(summary));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(summary.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM single-year replay pass summary for ${summary.executedObservationCount} executed observations.',
  );
}

String _buildMarkdown(ReplaySingleYearPassSummary summary) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Single-Year Replay Pass')
    ..writeln()
    ..writeln('- Environment: `${summary.environmentId}`')
    ..writeln('- Replay year: `${summary.replayYear}`')
    ..writeln('- Branch: `${summary.runContext.branchId}`')
    ..writeln('- Run: `${summary.runContext.runId}`')
    ..writeln('- Executed observations: `${summary.executedObservationCount}`')
    ..writeln('- Forecast evaluated: `${summary.forecastEvaluatedCount}`')
    ..writeln('- Virtual nodes: `${summary.virtualNodeCount}`')
    ..writeln('- Rollups: `${summary.rollupCount}`')
    ..writeln('- Higher-agent actions: `${summary.behaviorActionCount}`')
    ..writeln('- Daily agendas: `${summary.dailyAgendaCount}`')
    ..writeln('- Daily actor actions: `${summary.dailyActorActionCount}`')
    ..writeln('- Closure overrides: `${summary.closureOverrideCount}`')
    ..writeln('- Action explanations: `${summary.actionExplanationCount}`')
    ..writeln('- Training action records: `${summary.actionTrainingRecordCount}`')
    ..writeln('- Counterfactual choices: `${summary.counterfactualChoiceCount}`')
    ..writeln('- Outcome labels: `${summary.outcomeLabelCount}`')
    ..writeln('- Truth decision records: `${summary.truthDecisionRecordCount}`')
    ..writeln(
      '- Higher-agent intervention traces: `${summary.higherAgentInterventionTraceCount}`',
    )
    ..writeln(
      '- Holdout evaluation passed: `${summary.holdoutEvaluationReport?.passed ?? false}`',
    )
    ..writeln();

  buffer
    ..writeln('## Forecast Kernel')
    ..writeln()
    ..writeln(
      '- Selected kernel: `${summary.metadata['selected_forecast_kernel_id'] ?? 'unknown'}`',
    )
    ..writeln(
      '- Execution mode: `${summary.metadata['selected_forecast_kernel_execution_mode'] ?? 'unknown'}`',
    )
    ..writeln()
    ..writeln('## Replay Isolation')
    ..writeln()
    ..writeln('- `live_runtime_state_attached`: `false`')
    ..writeln('- `mesh_runtime_state_attached`: `false`')
    ..writeln('- `ai2ai_runtime_state_attached`: `false`')
    ..writeln('- `isolation_gate_passed`: `${summary.isolationReport?.passed ?? false}`')
    ..writeln();

  if (summary.populationProfile != null) {
    final population = summary.populationProfile!;
    buffer
      ..writeln('## Population Realism')
      ..writeln()
      ..writeln('- Total population: `${population.totalPopulation}`')
      ..writeln('- Agent eligible: `${population.agentEligiblePopulation}`')
      ..writeln('- Active agents: `${population.estimatedActiveAgentPopulation}`')
      ..writeln('- Dormant agents: `${population.estimatedDormantAgentPopulation}`')
      ..writeln('- Deleted agents: `${population.estimatedDeletedAgentPopulation}`')
      ..writeln('- Under-13 dependent mobility: `${population.dependentMobilityPopulation}`')
      ..writeln('- Modeled actors: `${population.modeledActorCount}`')
      ..writeln(
        '- Locality coverage: `${(((population.metadata['localityCoveragePct'] as num?) ?? 0).toDouble() * 100).toStringAsFixed(1)}%`',
      )
      ..writeln(
        '- Population model kind: `${population.metadata['populationModelKind'] ?? 'unknown'}`',
      )
      ..writeln();
  }

  if (summary.placeGraph != null) {
    final placeGraph = summary.placeGraph!;
    buffer
      ..writeln('## Place Graph Coverage')
      ..writeln()
      ..writeln('- Graph nodes: `${placeGraph.nodeCount}`')
      ..writeln('- Venue profiles: `${placeGraph.venueProfiles.length}`')
      ..writeln('- Club profiles: `${placeGraph.clubProfiles.length}`')
      ..writeln('- Organization profiles: `${placeGraph.organizationProfiles.length}`')
      ..writeln('- Community profiles: `${placeGraph.communityProfiles.length}`')
      ..writeln('- Event profiles: `${placeGraph.eventProfiles.length}`')
      ..writeln('- Localities: `${placeGraph.localityCounts.length}`')
      ..writeln();
  }

  if (summary.kernelParticipationReport != null) {
    final report = summary.kernelParticipationReport!;
    buffer
      ..writeln('## Kernel Participation')
      ..writeln()
      ..writeln('- Active kernels: `${report.activeKernelCount}` / `${report.requiredKernelCount}`')
      ..writeln();
    for (final record in report.records) {
      buffer.writeln(
        '- `${record.kernelId}` `${record.status}` `${record.evidenceCount}` evidence refs',
      );
    }
    buffer.writeln();
  }

  if (summary.actorKernelCoverageReport != null) {
    final report = summary.actorKernelCoverageReport!;
    buffer
      ..writeln('## Actor Kernel Coverage')
      ..writeln()
      ..writeln('- Actor count: `${report.actorCount}`')
      ..writeln('- Actors with full bundle: `${report.actorsWithFullBundle}`')
      ..writeln('- Activation traces: `${report.traces.length}`')
      ..writeln();
  }

  if (summary.exchangeSummary != null) {
    final summaryReport = summary.exchangeSummary!;
    buffer
      ..writeln('## Connectivity And Exchange')
      ..writeln()
      ..writeln(
        '- Actors with connectivity profiles: `${summary.metadata['actorsWithConnectivityProfiles'] ?? 0}`',
      )
      ..writeln(
        '- Connectivity transitions: `${summary.metadata['connectivityTransitionCount'] ?? 0}`',
      )
      ..writeln('- Exchange threads: `${summaryReport.totalThreads}`')
      ..writeln('- Exchange events: `${summaryReport.totalExchangeEvents}`')
      ..writeln('- AI2AI records: `${summaryReport.totalAi2AiRecords}`')
      ..writeln(
        '- Actors with any exchange: `${summaryReport.actorsWithAnyExchange}`',
      )
      ..writeln(
        '- Actors with personal AI threads: `${summaryReport.actorsWithPersonalAiThreads}`',
      )
      ..writeln(
        '- Actors with admin support: `${summaryReport.actorsWithAdminSupport}`',
      )
      ..writeln(
        '- Actors with group threads: `${summaryReport.actorsWithGroupThreads}`',
      )
      ..writeln(
        '- Offline queued exchanges: `${summaryReport.offlineQueuedExchangeCount}`',
      )
      ..writeln();
  }

  if (summary.calibrationReport != null) {
    final report = summary.calibrationReport!;
    buffer
      ..writeln('## Calibration')
      ..writeln()
      ..writeln('- Passed: `${report.passed}`')
      ..writeln('- Metric count: `${report.records.length}`')
      ..writeln('- Unresolved metrics: `${report.unresolvedMetrics.length}`')
      ..writeln();
    for (final record in report.records.take(12)) {
      final variancePct =
          (record.metadata['variancePct'] as num?)?.toStringAsFixed(2) ?? '0.00';
      buffer.writeln(
        '- `${record.metricId}` target `${record.targetValue}` actual `${record.actualValue}` variance `$variancePct%` passed `${record.passed}`',
      );
    }
    buffer.writeln();
  }

  if (summary.realismGateReport != null) {
    final report = summary.realismGateReport!;
    buffer
      ..writeln('## Realism Gates')
      ..writeln()
      ..writeln('- Ready for Monte Carlo base year: `${report.readyForMonteCarloBaseYear}`')
      ..writeln('- Open gaps: `${report.unresolvedGaps.length}`')
      ..writeln();
    for (final record in report.records) {
      buffer.writeln('- `${record.gateId}` `${record.status}` ${record.rationale}');
    }
    if (report.unresolvedGaps.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Unresolved Gaps')
        ..writeln();
      for (final gap in report.unresolvedGaps) {
        buffer.writeln('- `$gap`');
      }
    }
    buffer.writeln();
  }

  buffer..writeln('## Entity Type Counts')..writeln();
  for (final entry in summary.entityTypeCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Forecast Disposition Counts')
    ..writeln();
  for (final entry in summary.forecastDispositionCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Notes')
    ..writeln();
  for (final note in summary.notes) {
    buffer.writeln('- $note');
  }

  return '$buffer';
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_kernel_participation_service.dart';

const _defaultExecutionPlanInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json';
const _defaultForecastBatchInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json';
const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultIsolationReportInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/52_BHAM_REPLAY_ISOLATION_REPORT_2023.json';
const _defaultRollupInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json';
const _defaultBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';
const _defaultActorKernelCoverageInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json';
const _defaultExchangeSummaryInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.json';

Future<void> main(List<String> args) async {
  final executionPlanInput = _readFlag(args, '--execution-plan-input') ??
      _defaultExecutionPlanInputPath;
  final forecastBatchInput = _readFlag(args, '--forecast-batch-input') ??
      _defaultForecastBatchInputPath;
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final isolationReportInput =
      _readFlag(args, '--isolation-report-input') ??
          _defaultIsolationReportInputPath;
  final rollupInput =
      _readFlag(args, '--rollup-input') ?? _defaultRollupInputPath;
  final behaviorInput =
      _readFlag(args, '--behavior-input') ?? _defaultBehaviorInputPath;
  final actorKernelCoverageInput =
      _readFlag(args, '--actor-kernel-coverage-input') ??
          _defaultActorKernelCoverageInputPath;
  final exchangeSummaryInput =
      _readFlag(args, '--exchange-summary-input') ??
          _defaultExchangeSummaryInputPath;
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
  final actorKernelCoverageReport = ReplayActorKernelCoverageReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(actorKernelCoverageInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final exchangeSummary = ReplayExchangeSummary.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(exchangeSummaryInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final report = const BhamReplayKernelParticipationService().buildReport(
    environment: environment,
    populationProfile: populationProfile,
    placeGraph: placeGraph,
    executionPlan: executionPlan,
    forecastBatch: forecastBatch,
    rollupBatch: rollups,
    behaviorPass: behaviorPass,
    isolationReport: isolationReport,
    actorKernelCoverageReport: actorKernelCoverageReport,
    exchangeSummary: exchangeSummary,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(report));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay kernel participation report for ${report.activeKernelCount}/${report.requiredKernelCount} kernels.',
  );
}

String _buildMarkdown(ReplayKernelParticipationReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Kernel Participation')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Active kernels: `${report.activeKernelCount}`')
    ..writeln('- Required kernels: `${report.requiredKernelCount}`')
    ..writeln()
    ..writeln('## Records')
    ..writeln();

  for (final record in report.records) {
    buffer.writeln(
      '- `${record.kernelId}` `${record.status}` `${record.evidenceCount}` `${record.authoritySurface}`',
    );
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

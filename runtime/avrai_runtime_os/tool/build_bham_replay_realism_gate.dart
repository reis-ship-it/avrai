import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_realism_gate_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultIsolationReportInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/52_BHAM_REPLAY_ISOLATION_REPORT_2023.json';
const _defaultKernelParticipationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.json';
const _defaultRollupInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json';
const _defaultBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';
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
const _defaultPhysicalMovementInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json';
const _defaultTrainingSignalsInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json';
const _defaultHoldoutEvaluationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json';

Future<void> main(List<String> args) async {
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
  final kernelParticipationInput =
      _readFlag(args, '--kernel-participation-input') ??
          _defaultKernelParticipationInputPath;
  final rollupInput =
      _readFlag(args, '--rollup-input') ?? _defaultRollupInputPath;
  final behaviorInput =
      _readFlag(args, '--behavior-input') ?? _defaultBehaviorInputPath;
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
  final physicalMovementInput =
      _readFlag(args, '--physical-movement-input') ??
          _defaultPhysicalMovementInputPath;
  final trainingSignalsInput =
      _readFlag(args, '--training-signals-input') ??
          _defaultTrainingSignalsInputPath;
  final holdoutEvaluationInput =
      _readFlag(args, '--holdout-evaluation-input') ??
          _defaultHoldoutEvaluationInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

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
  final kernelReport = ReplayKernelParticipationReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(kernelParticipationInput).readAsStringSync())
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
  final physicalMovementFile = File(physicalMovementInput);
  final physicalMovementReport = physicalMovementFile.existsSync()
      ? ReplayPhysicalMovementReport.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(physicalMovementFile.readAsStringSync())
                as Map<String, dynamic>,
          ),
        )
      : null;
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
  final actionExplanations = (jsonDecode(
    File(actionExplanationsInput).readAsStringSync(),
  ) as List)
      .whereType<Map>()
      .map((entry) => ReplayActionExplanation.fromJson(
            Map<String, dynamic>.from(entry),
          ))
      .toList(growable: false);

  final report = const BhamReplayRealismGateService().buildReport(
    environment: environment,
    populationProfile: populationProfile,
    placeGraph: placeGraph,
    kernelReport: kernelReport,
    isolationReport: isolationReport,
    rollupBatch: rollups,
    behaviorPass: behaviorPass,
    dailyBehaviorBatch: dailyBehaviorBatch,
    calibrationReport: calibrationReport,
    actionExplanations: actionExplanations,
    actorKernelCoverageReport: actorKernelCoverageReport,
    connectivityProfiles: connectivityProfiles,
    exchangeSummary: exchangeSummary,
    physicalMovementReport: physicalMovementReport,
    trainingBundle: trainingBundle,
    holdoutEvaluationReport: holdoutEvaluationReport,
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
    'Wrote BHAM replay realism gate report with ${report.records.length} gates.',
  );
}

String _buildMarkdown(ReplayRealismGateReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Realism Gate Report')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Replay year: `${report.replayYear}`')
    ..writeln(
      '- Ready for Monte Carlo base year: `${report.readyForMonteCarloBaseYear}`',
    )
    ..writeln()
    ..writeln('## Gate Records')
    ..writeln();

  for (final record in report.records) {
    buffer.writeln('- `${record.gateId}` `${record.status}` ${record.rationale}');
  }

  if (report.unresolvedGaps.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Unresolved Gaps')
      ..writeln();
    for (final gap in report.unresolvedGaps) {
      buffer.writeln('- `$gap`');
    }
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

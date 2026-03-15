import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_holdout_evaluation_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultExchangeSummaryInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.json';
const _defaultPhysicalMovementInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json';
const _defaultTrainingSignalsInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ?? _defaultDailyBehaviorInputPath;
  final exchangeSummaryInput =
      _readFlag(args, '--exchange-summary-input') ??
          _defaultExchangeSummaryInputPath;
  final physicalMovementInput =
      _readFlag(args, '--physical-movement-input') ??
          _defaultPhysicalMovementInputPath;
  final trainingSignalsInput =
      _readFlag(args, '--training-signals-input') ??
          _defaultTrainingSignalsInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final environment = ReplayVirtualWorldEnvironment.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(environmentInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final placeGraph = ReplayPlaceGraph.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(placeGraphInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final dailyBehaviorBatch = ReplayDailyBehaviorBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(dailyBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final exchangeSummary = ReplayExchangeSummary.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(exchangeSummaryInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final physicalMovementReport = ReplayPhysicalMovementReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(physicalMovementInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final trainingBundle = BhamReplayActionTrainingBundle.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(trainingSignalsInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final report = const BhamReplayHoldoutEvaluationService().buildReport(
    environment: environment,
    placeGraph: placeGraph,
    dailyBehaviorBatch: dailyBehaviorBatch,
    exchangeSummary: exchangeSummary,
    physicalMovementReport: physicalMovementReport,
    trainingBundle: trainingBundle,
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
    'Wrote BHAM replay holdout evaluation with ${report.metrics.length} metrics.',
  );
}

String _buildMarkdown(ReplayHoldoutEvaluationReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Holdout Evaluation')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Replay year: `${report.replayYear}`')
    ..writeln('- Passed: `${report.passed}`')
    ..writeln('- Training months: `${report.trainingMonths.join(', ')}`')
    ..writeln('- Validation months: `${report.validationMonths.join(', ')}`')
    ..writeln('- Holdout months: `${report.holdoutMonths.join(', ')}`')
    ..writeln()
    ..writeln('## Metrics')
    ..writeln();

  for (final metric in report.metrics) {
    buffer.writeln(
      '- `${metric.metricName}` `${metric.passed}` train=`${metric.trainingValue}` validation=`${metric.validationValue}` holdout=`${metric.holdoutValue}` threshold=`${metric.threshold}`',
    );
  }

  if (report.notes.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Notes')
      ..writeln();
    for (final note in report.notes) {
      buffer.writeln('- $note');
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

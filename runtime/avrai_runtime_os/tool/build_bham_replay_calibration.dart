import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_calibration_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultKernelParticipationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final kernelParticipationInput =
      _readFlag(args, '--kernel-participation-input') ??
          _defaultKernelParticipationInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ??
          _defaultDailyBehaviorInputPath;
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
  final kernelParticipationReport = ReplayKernelParticipationReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(kernelParticipationInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final dailyBehaviorBatch = ReplayDailyBehaviorBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(dailyBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final report = const BhamReplayCalibrationService().buildReport(
    environment: environment,
    populationProfile: populationProfile,
    placeGraph: placeGraph,
    dailyBehaviorBatch: dailyBehaviorBatch,
    kernelParticipationReport: kernelParticipationReport,
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
    'Wrote BHAM replay calibration report with ${report.records.length} metrics.',
  );
}

String _buildMarkdown(ReplayCalibrationReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Calibration Report')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Replay year: `${report.replayYear}`')
    ..writeln('- Passed: `${report.passed}`')
    ..writeln()
    ..writeln('## Metrics')
    ..writeln();

  for (final record in report.records) {
    final variancePct =
        (record.metadata['variancePct'] as num?)?.toStringAsFixed(2) ?? '0.00';
    buffer.writeln(
      '- `${record.metricId}` target `${record.targetValue}` actual `${record.actualValue}` variance `$variancePct%` passed `${record.passed}`',
    );
  }

  if (report.unresolvedMetrics.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Unresolved Metrics')
      ..writeln();
    for (final metric in report.unresolvedMetrics) {
      buffer.writeln('- `$metric`');
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

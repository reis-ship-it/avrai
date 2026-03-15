import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_isolation_gate_service.dart';

const _defaultExecutionPlanInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json';
const _defaultForecastBatchInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json';
const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/52_BHAM_REPLAY_ISOLATION_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/52_BHAM_REPLAY_ISOLATION_REPORT_2023.json';

Future<void> main(List<String> args) async {
  final executionPlanInput = _readFlag(args, '--execution-plan-input') ??
      _defaultExecutionPlanInputPath;
  final forecastBatchInput = _readFlag(args, '--forecast-batch-input') ??
      _defaultForecastBatchInputPath;
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
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

  final report = const BhamReplayIsolationGateService().buildReport(
    executionPlan: executionPlan,
    forecastBatch: forecastBatch,
    environment: environment,
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
    'Wrote BHAM replay isolation report with ${report.violations.length} violations.',
  );
}

String _buildMarkdown(ReplayIsolationReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Isolation Report')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Passed: `${report.passed}`')
    ..writeln('- Violations: `${report.violations.length}`')
    ..writeln()
    ..writeln('## Policy Snapshot')
    ..writeln();

  for (final entry in report.policySnapshot.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Violations')
    ..writeln();
  if (report.violations.isEmpty) {
    buffer.writeln('- `none`');
  } else {
    for (final violation in report.violations) {
      buffer.writeln('- $violation');
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

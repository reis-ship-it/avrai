import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';

const _defaultInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json';
const _defaultPlanMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.md';
const _defaultPlanJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json';
const _defaultSummaryMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.md';
const _defaultSummaryJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/38_BHAM_REPLAY_EXECUTION_SUMMARY_2023.json';

Future<void> main(List<String> args) async {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final planMarkdownOut =
      _readFlag(args, '--plan-output') ?? _defaultPlanMarkdownOutPath;
  final planJsonOut =
      _readFlag(args, '--plan-json-out') ?? _defaultPlanJsonOutPath;
  final summaryMarkdownOut =
      _readFlag(args, '--summary-output') ?? _defaultSummaryMarkdownOutPath;
  final summaryJsonOut =
      _readFlag(args, '--summary-json-out') ?? _defaultSummaryJsonOutPath;

  final artifact = Map<String, dynamic>.from(
    jsonDecode(File(inputPath).readAsStringSync()) as Map<String, dynamic>,
  );

  final fixedClock = FixedClockSource(_buildInstant(DateTime.utc(2023, 1, 1)));
  final service = BhamReplayExecutionService(
    temporalKernel: SystemTemporalKernel(clockSource: fixedClock),
    replayClockSource: fixedClock,
  );

  final runContext = const MonteCarloRunContext(
    canonicalReplayYear: 2023,
    replayYear: 2023,
    branchId: 'canonical',
    runId: 'wave8_bham_truth_year',
    seed: 2023,
    divergencePolicy: 'none',
    branchPurpose: 'authoritative_bham_truth_year_execution_plan',
  );

  final plan = service.buildPlanFromConsolidatedArtifact(
    artifact: artifact,
    runContext: runContext,
  );
  final result = await service.executePlan(plan: plan);

  File(planMarkdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildPlanMarkdown(plan));
  File(planJsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(plan.toJson())}\n',
    );
  File(summaryMarkdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildSummaryMarkdown(result));
  File(summaryJsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay execution artifacts for ${plan.entries.length} observations.',
  );
}

TemporalInstant _buildInstant(DateTime time) {
  return TemporalInstant(
    referenceTime: time.toUtc(),
    civilTime: time,
    timezoneId: 'America/Chicago',
    provenance: const TemporalProvenance(
      authority: TemporalAuthority.device,
      source: 'bham_replay_execution_tool',
    ),
    uncertainty: const TemporalUncertainty.zero(),
    monotonicTicks: time.microsecondsSinceEpoch,
  );
}

String _buildPlanMarkdown(BhamReplayExecutionPlan plan) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Execution Plan')
    ..writeln()
    ..writeln('- Pack: `${plan.packId}`')
    ..writeln('- Replay year: `${plan.replayYear}`')
    ..writeln('- Branch: `${plan.runContext.branchId}`')
    ..writeln('- Run: `${plan.runContext.runId}`')
    ..writeln('- Planned observations: `${plan.entries.length}`')
    ..writeln('- Skipped sources: `${plan.skippedSources.length}`')
    ..writeln(
      '- First execution instant: `${plan.firstExecutionAt?.referenceTime.toUtc().toIso8601String() ?? 'n/a'}`',
    )
    ..writeln(
      '- Last execution instant: `${plan.lastExecutionAt?.referenceTime.toUtc().toIso8601String() ?? 'n/a'}`',
    )
    ..writeln()
    ..writeln('## Replay Isolation')
    ..writeln()
    ..writeln('- `live_runtime_state_attached`: `false`')
    ..writeln('- `mesh_runtime_state_attached`: `false`')
    ..writeln('- `ai2ai_runtime_state_attached`: `false`')
    ..writeln()
    ..writeln('## Entity Type Counts')
    ..writeln();

  for (final entry in plan.entityTypeCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Source Counts')
    ..writeln();
  for (final entry in plan.sourceCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Peak Replay Days')
    ..writeln();
  for (final entry in plan.dayCounts.entries.take(10)) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  return '$buffer';
}

String _buildSummaryMarkdown(BhamReplayExecutionResult result) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Execution Summary')
    ..writeln()
    ..writeln('- Pack: `${result.plan.packId}`')
    ..writeln('- Replay year: `${result.plan.replayYear}`')
    ..writeln('- Run: `${result.plan.runContext.runId}`')
    ..writeln('- Executed runtime events: `${result.executedEventIds.length}`')
    ..writeln(
      '- First executed instant: `${result.firstExecutedAt?.referenceTime.toUtc().toIso8601String() ?? 'n/a'}`',
    )
    ..writeln(
      '- Last executed instant: `${result.lastExecutedAt?.referenceTime.toUtc().toIso8601String() ?? 'n/a'}`',
    )
    ..writeln()
    ..writeln('## Replay Isolation')
    ..writeln()
    ..writeln('- `live_runtime_state_attached`: `false`')
    ..writeln('- `mesh_runtime_state_attached`: `false`')
    ..writeln('- `ai2ai_runtime_state_attached`: `false`')
    ..writeln()
    ..writeln('## Executed Entity Type Counts')
    ..writeln();

  for (final entry in result.executedEntityTypeCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Executed Source Counts')
    ..writeln();
  for (final entry in result.executedSourceCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/governed_forecast_runtime_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';
import 'package:reality_engine/reality_engine.dart';

const _defaultInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json';

Future<void> main(List<String> args) async {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final artifact = Map<String, dynamic>.from(
    jsonDecode(File(inputPath).readAsStringSync()) as Map<String, dynamic>,
  );

  final fixedClock = FixedClockSource(_buildInstant(DateTime.utc(2023, 1, 1)));
  final temporalKernel = SystemTemporalKernel(clockSource: fixedClock);
  final executionService = BhamReplayExecutionService(
    temporalKernel: temporalKernel,
    replayClockSource: fixedClock,
  );
  final runContext = const MonteCarloRunContext(
    canonicalReplayYear: 2023,
    replayYear: 2023,
    branchId: 'canonical',
    runId: 'wave8_bham_truth_year_forecast',
    seed: 2023,
    divergencePolicy: 'none',
    branchPurpose: 'authoritative_bham_truth_year_governed_forecast_batch',
  );
  final plan = executionService.buildPlanFromConsolidatedArtifact(
    artifact: artifact,
    runContext: runContext,
  );

  final batchService = BhamReplayForecastBatchService(
    governedForecastRuntimeService: GovernedForecastRuntimeService(
      forecastGovernanceProjectionService: ForecastGovernanceProjectionService(
        forecastKernel: buildNativeForecastKernel(),
        temporalKernel: temporalKernel,
      ),
      replayYearSelectionService: const AuthoritativeReplayYearSelectionService(
        completenessService: ReplayYearCompletenessService(),
      ),
    ),
    replayClockSource: fixedClock,
  );

  final result = await batchService.evaluatePlan(
    plan: plan,
    artifact: artifact,
    maxPerEntityType: 25,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(result));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
    );

  stdout.writeln(
    'Wrote governed BHAM replay forecast batch for ${result.evaluatedCount} observations.',
  );
}

TemporalInstant _buildInstant(DateTime time) {
  return TemporalInstant(
    referenceTime: time.toUtc(),
    civilTime: time,
    timezoneId: 'America/Chicago',
    provenance: const TemporalProvenance(
      authority: TemporalAuthority.device,
      source: 'bham_replay_forecast_batch_tool',
    ),
    uncertainty: const TemporalUncertainty.zero(),
    monotonicTicks: time.microsecondsSinceEpoch,
  );
}

String _buildMarkdown(BhamReplayForecastBatchResult result) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Governed Forecast Batch')
    ..writeln()
    ..writeln('- Replay year: `${result.runContext.replayYear}`')
    ..writeln('- Branch: `${result.runContext.branchId}`')
    ..writeln('- Run: `${result.runContext.runId}`')
    ..writeln('- Evaluated observations: `${result.evaluatedCount}`')
    ..writeln()
    ..writeln('## Replay Isolation')
    ..writeln()
    ..writeln('- `live_runtime_state_attached`: `false`')
    ..writeln('- `mesh_runtime_state_attached`: `false`')
    ..writeln('- `ai2ai_runtime_state_attached`: `false`')
    ..writeln()
    ..writeln('## Forecast Kernel')
    ..writeln()
    ..writeln(
      '- Selected kernel: `${result.metadata['selected_forecast_kernel_id'] ?? 'unknown'}`',
    )
    ..writeln(
      '- Execution mode: `${result.metadata['selected_forecast_kernel_execution_mode'] ?? 'unknown'}`',
    )
    ..writeln()
    ..writeln('## Disposition Counts')
    ..writeln();

  for (final entry in result.dispositionCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Entity Type Counts')
    ..writeln();
  for (final entry in result.entityTypeCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Source Counts')
    ..writeln();
  for (final entry in result.sourceCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Results')
    ..writeln();
  for (final item in result.items.take(25)) {
    buffer.writeln(
      '- `${item.observationId}` `${item.entityType}` `${item.disposition.name}` `${item.predictedOutcome}`',
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_forecast_batch_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_virtual_world_environment_service.dart';

const _defaultConsolidatedInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json';
const _defaultExecutionPlanInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json';
const _defaultForecastBatchInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';

Future<void> main(List<String> args) async {
  final consolidatedInput =
      _readFlag(args, '--consolidated-input') ?? _defaultConsolidatedInputPath;
  final executionPlanInput = _readFlag(args, '--execution-plan-input') ??
      _defaultExecutionPlanInputPath;
  final forecastBatchInput = _readFlag(args, '--forecast-batch-input') ??
      _defaultForecastBatchInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final consolidatedArtifact = Map<String, dynamic>.from(
    jsonDecode(File(consolidatedInput).readAsStringSync())
        as Map<String, dynamic>,
  );
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

  final environment =
      const BhamReplayVirtualWorldEnvironmentService().buildEnvironment(
    consolidatedArtifact: consolidatedArtifact,
    executionPlan: executionPlan,
    forecastBatch: forecastBatch,
    sourceArtifactRefs: <String>[
      '36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json',
      '37_BHAM_REPLAY_EXECUTION_PLAN_2023.json',
      '39_BHAM_REPLAY_GOVERNED_FORECAST_BATCH_2023.json',
    ],
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(environment));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(environment.toJson())}\n',
    );

  stdout.writeln(
    'Wrote replay virtual world environment for ${environment.nodeCount} nodes.',
  );
}

String _buildMarkdown(ReplayVirtualWorldEnvironment environment) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Virtual World Environment')
    ..writeln()
    ..writeln('- Environment: `${environment.environmentId}`')
    ..writeln('- Replay year: `${environment.replayYear}`')
    ..writeln(
        '- Namespace: `${environment.isolationBoundary.environmentNamespace}`')
    ..writeln('- Nodes: `${environment.nodeCount}`')
    ..writeln('- Observations: `${environment.observationCount}`')
    ..writeln(
        '- Forecast-evaluated observations: `${environment.forecastEvaluatedCount}`')
    ..writeln();

  buffer
    ..writeln('## Forecast Kernel')
    ..writeln()
    ..writeln(
      '- Selected kernel: `${environment.metadata['selected_forecast_kernel_id'] ?? 'unknown'}`',
    )
    ..writeln(
      '- Execution mode: `${environment.metadata['selected_forecast_kernel_execution_mode'] ?? 'unknown'}`',
    )
    ..writeln()
    ..writeln('## Isolation Boundary')
    ..writeln()
    ..writeln(
      '- Runtime mutation policy: `${environment.isolationBoundary.runtimeMutationPolicy.name}`',
    )
    ..writeln(
      '- Live ingress policy: `${environment.isolationBoundary.liveDataIngressPolicy.name}`',
    )
    ..writeln(
      '- App surface policy: `${environment.isolationBoundary.appSurfacePolicy.name}`',
    )
    ..writeln(
      '- Admin inspection policy: `${environment.isolationBoundary.adminInspectionPolicy.name}`',
    )
    ..writeln(
      '- Higher-agent policy: `${environment.isolationBoundary.higherAgentPolicy.name}`',
    )
    ..writeln('- Live runtime state attached: `false`')
    ..writeln('- Mesh runtime state attached: `false`')
    ..writeln('- AI2AI runtime state attached: `false`')
    ..writeln()
    ..writeln('## Entity Type Counts')
    ..writeln();

  for (final entry in environment.entityTypeCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Locality Counts')
    ..writeln();
  for (final entry in environment.localityCounts.entries.take(15)) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Forecast Disposition Counts')
    ..writeln();
  for (final entry in environment.forecastDispositionCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Nodes')
    ..writeln();
  for (final node in environment.nodes.take(20)) {
    buffer.writeln(
      '- `${node.subjectIdentity.entityType}` `${node.subjectIdentity.canonicalName}` `${node.localityAnchor ?? 'unanchored'}` `${node.observationIds.length}` observations',
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

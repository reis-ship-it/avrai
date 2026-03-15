import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_daily_behavior_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultHigherAgentBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final higherAgentBehaviorInput =
      _readFlag(args, '--higher-agent-behavior-input') ??
          _defaultHigherAgentBehaviorInputPath;
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
  final higherAgentBehaviorPass = ReplayHigherAgentBehaviorPass.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(higherAgentBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final batch = const BhamReplayDailyBehaviorService().buildBehavior(
    environment: environment,
    populationProfile: populationProfile,
    placeGraph: placeGraph,
    higherAgentBehaviorPass: higherAgentBehaviorPass,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(batch));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(batch.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay daily behavior batch with ${batch.actions.length} actions.',
  );
}

String _buildMarkdown(ReplayDailyBehaviorBatch batch) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Daily Behavior')
    ..writeln()
    ..writeln('- Environment: `${batch.environmentId}`')
    ..writeln('- Replay year: `${batch.replayYear}`')
    ..writeln('- Agendas: `${batch.agendas.length}`')
    ..writeln('- Actions: `${batch.actions.length}`')
    ..writeln('- Closure overrides: `${batch.closureOverrides.length}`')
    ..writeln()
    ..writeln('## Action Counts By Type')
    ..writeln();

  for (final entry in batch.actionCountsByType.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Action Counts By Locality')
    ..writeln();
  for (final entry in batch.actionCountsByLocality.entries.take(25)) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Actor Actions')
    ..writeln();
  for (final action in batch.actions.take(40)) {
    buffer.writeln(
      '- `${action.actorId}` `${action.actionType}` `${action.localityAnchor}` -> `${action.destinationChoice.entityType}` `${action.destinationChoice.entityId}` `${action.status}`',
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

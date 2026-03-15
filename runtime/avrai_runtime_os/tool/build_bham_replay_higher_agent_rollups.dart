import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_higher_agent_rollup_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
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

  final rollups = const BhamReplayHigherAgentRollupService().buildRollups(
    environment: environment,
    populationProfile: populationProfile,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(rollups));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(rollups.toJson())}\n',
    );

  stdout.writeln(
    'Wrote higher-agent replay rollups for ${rollups.rollups.length} rollups.',
  );
}

String _buildMarkdown(ReplayHigherAgentRollupBatch rollups) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Higher-Agent Rollups')
    ..writeln()
    ..writeln('- Environment: `${rollups.environmentId}`')
    ..writeln('- Replay year: `${rollups.replayYear}`')
    ..writeln('- Rollups: `${rollups.rollups.length}`')
    ..writeln()
    ..writeln('## Rollup Counts By Level')
    ..writeln();

  for (final entry in rollups.rollupCountsByLevel.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Rollups')
    ..writeln();
  for (final rollup in rollups.rollups.take(20)) {
    buffer.writeln(
      '- `${rollup.level.name}` `${rollup.canonicalName}` `${rollup.nodeCount}` nodes `${rollup.cautionHotspots.length}` caution hotspots',
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

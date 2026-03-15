import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_population_profile_service.dart';

const _defaultConsolidatedInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json';
const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';

Future<void> main(List<String> args) async {
  final consolidatedInput =
      _readFlag(args, '--consolidated-input') ?? _defaultConsolidatedInputPath;
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final consolidatedArtifact = Map<String, dynamic>.from(
    jsonDecode(File(consolidatedInput).readAsStringSync())
        as Map<String, dynamic>,
  );
  final environment = ReplayVirtualWorldEnvironment.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(environmentInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final profile = const BhamReplayPopulationProfileService().buildProfile(
    consolidatedArtifact: consolidatedArtifact,
    environment: environment,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(profile));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(profile.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay population profile for ${profile.totalPopulation} represented residents.',
  );
}

String _buildMarkdown(ReplayPopulationProfile profile) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Population Profile')
    ..writeln()
    ..writeln('- Replay year: `${profile.replayYear}`')
    ..writeln('- Total population: `${profile.totalPopulation}`')
    ..writeln('- Total housing units: `${profile.totalHousingUnits}`')
    ..writeln(
      '- Estimated occupied housing units: `${profile.estimatedOccupiedHousingUnits}`',
    )
    ..writeln('- Agent eligible population: `${profile.agentEligiblePopulation}`')
    ..writeln(
      '- Estimated active agent population: `${profile.estimatedActiveAgentPopulation}`',
    )
    ..writeln(
      '- Estimated dormant agent population: `${profile.estimatedDormantAgentPopulation}`',
    )
    ..writeln(
      '- Estimated deleted agent population: `${profile.estimatedDeletedAgentPopulation}`',
    )
    ..writeln(
      '- Dependent mobility population: `${profile.dependentMobilityPopulation}`',
    )
    ..writeln('- Modeled actor count: `${profile.modeledActorCount}`')
    ..writeln()
    ..writeln('## Locality Population Counts')
    ..writeln();

  for (final entry in profile.localityPopulationCounts.entries.take(20)) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Representative Actors')
    ..writeln();
  for (final actor in profile.actors.take(20)) {
    buffer.writeln(
      '- `${actor.actorId}` `${actor.populationRole.name}` `${actor.lifecycleState.name}` `${actor.localityAnchor}` `${actor.representedPopulationCount}` represented',
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

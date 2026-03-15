import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_place_graph_service.dart';

const _defaultConsolidatedInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json';
const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';

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

  final graph = const BhamReplayPlaceGraphService().buildGraph(
    consolidatedArtifact: consolidatedArtifact,
    environment: environment,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(graph));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(graph.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay place graph for ${graph.nodeCount} place nodes.',
  );
}

String _buildMarkdown(ReplayPlaceGraph graph) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Place Graph')
    ..writeln()
    ..writeln('- Replay year: `${graph.replayYear}`')
    ..writeln('- Node count: `${graph.nodeCount}`')
    ..writeln('- Venue profiles: `${graph.venueProfiles.length}`')
    ..writeln('- Club profiles: `${graph.clubProfiles.length}`')
    ..writeln('- Organization profiles: `${graph.organizationProfiles.length}`')
    ..writeln('- Community profiles: `${graph.communityProfiles.length}`')
    ..writeln('- Event profiles: `${graph.eventProfiles.length}`')
    ..writeln('- Localities: `${graph.localityCounts.length}`')
    ..writeln()
    ..writeln('## Venue Category Counts')
    ..writeln();

  for (final entry in graph.venueCategoryCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Event Category Counts')
    ..writeln();
  for (final entry in graph.eventCategoryCounts.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Club Category Counts')
    ..writeln();
  final clubCategoryCounts = Map<String, int>.from(
    graph.metadata['clubCategoryCounts'] as Map? ?? const <String, int>{},
  );
  final sortedClubEntries = clubCategoryCounts.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in sortedClubEntries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Locality Counts')
    ..writeln();
  final localityEntries = graph.localityCounts.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  for (final entry in localityEntries.take(25)) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Nodes')
    ..writeln();
  for (final node in graph.nodes.take(20)) {
    buffer.writeln(
      '- `${node.nodeType}` `${node.identity.canonicalName}` `${node.localityAnchor}` `${node.capacityBand ?? 'n/a'}` `${node.demandPressureBand ?? 'n/a'}`',
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

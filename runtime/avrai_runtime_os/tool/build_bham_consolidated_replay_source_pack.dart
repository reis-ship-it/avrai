import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_consolidated_replay_source_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';

const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.json';
const _defaultPackPaths = <String>[
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/14_BHAM_CITYWIDE_CULTURAL_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/16_BHAM_HISTORICAL_CITYWIDE_ARCHIVE_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/19_BHAM_CITYWIDE_SPATIAL_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/23_BHAM_REPLAY_HISTORICALIZED_SOURCE_PACK_2023_AUTOMATED.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/25_BHAM_OFFICIAL_CITY_EVENT_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/27_BHAM_HISTORICAL_COMMUNITY_ARCHIVE_EXTENSION_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/33_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/42_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_SOURCE_PACK_2023.json',
  '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/46_BHAM_OFFICIAL_ARTS_MUSEUMS_EXTENSION_SOURCE_PACK_2023.json',
];

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final packService = const BhamReplaySourcePackService();
  final packs = _defaultPackPaths
      .map((path) => packService.parsePackJson(File(path).readAsStringSync()))
      .toList(growable: false);

  final replayYear = packs.isEmpty ? 2023 : packs.first.replayYear;
  final consolidated =
      const BhamConsolidatedReplaySourcePackService().mergePacks(
    replayYear: replayYear,
    packs: packs,
  );

  final jsonPretty =
      const JsonEncoder.withIndent('  ').convert(consolidated.toJson());
  final markdown = _buildMarkdown(consolidated);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Wrote consolidated BHAM replay source pack ${consolidated.packId}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

String _buildMarkdown(ReplaySourcePack pack) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Consolidated Replay Source Pack')
    ..writeln()
    ..writeln('- Pack: `${pack.packId}`')
    ..writeln('- Replay year: `${pack.replayYear}`')
    ..writeln('- Merged source datasets: `${pack.datasets.length}`')
    ..writeln(
        '- Merged pack count: `${(pack.metadata['mergedPackIds'] as List?)?.length ?? 0}`')
    ..writeln()
    ..writeln('## Source Datasets')
    ..writeln();

  for (final dataset in pack.datasets) {
    buffer.writeln(
      '- `${dataset.sourceName}` records `${dataset.records.length}`',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Notes')
    ..writeln();
  for (final note in pack.notes) {
    buffer.writeln('- $note');
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

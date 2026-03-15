import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_eventbrite_meetup_historicalized_source_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';

const _defaultAutomatedPackPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/22_BHAM_REPLAY_SOURCE_PACK_2023_AUTOMATED.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/42_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_SOURCE_PACK_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/42_BHAM_EVENTBRITE_MEETUP_HISTORICALIZED_SOURCE_PACK_2023.json';

Future<void> main(List<String> args) async {
  final automatedPackPath =
      _readFlag(args, '--automated-pack') ?? _defaultAutomatedPackPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final automatedPack = const BhamReplaySourcePackService().parsePackJson(
    File(automatedPackPath).readAsStringSync(),
  );
  final pack = const BhamEventbriteMeetupHistoricalizedSourcePackService()
      .buildPack(automatedPack: automatedPack);

  final jsonPretty = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final markdown = _buildMarkdown(pack);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Wrote BHAM Eventbrite / Meetup historicalized source pack ${pack.packId}.',
  );
}

String _buildMarkdown(ReplaySourcePack pack) {
  final dataset = pack.datasets.isEmpty ? null : pack.datasets.first;
  final buffer = StringBuffer()
    ..writeln('# BHAM Eventbrite / Meetup Historicalized Source Pack')
    ..writeln()
    ..writeln('- Pack: `${pack.packId}`')
    ..writeln('- Replay year: `${pack.replayYear}`')
    ..writeln('- Dataset count: `${pack.datasets.length}`')
    ..writeln(
      '- Historicalized rows: `${dataset?.records.length ?? 0}`',
    )
    ..writeln()
    ..writeln(
      'This pack promotes only persistent Birmingham Meetup group pages as replay-safe community and club anchors.',
    )
    ..writeln()
    ..writeln('## Notes')
    ..writeln();

  for (final note in pack.notes) {
    buffer.writeln('- $note');
  }

  if (dataset != null) {
    final communityCount = dataset.records
        .where((record) => record['entity_type'] == 'community')
        .length;
    final clubCount = dataset.records
        .where((record) => record['entity_type'] == 'club')
        .length;
    buffer
      ..writeln()
      ..writeln('## Row Counts')
      ..writeln()
      ..writeln('- `community`: `$communityCount`')
      ..writeln('- `club`: `$clubCount`');
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_neighborhood_association_calendar_source_pack_service.dart';

const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/33_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_SOURCE_PACK_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/33_BHAM_NEIGHBORHOOD_ASSOCIATION_CALENDAR_SOURCE_PACK_2023.json';

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final pack =
      const BhamNeighborhoodAssociationCalendarSourcePackService().buildPack();

  final jsonPretty = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final markdown = _buildMarkdown(pack);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Wrote BHAM neighborhood association calendar source pack ${pack.packId}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

String _buildMarkdown(ReplaySourcePack pack) {
  final dataset = pack.datasets.single;
  final buffer = StringBuffer()
    ..writeln('# BHAM Neighborhood Association Calendar Source Pack')
    ..writeln()
    ..writeln('- Pack: `${pack.packId}`')
    ..writeln('- Replay year: `${pack.replayYear}`')
    ..writeln('- Records: `${dataset.records.length}`')
    ..writeln()
    ..writeln('This pack operationalizes neighborhood-association cadence truth through archival reconstruction.')
    ..writeln()
    ..writeln('## Associations')
    ..writeln();

  for (final record in dataset.records) {
    buffer.writeln(
      '- `${record['name']}` '
      '`${record['locality']}` '
      'meeting `${record['meeting_dates']}`',
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

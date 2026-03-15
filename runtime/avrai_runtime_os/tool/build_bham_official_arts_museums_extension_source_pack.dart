import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/prediction/bham_official_arts_museums_extension_source_pack_service.dart';

const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/46_BHAM_OFFICIAL_ARTS_MUSEUMS_EXTENSION_SOURCE_PACK_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/46_BHAM_OFFICIAL_ARTS_MUSEUMS_EXTENSION_SOURCE_PACK_2023.json';

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final pack = const BhamOfficialArtsMuseumsExtensionSourcePackService()
      .buildPack(replayYear: 2023);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(pack));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(pack.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM official arts & museums extension source pack ${pack.packId}.',
  );
}

String _buildMarkdown(dynamic pack) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Official Arts & Museums Extension Source Pack')
    ..writeln()
    ..writeln('- Pack: `${pack.packId}`')
    ..writeln('- Replay year: `${pack.replayYear}`')
    ..writeln('- Source datasets: `${pack.datasets.length}`')
    ..writeln()
    ..writeln('## Records')
    ..writeln();

  for (final dataset in pack.datasets) {
    buffer.writeln('- `${dataset.sourceName}` records `${dataset.records.length}`');
    for (final record in dataset.records) {
      buffer.writeln(
        '  - `${record['entity_type']}` `${record['title'] ?? record['name']}` `${record['locality']}`',
      );
    }
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

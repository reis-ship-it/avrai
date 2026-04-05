import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalized_source_pack_service.dart';

const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/31_BHAM_PUBLIC_CATALOG_HISTORICALIZED_SOURCE_PACK_2023.json';

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final pack = const BhamPublicCatalogHistoricalizedSourcePackService().buildPack();

  final jsonPretty = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final markdown = _buildMarkdown(pack);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Wrote BHAM public catalog historicalized source pack ${pack.packId}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

String _buildMarkdown(ReplaySourcePack pack) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Public Catalog Historicalized Source Pack')
    ..writeln()
    ..writeln('- Pack: `${pack.packId}`')
    ..writeln('- Replay year: `${pack.replayYear}`')
    ..writeln('- Dataset count: `${pack.datasets.length}`')
    ..writeln('- Excluded pending sources: `${(pack.metadata['excludedPendingHistoricalizationSources'] as List?)?.length ?? 0}`')
    ..writeln()
    ..writeln('This pack promotes only safe 2023-valid structural rows from current public catalogs.')
    ..writeln()
    ..writeln('## Datasets')
    ..writeln();

  for (final dataset in pack.datasets) {
    buffer
      ..writeln('- `${dataset.sourceName}`')
      ..writeln('  - records: `${dataset.records.length}`')
      ..writeln('  - status: `${dataset.metadata['status'] ?? 'unknown'}`');
  }

  final excluded = (pack.metadata['excludedPendingHistoricalizationSources'] as List?)
          ?.map((entry) => entry.toString())
          .toList() ??
      const <String>[];
  if (excluded.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Still Pending')
      ..writeln();
    for (final sourceName in excluded) {
      buffer.writeln('- `$sourceName`');
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_public_catalog_historicalization_bundle_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';

const _defaultInputPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/22_BHAM_REPLAY_SOURCE_PACK_2023_AUTOMATED.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/30_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_BUNDLE_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/30_BHAM_PUBLIC_CATALOG_HISTORICALIZATION_BUNDLE_2023.json';

Future<void> main(List<String> args) async {
  final inputPath = _readFlag(args, '--input') ?? _defaultInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Missing replay source pack: $inputPath');
    exit(1);
  }

  final pack = const BhamReplaySourcePackService().parsePackJson(
    inputFile.readAsStringSync(),
  );
  final bundle =
      const BhamPublicCatalogHistoricalizationBundleService().buildBundle(pack);

  final jsonPretty = const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(bundle));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Built BHAM public catalog historicalization bundle for ${bundle.replayYear}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

String _buildMarkdown(ReplayHistoricalizationBundle bundle) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Public Catalog Historicalization Bundle')
    ..writeln()
    ..writeln('- Replay year: `${bundle.replayYear}`')
    ..writeln('- Bundle id: `${bundle.bundleId}`')
    ..writeln('- Entry count: `${bundle.entries.length}`')
    ..writeln();

  for (final entry in bundle.entries) {
    buffer
      ..writeln('## ${entry.sourceName}')
      ..writeln()
      ..writeln('- Source URI: `${entry.sourceUri}`')
      ..writeln('- Coverage status: `${entry.coverageStatus}`')
      ..writeln('- Current catalog records: `${entry.recordCount}`')
      ..writeln()
      ..writeln('### Required Historical Fields')
      ..writeln();
    for (final field in entry.requiredHistoricalFields) {
      buffer.writeln('- `$field`');
    }
    buffer
      ..writeln()
      ..writeln('### Source-Specific Actions')
      ..writeln();
    for (final action in entry.sourceSpecificActions) {
      buffer.writeln('- $action');
    }
    if (entry.notes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Notes')
        ..writeln();
      for (final note in entry.notes) {
        buffer.writeln('- $note');
      }
    }
    if (entry.samples.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Sample Candidates')
        ..writeln();
      for (final sample in entry.samples) {
        buffer.writeln(
          '- `${sample.entityType}` ${sample.name}'
          ' (`${sample.locality ?? 'unknown'}`)',
        );
      }
    }
    buffer.writeln();
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

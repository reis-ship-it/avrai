import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_partition_service.dart';

const _defaultExportManifestInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json';
const _defaultPartitionRoot =
    'runtime_exports/replay_storage_partitions/bham_2023';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json';

Future<void> main(List<String> args) async {
  final exportManifestInput =
      _readFlag(args, '--export-manifest-input') ??
          _defaultExportManifestInputPath;
  final partitionRoot =
      _readFlag(args, '--partition-root') ?? _defaultPartitionRoot;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final maxRecordsPerChunk = int.tryParse(
        _readFlag(args, '--max-records-per-chunk') ?? '',
      ) ??
      1000;

  final exportManifest = ReplayStorageExportManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(exportManifestInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final partitionManifest =
      const BhamReplayStoragePartitionService().partitionStagedArtifacts(
    exportManifest: exportManifest,
    partitionRoot: partitionRoot,
    maxRecordsPerChunk: maxRecordsPerChunk,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(partitionManifest));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(partitionManifest.toJson())}\n',
    );

  stdout.writeln('Wrote BHAM replay storage partition summary.');
}

String _buildMarkdown(ReplayStoragePartitionManifest manifest) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Storage Partition Summary')
    ..writeln()
    ..writeln('- Environment: `${manifest.environmentId}`')
    ..writeln('- Replay year: `${manifest.replayYear}`')
    ..writeln('- Partition root: `${manifest.partitionRoot}`')
    ..writeln('- Max records per chunk: `${manifest.maxRecordsPerChunk}`')
    ..writeln('- Partition entries: `${manifest.entries.length}`')
    ..writeln('- Total bytes: `${manifest.totalBytes}`')
    ..writeln()
    ..writeln('## Partition Entries')
    ..writeln();

  for (final entry in manifest.entries) {
    buffer.writeln(
      '- `${entry.artifactRef}` / `${entry.section}` / chunk `${entry.chunkIndex}` -> `${entry.objectPath}` (`${entry.recordCount}` records, `${entry.byteSize}` bytes)',
    );
  }

  if (manifest.notes.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Notes')
      ..writeln();
    for (final note in manifest.notes) {
      buffer.writeln('- $note');
    }
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

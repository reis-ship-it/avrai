import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_supabase_upload_index_service.dart';

const _defaultExportManifestInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json';
const _defaultPartitionManifestInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/65_BHAM_REPLAY_STORAGE_PARTITION_SUMMARY_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/66_BHAM_REPLAY_SUPABASE_UPLOAD_INDEX_SUMMARY_2023.json';

void main(List<String> args) async {
  final liveMode = args.contains('--live');
  final exportManifestInput = _readFlag(args, '--export-manifest-input') ??
      _defaultExportManifestInputPath;
  final partitionManifestInput =
      _readFlag(args, '--partition-manifest-input') ??
          _defaultPartitionManifestInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final exportManifestFile = File(exportManifestInput);
  final partitionManifestFile = File(partitionManifestInput);
  if (!exportManifestFile.existsSync() || !partitionManifestFile.existsSync()) {
    throw StateError(
      'Replay storage manifests are missing. Generate 64 and 65 before upload/index.',
    );
  }

  final exportManifest = ReplayStorageExportManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(exportManifestFile.readAsStringSync()) as Map,
    ),
  );
  final partitionManifest = ReplayStoragePartitionManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(partitionManifestFile.readAsStringSync()) as Map,
    ),
  );

  final replayUrl = _readSecret('SUPABASE_REPLAY_URL');
  final replayAnonKey = _readSecret('SUPABASE_REPLAY_ANON_KEY');
  final replayServiceRoleKey = _readSecret('SUPABASE_REPLAY_SERVICE_ROLE_KEY');
  final dryRun = !liveMode ||
      replayUrl == null ||
      replayUrl.isEmpty ||
      replayServiceRoleKey == null ||
      replayServiceRoleKey.isEmpty;

  final service = const BhamReplaySupabaseUploadIndexService();
  final uploadManifest = service.buildUploadManifest(
    exportManifest: exportManifest,
    partitionManifest: partitionManifest,
    dryRun: dryRun,
  );
  final result = await service.uploadAndIndex(
    uploadManifest: uploadManifest,
    exportManifest: exportManifest,
    partitionManifest: partitionManifest,
    replayUrl: replayUrl,
    replayAnonKey: replayAnonKey,
    replayServiceRoleKey: replayServiceRoleKey,
    dryRun: dryRun,
  );

  final markdownFile = File(markdownOut)..parent.createSync(recursive: true);
  final jsonFile = File(jsonOut)..parent.createSync(recursive: true);

  markdownFile.writeAsStringSync(_buildMarkdown(result));
  jsonFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(result.toJson()),
  );

  stdout.writeln('Wrote BHAM replay Supabase upload/index summary.');
}

String? _readSecret(String key) {
  final fromEnvironment = Platform.environment[key]?.trim();
  if (fromEnvironment != null && fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }

  const candidates = <String>[
    '../../secrets/.env',
    '../secrets/.env',
    'secrets/.env',
    '.env',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          !trimmed.contains('=')) {
        continue;
      }
      final separator = trimmed.indexOf('=');
      final currentKey = trimmed.substring(0, separator).trim();
      if (currentKey != key) {
        continue;
      }
      final value = trimmed.substring(separator + 1).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

String _buildMarkdown(ReplayStorageUploadManifest manifest) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Supabase Upload And Index Summary')
    ..writeln()
    ..writeln('- Environment: `${manifest.environmentId}`')
    ..writeln('- Replay year: `${manifest.replayYear}`')
    ..writeln('- Replay schema: `${manifest.replaySchema}`')
    ..writeln('- Dry run: `${manifest.dryRun}`')
    ..writeln('- Project isolation mode: `${manifest.projectIsolationMode}`')
    ..writeln('- Upload entries: `${manifest.entries.length}`')
    ..writeln('- Total bytes: `${manifest.totalBytes}`')
    ..writeln();

  buffer
    ..writeln('## Notes')
    ..writeln();
  for (final note in manifest.notes) {
    buffer.writeln('- $note');
  }

  buffer
    ..writeln()
    ..writeln('## Representation Counts')
    ..writeln();
  final representationCounts = Map<String, dynamic>.from(
    manifest.metadata['representationCounts'] as Map? ??
        const <String, dynamic>{},
  );
  for (final entry in representationCounts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key))) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Bucket Counts')
    ..writeln();
  final bucketCounts = Map<String, dynamic>.from(
    manifest.metadata['bucketCounts'] as Map? ?? const <String, dynamic>{},
  );
  for (final entry in bucketCounts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key))) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Indexed Tables')
    ..writeln();
  final indexedTables = Map<String, dynamic>.from(
    manifest.metadata['indexedTables'] as Map? ?? const <String, dynamic>{},
  );
  if (indexedTables.isEmpty) {
    buffer.writeln('- none');
  } else {
    for (final entry in indexedTables.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      buffer.writeln('- `${entry.key}`: `${entry.value}`');
    }
  }

  final plannedIndexedTables = Map<String, dynamic>.from(
    manifest.metadata['plannedIndexedTables'] as Map? ??
        const <String, dynamic>{},
  );
  if (plannedIndexedTables.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Planned Indexed Tables')
      ..writeln();
    for (final entry in plannedIndexedTables.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      buffer.writeln('- `${entry.key}`: `${entry.value}`');
    }
  }
  return buffer.toString();
}

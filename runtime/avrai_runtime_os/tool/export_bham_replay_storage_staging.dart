import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_export_service.dart';

const _defaultManifestInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json';
const _defaultSourceRoot =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation';
const _defaultExportRoot = 'runtime_exports/replay_storage_staging/bham_2023';
const _defaultSummaryOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/64_BHAM_REPLAY_STORAGE_EXPORT_SUMMARY_2023.json';

Future<void> main(List<String> args) async {
  final manifestInput =
      _readFlag(args, '--manifest-input') ?? _defaultManifestInputPath;
  final sourceRoot = _readFlag(args, '--source-root') ?? _defaultSourceRoot;
  final exportRoot = _readFlag(args, '--export-root') ?? _defaultExportRoot;
  final markdownOut = _readFlag(args, '--output') ?? _defaultSummaryOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final manifest = ReplayTrainingExportManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(manifestInput).readAsStringSync()) as Map<String, dynamic>,
    ),
  );

  final exportManifest =
      const BhamReplayStorageExportService().exportToStaging(
    trainingManifest: manifest,
    sourceRoot: sourceRoot,
    exportRoot: exportRoot,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(exportManifest));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(exportManifest.toJson())}\n',
    );

  stdout.writeln('Wrote BHAM replay storage staging export summary.');
}

String _buildMarkdown(ReplayStorageExportManifest manifest) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Storage Export Summary')
    ..writeln()
    ..writeln('- Environment: `${manifest.environmentId}`')
    ..writeln('- Replay year: `${manifest.replayYear}`')
    ..writeln('- Status: `${manifest.status}`')
    ..writeln('- Export root: `${manifest.exportRoot}`')
    ..writeln('- Project isolation mode: `${manifest.projectIsolationMode}`')
    ..writeln('- Replay schema: `${manifest.replaySchema}`')
    ..writeln('- Exported entries: `${manifest.entries.length}`')
    ..writeln('- Total bytes: `${manifest.totalBytes}`')
    ..writeln()
    ..writeln('## Entries')
    ..writeln();

  for (final entry in manifest.entries) {
    buffer.writeln(
      '- `${entry.artifactRef}` -> `${entry.bucket}/${entry.objectPath}` (`${entry.byteSize}` bytes)',
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

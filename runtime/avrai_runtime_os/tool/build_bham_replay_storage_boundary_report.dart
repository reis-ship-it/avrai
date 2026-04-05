import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_boundary_service.dart';

const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/63_BHAM_REPLAY_STORAGE_BOUNDARY_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/63_BHAM_REPLAY_STORAGE_BOUNDARY_REPORT_2023.json';

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final report = const BhamReplayStorageBoundaryService().buildReport(
    environmentId: 'bham-replay-2023',
    replayYear: 2023,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(report));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );

  stdout.writeln('Wrote BHAM replay storage boundary report.');
}

String _buildMarkdown(ReplayStorageBoundaryReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Storage Boundary Report')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Replay year: `${report.replayYear}`')
    ..writeln('- Passed: `${report.passed}`')
    ..writeln('- Project isolation mode: `${report.projectIsolationMode}`')
    ..writeln('- Replay schema: `${report.replaySchema}`')
    ..writeln()
    ..writeln('## Replay Buckets')
    ..writeln();
  for (final bucket in report.replayBuckets) {
    buffer.writeln('- `$bucket`');
  }
  buffer
    ..writeln()
    ..writeln('## Replay Metadata Tables')
    ..writeln();
  for (final table in report.replayMetadataTables) {
    buffer.writeln('- `${report.replaySchema}.$table`');
  }
  buffer
    ..writeln()
    ..writeln('## App Buckets')
    ..writeln();
  for (final bucket in report.appBuckets) {
    buffer.writeln('- `$bucket`');
  }
  buffer
    ..writeln()
    ..writeln('## Policy Snapshot')
    ..writeln();
  final policyEntries = report.policySnapshot.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in policyEntries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }
  if (report.notes.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Notes')
      ..writeln();
    for (final note in report.notes) {
      buffer.writeln('- $note');
    }
  }
  buffer
    ..writeln()
    ..writeln('## Violations')
    ..writeln();
  if (report.violations.isEmpty) {
    buffer.writeln('- `none`');
  } else {
    for (final violation in report.violations) {
      buffer.writeln('- $violation');
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

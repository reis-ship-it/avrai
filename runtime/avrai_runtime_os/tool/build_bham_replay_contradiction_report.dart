import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';

const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/74_BHAM_REPLAY_CONTRADICTION_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/74_BHAM_REPLAY_CONTRADICTION_REPORT_2023.json';

Future<void> main(List<String> args) async {
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final snapshot = await ReplaySimulationAdminService().getSnapshot();

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(snapshot));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(snapshot.contradictions.map((entry) => entry.toJson()).toList())}\n',
    );
  stdout.writeln('Wrote BHAM replay contradiction report.');
}

String _buildMarkdown(ReplaySimulationAdminSnapshot snapshot) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Contradiction Report')
    ..writeln()
    ..writeln('- Generated: `${snapshot.generatedAt.toIso8601String()}`')
    ..writeln('- Contradictions: `${snapshot.contradictions.length}`')
    ..writeln();

  for (final contradiction in snapshot.contradictions) {
    buffer.writeln(
      '- `${contradiction.localityCode}` `${contradiction.contradictionType.name}` severity `${contradiction.severity.toStringAsFixed(2)}` status `${contradiction.status.name}`',
    );
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

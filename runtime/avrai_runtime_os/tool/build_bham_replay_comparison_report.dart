import 'dart:convert';
import 'dart:io';

import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';

const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/73_BHAM_REPLAY_COMPARISON_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/73_BHAM_REPLAY_COMPARISON_REPORT_2023.json';

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
      '${const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
            'generatedAt': snapshot.generatedAt.toIso8601String(),
            'comparisons':
                snapshot.comparisons.map((entry) => entry.toJson()).toList(),
            'receipts':
                snapshot.receipts.map((entry) => entry.toJson()).toList(),
            'overlays': snapshot.localityOverlays
                .map((entry) => entry.toJson())
                .toList(),
          })}\n',
    );
  stdout.writeln('Wrote BHAM replay comparison report.');
}

String _buildMarkdown(ReplaySimulationAdminSnapshot snapshot) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Comparison Report')
    ..writeln()
    ..writeln('- Generated: `${snapshot.generatedAt.toIso8601String()}`')
    ..writeln('- Comparisons: `${snapshot.comparisons.length}`')
    ..writeln('- Receipts: `${snapshot.receipts.length}`')
    ..writeln();

  for (final comparison in snapshot.comparisons) {
    buffer
      ..writeln('## ${comparison.scenarioId}')
      ..writeln()
      ..writeln('- Summary: ${comparison.summary}')
      ..writeln('- Branches: `${comparison.branchRunIds.length}`')
      ..writeln();
    for (final diff in comparison.branchDiffs) {
      buffer.writeln(
        '- `${diff.branchRunId}` attendance `${diff.attendanceDelta.toStringAsFixed(2)}` movement `${diff.movementDelta.toStringAsFixed(2)}` delivery `${diff.deliveryDelta.toStringAsFixed(2)}` safety `${diff.safetyStressDelta.toStringAsFixed(2)}`',
      );
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

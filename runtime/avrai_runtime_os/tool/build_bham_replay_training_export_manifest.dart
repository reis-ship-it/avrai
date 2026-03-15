import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_training_export_manifest_service.dart';

const _defaultSummaryInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json';
const _defaultCalibrationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json';
const _defaultPhysicalMovementInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json';

Future<void> main(List<String> args) async {
  final summaryInput =
      _readFlag(args, '--summary-input') ?? _defaultSummaryInputPath;
  final calibrationInput =
      _readFlag(args, '--calibration-input') ?? _defaultCalibrationInputPath;
  final physicalMovementInput =
      _readFlag(args, '--physical-movement-input') ??
          _defaultPhysicalMovementInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final summary = ReplaySingleYearPassSummary.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(summaryInput).readAsStringSync()) as Map<String, dynamic>,
    ),
  );
  final calibrationReport = ReplayCalibrationReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(calibrationInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final physicalMovementFile = File(physicalMovementInput);
  final physicalMovementReport = physicalMovementFile.existsSync()
      ? ReplayPhysicalMovementReport.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(physicalMovementFile.readAsStringSync())
                as Map<String, dynamic>,
          ),
        )
      : null;

  final manifest = const BhamReplayTrainingExportManifestService().buildManifest(
    summary: summary,
    calibrationReport: calibrationReport,
    physicalMovementReport: physicalMovementReport,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(manifest));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
    );

  stdout.writeln('Wrote BHAM replay training export manifest.');
}

String _buildMarkdown(ReplayTrainingExportManifest manifest) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Training Export Manifest')
    ..writeln()
    ..writeln('- Environment: `${manifest.environmentId}`')
    ..writeln('- Replay year: `${manifest.replayYear}`')
    ..writeln('- Status: `${manifest.status}`')
    ..writeln()
    ..writeln('## Metrics')
    ..writeln();

  final entries = manifest.metrics.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Artifact Refs')
    ..writeln();
  for (final ref in manifest.artifactRefs) {
    buffer.writeln('- `$ref`');
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

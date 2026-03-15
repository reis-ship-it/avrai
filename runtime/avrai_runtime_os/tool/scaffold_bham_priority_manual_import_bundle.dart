import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_manual_import_bundle_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';

const _defaultManifestPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json';
const _defaultPullPlanPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/09_BHAM_REPLAY_PULL_PLAN_2023.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_IMPORT_BUNDLE_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/11_BHAM_REPLAY_PRIORITY_MANUAL_IMPORT_BUNDLE_2023.json';

void main(List<String> args) {
  final manifestPath = _resolvePath(
    _readFlag(args, '--manifest') ?? _defaultManifestPath,
  );
  final pullPlanPath = _resolvePath(
    _readFlag(args, '--pull-plan') ?? _defaultPullPlanPath,
  );
  final markdownOut = _resolvePath(
    _readFlag(args, '--output') ?? _defaultMarkdownOutPath,
  );
  final jsonOut = _resolvePath(
    _readFlag(args, '--json-out') ?? _defaultJsonOutPath,
  );
  final prioritySources = _readListFlag(args, '--sources');

  final manifest = _loadManifest(manifestPath);
  final pullPlan = _loadPullPlanBatch(pullPlanPath);
  final bundle =
      const BhamReplayManualImportBundleService().buildPriorityBundle(
    manifest: manifest,
    pullPlan: pullPlan,
    prioritySources: prioritySources?.isNotEmpty == true
        ? prioritySources!
        : BhamReplayManualImportBundleService.defaultPrioritySources,
  );

  final jsonPretty =
      const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  final markdown = _buildMarkdown(bundle);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Built BHAM priority manual-import bundle scaffold for ${bundle.replayYear}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

ReplayIngestionManifest _loadManifest(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing replay ingestion manifest: $path');
    exit(1);
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('Replay ingestion manifest is empty: $path');
    exit(1);
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    stderr.writeln('Replay ingestion manifest must be a JSON object.');
    exit(1);
  }
  return ReplayIngestionManifest.fromJson(
    decoded.map((key, value) => MapEntry('$key', value)),
  );
}

BhamReplayPullPlanBatch _loadPullPlanBatch(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing replay pull plan: $path');
    exit(1);
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('Replay pull plan is empty: $path');
    exit(1);
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    stderr.writeln('Replay pull plan must be a JSON object.');
    exit(1);
  }
  final plans = (decoded['plans'] as List?)
          ?.whereType<Map>()
          .map(
            (entry) => ReplaySourcePullPlan.fromJson(
              entry.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList() ??
      const <ReplaySourcePullPlan>[];
  return BhamReplayPullPlanBatch(
    replayYear: (decoded['replayYear'] as num?)?.toInt() ?? 0,
    plans: plans,
    notes: (decoded['notes'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        const <String>[],
  );
}

String _buildMarkdown(ReplayManualImportBundle bundle) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Priority Manual Import Bundle')
    ..writeln()
    ..writeln('- Replay year: `${bundle.replayYear}`')
    ..writeln('- Bundle id: `${bundle.bundleId}`')
    ..writeln('- Entry count: `${bundle.entries.length}`')
    ..writeln()
    ..writeln('## Priority Sources')
    ..writeln();

  for (final entry in bundle.entries) {
    buffer
        .writeln('- `${entry.sourceName}` -> raw key `${entry.rawOutputKey}`');
    buffer.writeln('  targets: ${entry.normalizationTargets.join(', ')}');
    buffer.writeln('  required fields: ${entry.requiredFields.join(', ')}');
    if (entry.notes.isNotEmpty) {
      buffer.writeln('  notes: ${entry.notes.join(' | ')}');
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

List<String>? _readListFlag(List<String> args, String flag) {
  final raw = _readFlag(args, flag);
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return raw
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

String _resolvePath(String rawPath) {
  final direct = File(rawPath);
  if (direct.existsSync() || direct.parent.existsSync()) {
    return direct.path;
  }

  final runtimeRelative = File('runtime/avrai_runtime_os/$rawPath');
  if (runtimeRelative.existsSync() || runtimeRelative.parent.existsSync()) {
    return runtimeRelative.path;
  }

  return rawPath;
}

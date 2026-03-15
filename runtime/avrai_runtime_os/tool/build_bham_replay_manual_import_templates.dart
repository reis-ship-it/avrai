import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_manual_import_template_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';

const _defaultManifestPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json';
const _defaultPullPlanPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/09_BHAM_REPLAY_PULL_PLAN_2023.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/10_BHAM_REPLAY_MANUAL_IMPORT_TEMPLATES.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/10_BHAM_REPLAY_MANUAL_IMPORT_TEMPLATES.json';

void main(List<String> args) {
  final manifestPath = _readFlag(args, '--manifest') ?? _defaultManifestPath;
  final pullPlanPath = _readFlag(args, '--pull-plan') ?? _defaultPullPlanPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final manifest = _loadManifest(manifestPath);
  final pullPlan = _loadPullPlanBatch(pullPlanPath);
  final templates = const BhamReplayManualImportTemplateService().buildTemplates(
    manifest: manifest,
    pullPlan: pullPlan,
  );

  final jsonPretty = const JsonEncoder.withIndent('  ').convert(templates.toJson());
  final markdown = _buildMarkdown(templates);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Built BHAM replay manual import templates for ${templates.replayYear}.',
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

String _buildMarkdown(ReplayManualImportTemplateBatch batch) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Manual Import Templates')
    ..writeln()
    ..writeln('- Replay year: `${batch.replayYear}`')
    ..writeln('- Template count: `${batch.templates.length}`')
    ..writeln()
    ..writeln('## Templates')
    ..writeln();

  for (final template in batch.templates) {
    buffer.writeln(
      '- `${template.sourceName}` -> raw key `${template.rawOutputKey}`',
    );
    buffer.writeln('  targets: ${template.normalizationTargets.join(', ')}');
    if (template.dedupeKeys.isNotEmpty) {
      buffer.writeln('  dedupe: ${template.dedupeKeys.join(', ')}');
    }
    buffer.writeln('  required fields: ${template.requiredFields.join(', ')}');
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

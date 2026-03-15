import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';

const _defaultManifestPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json';
const _defaultRegistryPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/03_BHAM_SOURCE_REGISTRY_DATA.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/09_BHAM_REPLAY_PULL_PLAN_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/09_BHAM_REPLAY_PULL_PLAN_2023.json';

void main(List<String> args) {
  final manifestPath = _readFlag(args, '--input') ?? _defaultManifestPath;
  final registryPath = _readFlag(args, '--registry') ?? _defaultRegistryPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final manifest = _loadManifest(manifestPath);
  final registry = _loadRegistry(registryPath);
  final batch = const BhamReplayPullPlanService().buildPullPlan(
    manifest: manifest,
    registry: registry,
  );
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(batch.toJson());
  final markdown = _buildMarkdown(batch);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Built BHAM replay pull plan for ${batch.replayYear}.',
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

BhamReplaySourceRegistry _loadRegistry(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing replay source registry: $path');
    exit(1);
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('Replay source registry is empty: $path');
    exit(1);
  }
  try {
    return const BhamReplaySourceRegistryService().parseRegistryJson(raw);
  } on FormatException catch (error) {
    stderr.writeln('Invalid replay source registry: ${error.message}');
    exit(1);
  }
}

String _buildMarkdown(BhamReplayPullPlanBatch batch) {
  final automated = batch.plans
      .where((plan) => plan.acquisitionMode == ReplaySourceAcquisitionMode.automated)
      .length;
  final apiKeyRequired = batch.plans
      .where((plan) => plan.acquisitionMode == ReplaySourceAcquisitionMode.apiKeyRequired)
      .length;
  final manual = batch.plans
      .where((plan) => plan.acquisitionMode == ReplaySourceAcquisitionMode.manualImport)
      .length;
  final review = batch.plans
      .where((plan) => plan.acquisitionMode == ReplaySourceAcquisitionMode.partnerReview)
      .length;

  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Pull Plan')
    ..writeln()
    ..writeln('- Replay year: `${batch.replayYear}`')
    ..writeln('- Automated sources: `$automated`')
    ..writeln('- API-key-required sources: `$apiKeyRequired`')
    ..writeln('- Manual-import sources: `$manual`')
    ..writeln('- Review-gated sources: `$review`')
    ..writeln()
    ..writeln('## Source Pull Plans')
    ..writeln();

  for (final plan in batch.plans) {
    buffer.writeln(
      '- `${plan.sourceName}` [`${plan.acquisitionMode.name}`] -> raw key `${plan.rawOutputKey}`',
    );
    if (plan.sourceUrl != null) {
      buffer.writeln('  sourceUrl: ${plan.sourceUrl}');
    }
    if (plan.endpointRef != null) {
      buffer.writeln('  endpointRef: ${plan.endpointRef}');
    }
    for (final note in plan.notes) {
      buffer.writeln('  note: $note');
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

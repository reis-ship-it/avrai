import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_ingestion_manifest_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_registry_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';

const _defaultRegistryPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/03_BHAM_SOURCE_REGISTRY_DATA.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json';

void main(List<String> args) {
  final registryPath = _readFlag(args, '--input') ?? _defaultRegistryPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final registry = _loadRegistry(registryPath);
  final selectionService = const AuthoritativeReplayYearSelectionService(
    completenessService: ReplayYearCompletenessService(),
  );
  final selection = selectionService.select(
    candidateYears: registry.selectionCandidateYears,
    sources: registry.sources,
  );
  final manifest = const BhamReplayIngestionManifestService().buildManifest(
    registry: registry,
    selection: selection,
  );

  final jsonPretty = const JsonEncoder.withIndent('  ').convert(manifest.toJson());
  final markdown = _buildMarkdown(manifest);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Built BHAM replay ingestion manifest for ${manifest.replayYear}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
}

BhamReplaySourceRegistry _loadRegistry(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing BHAM replay source registry: $path');
    exit(1);
  }
  final raw = file.readAsStringSync().trim();
  if (raw.isEmpty) {
    stderr.writeln('BHAM replay source registry is empty: $path');
    exit(1);
  }
  try {
    return const BhamReplaySourceRegistryService().parseRegistryJson(raw);
  } on FormatException catch (error) {
    stderr.writeln('Invalid BHAM replay source registry: ${error.message}');
    exit(1);
  }
}

String _buildMarkdown(ReplayIngestionManifest manifest) {
  final ready = manifest.sourcePlans
      .where((plan) => plan.readiness == ReplayIngestionReadiness.ready)
      .length;
  final review = manifest.sourcePlans
      .where((plan) => plan.readiness == ReplayIngestionReadiness.pendingReview)
      .length;
  final blocked = manifest.sourcePlans
      .where((plan) => plan.readiness == ReplayIngestionReadiness.blocked)
      .length;

  final buffer = StringBuffer();
  buffer
    ..writeln('# BHAM Replay Ingestion Manifest')
    ..writeln()
    ..writeln('- Replay year: `${manifest.replayYear}`')
    ..writeln('- Generated at: `${manifest.generatedAtUtc.toUtc().toIso8601String()}`')
    ..writeln('- Overall completeness score: `${manifest.selectedScore.overallScore.toStringAsFixed(3)}`')
    ..writeln('- Ready sources: `$ready`')
    ..writeln('- Pending review sources: `$review`')
    ..writeln('- Blocked sources: `$blocked`')
    ..writeln()
    ..writeln('## Canonical Entity Types')
    ..writeln();

  for (final entityType in manifest.canonicalEntityTypes) {
    buffer.writeln('- `$entityType`');
  }

  buffer
    ..writeln()
    ..writeln('## Source Plans')
    ..writeln();

  for (final plan in manifest.sourcePlans) {
    buffer.writeln(
      '- `${plan.source.sourceName}`'
      ' [priority `${plan.ingestPriority}` / `${plan.readiness.name}`]'
      ' -> ${plan.normalizationTargetTypes.join(', ')}',
    );
    if (plan.dedupeKeys.isNotEmpty) {
      buffer.writeln('  dedupe: ${plan.dedupeKeys.join(', ')}');
    }
    for (final note in plan.notes) {
      buffer.writeln('  note: $note');
    }
  }

  buffer
    ..writeln()
    ..writeln('## Notes')
    ..writeln();

  for (final note in manifest.notes) {
    buffer.writeln('- $note');
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/services/prediction/aggregate_metric_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/bham_priority_replay_ingestion_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_source_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/calendar_event_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/historical_entity_replay_source_adapter.dart';
import 'package:avrai_runtime_os/services/prediction/replay_record_normalization_service.dart';
import 'package:avrai_runtime_os/services/prediction/spatial_feature_replay_source_adapter.dart';

const _defaultManifestPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/07_BHAM_REPLAY_INGESTION_MANIFEST.json';
const _defaultPackPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/35_BHAM_CONSOLIDATED_REPLAY_SOURCE_PACK_2023.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json';

Future<void> main(List<String> args) async {
  final manifestPath = _readFlag(args, '--manifest') ?? _defaultManifestPath;
  final packPath = _readFlag(args, '--pack') ?? _defaultPackPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final manifest = _loadManifest(manifestPath);
  final pack = _loadPack(packPath);
  final temporalKernel = SystemTemporalKernel(
    clockSource: SystemClockSource(timezoneId: 'America/Chicago'),
  );
  final service = BhamPriorityReplayIngestionService(
    adapters: const <BhamReplaySourceAdapter>[
      AggregateMetricReplaySourceAdapter(),
      HistoricalEntityReplaySourceAdapter(),
      CalendarEventReplaySourceAdapter(),
      SpatialFeatureReplaySourceAdapter(),
    ],
    normalizationService: ReplayRecordNormalizationService(
      temporalKernel: temporalKernel,
    ),
    temporalKernel: temporalKernel,
  );

  final result = await service.ingestManifest(
    manifest: manifest,
    rawRecordsBySourceName:
        const BhamReplaySourcePackService().toRawRecordsBySourceName(pack),
  );

  final artifactJson = <String, dynamic>{
    'pack': pack.toJson(),
    'ingestion': result.toJson(),
  };
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(artifactJson);
  final markdown = _buildMarkdown(pack: pack, result: result);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Wrote consolidated BHAM replay normalized observations for ${pack.packId}.',
  );
}

ReplayIngestionManifest _loadManifest(String path) {
  return ReplayIngestionManifest.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
    ),
  );
}

ReplaySourcePack _loadPack(String path) {
  return const BhamReplaySourcePackService().parsePackJson(
    File(path).readAsStringSync(),
  );
}

String _buildMarkdown({
  required ReplaySourcePack pack,
  required BhamReplayIngestionBatchResult result,
}) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Consolidated Replay Normalized Observations')
    ..writeln()
    ..writeln('- Pack: `${pack.packId}`')
    ..writeln('- Replay year: `${pack.replayYear}`')
    ..writeln('- Datasets: `${pack.datasets.length}`')
    ..writeln('- Ingested sources: `${result.results.length}`')
    ..writeln('- Skipped sources: `${result.skippedSources.length}`')
    ..writeln()
    ..writeln('## Ingested Sources')
    ..writeln();

  for (final entry in result.results) {
    buffer.writeln(
      '- `${entry.sourcePlan.source.sourceName}` '
      '[`${entry.adapterId}`] '
      'records `${entry.records.length}` '
      'observations `${entry.observations.length}`',
    );
  }

  if (result.skippedSources.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Skipped Sources')
      ..writeln();
    for (final sourceName in result.skippedSources) {
      buffer.writeln('- `$sourceName`');
    }
  }

  buffer
    ..writeln()
    ..writeln('## Observation Summary')
    ..writeln();

  for (final entry in result.results) {
    for (final observation in entry.observations) {
      buffer.writeln(
        '- `${observation.observationId}` '
        '-> `${observation.subjectIdentity.entityType}` '
        '`${observation.subjectIdentity.localityAnchor ?? 'unknown_locality'}`',
      );
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bea_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_pull_service.dart';
import 'package:avrai_runtime_os/services/prediction/census_acs_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/birmingham_public_library_archives_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_pull_plan_service.dart';
import 'package:avrai_runtime_os/services/prediction/eventbrite_meetup_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/in_birmingham_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/noaa_weather_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/open_street_map_replay_source_puller.dart';
import 'package:avrai_runtime_os/services/prediction/rpcgb_spatial_replay_source_puller.dart';

const _defaultPullPlanPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/09_BHAM_REPLAY_PULL_PLAN_2023.json';
const _defaultMarkdownOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/22_BHAM_REPLAY_AUTOMATED_PULL_SUMMARY_2023.md';
const _defaultJsonOutPath =
    '../../work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/22_BHAM_REPLAY_SOURCE_PACK_2023_AUTOMATED.json';

Future<void> main(List<String> args) async {
  final inputPath = _readFlag(args, '--input') ?? _defaultPullPlanPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final batch = _loadPullPlanBatch(inputPath);
  final service = BhamReplayAutomatedPullService(
    pullers: <dynamic>[
      CensusAcsReplaySourcePuller(
        apiKey: _readSecret('CENSUS_API_KEY'),
      ),
      BeaReplaySourcePuller(
        apiKey: _readSecret('BEA_API_KEY'),
      ),
      NoaaWeatherReplaySourcePuller(),
      OpenStreetMapReplaySourcePuller(),
      BirminghamPublicLibraryArchivesReplaySourcePuller(),
      RpcgbSpatialReplaySourcePuller(),
      InBirminghamReplaySourcePuller(),
      EventbriteMeetupReplaySourcePuller(),
    ].cast(),
  );
  final result = await service.pullPlans(
    replayYear: batch.replayYear,
    plans: batch.plans,
  );

  final exportPack = ReplaySourcePack(
    packId: result.pack.packId,
    replayYear: result.pack.replayYear,
    generatedAtUtc: result.pack.generatedAtUtc,
    datasets: result.pack.datasets,
    notes: result.pack.notes,
    metadata: <String, dynamic>{
      ...result.pack.metadata,
      'pulledSources': result.pulledSources,
      'skippedSources': result.skippedSources,
      'failedSources': result.failedSources,
    },
  );
  final jsonPretty = const JsonEncoder.withIndent('  ').convert(
    exportPack.toJson(),
  );
  final markdown = _buildMarkdown(result);

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(markdown);
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync('$jsonPretty\n');

  stdout.writeln(
    'Pulled automated BHAM replay sources for ${batch.replayYear}.',
  );
  stdout.writeln('Wrote $markdownOut and $jsonOut');
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

String? _readSecret(String key) {
  final fromEnvironment = Platform.environment[key]?.trim();
  if (fromEnvironment != null && fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }

  const candidates = <String>[
    '../../secrets/.env',
    '../secrets/.env',
    'secrets/.env',
    '.env',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#') || !trimmed.contains('=')) {
        continue;
      }
      final separator = trimmed.indexOf('=');
      final currentKey = trimmed.substring(0, separator).trim();
      if (currentKey != key) {
        continue;
      }
      final value = trimmed.substring(separator + 1).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

String _buildMarkdown(BhamReplayAutomatedPullBatchResult result) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Automated Pull Summary')
    ..writeln()
    ..writeln('- Replay year: `${result.pack.replayYear}`')
    ..writeln('- Pulled sources: `${result.pulledSources.length}`')
    ..writeln('- Skipped sources: `${result.skippedSources.length}`')
    ..writeln()
    ..writeln('## Pulled Sources')
    ..writeln();

  for (final sourceName in result.pulledSources) {
    buffer.writeln('- `$sourceName`');
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

  if (result.failedSources.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Failed Sources')
      ..writeln();
    result.failedSources.forEach((sourceName, error) {
      buffer.writeln('- `$sourceName`: $error');
    });
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

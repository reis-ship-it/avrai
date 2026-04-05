import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_exchange_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultConnectivityInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.json';
const _defaultEventLogJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ?? _defaultDailyBehaviorInputPath;
  final connectivityInput =
      _readFlag(args, '--connectivity-input') ?? _defaultConnectivityInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;
  final eventLogJsonOut =
      _readFlag(args, '--event-log-json-out') ?? _defaultEventLogJsonOutPath;

  final environment = ReplayVirtualWorldEnvironment.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(environmentInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final populationProfile = ReplayPopulationProfile.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(populationProfileInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final placeGraph = ReplayPlaceGraph.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(placeGraphInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final dailyBehaviorBatch = ReplayDailyBehaviorBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(dailyBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final connectivityProfiles = (jsonDecode(
    File(connectivityInput).readAsStringSync(),
  ) as List)
      .whereType<Map>()
      .map(
        (entry) =>
            ReplayConnectivityProfile.fromJson(Map<String, dynamic>.from(entry)),
      )
      .toList(growable: false);

  final result = const BhamReplayExchangeService().buildSimulation(
    environment: environment,
    populationProfile: populationProfile,
    placeGraph: placeGraph,
    dailyBehaviorBatch: dailyBehaviorBatch,
    connectivityProfiles: connectivityProfiles,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(result.summary));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(result.summary.toJson())}\n',
    );
  File(eventLogJsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'environmentId': result.summary.environmentId,
        'replayYear': result.summary.replayYear,
        'threads': result.threads.map((entry) => entry.toJson()).toList(),
        'participations':
            result.participations.map((entry) => entry.toJson()).toList(),
        'events': result.events.map((entry) => entry.toJson()).toList(),
        'ai2aiRecords':
            result.ai2aiRecords.map((entry) => entry.toJson()).toList(),
      })}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay exchange summary for ${result.summary.totalThreads} threads and ${result.summary.totalExchangeEvents} events.',
  );
}

String _buildMarkdown(ReplayExchangeSummary summary) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Exchange Summary')
    ..writeln()
    ..writeln('- Environment: `${summary.environmentId}`')
    ..writeln('- Replay year: `${summary.replayYear}`')
    ..writeln('- Threads: `${summary.totalThreads}`')
    ..writeln('- Exchange events: `${summary.totalExchangeEvents}`')
    ..writeln('- AI2AI records: `${summary.totalAi2AiRecords}`')
    ..writeln('- Actors with any exchange: `${summary.actorsWithAnyExchange}`')
    ..writeln('- Actors with personal AI threads: `${summary.actorsWithPersonalAiThreads}`')
    ..writeln('- Actors with admin support: `${summary.actorsWithAdminSupport}`')
    ..writeln('- Actors with group threads: `${summary.actorsWithGroupThreads}`')
    ..writeln('- Offline queued exchanges: `${summary.offlineQueuedExchangeCount}`')
    ..writeln()
    ..writeln('## Thread Counts By Kind')
    ..writeln();

  final threadCounts = summary.threadCountsByKind.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  for (final entry in threadCounts) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Connectivity Mode Counts')
    ..writeln();
  final connectivityCounts = summary.connectivityModeCounts.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  for (final entry in connectivityCounts) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
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

import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_actor_kernel_coverage_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultExchangeSummaryInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/61_BHAM_REPLAY_EXCHANGE_SUMMARY_2023.json';
const _defaultExchangeEventLogInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final behaviorInput =
      _readFlag(args, '--behavior-input') ?? _defaultBehaviorInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ?? _defaultDailyBehaviorInputPath;
  final exchangeSummaryInput =
      _readFlag(args, '--exchange-summary-input') ??
          _defaultExchangeSummaryInputPath;
  final exchangeEventLogInput =
      _readFlag(args, '--exchange-event-log-input') ??
          _defaultExchangeEventLogInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

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
  final higherAgentBehaviorPass = ReplayHigherAgentBehaviorPass.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(behaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final dailyBehaviorBatch = ReplayDailyBehaviorBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(dailyBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final exchangeSummary = ReplayExchangeSummary.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(exchangeSummaryInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final exchangeEventLog = Map<String, dynamic>.from(
    jsonDecode(File(exchangeEventLogInput).readAsStringSync())
        as Map<String, dynamic>,
  );
  final exchangeEvents = (exchangeEventLog['events'] as List?)
          ?.whereType<Map>()
          .map(
            (entry) => ReplayExchangeEvent.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(growable: false) ??
      const <ReplayExchangeEvent>[];

  final report = const BhamReplayActorKernelCoverageService().buildReport(
    environment: environment,
    populationProfile: populationProfile,
    dailyBehaviorBatch: dailyBehaviorBatch,
    higherAgentBehaviorPass: higherAgentBehaviorPass,
    exchangeSummary: exchangeSummary,
    exchangeEvents: exchangeEvents,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(report));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay actor kernel coverage for ${report.actorCount} actors.',
  );
}

String _buildMarkdown(ReplayActorKernelCoverageReport report) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Actor Kernel Coverage')
    ..writeln()
    ..writeln('- Environment: `${report.environmentId}`')
    ..writeln('- Replay year: `${report.replayYear}`')
    ..writeln('- Required kernels: `${report.requiredKernelIds.length}`')
    ..writeln('- Actor count: `${report.actorCount}`')
    ..writeln('- Actors with full bundle: `${report.actorsWithFullBundle}`')
    ..writeln('- Activation traces: `${report.traces.length}`')
    ..writeln()
    ..writeln('## Sample Actor Coverage')
    ..writeln();

  for (final record in report.records.take(25)) {
    buffer.writeln(
      '- `${record.actorId}` full `${record.hasFullBundle}` locality `${record.localityAnchor}` guidance `${record.higherAgentGuidanceCount}`',
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

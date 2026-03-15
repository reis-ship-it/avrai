import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultHigherAgentBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';
const _defaultExchangeEventLogInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json';
const _defaultPhysicalMovementInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/68_BHAM_REPLAY_TRAINING_SIGNALS_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ?? _defaultDailyBehaviorInputPath;
  final higherAgentBehaviorInput =
      _readFlag(args, '--higher-agent-behavior-input') ??
          _defaultHigherAgentBehaviorInputPath;
  final exchangeEventLogInput =
      _readFlag(args, '--exchange-event-log-input') ??
          _defaultExchangeEventLogInputPath;
  final physicalMovementInput =
      _readFlag(args, '--physical-movement-input') ??
          _defaultPhysicalMovementInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final environment = ReplayVirtualWorldEnvironment.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(environmentInput).readAsStringSync())
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
  final higherAgentBehaviorPass = ReplayHigherAgentBehaviorPass.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(higherAgentBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final exchangeArtifact = Map<String, dynamic>.from(
    jsonDecode(File(exchangeEventLogInput).readAsStringSync())
        as Map<String, dynamic>,
  );
  final exchangeThreads = (exchangeArtifact['threads'] as List? ??
          const <dynamic>[])
      .whereType<Map>()
      .map((entry) => ReplayExchangeThread.fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
  final exchangeEvents = (exchangeArtifact['events'] as List? ??
          const <dynamic>[])
      .whereType<Map>()
      .map((entry) => ReplayExchangeEvent.fromJson(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
  final ai2aiRecords = (exchangeArtifact['ai2aiRecords'] as List? ??
          const <dynamic>[])
      .whereType<Map>()
      .map(
        (entry) =>
            ReplayAi2AiExchangeRecord.fromJson(Map<String, dynamic>.from(entry)),
      )
      .toList(growable: false);
  final physicalMovementReport = ReplayPhysicalMovementReport.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(physicalMovementInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final bundle = const BhamReplayActionTrainingService().buildBundle(
    environment: environment,
    placeGraph: placeGraph,
    dailyBehaviorBatch: dailyBehaviorBatch,
    higherAgentBehaviorPass: higherAgentBehaviorPass,
    exchangeThreads: exchangeThreads,
    exchangeEvents: exchangeEvents,
    ai2aiRecords: ai2aiRecords,
    physicalMovementReport: physicalMovementReport,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(bundle));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(bundle.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay training signals with ${bundle.records.length} action records.',
  );
}

String _buildMarkdown(BhamReplayActionTrainingBundle bundle) {
  final counterfactualCount = bundle.records.fold<int>(
    0,
    (sum, record) => sum + record.counterfactuals.length,
  );
  final outcomeKinds = <String, int>{};
  for (final label in bundle.outcomeLabels) {
    outcomeKinds.update(label.outcomeKind, (value) => value + 1, ifAbsent: () => 1);
  }
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Training Signals')
    ..writeln()
    ..writeln('- Action training records: `${bundle.records.length}`')
    ..writeln('- Counterfactual choices: `$counterfactualCount`')
    ..writeln('- Outcome labels: `${bundle.outcomeLabels.length}`')
    ..writeln(
      '- Truth decision records: `${bundle.truthDecisionRecords.length}`',
    )
    ..writeln(
      '- Higher-agent intervention traces: `${bundle.higherAgentInterventionTraces.length}`',
    )
    ..writeln(
      '- Untracked windows: `${bundle.variationProfile.untrackedWindowCount}`',
    )
    ..writeln(
      '- Offline queued count: `${bundle.variationProfile.offlineQueuedCount}`',
    )
    ..writeln()
    ..writeln('## Outcome Kinds')
    ..writeln();

  final entries = outcomeKinds.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in entries) {
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

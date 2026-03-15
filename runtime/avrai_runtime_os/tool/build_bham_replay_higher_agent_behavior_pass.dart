import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_higher_agent_behavior_service.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultRollupInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/41_BHAM_REPLAY_HIGHER_AGENT_ROLLUPS_2023.json';
const _defaultExecutionPlanInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/37_BHAM_REPLAY_EXECUTION_PLAN_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/44_BHAM_REPLAY_HIGHER_AGENT_BEHAVIOR_PASS_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final rollupInput =
      _readFlag(args, '--rollup-input') ?? _defaultRollupInputPath;
  final executionPlanInput = _readFlag(args, '--execution-plan-input') ??
      _defaultExecutionPlanInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final environment = ReplayVirtualWorldEnvironment.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(environmentInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final rollups = ReplayHigherAgentRollupBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(rollupInput).readAsStringSync()) as Map<String, dynamic>,
    ),
  );
  final executionPlan = BhamReplayExecutionPlan.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(executionPlanInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final populationProfile = ReplayPopulationProfile.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(populationProfileInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final behaviorPass =
      const BhamReplayHigherAgentBehaviorService().buildBehaviorPass(
    environment: environment,
    rollupBatch: rollups,
    executionPlan: executionPlan,
    populationProfile: populationProfile,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(behaviorPass));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(behaviorPass.toJson())}\n',
    );

  stdout.writeln(
    'Wrote replay higher-agent behavior pass with ${behaviorPass.actions.length} actions.',
  );
}

String _buildMarkdown(ReplayHigherAgentBehaviorPass pass) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Higher-Agent Behavior Pass')
    ..writeln()
    ..writeln('- Environment: `${pass.environmentId}`')
    ..writeln('- Replay year: `${pass.replayYear}`')
    ..writeln('- Branch: `${pass.runContext.branchId}`')
    ..writeln('- Run: `${pass.runContext.runId}`')
    ..writeln('- Actions: `${pass.actions.length}`')
    ..writeln()
    ..writeln('## Action Counts By Type')
    ..writeln();
  for (final entry in pass.actionCountsByType.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Action Counts By Level')
    ..writeln();
  for (final entry in pass.actionCountsByLevel.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Actions')
    ..writeln();
  for (final action in pass.actions.take(25)) {
    buffer.writeln(
      '- `${action.level.name}` `${action.actionType.name}` `${action.monthKey}` `${action.agentId}`',
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

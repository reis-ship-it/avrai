import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_connectivity_service.dart';

const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json';

Future<void> main(List<String> args) async {
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final dailyBehaviorInput =
      _readFlag(args, '--daily-behavior-input') ?? _defaultDailyBehaviorInputPath;
  final markdownOut = _readFlag(args, '--output') ?? _defaultMarkdownOutPath;
  final jsonOut = _readFlag(args, '--json-out') ?? _defaultJsonOutPath;

  final populationProfile = ReplayPopulationProfile.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(populationProfileInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );
  final dailyBehaviorBatch = ReplayDailyBehaviorBatch.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(File(dailyBehaviorInput).readAsStringSync())
          as Map<String, dynamic>,
    ),
  );

  final profiles = const BhamReplayConnectivityService().buildProfiles(
    populationProfile: populationProfile,
    dailyBehaviorBatch: dailyBehaviorBatch,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(_buildMarkdown(profiles));
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(
        profiles.map((entry) => entry.toJson()).toList(),
      )}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay connectivity profiles for ${profiles.length} actors.',
  );
}

String _buildMarkdown(List<ReplayConnectivityProfile> profiles) {
  final modeCounts = <String, int>{};
  var transitionCount = 0;
  for (final profile in profiles) {
    modeCounts[profile.dominantMode.name] =
        (modeCounts[profile.dominantMode.name] ?? 0) + 1;
    transitionCount += profile.transitions.length;
  }

  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Connectivity Profiles')
    ..writeln()
    ..writeln('- Actor profiles: `${profiles.length}`')
    ..writeln('- Connectivity transitions: `$transitionCount`')
    ..writeln()
    ..writeln('## Dominant Modes')
    ..writeln();

  final sortedModes = modeCounts.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  for (final entry in sortedModes) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }

  buffer
    ..writeln()
    ..writeln('## Sample Profiles')
    ..writeln();
  for (final profile in profiles.take(25)) {
    buffer.writeln(
      '- `${profile.actorId}` `${profile.localityAnchor}` dominant `${profile.dominantMode.name}` transitions `${profile.transitions.length}`',
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

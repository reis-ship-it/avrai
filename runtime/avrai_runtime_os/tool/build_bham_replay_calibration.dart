import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_calibration_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_comparison_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_packet_service.dart';
import 'package:avrai_runtime_os/simulation/models/city_profile.dart';
import 'package:avrai_runtime_os/simulation/models/simulated_human.dart';
import 'package:avrai_runtime_os/simulation/models/spatial/geo_coordinate.dart';

const _defaultEnvironmentInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/40_BHAM_REPLAY_VIRTUAL_WORLD_ENVIRONMENT_2023.json';
const _defaultPopulationProfileInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json';
const _defaultPlaceGraphInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/51_BHAM_REPLAY_PLACE_GRAPH_2023.json';
const _defaultKernelParticipationInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/53_BHAM_REPLAY_KERNEL_PARTICIPATION_2023.json';
const _defaultDailyBehaviorInputPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json';
const _defaultMarkdownOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.md';
const _defaultJsonOutPath =
    'work/docs/plans/beta_launch/AVRAI_BHAM_BETA_LAUNCH_PACK/Bham simulation/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json';

Future<void> main(List<String> args) async {
  final environmentInput =
      _readFlag(args, '--environment-input') ?? _defaultEnvironmentInputPath;
  final populationProfileInput =
      _readFlag(args, '--population-profile-input') ??
          _defaultPopulationProfileInputPath;
  final placeGraphInput =
      _readFlag(args, '--place-graph-input') ?? _defaultPlaceGraphInputPath;
  final kernelParticipationInput =
      _readFlag(args, '--kernel-participation-input') ??
          _defaultKernelParticipationInputPath;
  final dailyBehaviorInput = _readFlag(args, '--daily-behavior-input') ??
      _defaultDailyBehaviorInputPath;
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
  File(placeGraphInput).readAsStringSync();
  File(kernelParticipationInput).readAsStringSync();
  File(dailyBehaviorInput).readAsStringSync();

  final scenarios = const BhamEventScenarioPackService().buildScenarioPack();
  final packetService = const BhamReplayScenarioPacketService();
  final comparisonService = const BhamReplayScenarioComparisonService();
  final comparisons = scenarios
      .map(
        (scenario) => comparisonService.compareScenarioRuns(
          packet: scenario,
          items: packetService.materializeScenarioBatchItems(scenario),
        ),
      )
      .toList(growable: false);
  final sampledPopulation = _buildSampledPopulation(populationProfile);
  final report = const BhamReplayCalibrationService().buildReport(
    scenarios: scenarios,
    sampledPopulation: sampledPopulation,
    comparisons: comparisons,
  );

  File(markdownOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      _buildMarkdown(
        report,
        environmentId: environment.environmentId,
      ),
    );
  File(jsonOut)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
    );

  stdout.writeln(
    'Wrote BHAM replay calibration report with ${report.records.length} metrics.',
  );
}

String _buildMarkdown(
  ReplayCalibrationReport report, {
  required String environmentId,
}) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Replay Calibration Report')
    ..writeln()
    ..writeln('- Environment: `$environmentId`')
    ..writeln('- Replay year: `${report.replayYear}`')
    ..writeln('- Passed: `${report.passed}`')
    ..writeln()
    ..writeln('## Metrics')
    ..writeln();

  for (final record in report.records) {
    final variancePct =
        (record.metadata['variancePct'] as num?)?.toStringAsFixed(2) ?? '0.00';
    buffer.writeln(
      '- `${record.metricId}` target `${record.targetValue}` actual `${record.actualValue}` variance `$variancePct%` passed `${record.passed}`',
    );
  }

  if (report.unresolvedMetrics.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Unresolved Metrics')
      ..writeln();
    for (final metric in report.unresolvedMetrics) {
      buffer.writeln('- `$metric`');
    }
  }

  return '$buffer';
}

List<SimulatedHuman> _buildSampledPopulation(
  ReplayPopulationProfile populationProfile,
) {
  final city = CityProfile.birmingham();
  const routine = DailyRoutine(
    wakeUpHour: 7,
    leaveForWorkHour: 8,
    arriveAtWorkHour: 9,
    leaveWorkHour: 17,
    arriveHomeHour: 18,
    sleepHour: 23,
  );
  const finances = FinancialProfile(
    discretionaryBudget: 0.6,
    priceSensitivity: 0.4,
  );
  const home = GeoCoordinate(33.5186, -86.8104);
  const work = GeoCoordinate(33.5150, -86.8010);
  final actors = populationProfile.actors.take(12).toList(growable: false);
  if (actors.isEmpty) {
    return <SimulatedHuman>[
      SimulatedHuman(
        id: 'fallback-human-1',
        city: city,
        routine: routine,
        finances: finances,
        homeLocation: home,
        workLocation: work,
      ),
    ];
  }
  return actors.asMap().entries.map((entry) {
    final actor = entry.value;
    final offset = entry.key / 100.0;
    return SimulatedHuman(
      id: actor.actorId,
      city: city,
      routine: routine,
      finances: finances,
      homeLocation: home,
      workLocation: work,
      socialFollowThrough: 0.45 + (offset % 0.2),
      weatherSensitivity: 0.4 + (offset % 0.2),
      nightlifeAffinity: 0.3 + (offset % 0.2),
    );
  }).toList(growable: false);
}

String? _readFlag(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

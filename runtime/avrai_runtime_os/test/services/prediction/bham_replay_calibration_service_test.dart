import 'package:avrai_runtime_os/services/prediction/bham_replay_calibration_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_comparison_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_packet_service.dart';
import 'package:avrai_runtime_os/simulation/models/city_profile.dart';
import 'package:avrai_runtime_os/simulation/models/simulated_human.dart';
import 'package:avrai_runtime_os/simulation/models/spatial/geo_coordinate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<SimulatedHuman> buildSampledPopulation() {
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
    return <SimulatedHuman>[
      SimulatedHuman(
        id: 'human-1',
        city: city,
        routine: routine,
        finances: finances,
        homeLocation: home,
        workLocation: work,
        socialFollowThrough: 0.50,
        weatherSensitivity: 0.45,
        nightlifeAffinity: 0.35,
      ),
      SimulatedHuman(
        id: 'human-2',
        city: city,
        routine: routine,
        finances: finances,
        homeLocation: home,
        workLocation: work,
        socialFollowThrough: 0.55,
        weatherSensitivity: 0.50,
        nightlifeAffinity: 0.40,
      ),
      SimulatedHuman(
        id: 'human-3',
        city: city,
        routine: routine,
        finances: finances,
        homeLocation: home,
        workLocation: work,
        socialFollowThrough: 0.60,
        weatherSensitivity: 0.55,
        nightlifeAffinity: 0.45,
      ),
    ];
  }

  test(
    'builds a calibration report from scenario, population, and comparison signals',
    () {
      final scenarios = const BhamEventScenarioPackService()
          .buildScenarioPack();
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

      final report = const BhamReplayCalibrationService().buildReport(
        scenarios: scenarios,
        sampledPopulation: buildSampledPopulation(),
        comparisons: comparisons,
      );

      expect(report.records.length, 6);
      expect(report.metadata['sampledPopulationCount'], 3);
      expect(report.metadata['comparisonCount'], comparisons.length);
      final scenarioCoverage = report.records.firstWhere(
        (record) => record.metricId == 'scenario_pack_coverage',
      );
      final socialFollowThrough = report.records.firstWhere(
        (record) => record.metricId == 'social_follow_through_avg',
      );
      final branchSensitivity = report.records.firstWhere(
        (record) => record.metricId == 'branch_sensitivity_signal',
      );

      expect(scenarioCoverage.passed, isTrue);
      expect(socialFollowThrough.passed, isTrue);
      expect(branchSensitivity.actualValue, greaterThan(0.0));
      expect(
        report.unresolvedMetrics,
        equals(
          report.records
              .where((record) => !record.passed)
              .map((record) => record.metricId)
              .toList(growable: false),
        ),
      );
    },
  );
}

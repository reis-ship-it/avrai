import 'package:avrai_core/models/temporal/replay_calibration_report.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/simulation/models/simulated_human.dart';

import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';

class BhamReplayCalibrationService {
  const BhamReplayCalibrationService();

  ReplayCalibrationReport buildReport({
    required List<ReplayScenarioPacket> scenarios,
    required List<SimulatedHuman> sampledPopulation,
    required List<ReplayScenarioComparison> comparisons,
  }) {
    final socialFollowThroughAvg = _average(
      sampledPopulation.map((entry) => entry.socialFollowThrough),
    );
    final weatherSensitivityAvg = _average(
      sampledPopulation.map((entry) => entry.weatherSensitivity),
    );
    final nightlifeAffinityAvg = _average(
      sampledPopulation.map((entry) => entry.nightlifeAffinity),
    );
    final branchSensitivityAvg = _average(
      comparisons.expand((comparison) => comparison.branchDiffs).map(
            (diff) => diff.localityPressureDeltas.values.fold<double>(
              0.0,
              (sum, value) => sum + value.abs(),
            ),
          ),
    );

    final records = <ReplayCalibrationRecord>[
      _minimumRecord(
        metricId: 'scenario_pack_coverage',
        targetValue: 6,
        actualValue: scenarios.length.toDouble(),
        rationale:
            'Phase 1 should cover the six Birmingham scenario families in the event scenario pack.',
      ),
      _rangeRecord(
        metricId: 'social_follow_through_avg',
        targetValue: 0.55,
        actualValue: socialFollowThroughAvg,
        allowedVariancePct: 30,
        rationale:
            'Actor realism needs moderate social follow-through instead of purely routine-driven acceptance.',
      ),
      _rangeRecord(
        metricId: 'weather_sensitivity_avg',
        targetValue: 0.50,
        actualValue: weatherSensitivityAvg,
        allowedVariancePct: 35,
        rationale:
            'Weather sensitivity should be materially present for outdoor Birmingham planning.',
      ),
      _rangeRecord(
        metricId: 'nightlife_affinity_avg',
        targetValue: 0.40,
        actualValue: nightlifeAffinityAvg,
        allowedVariancePct: 45,
        rationale:
            'Nightlife affinity should exist but not dominate the synthetic population.',
      ),
      _minimumRecord(
        metricId: 'branch_sensitivity_signal',
        targetValue: 0.60,
        actualValue: branchSensitivityAvg,
        rationale:
            'Scenario branches should generate measurable locality pressure deltas.',
      ),
      _minimumRecord(
        metricId: 'bham_locality_overlay_count',
        targetValue: 4,
        actualValue: scenarios
            .expand((scenario) => scenario.seedLocalityCodes)
            .toSet()
            .length
            .toDouble(),
        rationale:
            'Neighborhood-readable Birmingham overlays should exist for multiple localities.',
      ),
    ];

    final unresolved = records
        .where((record) => !record.passed)
        .map((record) => record.metricId)
        .toList(growable: false);
    return ReplayCalibrationReport(
      reportId:
          'bham_phase1_calibration_${DateTime.now().toUtc().millisecondsSinceEpoch}',
      replayYear: bhamReplayBaseYear,
      passed: unresolved.isEmpty,
      records: records,
      unresolvedMetrics: unresolved,
      metadata: <String, dynamic>{
        'cityCode': bhamReplayCityCode,
        'sampledPopulationCount': sampledPopulation.length,
        'comparisonCount': comparisons.length,
      },
    );
  }

  ReplayCalibrationRecord _minimumRecord({
    required String metricId,
    required double targetValue,
    required double actualValue,
    required String rationale,
  }) {
    return ReplayCalibrationRecord(
      metricId: metricId,
      targetValue: targetValue,
      actualValue: actualValue,
      allowedVariancePct: 0.0,
      passed: actualValue >= targetValue,
      rationale: rationale,
      metadata: <String, dynamic>{
        'comparison': 'minimum',
        'variancePct': targetValue == 0
            ? 0.0
            : ((targetValue - actualValue).clamp(0.0, double.infinity) /
                    targetValue) *
                100.0,
      },
    );
  }

  ReplayCalibrationRecord _rangeRecord({
    required String metricId,
    required double targetValue,
    required double actualValue,
    required double allowedVariancePct,
    required String rationale,
  }) {
    final deltaPct = targetValue == 0
        ? 0.0
        : ((actualValue - targetValue).abs() / targetValue) * 100.0;
    return ReplayCalibrationRecord(
      metricId: metricId,
      targetValue: targetValue,
      actualValue: actualValue,
      allowedVariancePct: allowedVariancePct,
      passed: deltaPct <= allowedVariancePct,
      rationale: rationale,
      metadata: <String, dynamic>{
        'comparison': 'range',
        'variancePct': deltaPct,
      },
    );
  }

  double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0.0;
    }
    return list.reduce((left, right) => left + right) / list.length;
  }
}

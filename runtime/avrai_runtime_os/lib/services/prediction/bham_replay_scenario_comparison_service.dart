import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';

import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_packet_service.dart';

class BhamReplayScenarioComparisonService {
  const BhamReplayScenarioComparisonService();

  ReplayScenarioComparison compareScenarioRuns({
    required ReplayScenarioPacket packet,
    required List<BhamReplayScenarioBatchItem> items,
  }) {
    if (items.isEmpty) {
      throw ArgumentError(
          'Scenario comparison requires at least one batch item.');
    }
    final baseline = items.first;
    final branchItems = items.skip(1).toList(growable: false);
    final branchDiffs = branchItems.map((item) {
      return ReplayScenarioBranchDiff(
        branchRunId: item.runId,
        attendanceDelta: item.attendanceScore - baseline.attendanceScore,
        movementDelta: item.movementScore - baseline.movementScore,
        deliveryDelta: item.deliveryScore - baseline.deliveryScore,
        safetyStressDelta: item.safetyStress - baseline.safetyStress,
        localityPressureDeltas: <String, double>{
          for (final locality in {
            ...baseline.localityPressures.keys,
            ...item.localityPressures.keys
          })
            locality: (item.localityPressures[locality] ?? 0.0) -
                (baseline.localityPressures[locality] ?? 0.0),
        },
        keyNarrativeLines: summarizeBranchDiffs(
          packet: packet,
          baseline: baseline,
          branch: item,
        ),
      );
    }).toList(growable: false);

    final dominantLocality = _dominantLocality(branchDiffs);
    return ReplayScenarioComparison(
      scenarioId: packet.scenarioId,
      baselineRunId: baseline.runId,
      branchRunIds:
          branchItems.map((item) => item.runId).toList(growable: false),
      branchDiffs: branchDiffs,
      summary:
          '${packet.name} shifts most strongly around ${displayNameForBhamLocality(dominantLocality)} with ${branchDiffs.length} intervention branches.',
      generatedAt: DateTime.now().toUtc(),
    );
  }

  List<String> summarizeBranchDiffs({
    required ReplayScenarioPacket packet,
    required BhamReplayScenarioBatchItem baseline,
    required BhamReplayScenarioBatchItem branch,
  }) {
    final dominantLocality = _dominantPressureLocality(
      baseline.localityPressures,
      branch.localityPressures,
    );
    return <String>[
      '${branch.branchLabel} shifts attendance by ${_signedPct(branch.attendanceScore - baseline.attendanceScore)} against baseline.',
      'Movement changes by ${_signedPct(branch.movementScore - baseline.movementScore)} and delivery changes by ${_signedPct(branch.deliveryScore - baseline.deliveryScore)}.',
      'The largest locality pressure change lands in ${displayNameForBhamLocality(dominantLocality)}.',
    ];
  }

  String _dominantLocality(List<ReplayScenarioBranchDiff> diffs) {
    final accumulator = <String, double>{};
    for (final diff in diffs) {
      for (final entry in diff.localityPressureDeltas.entries) {
        accumulator[entry.key] =
            (accumulator[entry.key] ?? 0.0) + entry.value.abs();
      }
    }
    if (accumulator.isEmpty) {
      return bhamLocalityDisplayNames.keys.first;
    }
    return accumulator.entries
        .reduce(
          (left, right) => left.value >= right.value ? left : right,
        )
        .key;
  }

  String _dominantPressureLocality(
    Map<String, double> baseline,
    Map<String, double> branch,
  ) {
    final codes = {...baseline.keys, ...branch.keys};
    var bestCode =
        codes.isEmpty ? bhamLocalityDisplayNames.keys.first : codes.first;
    var bestMagnitude = -1.0;
    for (final code in codes) {
      final magnitude = ((branch[code] ?? 0.0) - (baseline[code] ?? 0.0)).abs();
      if (magnitude > bestMagnitude) {
        bestMagnitude = magnitude;
        bestCode = code;
      }
    }
    return bestCode;
  }

  String _signedPct(double value) {
    final pct = (value * 100).toStringAsFixed(1);
    return value >= 0 ? '+$pct%' : '$pct%';
  }
}

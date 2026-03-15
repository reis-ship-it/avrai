import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';

import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';

class BhamReplayLocalityOverlayService {
  const BhamReplayLocalityOverlayService();

  List<ReplayLocalityOverlaySnapshot> buildOverlaySnapshots({
    required ReplayScenarioPacket packet,
    required ReplayScenarioComparison comparison,
    required List<ReplayContradictionSnapshot> contradictions,
  }) {
    final contradictionCounts = <String, int>{};
    for (final snapshot in contradictions) {
      contradictionCounts[snapshot.localityCode] =
          (contradictionCounts[snapshot.localityCode] ?? 0) + 1;
    }

    final localitySensitivity = <String, double>{};
    for (final diff in comparison.branchDiffs) {
      for (final entry in diff.localityPressureDeltas.entries) {
        localitySensitivity[entry.key] =
            (localitySensitivity[entry.key] ?? 0.0) + entry.value.abs();
      }
    }

    final codes = {
      ...packet.seedLocalityCodes,
      ...localitySensitivity.keys,
      ...contradictionCounts.keys,
    }.toList(growable: false)
      ..sort();

    return codes.map((localityCode) {
      final sensitivity = localitySensitivity[localityCode] ?? 0.0;
      final contradictionCount = contradictionCounts[localityCode] ?? 0;
      return ReplayLocalityOverlaySnapshot(
        localityCode: localityCode,
        displayName: displayNameForBhamLocality(localityCode),
        pressureBand: _pressureBand(sensitivity),
        attentionBand: contradictionCount >= 2 ? 'escalate' : 'watch',
        primarySignals: <String>[
          if (packet.seedLocalityCodes.contains(localityCode)) 'scenario_seed',
          if (sensitivity > 0.10) 'branch_sensitive',
          if (contradictionCount > 0) 'contradiction_present',
        ],
        branchSensitivity: sensitivity.clamp(0.0, 1.0),
        contradictionCount: contradictionCount,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList(growable: false);
  }

  String _pressureBand(double sensitivity) {
    if (sensitivity >= 0.35) {
      return 'high';
    }
    if (sensitivity >= 0.18) {
      return 'moderate';
    }
    return 'low';
  }
}

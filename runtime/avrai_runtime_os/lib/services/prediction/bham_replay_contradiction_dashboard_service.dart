import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';

class ReplayContradictionLocalitySummary {
  const ReplayContradictionLocalitySummary({
    required this.localityCode,
    required this.count,
    required this.averageSeverity,
  });

  final String localityCode;
  final int count;
  final double averageSeverity;
}

class BhamReplayContradictionDashboardService {
  const BhamReplayContradictionDashboardService();

  List<ReplayContradictionSnapshot> buildSnapshot({
    required ReplayScenarioPacket packet,
    required ReplayScenarioComparison comparison,
  }) {
    final snapshots = <ReplayContradictionSnapshot>[];
    for (final diff in comparison.branchDiffs) {
      snapshots.add(
        ReplayContradictionSnapshot(
          snapshotId: '${diff.branchRunId}:attendance',
          runId: diff.branchRunId,
          entityRef: packet.seedEntityRefs.isEmpty
              ? packet.scenarioId
              : packet.seedEntityRefs.first,
          localityCode: _dominantLocality(diff),
          contradictionType: _typeForDiff(diff),
          replayExpectation:
              'Baseline replay branch remains within ordinary Birmingham pressure.',
          liveObserved:
              'Intervention branch diverges from replay prior under ${diff.branchRunId}.',
          severity: _severityForDiff(diff),
          status: ReplayContradictionStatus.open,
          capturedAt: DateTime.now().toUtc(),
        ),
      );
    }
    return snapshots;
  }

  List<ReplayContradictionSnapshot> listRecentContradictions({
    required List<ReplayContradictionSnapshot> snapshots,
    int limit = 10,
  }) {
    final ordered = snapshots.toList()
      ..sort((left, right) => right.capturedAt.compareTo(left.capturedAt));
    return ordered.take(limit).toList(growable: false);
  }

  List<ReplayContradictionLocalitySummary> summarizeByLocality({
    required List<ReplayContradictionSnapshot> snapshots,
  }) {
    final buckets = <String, List<ReplayContradictionSnapshot>>{};
    for (final snapshot in snapshots) {
      buckets.putIfAbsent(
          snapshot.localityCode, () => <ReplayContradictionSnapshot>[]);
      buckets[snapshot.localityCode]!.add(snapshot);
    }
    return buckets.entries.map((entry) {
      final totalSeverity = entry.value.fold<double>(
        0.0,
        (sum, snapshot) => sum + snapshot.severity,
      );
      return ReplayContradictionLocalitySummary(
        localityCode: entry.key,
        count: entry.value.length,
        averageSeverity:
            entry.value.isEmpty ? 0.0 : totalSeverity / entry.value.length,
      );
    }).toList(growable: false)
      ..sort((left, right) =>
          right.averageSeverity.compareTo(left.averageSeverity));
  }

  ReplayContradictionType _typeForDiff(ReplayScenarioBranchDiff diff) {
    if (diff.safetyStressDelta.abs() >= 0.15) {
      return ReplayContradictionType.safetyStress;
    }
    if (diff.deliveryDelta.abs() >= 0.12) {
      return ReplayContradictionType.delivery;
    }
    if (diff.movementDelta.abs() >= 0.12) {
      return ReplayContradictionType.movement;
    }
    return ReplayContradictionType.localityPressure;
  }

  double _severityForDiff(ReplayScenarioBranchDiff diff) {
    return (diff.safetyStressDelta.abs() * 0.45 +
            diff.deliveryDelta.abs() * 0.25 +
            diff.movementDelta.abs() * 0.20 +
            diff.attendanceDelta.abs() * 0.10)
        .clamp(0.0, 1.0);
  }

  String _dominantLocality(ReplayScenarioBranchDiff diff) {
    if (diff.localityPressureDeltas.isEmpty) {
      return 'bham_downtown';
    }
    return diff.localityPressureDeltas.entries
        .reduce(
          (left, right) => left.value.abs() >= right.value.abs() ? left : right,
        )
        .key;
  }
}

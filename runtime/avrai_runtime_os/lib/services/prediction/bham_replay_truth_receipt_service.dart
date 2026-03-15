import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';

class BhamReplayTruthReceiptService {
  const BhamReplayTruthReceiptService();

  SimulationTruthReceipt buildReceipt({
    required ReplayScenarioPacket packet,
    required ReplayScenarioComparison comparison,
    required List<ReplayContradictionSnapshot> contradictions,
  }) {
    final dominantDiff = comparison.branchDiffs.isEmpty
        ? null
        : comparison.branchDiffs.reduce(
            (left, right) => left.safetyStressDelta.abs() >= right.safetyStressDelta.abs()
                ? left
                : right,
          );
    return SimulationTruthReceipt(
      receiptId: '${packet.scenarioId}:receipt',
      runId: comparison.baselineRunId,
      scenarioId: packet.scenarioId,
      forecastTraceRefs: comparison.branchRunIds
          .map((runId) => '$runId:trace')
          .toList(growable: false),
      replayPriorSummary: SimulationTruthSummaryBlock(
        title: 'Replay Prior',
        lines: <String>[
          'Phase 1 receipt remains replay-only prior for Birmingham beta.',
          '${packet.name} started from ${packet.seedLocalityCodes.length} seeded localities.',
        ],
        metadata: <String, dynamic>{
          'baseReplayYear': packet.baseReplayYear,
          'scope': packet.scope.name,
        },
      ),
      liveEvidenceSummary: SimulationTruthSummaryBlock(
        title: 'Live Evidence',
        lines: <String>[
          'No live user data is promoted here; this receipt is an internal simulation artifact.',
          if (dominantDiff != null)
            'Most volatile branch was ${dominantDiff.branchRunId} with safety delta ${dominantDiff.safetyStressDelta.toStringAsFixed(2)}.',
        ],
        metadata: const <String, dynamic>{
          'liveEvidencePromoted': false,
        },
      ),
      localityConsensusSummary: SimulationTruthSummaryBlock(
        title: 'Locality Consensus',
        lines: <String>[
          'Comparison synthesized locality pressure deltas across all seeded Birmingham localities.',
          'Branch sensitivity remains bounded and admin-visible only.',
        ],
      ),
      adminCorrectionSummary: SimulationTruthSummaryBlock(
        title: 'Admin Correction',
        lines: <String>[
          'No admin correction is auto-applied in phase 1.',
          'Receipts are for operator inspection and calibration only.',
        ],
      ),
      contradictionSummary: SimulationTruthSummaryBlock(
        title: 'Contradiction Summary',
        lines: <String>[
          '${contradictions.length} contradiction snapshots were generated from branch deltas.',
          if (contradictions.isNotEmpty)
            'Highest contradiction severity is ${contradictions.map((entry) => entry.severity).reduce((left, right) => left >= right ? left : right).toStringAsFixed(2)}.',
        ],
      ),
      generatedAt: DateTime.now().toUtc(),
    );
  }
}

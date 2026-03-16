import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:test/test.dart';

void main() {
  test('ReplayScenarioPacket normalizes base year and replay-only flag', () {
    final packet = ReplayScenarioPacket(
      scenarioId: 'scenario',
      name: 'Scenario',
      description: 'A replay-only scenario',
      cityCode: 'bham',
      baseReplayYear: 2021,
      scenarioKind: ReplayScenarioKind.eventOps,
      scope: ReplayScopeKind.city,
      seedEntityRefs: const <String>['event:test'],
      seedLocalityCodes: const <String>['bham_downtown'],
      seedObservationRefs: const <String>[],
      interventions: const <ReplayScenarioIntervention>[],
      expectedQuestions: const <String>['What changed?'],
      createdAt: DateTime.utc(2026, 3, 14),
      createdBy: 'tester',
      isReplayOnly: false,
    ).normalized();

    expect(packet.baseReplayYear, 2023);
    expect(packet.isReplayOnly, isTrue);
    expect(packet.isValidForPhase1, isTrue);
  });

  test('SimulationTruthReceipt round-trips through json', () {
    final receipt = SimulationTruthReceipt(
      receiptId: 'receipt-1',
      runId: 'run-1',
      scenarioId: 'scenario-1',
      forecastTraceRefs: const <String>['trace-1'],
      replayPriorSummary: const SimulationTruthSummaryBlock(
        title: 'Replay Prior',
        lines: <String>['Prior only'],
      ),
      liveEvidenceSummary: const SimulationTruthSummaryBlock(
        title: 'Live Evidence',
        lines: <String>['No live promotion'],
      ),
      localityConsensusSummary: const SimulationTruthSummaryBlock(
        title: 'Locality Consensus',
        lines: <String>['Bounded'],
      ),
      adminCorrectionSummary: const SimulationTruthSummaryBlock(
        title: 'Admin Correction',
        lines: <String>['Manual only'],
      ),
      contradictionSummary: const SimulationTruthSummaryBlock(
        title: 'Contradictions',
        lines: <String>['One open contradiction'],
      ),
      generatedAt: DateTime.utc(2026, 3, 14),
    );

    final decoded = SimulationTruthReceipt.fromJson(receipt.toJson());
    expect(decoded.receiptId, receipt.receiptId);
    expect(decoded.replayPriorSummary.title, 'Replay Prior');
    expect(decoded.forecastTraceRefs, contains('trace-1'));
  });
}

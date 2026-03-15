import 'dart:async';

import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_contradiction_dashboard_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_locality_overlay_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_comparison_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_packet_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_truth_receipt_service.dart';

class ReplaySimulationAdminSnapshot {
  const ReplaySimulationAdminSnapshot({
    required this.generatedAt,
    required this.scenarios,
    required this.comparisons,
    required this.receipts,
    required this.contradictions,
    required this.localityOverlays,
  });

  final DateTime generatedAt;
  final List<ReplayScenarioPacket> scenarios;
  final List<ReplayScenarioComparison> comparisons;
  final List<SimulationTruthReceipt> receipts;
  final List<ReplayContradictionSnapshot> contradictions;
  final List<ReplayLocalityOverlaySnapshot> localityOverlays;
}

class ReplaySimulationAdminService {
  ReplaySimulationAdminService({
    BhamEventScenarioPackService? scenarioPackService,
    BhamReplayScenarioPacketService? scenarioPacketService,
    BhamReplayScenarioComparisonService? scenarioComparisonService,
    BhamReplayTruthReceiptService? truthReceiptService,
    BhamReplayContradictionDashboardService? contradictionDashboardService,
    BhamReplayLocalityOverlayService? localityOverlayService,
    DateTime Function()? nowProvider,
  })  : _scenarioPackService =
            scenarioPackService ?? const BhamEventScenarioPackService(),
        _scenarioPacketService =
            scenarioPacketService ?? const BhamReplayScenarioPacketService(),
        _scenarioComparisonService = scenarioComparisonService ??
            const BhamReplayScenarioComparisonService(),
        _truthReceiptService =
            truthReceiptService ?? const BhamReplayTruthReceiptService(),
        _contradictionDashboardService = contradictionDashboardService ??
            const BhamReplayContradictionDashboardService(),
        _localityOverlayService =
            localityOverlayService ?? const BhamReplayLocalityOverlayService(),
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final BhamEventScenarioPackService _scenarioPackService;
  final BhamReplayScenarioPacketService _scenarioPacketService;
  final BhamReplayScenarioComparisonService _scenarioComparisonService;
  final BhamReplayTruthReceiptService _truthReceiptService;
  final BhamReplayContradictionDashboardService _contradictionDashboardService;
  final BhamReplayLocalityOverlayService _localityOverlayService;
  final DateTime Function() _nowProvider;

  Future<ReplaySimulationAdminSnapshot> getSnapshot() async {
    final scenarios = _scenarioPackService.buildScenarioPack(createdAt: _nowProvider());
    final comparisons = <ReplayScenarioComparison>[];
    final receipts = <SimulationTruthReceipt>[];
    final contradictions = <ReplayContradictionSnapshot>[];
    final overlays = <ReplayLocalityOverlaySnapshot>[];

    for (final scenario in scenarios) {
      final batchItems = _scenarioPacketService.materializeScenarioBatchItems(scenario);
      final comparison = _scenarioComparisonService.compareScenarioRuns(
        packet: scenario,
        items: batchItems,
      );
      final scenarioContradictions =
          _contradictionDashboardService.buildSnapshot(
        packet: scenario,
        comparison: comparison,
      );
      comparisons.add(comparison);
      contradictions.addAll(scenarioContradictions);
      receipts.add(
        _truthReceiptService.buildReceipt(
          packet: scenario,
          comparison: comparison,
          contradictions: scenarioContradictions,
        ),
      );
      overlays.addAll(
        _localityOverlayService.buildOverlaySnapshots(
          packet: scenario,
          comparison: comparison,
          contradictions: scenarioContradictions,
        ),
      );
    }

    final dedupedOverlays = <String, ReplayLocalityOverlaySnapshot>{};
    for (final overlay in overlays) {
      final current = dedupedOverlays[overlay.localityCode];
      if (current == null ||
          overlay.branchSensitivity > current.branchSensitivity ||
          overlay.contradictionCount > current.contradictionCount) {
        dedupedOverlays[overlay.localityCode] = overlay;
      }
    }

    return ReplaySimulationAdminSnapshot(
      generatedAt: _nowProvider(),
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: dedupedOverlays.values.toList(growable: false)
        ..sort(
          (left, right) =>
              right.branchSensitivity.compareTo(left.branchSensitivity),
        ),
    );
  }

  Stream<ReplaySimulationAdminSnapshot> watchSnapshot({
    Duration refreshInterval = const Duration(seconds: 20),
  }) {
    late final StreamController<ReplaySimulationAdminSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(await getSnapshot());
    }

    controller = StreamController<ReplaySimulationAdminSnapshot>.broadcast(
      onListen: () async {
        await emit();
        timer = Timer.periodic(refreshInterval, (_) {
          unawaited(emit());
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}

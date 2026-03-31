import 'dart:async';

import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_contradiction_dashboard_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_locality_overlay_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_comparison_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_packet_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_truth_receipt_service.dart';

class ReplaySimulationAdminEnvironmentDescriptor {
  const ReplaySimulationAdminEnvironmentDescriptor({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    this.description = '',
  });

  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String description;
}

class ReplaySimulationAdminSnapshot {
  const ReplaySimulationAdminSnapshot({
    required this.generatedAt,
    required this.environmentId,
    required this.cityCode,
    required this.replayYear,
    required this.scenarios,
    required this.comparisons,
    required this.receipts,
    required this.contradictions,
    required this.localityOverlays,
  });

  final DateTime generatedAt;
  final String environmentId;
  final String cityCode;
  final int replayYear;
  final List<ReplayScenarioPacket> scenarios;
  final List<ReplayScenarioComparison> comparisons;
  final List<SimulationTruthReceipt> receipts;
  final List<ReplayContradictionSnapshot> contradictions;
  final List<ReplayLocalityOverlaySnapshot> localityOverlays;
}

abstract class ReplaySimulationAdminEnvironmentAdapter {
  const ReplaySimulationAdminEnvironmentAdapter();

  ReplaySimulationAdminEnvironmentDescriptor get descriptor;

  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  });
}

class BhamReplaySimulationAdminEnvironmentAdapter
    implements ReplaySimulationAdminEnvironmentAdapter {
  const BhamReplaySimulationAdminEnvironmentAdapter({
    BhamEventScenarioPackService? scenarioPackService,
    BhamReplayScenarioPacketService? scenarioPacketService,
    BhamReplayScenarioComparisonService? scenarioComparisonService,
    BhamReplayTruthReceiptService? truthReceiptService,
    BhamReplayContradictionDashboardService? contradictionDashboardService,
    BhamReplayLocalityOverlayService? localityOverlayService,
    this.environmentId = 'bham-replay-world-2023',
    this.displayName = 'BHAM Replay World 2023',
    this.description =
        'Default Birmingham replay simulation environment for admin oversight.',
    this.replayYear = bhamReplayBaseYear,
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
            localityOverlayService ?? const BhamReplayLocalityOverlayService();

  final BhamEventScenarioPackService _scenarioPackService;
  final BhamReplayScenarioPacketService _scenarioPacketService;
  final BhamReplayScenarioComparisonService _scenarioComparisonService;
  final BhamReplayTruthReceiptService _truthReceiptService;
  final BhamReplayContradictionDashboardService _contradictionDashboardService;
  final BhamReplayLocalityOverlayService _localityOverlayService;

  final String environmentId;
  final String displayName;
  final String description;
  final int replayYear;

  @override
  ReplaySimulationAdminEnvironmentDescriptor get descriptor =>
      ReplaySimulationAdminEnvironmentDescriptor(
        environmentId: environmentId,
        displayName: displayName,
        cityCode: bhamReplayCityCode,
        replayYear: replayYear,
        description: description,
      );

  @override
  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  }) async {
    final scenarios = _scenarioPackService.buildScenarioPack(
      createdAt: generatedAt,
    );
    final comparisons = <ReplayScenarioComparison>[];
    final receipts = <SimulationTruthReceipt>[];
    final contradictions = <ReplayContradictionSnapshot>[];
    final overlays = <ReplayLocalityOverlaySnapshot>[];

    for (final scenario in scenarios) {
      final batchItems = _scenarioPacketService.materializeScenarioBatchItems(
        scenario,
      );
      final comparison = _scenarioComparisonService.compareScenarioRuns(
        packet: scenario,
        items: batchItems,
      );
      final scenarioContradictions = _contradictionDashboardService
          .buildSnapshot(packet: scenario, comparison: comparison);
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
      generatedAt: generatedAt,
      environmentId: environmentId,
      cityCode: bhamReplayCityCode,
      replayYear: replayYear,
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
}

class ReplaySimulationAdminService {
  ReplaySimulationAdminService({
    Iterable<ReplaySimulationAdminEnvironmentAdapter>? environmentAdapters,
    String? defaultEnvironmentId,
    BhamEventScenarioPackService? scenarioPackService,
    BhamReplayScenarioPacketService? scenarioPacketService,
    BhamReplayScenarioComparisonService? scenarioComparisonService,
    BhamReplayTruthReceiptService? truthReceiptService,
    BhamReplayContradictionDashboardService? contradictionDashboardService,
    BhamReplayLocalityOverlayService? localityOverlayService,
    DateTime Function()? nowProvider,
  })  : _environmentAdapters = _buildEnvironmentAdapterMap(
          environmentAdapters ??
              <ReplaySimulationAdminEnvironmentAdapter>[
                BhamReplaySimulationAdminEnvironmentAdapter(
                  scenarioPackService: scenarioPackService,
                  scenarioPacketService: scenarioPacketService,
                  scenarioComparisonService: scenarioComparisonService,
                  truthReceiptService: truthReceiptService,
                  contradictionDashboardService: contradictionDashboardService,
                  localityOverlayService: localityOverlayService,
                ),
              ],
        ),
        _defaultEnvironmentId = defaultEnvironmentId,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final Map<String, ReplaySimulationAdminEnvironmentAdapter>
      _environmentAdapters;
  final String? _defaultEnvironmentId;
  final DateTime Function() _nowProvider;

  List<ReplaySimulationAdminEnvironmentDescriptor> listEnvironments() {
    final descriptors = _environmentAdapters.values
        .map((adapter) => adapter.descriptor)
        .toList(growable: false)
      ..sort(
        (left, right) => left.environmentId.compareTo(right.environmentId),
      );
    return descriptors;
  }

  Future<ReplaySimulationAdminSnapshot> getSnapshot({
    String? environmentId,
  }) async {
    final adapter = _resolveEnvironmentAdapter(environmentId);
    return adapter.buildSnapshot(generatedAt: _nowProvider());
  }

  Stream<ReplaySimulationAdminSnapshot> watchSnapshot({
    Duration refreshInterval = const Duration(seconds: 20),
    String? environmentId,
  }) {
    late final StreamController<ReplaySimulationAdminSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(await getSnapshot(environmentId: environmentId));
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

  ReplaySimulationAdminEnvironmentAdapter _resolveEnvironmentAdapter(
    String? environmentId,
  ) {
    var resolvedEnvironmentId = environmentId ?? _defaultEnvironmentId;
    if (resolvedEnvironmentId == null && _environmentAdapters.isNotEmpty) {
      final sortedEnvironmentIds = _environmentAdapters.keys.toList()..sort();
      resolvedEnvironmentId = sortedEnvironmentIds.first;
    }
    if (resolvedEnvironmentId == null) {
      throw StateError('No replay simulation environments are registered.');
    }
    final adapter = _environmentAdapters[resolvedEnvironmentId];
    if (adapter == null) {
      throw StateError(
        'Unknown replay simulation environment: $resolvedEnvironmentId',
      );
    }
    return adapter;
  }

  static Map<String, ReplaySimulationAdminEnvironmentAdapter>
      _buildEnvironmentAdapterMap(
    Iterable<ReplaySimulationAdminEnvironmentAdapter> adapters,
  ) {
    final adapterMap = <String, ReplaySimulationAdminEnvironmentAdapter>{};
    for (final adapter in adapters) {
      final environmentId = adapter.descriptor.environmentId.trim();
      if (environmentId.isEmpty) {
        throw StateError('Replay simulation environment ids may not be empty.');
      }
      if (adapterMap.containsKey(environmentId)) {
        throw StateError(
          'Duplicate replay simulation environment id: $environmentId',
        );
      }
      adapterMap[environmentId] = adapter;
    }
    return adapterMap;
  }
}

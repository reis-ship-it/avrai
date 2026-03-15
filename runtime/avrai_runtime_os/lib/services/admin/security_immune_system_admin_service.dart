import 'dart:async';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/sandbox_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_scheduler.dart';
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';
import 'package:avrai_runtime_os/services/security/security_scout_coordinator.dart';

class SecurityImmuneSystemAdminRunRow {
  const SecurityImmuneSystemAdminRunRow({
    required this.runId,
    required this.governedRunId,
    required this.laneId,
    required this.name,
    required this.ownerAlias,
    required this.ownershipArea,
    required this.truthScope,
    required this.status,
    required this.trigger,
    required this.disposition,
    required this.startedAt,
    required this.completedAt,
    required this.findingCount,
    required this.highestSeverity,
    required this.proofCoverageScore,
    required this.autoClearEligible,
    required this.missingScenarioIds,
    required this.missingProofKinds,
  });

  final String runId;
  final String governedRunId;
  final String laneId;
  final String name;
  final String ownerAlias;
  final String ownershipArea;
  final TruthScopeDescriptor truthScope;
  final SecurityCampaignStatus status;
  final SecurityCampaignTrigger trigger;
  final SecurityInterventionDisposition disposition;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int findingCount;
  final SecurityFindingSeverity highestSeverity;
  final double proofCoverageScore;
  final bool autoClearEligible;
  final List<String> missingScenarioIds;
  final List<SecurityProofKind> missingProofKinds;
}

class SecurityImmuneSystemAdminSnapshot {
  const SecurityImmuneSystemAdminSnapshot({
    required this.generatedAt,
    required this.campaignCount,
    required this.pendingReviewCount,
    required this.releaseBlockingFailureCount,
    required this.findingCount,
    required this.memoryCount,
    required this.learningMomentCount,
    required this.bundleCandidateCount,
    required this.propagationReceiptCount,
    required this.scoutCount,
    required this.blockingAutonomyExpansion,
    required this.stratumCounts,
    required this.dispositionCounts,
    required this.readinessChecks,
    required this.recentRuns,
    required this.recentFindings,
    required this.recentMemory,
    required this.recentLearningMoments,
    required this.recentScouts,
    required this.recentBundles,
    required this.recentPropagationReceipts,
    required this.recentGovernedRuns,
    required this.releaseGate,
  });

  final DateTime generatedAt;
  final int campaignCount;
  final int pendingReviewCount;
  final int releaseBlockingFailureCount;
  final int findingCount;
  final int memoryCount;
  final int learningMomentCount;
  final int bundleCandidateCount;
  final int propagationReceiptCount;
  final int scoutCount;
  final bool blockingAutonomyExpansion;
  final Map<String, int> stratumCounts;
  final Map<String, int> dispositionCounts;
  final Map<String, bool> readinessChecks;
  final List<SecurityImmuneSystemAdminRunRow> recentRuns;
  final List<SecurityFinding> recentFindings;
  final List<ImmuneMemoryRecord> recentMemory;
  final List<SecurityLearningMoment> recentLearningMoments;
  final List<SecurityScoutStatus> recentScouts;
  final List<CountermeasureBundleCandidate> recentBundles;
  final List<CountermeasurePropagationReceipt> recentPropagationReceipts;
  final List<GovernedRunRecord> recentGovernedRuns;
  final SecurityKernelReleaseGateSnapshot releaseGate;
}

class SecurityImmuneSystemAdminService {
  SecurityImmuneSystemAdminService({
    required SandboxOrchestratorService sandboxOrchestrator,
    required ImmuneMemoryLedger immuneMemoryLedger,
    required SecurityCampaignRegistry campaignRegistry,
    required SecurityCampaignScheduler campaignScheduler,
    required SecurityScoutCoordinator scoutCoordinator,
    GovernedRunKernelService? governedRunKernel,
    SecurityKernelReleaseGateService? releaseGateService,
    DateTime Function()? nowProvider,
  })  : _sandboxOrchestrator = sandboxOrchestrator,
        _immuneMemoryLedger = immuneMemoryLedger,
        _campaignRegistry = campaignRegistry,
        _campaignScheduler = campaignScheduler,
        _scoutCoordinator = scoutCoordinator,
        _governedRunKernel = governedRunKernel,
        _releaseGateService = releaseGateService,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final SandboxOrchestratorService _sandboxOrchestrator;
  final ImmuneMemoryLedger _immuneMemoryLedger;
  final SecurityCampaignRegistry _campaignRegistry;
  final SecurityCampaignScheduler _campaignScheduler;
  final SecurityScoutCoordinator _scoutCoordinator;
  final GovernedRunKernelService? _governedRunKernel;
  final SecurityKernelReleaseGateService? _releaseGateService;
  final DateTime Function() _nowProvider;

  Future<SecurityImmuneSystemAdminSnapshot> getSnapshot({
    int limit = 20,
  }) async {
    final runs = _sandboxOrchestrator.recentCampaignRuns(limit: limit);
    final findings = _immuneMemoryLedger.recentFindings(limit: limit);
    final memory = _immuneMemoryLedger.recentMemory(limit: limit);
    final learning = _immuneMemoryLedger.recentLearningMoments(limit: limit);
    final bundleCandidates = _immuneMemoryLedger.bundleCandidates(limit: limit);
    final receipts = _immuneMemoryLedger.propagationReceipts(limit: limit);
    final scouts = _scoutCoordinator.listScouts();
    final governedRuns = _governedRunKernel == null
        ? const <GovernedRunRecord>[]
        : await _governedRunKernel.listRuns();
    final releaseGate = _releaseGateService == null
        ? SecurityKernelReleaseGateSnapshot(
            generatedAt: _nowProvider(),
            servingAllowed: !_campaignScheduler.hasBlockingFailures(),
            degradedReleaseAllowed: false,
            reasonCodes: _campaignScheduler.hasBlockingFailures()
                ? const <String>['release_blocking_campaigns_red']
                : const <String>[],
            blockingCampaignIds: const <String>[],
            hardStopRunIds: const <String>[],
            blockingBundleIds: const <String>[],
          )
        : await _releaseGateService.getSnapshot();
    final stratumCounts = <String, int>{};
    final dispositionCounts = <String, int>{};
    final latestReleaseBlockingRuns = <String, SecurityCampaignRun>{};

    for (final run in runs) {
      stratumCounts[run.truthScope.governanceStratum.name] =
          (stratumCounts[run.truthScope.governanceStratum.name] ?? 0) + 1;
      dispositionCounts[run.disposition.name] =
          (dispositionCounts[run.disposition.name] ?? 0) + 1;
      final definition = _campaignRegistry.definitionById(run.definitionId);
      if (definition?.releaseBlocking == true &&
          !latestReleaseBlockingRuns.containsKey(run.definitionId)) {
        latestReleaseBlockingRuns[run.definitionId] = run;
      }
    }

    final rows = runs.map((run) {
      final definition = _campaignRegistry.definitionById(run.definitionId);
      return SecurityImmuneSystemAdminRunRow(
        runId: run.runId,
        governedRunId: run.governedRunId,
        laneId: definition?.laneId ?? run.definitionId,
        name: definition?.name ?? run.definitionId,
        ownerAlias: definition?.ownerAlias ?? 'security_kernel',
        ownershipArea: definition?.ownershipArea ?? 'unknown',
        truthScope: run.truthScope,
        status: run.status,
        trigger: run.trigger,
        disposition: run.disposition,
        startedAt: run.startedAt,
        completedAt: run.completedAt,
        findingCount: run.findingCount,
        highestSeverity: run.highestSeverity,
        proofCoverageScore: run.proofCoverageScore,
        autoClearEligible: run.autoClearEligible,
        missingScenarioIds: run.missingScenarioIds,
        missingProofKinds: run.missingProofKinds,
      );
    }).toList(growable: false);

    final releaseBlockingDefinitions =
        _campaignRegistry.releaseBlockingDefinitions();
    final activeBundles = bundleCandidates
        .where((entry) =>
            entry.status == CountermeasureBundleCandidateStatus.active)
        .toList(growable: false);
    final readinessChecks = <String, bool>{
      'critical_lanes_mapped': releaseBlockingDefinitions.every(
        (entry) =>
            entry.mappedScenarioIds.isNotEmpty &&
            entry.requiredProofKinds.isNotEmpty,
      ),
      'no_missing_proof_coverage': releaseBlockingDefinitions.every((entry) {
        final run = latestReleaseBlockingRuns[entry.id];
        return run != null &&
            run.missingScenarioIds.isEmpty &&
            run.missingProofKinds.isEmpty;
      }),
      'no_unsigned_active_bundles': activeBundles.every((entry) {
        final bundle = entry.bundle;
        final signature = bundle.signature ?? '';
        final notExpired = bundle.expiresAt == null ||
            !bundle.expiresAt!.isBefore(_nowProvider());
        return signature.isNotEmpty && bundle.signedAt != null && notExpired;
      }),
      'no_stale_active_rollouts': receipts.every(
        (entry) => entry.activationStage != 'active' || !entry.staleNode,
      ),
      'no_critical_hard_stops': governedRuns.every(
        (entry) => entry.disposition != GovernedRunDisposition.hardStop,
      ),
      'release_gate_clear_or_approved': releaseGate.servingAllowed,
    };

    return SecurityImmuneSystemAdminSnapshot(
      generatedAt: _nowProvider(),
      campaignCount: runs.length,
      pendingReviewCount: runs
          .where((entry) => entry.status == SecurityCampaignStatus.review)
          .length,
      releaseBlockingFailureCount: runs.where((entry) {
        final definition = _campaignRegistry.definitionById(entry.definitionId);
        return definition?.releaseBlocking == true &&
            entry.disposition != SecurityInterventionDisposition.observe;
      }).length,
      findingCount: findings.length,
      memoryCount: memory.length,
      learningMomentCount: learning.length,
      bundleCandidateCount: bundleCandidates.length,
      propagationReceiptCount: receipts.length,
      scoutCount: scouts.length,
      blockingAutonomyExpansion: _campaignScheduler.hasBlockingFailures(),
      stratumCounts: stratumCounts,
      dispositionCounts: dispositionCounts,
      readinessChecks: readinessChecks,
      recentRuns: rows,
      recentFindings: findings,
      recentMemory: memory,
      recentLearningMoments: learning,
      recentScouts: scouts.take(limit).toList(growable: false),
      recentBundles: bundleCandidates,
      recentPropagationReceipts: receipts,
      recentGovernedRuns: governedRuns.take(limit).toList(growable: false),
      releaseGate: releaseGate,
    );
  }

  Stream<SecurityImmuneSystemAdminSnapshot> watchSnapshot({
    Duration refreshInterval = const Duration(seconds: 15),
    int limit = 20,
  }) {
    late final StreamController<SecurityImmuneSystemAdminSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(await getSnapshot(limit: limit));
    }

    controller = StreamController<SecurityImmuneSystemAdminSnapshot>.broadcast(
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

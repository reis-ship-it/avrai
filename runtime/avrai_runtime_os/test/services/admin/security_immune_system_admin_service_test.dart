import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/admin/security_immune_system_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/self_heal_governance_adapter_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/sandbox_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/security/security_autonomy_impact_policy.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_scheduler.dart';
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';
import 'package:avrai_runtime_os/services/security/security_learning_moment_bridge.dart';
import 'package:avrai_runtime_os/services/security/security_replay_harness.dart';
import 'package:avrai_runtime_os/services/security/security_scout_coordinator.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;
  late SharedPreferencesCompat prefs;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );
    storageRoot = await Directory.systemTemp.createTemp('security_immune_');
    await GetStorage('security_immune', storageRoot.path).initStorage;
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Ignore temp cleanup failures.
    }
  });

  setUp(() async {
    final storage = GetStorage('security_immune');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
  });

  test('aggregates sandbox campaigns, learning moments, and scout state',
      () async {
    final governedRunKernel = GovernedRunKernelService(prefs: prefs);
    final campaignRegistry = const SecurityCampaignRegistry();
    final impactPolicy = const SecurityAutonomyImpactPolicy();
    final immuneMemoryLedger = ImmuneMemoryLedger(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final learningBridge = SecurityLearningMomentBridge(
      prefs: prefs,
      impactPolicy: impactPolicy,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final sandboxOrchestrator = SandboxOrchestratorService(
      governedRunKernel: governedRunKernel,
      campaignRegistry: campaignRegistry,
      immuneMemoryLedger: immuneMemoryLedger,
      replayHarness: const SecurityReplayHarness(),
      learningMomentBridge: learningBridge,
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final triggerIngress = SecurityTriggerIngressService(
      campaignRegistry: campaignRegistry,
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final scheduler = SecurityCampaignScheduler(
      campaignRegistry: campaignRegistry,
      sandboxOrchestrator: sandboxOrchestrator,
      triggerIngressService: triggerIngress,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final scoutCoordinator = SecurityScoutCoordinator(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final releaseGate = SecurityKernelReleaseGateService(
      campaignScheduler: scheduler,
      campaignRegistry: campaignRegistry,
      sandboxOrchestrator: sandboxOrchestrator,
      immuneMemoryLedger: immuneMemoryLedger,
      governedRunKernel: governedRunKernel,
      triggerIngressService: triggerIngress,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final selfHealAdapter = SelfHealGovernanceAdapterService(
      governedRunKernel: governedRunKernel,
      impactPolicy: impactPolicy,
      learningMomentBridge: learningBridge,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    await scoutCoordinator.updateScoutHeartbeat(
      scoutId: 'pi-4-1',
      alias: 'Edge Scout 1',
      truthScope: const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.locality,
        sphereId: 'security_transport',
        familyId: 'signal_lifecycle_downgrade',
      ),
      activeCampaignCount: 1,
    );
    await sandboxOrchestrator.runCampaign(
      campaignId: 'RT-004',
      trigger: SecurityCampaignTrigger.schedule,
    );
    await immuneMemoryLedger.upsertBundleCandidate(
      CountermeasureBundleCandidate(
        candidateId: 'candidate-1',
        status: CountermeasureBundleCandidateStatus.candidate,
        bundle: SecurityCountermeasureBundle(
          bundleId: 'bundle-1',
          targetScope: const TruthScopeDescriptor.defaultSecurity(
            governanceStratum: GovernanceStratum.locality,
            sphereId: 'security_learning',
            familyId: 'federated_update_poisoning',
          ),
          allowedStrata: const <GovernanceStratum>[
            GovernanceStratum.locality,
            GovernanceStratum.world,
          ],
          tenantScope: TruthTenantScope.avraiNative,
          evidenceEnvelopeTraceIds: const <String>['trace-1'],
          requiredApprovals: const <String>['security_lead'],
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12),
        updatedAt: DateTime.utc(2026, 3, 14, 12),
        sourceFindingIds: const <String>['finding-1'],
        shadowValidationEvidenceTraceIds: const <String>['trace-1'],
        approvalActors: const <String>['security_lead'],
      ),
    );
    final selfHealRun = await selfHealAdapter.startRecoveryRun(
      truthScope: const TruthScopeDescriptor.defaultHealing(
        governanceStratum: GovernanceStratum.locality,
        sphereId: 'self_healing',
        familyId: 'self_heal_kernel',
      ),
      title: 'Mesh recovery',
      objective: 'Redirect the affected lane to shadow and preserve scope.',
    );
    expect(selfHealRun.runKind, GovernedRunKind.selfHeal);

    final service = SecurityImmuneSystemAdminService(
      sandboxOrchestrator: sandboxOrchestrator,
      immuneMemoryLedger: immuneMemoryLedger,
      campaignRegistry: campaignRegistry,
      campaignScheduler: scheduler,
      scoutCoordinator: scoutCoordinator,
      governedRunKernel: governedRunKernel,
      releaseGateService: releaseGate,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final snapshot = await service.getSnapshot();

    expect(snapshot.campaignCount, 1);
    expect(snapshot.findingCount, 1);
    expect(snapshot.learningMomentCount, 1);
    expect(snapshot.bundleCandidateCount, 1);
    expect(snapshot.scoutCount, 1);
    expect(snapshot.blockingAutonomyExpansion, isTrue);
    expect(snapshot.readinessChecks['critical_lanes_mapped'], isTrue);
    expect(snapshot.readinessChecks['release_gate_clear_or_approved'], isFalse);
    expect(snapshot.recentRuns.first.laneId, 'RT-004');
    expect(snapshot.recentFindings.first.title, contains('Harness coverage'));
    expect(
        snapshot.recentGovernedRuns.any(
          (entry) => entry.runKind == GovernedRunKind.selfHeal,
        ),
        isTrue);
    expect(snapshot.releaseGate.servingAllowed, isFalse);
  });
}

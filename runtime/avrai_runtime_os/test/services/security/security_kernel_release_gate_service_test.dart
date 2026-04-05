import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/sandbox_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_scheduler.dart';
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';
import 'package:avrai_runtime_os/services/security/security_learning_moment_bridge.dart';
import 'package:avrai_runtime_os/services/security/security_replay_harness.dart';
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
    storageRoot =
        await Directory.systemTemp.createTemp('security_release_gate_');
    await GetStorage('security_release_gate', storageRoot.path).initStorage;
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
    final storage = GetStorage('security_release_gate');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
  });

  test('runtime bundle activation ignores the candidate bundle deadlock',
      () async {
    final governedRunKernel = GovernedRunKernelService(prefs: prefs);
    final campaignRegistry = const SecurityCampaignRegistry();
    final immuneMemoryLedger = ImmuneMemoryLedger(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );
    final sandboxOrchestrator = SandboxOrchestratorService(
      governedRunKernel: governedRunKernel,
      campaignRegistry: campaignRegistry,
      immuneMemoryLedger: immuneMemoryLedger,
      replayHarness: _FakeReplayHarness.complete(),
      learningMomentBridge: SecurityLearningMomentBridge(
        prefs: prefs,
        nowProvider: () => DateTime.utc(2026, 3, 14, 12),
      ),
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
    final gate = SecurityKernelReleaseGateService(
      campaignScheduler: scheduler,
      campaignRegistry: campaignRegistry,
      sandboxOrchestrator: sandboxOrchestrator,
      immuneMemoryLedger: immuneMemoryLedger,
      governedRunKernel: governedRunKernel,
      triggerIngressService: triggerIngress,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    );

    const targetScope = TruthScopeDescriptor.defaultSecurity(
      governanceStratum: GovernanceStratum.universal,
      sphereId: 'security_autonomy',
      familyId: 'autonomy_hijack',
    );
    await immuneMemoryLedger.upsertBundleCandidate(
      CountermeasureBundleCandidate(
        candidateId: 'candidate-1',
        status: CountermeasureBundleCandidateStatus.shadowValidated,
        bundle: SecurityCountermeasureBundle(
          bundleId: 'bundle-autonomy',
          targetScope: targetScope,
          allowedStrata: const <GovernanceStratum>[
            GovernanceStratum.universal,
          ],
          tenantScope: TruthTenantScope.avraiNative,
          evidenceEnvelopeTraceIds: const <String>['trace-1'],
          requiredApprovals: const <String>['security_lead'],
          signature: 'signed',
          signedBy: 'security_lead',
          signedAt: DateTime.utc(2026, 3, 14, 11),
          metadata: const <String, dynamic>{
            'required_for_promotion': true,
          },
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12),
        updatedAt: DateTime.utc(2026, 3, 14, 12),
        sourceFindingIds: const <String>['finding-1'],
        shadowValidationEvidenceTraceIds: const <String>['trace-1'],
        approvalActors: const <String>['security_lead'],
        metadata: const <String, dynamic>{
          'required_for_promotion': true,
        },
      ),
    );

    final snapshot = await gate.evaluateRuntimeBundleActivation(
      bundleId: 'bundle-autonomy',
      scope: targetScope,
      actorAlias: 'admin_operator',
      operatorApproved: true,
    );

    expect(
        snapshot.reasonCodes, isNot(contains('required_bundles_not_active')));
    expect(snapshot.servingAllowed, isTrue);
  });
}

class _FakeReplayHarness extends SecurityReplayHarness {
  _FakeReplayHarness._(this._summary);

  final SecurityReplayPackSummary _summary;

  factory _FakeReplayHarness.complete() {
    return _FakeReplayHarness._(
      const SecurityReplayPackSummary(
        executedScenarioIds: <String>['scenario-1'],
        passedScenarioIds: <String>['scenario-1'],
        failedScenarioIds: <String>[],
        missingScenarioIds: <String>[],
        requiredProofKinds: <SecurityProofKind>[
          SecurityProofKind.rolloutLifecycle,
        ],
        coveredProofKinds: <SecurityProofKind>[
          SecurityProofKind.rolloutLifecycle,
        ],
        proofRefs: <String>['proof:scenario-1'],
        coverageScore: 1.0,
      ),
    );
  }

  @override
  Future<SecurityReplayPackSummary> runReplayPack(
    SecurityCampaignDefinition definition,
  ) async {
    return SecurityReplayPackSummary(
      executedScenarioIds: _summary.executedScenarioIds,
      passedScenarioIds: _summary.passedScenarioIds,
      failedScenarioIds: _summary.failedScenarioIds,
      missingScenarioIds: _summary.missingScenarioIds,
      requiredProofKinds: definition.requiredProofKinds,
      coveredProofKinds: definition.requiredProofKinds,
      proofRefs: _summary.proofRefs,
      coverageScore: 1.0,
    );
  }
}

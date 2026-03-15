import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/sandbox_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_learning_moment_bridge.dart';
import 'package:avrai_runtime_os/services/security/security_replay_harness.dart';
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
        await Directory.systemTemp.createTemp('security_sandbox_runs_');
    await GetStorage('security_sandbox_runs', storageRoot.path).initStorage;
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
    final storage = GetStorage('security_sandbox_runs');
    await storage.erase();
    prefs = await SharedPreferencesCompat.getInstance(storage: storage);
  });

  test('auto-clears release-blocking campaign when replay pack is green',
      () async {
    final orchestrator = _buildOrchestrator(
      prefs: prefs,
      replayHarness: _StubReplayHarness(
        summary: const SecurityReplayPackSummary(
          executedScenarioIds: <String>['scenario-green'],
          passedScenarioIds: <String>['scenario-green'],
          failedScenarioIds: <String>[],
          missingScenarioIds: <String>[],
          requiredProofKinds: <SecurityProofKind>[
            SecurityProofKind.learningPath,
            SecurityProofKind.governanceBoundary,
          ],
          coveredProofKinds: <SecurityProofKind>[
            SecurityProofKind.learningPath,
            SecurityProofKind.governanceBoundary,
          ],
          proofRefs: <String>['proof:scenario-green'],
          coverageScore: 1.0,
        ),
      ),
    );

    final run = await orchestrator.runCampaign(
      campaignId: 'RT-004',
      trigger: SecurityCampaignTrigger.modelPromotion,
    );

    expect(run.status, SecurityCampaignStatus.completed);
    expect(run.autoClearEligible, isTrue);
    expect(run.disposition, SecurityInterventionDisposition.observe);
  });

  test('keeps campaign in review when replay coverage is incomplete', () async {
    final orchestrator = _buildOrchestrator(
      prefs: prefs,
      replayHarness: _StubReplayHarness(
        summary: const SecurityReplayPackSummary(
          executedScenarioIds: <String>[],
          passedScenarioIds: <String>[],
          failedScenarioIds: <String>[],
          missingScenarioIds: <String>['scenario-missing'],
          requiredProofKinds: <SecurityProofKind>[
            SecurityProofKind.learningPath,
          ],
          coveredProofKinds: <SecurityProofKind>[],
          proofRefs: <String>[],
          coverageScore: 0.0,
        ),
      ),
    );

    final run = await orchestrator.runCampaign(
      campaignId: 'RT-004',
      trigger: SecurityCampaignTrigger.modelPromotion,
    );

    expect(run.status, SecurityCampaignStatus.review);
    expect(run.autoClearEligible, isFalse);
    expect(run.disposition, SecurityInterventionDisposition.observe);
    expect(run.missingProofKinds, contains(SecurityProofKind.learningPath));
  });
}

SandboxOrchestratorService _buildOrchestrator({
  required SharedPreferencesCompat prefs,
  required SecurityReplayHarness replayHarness,
}) {
  return SandboxOrchestratorService(
    governedRunKernel: GovernedRunKernelService(prefs: prefs),
    campaignRegistry: const SecurityCampaignRegistry(),
    immuneMemoryLedger: ImmuneMemoryLedger(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    ),
    replayHarness: replayHarness,
    learningMomentBridge: SecurityLearningMomentBridge(
      prefs: prefs,
      nowProvider: () => DateTime.utc(2026, 3, 14, 12),
    ),
    prefs: prefs,
    nowProvider: () => DateTime.utc(2026, 3, 14, 12),
  );
}

class _StubReplayHarness extends SecurityReplayHarness {
  _StubReplayHarness({required this.summary});

  final SecurityReplayPackSummary summary;

  @override
  Future<SecurityReplayPackSummary> runReplayPack(
    SecurityCampaignDefinition definition,
  ) async {
    return SecurityReplayPackSummary(
      executedScenarioIds: summary.executedScenarioIds,
      passedScenarioIds: summary.passedScenarioIds,
      failedScenarioIds: summary.failedScenarioIds,
      missingScenarioIds: summary.missingScenarioIds,
      requiredProofKinds: definition.requiredProofKinds,
      coveredProofKinds: summary.coveredProofKinds,
      proofRefs: summary.proofRefs,
      coverageScore: summary.coverageScore,
    );
  }
}

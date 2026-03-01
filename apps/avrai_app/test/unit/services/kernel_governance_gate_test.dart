import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelGovernanceGate', () {
    test('shadow mode bypasses blocked decisions', () async {
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.shadow,
        snapshotLoader: () async => const UrkKernelRegistrySnapshot(
          version: 'v-test',
          updatedAt: '2026-02-28',
          kernels: <UrkKernelRecord>[],
          byProng: <String, int>{},
          byMode: <String, int>{},
          byImpactTier: <String, int>{},
        ),
      );

      final decision = await gate.evaluate(
        const KernelGovernanceRequest(
          action: KernelGovernanceAction.modelSwitch,
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
        ),
      );

      expect(decision.mode, KernelGovernanceMode.shadow);
      expect(decision.wouldAllow, isFalse);
      expect(decision.servingAllowed, isTrue);
      expect(decision.shadowBypassApplied, isTrue);
    });

    test('enforce mode blocks when required kernels are missing', () async {
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.enforce,
        snapshotLoader: () async => const UrkKernelRegistrySnapshot(
          version: 'v-test',
          updatedAt: '2026-02-28',
          kernels: <UrkKernelRecord>[],
          byProng: <String, int>{},
          byMode: <String, int>{},
          byImpactTier: <String, int>{},
        ),
      );

      final decision = await gate.evaluate(
        const KernelGovernanceRequest(
          action: KernelGovernanceAction.modelSwitch,
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
        ),
      );

      expect(decision.mode, KernelGovernanceMode.enforce);
      expect(decision.wouldAllow, isFalse);
      expect(decision.servingAllowed, isFalse);
      expect(decision.shadowBypassApplied, isFalse);
      expect(
        decision.reasonCodes,
        contains('missing_urk_learning_update_governance'),
      );
    });

    test('enforce mode allows when required kernels are present and healthy',
        () async {
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.enforce,
        snapshotLoader: () async => UrkKernelRegistrySnapshot(
          version: 'v-test',
          updatedAt: '2026-02-28',
          kernels: <UrkKernelRecord>[
            _kernel('urk_learning_update_governance'),
            _kernel('urk_kernel_promotion_lifecycle'),
          ],
          byProng: const <String, int>{'model_core': 1, 'governance_core': 1},
          byMode: const <String, int>{'multi_mode': 2},
          byImpactTier: const <String, int>{'L4': 1, 'L3': 1},
        ),
      );

      final decision = await gate.evaluate(
        const KernelGovernanceRequest(
          action: KernelGovernanceAction.modelSwitch,
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
        ),
      );

      expect(decision.mode, KernelGovernanceMode.enforce);
      expect(decision.wouldAllow, isTrue);
      expect(decision.servingAllowed, isTrue);
      expect(decision.reasonCodes, isEmpty);
    });

    test('decision and correlation ids are populated', () async {
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.enforce,
        snapshotLoader: () async => UrkKernelRegistrySnapshot(
          version: 'v-test',
          updatedAt: '2026-02-28',
          kernels: <UrkKernelRecord>[
            _kernel('urk_learning_update_governance'),
            _kernel('urk_kernel_promotion_lifecycle'),
          ],
          byProng: const <String, int>{'model_core': 1, 'governance_core': 1},
          byMode: const <String, int>{'multi_mode': 2},
          byImpactTier: const <String, int>{'L4': 1, 'L3': 1},
        ),
      );

      final decision = await gate.evaluate(
        const KernelGovernanceRequest(
          action: KernelGovernanceAction.modelSwitch,
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
          correlationId: 'corr_test_123',
        ),
      );

      expect(decision.decisionId, startsWith('kgd_modelSwitch_'));
      expect(decision.correlationId, 'corr_test_123');
    });
  });
}

UrkKernelRecord _kernel(String kernelId) {
  return UrkKernelRecord(
    kernelId: kernelId,
    title: kernelId,
    purpose: 'test',
    runtimeScope: const <String>['shared'],
    prongScope: 'model_core',
    privacyModes: const <String>['multi_mode'],
    impactTier: 'L4',
    localityScope: const <String>['device'],
    activationTriggers: const <String>['test'],
    authorityMode: 'enforced',
    dependencies: const <String>[],
    lifecycleState: 'enforced',
    owner: 'test',
    approver: 'test',
    milestoneId: 'test',
    status: 'done',
  );
}

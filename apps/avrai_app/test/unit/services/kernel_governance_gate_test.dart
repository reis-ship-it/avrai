import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_priority.dart';
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

    test('evaluateWithExplanation emits canonical why snapshot', () async {
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.enforce,
        snapshotLoader: () async => const UrkKernelRegistrySnapshot(
          version: 'v-policy',
          updatedAt: '2026-02-28',
          kernels: <UrkKernelRecord>[],
          byProng: <String, int>{},
          byMode: <String, int>{},
          byImpactTier: <String, int>{},
        ),
      );

      final explained = await gate.evaluateWithExplanation(
        const KernelGovernanceRequest(
          action: KernelGovernanceAction.modelSwitch,
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
          correlationId: 'corr-77',
          metadata: <String, dynamic>{
            'executionPath': 'governance_pipeline',
            'workflowStage': 'policy_eval',
            'interventionChain': <String>['validate', 'gate', 'telemetry'],
          },
        ),
      );

      expect(explained.decision.servingAllowed, isFalse);
      expect(explained.explanation.queryKind, WhyQueryKind.policyAction);
      expect(
        explained.explanation.governanceEnvelope.policyRefs,
        contains('v-policy'),
      );
      expect(
        explained.explanation.traceRefs.map((entry) => entry.kernel),
        containsAll(<WhyEvidenceSourceKernel>[
          WhyEvidenceSourceKernel.policy,
          WhyEvidenceSourceKernel.when,
          WhyEvidenceSourceKernel.how,
        ]),
      );
      expect(explained.explanation.summary, contains('Confidence'));
    });

    test('native governance bridge decides and uses when authority timestamp',
        () async {
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.enforce,
        nativeBridge: _FakeGovernanceNativeBridge(),
        nativePolicy:
            const KernelGovernanceNativeExecutionPolicy(requireNative: true),
        whenKernel: _FixedWhenKernel(),
        snapshotLoader: () async => UrkKernelRegistrySnapshot(
          version: 'v-native',
          updatedAt: '2026-03-10',
          kernels: <UrkKernelRecord>[
            _kernel('urk_learning_update_governance'),
            _kernel('urk_kernel_promotion_lifecycle'),
          ],
          byProng: const <String, int>{'governance_core': 2},
          byMode: const <String, int>{'multi_mode': 2},
          byImpactTier: const <String, int>{'L4': 2},
        ),
      );

      final decision = await gate.evaluate(
        const KernelGovernanceRequest(
          action: KernelGovernanceAction.modelSwitch,
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
          correlationId: 'corr-native',
        ),
      );

      expect(decision.wouldAllow, isTrue);
      expect(decision.servingAllowed, isTrue);
      expect(decision.policyVersion, 'v-native');
      expect(decision.decisionId, 'kgd_modelSwitch_1773144000000000');
      expect(decision.timestamp, DateTime.utc(2026, 3, 10, 12));
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

class _FakeGovernanceNativeBridge
    implements KernelGovernanceNativeInvocationBridge {
  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    expect(syscall, 'evaluate_kernel_governance');
    expect(payload['mode'], 'enforce');
    expect(payload['action'], 'model_switch');
    return <String, dynamic>{
      'handled': true,
      'payload': <String, dynamic>{
        'mode': 'enforce',
        'would_allow': true,
        'serving_allowed': true,
        'shadow_bypass_applied': false,
        'reason_codes': const <String>[],
        'policy_version': payload['policy_version'],
      },
    };
  }
}

class _FixedWhenKernel extends WhenKernelFallbackSurface {
  static final DateTime _fixedTime = DateTime.utc(2026, 3, 10, 12);

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    return WhenKernelSnapshot(
      observedAt: _fixedTime,
      effectiveAt: _fixedTime,
      expiresAt: _fixedTime.add(const Duration(hours: 4)),
      freshness: 1.0,
      cadence: 'governance',
      recencyBucket: 'immediate',
      timingConflictFlags: const <String>[],
      temporalConfidence: 1.0,
    );
  }

  @override
  Future<WhenTimestamp> issueTimestamp(WhenTimestampRequest request) async {
    return WhenTimestamp(
      referenceId: request.referenceId,
      observedAtUtc: _fixedTime,
      quantumAtomicTick: _fixedTime.microsecondsSinceEpoch,
      confidence: 1.0,
    );
  }
}

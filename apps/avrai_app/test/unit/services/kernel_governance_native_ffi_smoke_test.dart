import 'dart:io';

import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelGovernanceGate FFI smoke', () {
    test('evaluates through the governance dylib when available', () async {
      if (!_hasBuiltGovernanceLibrary()) {
        return;
      }

      final audit = KernelGovernanceNativeFallbackAudit();
      final gate = KernelGovernanceGate(
        defaultMode: KernelGovernanceMode.enforce,
        nativeBridge: KernelGovernanceNativeBridgeBindings(),
        nativePolicy:
            const KernelGovernanceNativeExecutionPolicy(requireNative: true),
        nativeAudit: audit,
        whenKernel: _FixedWhenKernel(),
        snapshotLoader: () async => UrkKernelRegistrySnapshot(
          version: 'v-ffi',
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
          correlationId: 'corr-ffi',
        ),
      );

      expect(decision.servingAllowed, isTrue);
      expect(decision.reasonCodes, isEmpty);
      expect(decision.policyVersion, 'v-ffi');
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(1));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });
  });
}

UrkKernelRecord _kernel(String kernelId) {
  return UrkKernelRecord(
    kernelId: kernelId,
    title: kernelId,
    purpose: 'test',
    runtimeScope: const <String>['shared'],
    prongScope: 'governance_core',
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

bool _hasBuiltGovernanceLibrary() {
  final currentDir = Directory.current.path;
  final candidates = <String>[
    '$currentDir/runtime/avrai_network/native/governance_kernel/target/debug/libavrai_governance_kernel.dylib',
    '$currentDir/runtime/avrai_network/native/governance_kernel/target/release/libavrai_governance_kernel.dylib',
    '$currentDir/runtime/avrai_network/native/governance_kernel/target/debug/libavrai_governance_kernel.so',
    '$currentDir/runtime/avrai_network/native/governance_kernel/target/release/libavrai_governance_kernel.so',
  ];
  return candidates.any((path) => File(path).existsSync());
}

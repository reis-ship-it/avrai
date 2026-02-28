import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkKernelActivationEngineValidator', () {
    const validator = UrkKernelActivationEngineValidator();

    test('passes when activation engine governance checks are healthy', () {
      const snapshot = UrkKernelActivationEngineSnapshot(
        observedTriggerRoutingCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedReceiptCoveragePct: 100.0,
        observedUnauthorizedActivations: 0,
        observedDependencyBypasses: 0,
      );
      const policy = UrkKernelActivationEnginePolicy(
        requiredTriggerRoutingCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredReceiptCoveragePct: 100.0,
        maxUnauthorizedActivations: 0,
        maxDependencyBypasses: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when coverage thresholds regress', () {
      const snapshot = UrkKernelActivationEngineSnapshot(
        observedTriggerRoutingCoveragePct: 94.0,
        observedPolicyGateCoveragePct: 92.0,
        observedReceiptCoveragePct: 90.0,
        observedUnauthorizedActivations: 0,
        observedDependencyBypasses: 0,
      );
      const policy = UrkKernelActivationEnginePolicy(
        requiredTriggerRoutingCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredReceiptCoveragePct: 100.0,
        maxUnauthorizedActivations: 0,
        maxDependencyBypasses: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkKernelActivationEngineFailure.triggerRoutingCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkKernelActivationEngineFailure.policyGateCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkKernelActivationEngineFailure.receiptCoverageBelowThreshold,
        ),
      );
    });

    test('fails when unauthorized activation or dependency bypass is detected',
        () {
      const snapshot = UrkKernelActivationEngineSnapshot(
        observedTriggerRoutingCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedReceiptCoveragePct: 100.0,
        observedUnauthorizedActivations: 1,
        observedDependencyBypasses: 2,
      );
      const policy = UrkKernelActivationEnginePolicy(
        requiredTriggerRoutingCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredReceiptCoveragePct: 100.0,
        maxUnauthorizedActivations: 0,
        maxDependencyBypasses: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkKernelActivationEngineFailure.unauthorizedActivationDetected,
        ),
      );
      expect(
        result.failures,
        contains(UrkKernelActivationEngineFailure.dependencyBypassDetected),
      );
    });
  });

  group('UrkKernelActivationEngine', () {
    const engine = UrkKernelActivationEngine();

    test('activates matching kernels and returns deterministic ordering', () {
      const rules = [
        UrkKernelActivationRule(
          kernelId: 'b_kernel',
          activationTriggers: ['incident_closed'],
          privacyModes: [UrkPrivacyMode.multiMode],
          dependencies: ['base_kernel'],
        ),
        UrkKernelActivationRule(
          kernelId: 'a_kernel',
          activationTriggers: ['incident_closed'],
          privacyModes: [UrkPrivacyMode.multiMode],
        ),
      ];

      const request = UrkKernelActivationRequest(
        requestId: 'req-1',
        trigger: 'incident_closed',
        privacyMode: UrkPrivacyMode.multiMode,
        activeKernels: {'base_kernel'},
      );

      final receipt = engine.evaluate(request: request, rules: rules);
      expect(receipt.decisions.length, 2);
      expect(receipt.decisions[0].kernelId, 'a_kernel');
      expect(receipt.decisions[1].kernelId, 'b_kernel');
      expect(receipt.decisions.every((d) => d.activated), isTrue);
    });

    test('denies activation on privacy mode mismatch', () {
      const rules = [
        UrkKernelActivationRule(
          kernelId: 'private_mesh_only_kernel',
          activationTriggers: ['runtime_health_breach'],
          privacyModes: [UrkPrivacyMode.privateMesh],
        ),
      ];
      const request = UrkKernelActivationRequest(
        requestId: 'req-2',
        trigger: 'runtime_health_breach',
        privacyMode: UrkPrivacyMode.localSovereign,
      );

      final receipt = engine.evaluate(request: request, rules: rules);
      expect(receipt.decisions.single.activated, isFalse);
      expect(receipt.decisions.single.reason, 'privacy_mode_not_allowed');
    });

    test('denies activation when dependencies are missing', () {
      const rules = [
        UrkKernelActivationRule(
          kernelId: 'bridge_kernel',
          activationTriggers: ['incident_closed'],
          privacyModes: [UrkPrivacyMode.multiMode],
          dependencies: ['self_learning_kernel', 'self_healing_kernel'],
        ),
      ];
      const request = UrkKernelActivationRequest(
        requestId: 'req-3',
        trigger: 'incident_closed',
        privacyMode: UrkPrivacyMode.multiMode,
        activeKernels: {'self_learning_kernel'},
      );

      final receipt = engine.evaluate(request: request, rules: rules);
      expect(receipt.decisions.single.activated, isFalse);
      expect(receipt.decisions.single.reason, 'missing_dependency');
    });
  });
}

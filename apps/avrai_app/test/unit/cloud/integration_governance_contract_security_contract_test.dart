import 'package:avrai_runtime_os/cloud/integration_governance_contract_security_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntegrationGovernanceSecurityValidator', () {
    const validator = IntegrationGovernanceSecurityValidator();

    test('passes when contract security and release gates are healthy', () {
      const snapshot = IntegrationGovernanceSecuritySnapshot(
        observedContractPassRatePct: 100.0,
        criticalBreakingChanges: 0,
        observedSecurityPassRatePct: 100.0,
        criticalSecurityFindings: 0,
        observedReleaseGatePassRatePct: 100.0,
        criticalOpenReleaseFindings: 0,
      );

      const policy = IntegrationGovernanceSecurityPolicy(
        minContractPassRatePct: 99.5,
        requiredSecurityPassRatePct: 100.0,
        requiredReleaseGatePassRatePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when contract pass rate drops or breaking change is detected',
        () {
      const snapshot = IntegrationGovernanceSecuritySnapshot(
        observedContractPassRatePct: 95.0,
        criticalBreakingChanges: 1,
        observedSecurityPassRatePct: 100.0,
        criticalSecurityFindings: 0,
        observedReleaseGatePassRatePct: 100.0,
        criticalOpenReleaseFindings: 0,
      );

      const policy = IntegrationGovernanceSecurityPolicy(
        minContractPassRatePct: 99.5,
        requiredSecurityPassRatePct: 100.0,
        requiredReleaseGatePassRatePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          IntegrationGovernanceSecurityFailure.contractPassRateBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          IntegrationGovernanceSecurityFailure.criticalBreakingChangeDetected,
        ),
      );
    });

    test('fails when security gate does not pass', () {
      const snapshot = IntegrationGovernanceSecuritySnapshot(
        observedContractPassRatePct: 100.0,
        criticalBreakingChanges: 0,
        observedSecurityPassRatePct: 97.0,
        criticalSecurityFindings: 2,
        observedReleaseGatePassRatePct: 100.0,
        criticalOpenReleaseFindings: 0,
      );

      const policy = IntegrationGovernanceSecurityPolicy(
        minContractPassRatePct: 99.5,
        requiredSecurityPassRatePct: 100.0,
        requiredReleaseGatePassRatePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          IntegrationGovernanceSecurityFailure.securityPassRateBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          IntegrationGovernanceSecurityFailure.criticalSecurityFindingDetected,
        ),
      );
    });

    test('fails when release gate has critical open findings', () {
      const snapshot = IntegrationGovernanceSecuritySnapshot(
        observedContractPassRatePct: 100.0,
        criticalBreakingChanges: 0,
        observedSecurityPassRatePct: 100.0,
        criticalSecurityFindings: 0,
        observedReleaseGatePassRatePct: 90.0,
        criticalOpenReleaseFindings: 1,
      );

      const policy = IntegrationGovernanceSecurityPolicy(
        minContractPassRatePct: 99.5,
        requiredSecurityPassRatePct: 100.0,
        requiredReleaseGatePassRatePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          IntegrationGovernanceSecurityFailure
              .releaseGatePassRateBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          IntegrationGovernanceSecurityFailure
              .criticalOpenReleaseFindingDetected,
        ),
      );
    });
  });
}

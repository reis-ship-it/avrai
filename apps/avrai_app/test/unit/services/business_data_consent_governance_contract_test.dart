import 'package:avrai_runtime_os/services/business/business_data_consent_governance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessDataConsentGovernanceValidator', () {
    const validator = BusinessDataConsentGovernanceValidator();

    test('passes when consent, DP, and audit checks are healthy', () {
      const snapshot = BusinessDataConsentGovernanceSnapshot(
        observedConsentCoveragePct: 100.0,
        unauthorizedProcessingEvents: 0,
        observedDpBudgetUsagePct: 32.0,
        epsilonExceededEvents: 0,
        observedAuditCompletenessPct: 100.0,
        retentionPolicyPassed: true,
      );

      const policy = BusinessDataConsentGovernancePolicy(
        minConsentCoveragePct: 99.9,
        maxDpBudgetUsagePct: 80.0,
        requiredAuditCompletenessPct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when consent coverage is below threshold', () {
      const snapshot = BusinessDataConsentGovernanceSnapshot(
        observedConsentCoveragePct: 98.0,
        unauthorizedProcessingEvents: 0,
        observedDpBudgetUsagePct: 32.0,
        epsilonExceededEvents: 0,
        observedAuditCompletenessPct: 100.0,
        retentionPolicyPassed: true,
      );

      const policy = BusinessDataConsentGovernancePolicy(
        minConsentCoveragePct: 99.9,
        maxDpBudgetUsagePct: 80.0,
        requiredAuditCompletenessPct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          BusinessDataConsentGovernanceFailure.consentCoverageBelowThreshold,
        ),
      );
    });

    test('fails when unauthorized processing or epsilon exceeded is detected',
        () {
      const snapshot = BusinessDataConsentGovernanceSnapshot(
        observedConsentCoveragePct: 100.0,
        unauthorizedProcessingEvents: 2,
        observedDpBudgetUsagePct: 32.0,
        epsilonExceededEvents: 1,
        observedAuditCompletenessPct: 100.0,
        retentionPolicyPassed: true,
      );

      const policy = BusinessDataConsentGovernancePolicy(
        minConsentCoveragePct: 99.9,
        maxDpBudgetUsagePct: 80.0,
        requiredAuditCompletenessPct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          BusinessDataConsentGovernanceFailure.unauthorizedProcessingDetected,
        ),
      );
      expect(
        result.failures,
        contains(BusinessDataConsentGovernanceFailure.epsilonExceededDetected),
      );
    });

    test('fails when DP budget or audit retention checks fail', () {
      const snapshot = BusinessDataConsentGovernanceSnapshot(
        observedConsentCoveragePct: 100.0,
        unauthorizedProcessingEvents: 0,
        observedDpBudgetUsagePct: 92.0,
        epsilonExceededEvents: 0,
        observedAuditCompletenessPct: 96.0,
        retentionPolicyPassed: false,
      );

      const policy = BusinessDataConsentGovernancePolicy(
        minConsentCoveragePct: 99.9,
        maxDpBudgetUsagePct: 80.0,
        requiredAuditCompletenessPct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(BusinessDataConsentGovernanceFailure.dpBudgetExceeded),
      );
      expect(
        result.failures,
        contains(
          BusinessDataConsentGovernanceFailure.auditCompletenessBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(BusinessDataConsentGovernanceFailure.retentionPolicyFailed),
      );
    });
  });
}

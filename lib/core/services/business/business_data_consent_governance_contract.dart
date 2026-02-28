// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
enum BusinessDataConsentGovernanceFailure {
  invalidConsentThreshold,
  invalidDpThreshold,
  invalidAuditThreshold,
  consentCoverageBelowThreshold,
  unauthorizedProcessingDetected,
  dpBudgetExceeded,
  epsilonExceededDetected,
  auditCompletenessBelowThreshold,
  retentionPolicyFailed,
}

class BusinessDataConsentGovernancePolicy {
  const BusinessDataConsentGovernancePolicy({
    required this.minConsentCoveragePct,
    required this.maxDpBudgetUsagePct,
    required this.requiredAuditCompletenessPct,
  });

  final double minConsentCoveragePct;
  final double maxDpBudgetUsagePct;
  final double requiredAuditCompletenessPct;
}

class BusinessDataConsentGovernanceSnapshot {
  const BusinessDataConsentGovernanceSnapshot({
    required this.observedConsentCoveragePct,
    required this.unauthorizedProcessingEvents,
    required this.observedDpBudgetUsagePct,
    required this.epsilonExceededEvents,
    required this.observedAuditCompletenessPct,
    required this.retentionPolicyPassed,
  });

  final double observedConsentCoveragePct;
  final int unauthorizedProcessingEvents;
  final double observedDpBudgetUsagePct;
  final int epsilonExceededEvents;
  final double observedAuditCompletenessPct;
  final bool retentionPolicyPassed;
}

class BusinessDataConsentGovernanceValidationResult {
  const BusinessDataConsentGovernanceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory BusinessDataConsentGovernanceValidationResult.pass() {
    return const BusinessDataConsentGovernanceValidationResult._(
      isPassing: true,
      failures: <BusinessDataConsentGovernanceFailure>[],
    );
  }

  factory BusinessDataConsentGovernanceValidationResult.fail(
    List<BusinessDataConsentGovernanceFailure> failures,
  ) {
    return BusinessDataConsentGovernanceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<BusinessDataConsentGovernanceFailure> failures;
}

class BusinessDataConsentGovernanceValidator {
  const BusinessDataConsentGovernanceValidator();

  BusinessDataConsentGovernanceValidationResult validate({
    required BusinessDataConsentGovernanceSnapshot snapshot,
    required BusinessDataConsentGovernancePolicy policy,
  }) {
    final failures = <BusinessDataConsentGovernanceFailure>[];

    if (policy.minConsentCoveragePct < 0) {
      failures
          .add(BusinessDataConsentGovernanceFailure.invalidConsentThreshold);
    }
    if (policy.maxDpBudgetUsagePct < 0) {
      failures.add(BusinessDataConsentGovernanceFailure.invalidDpThreshold);
    }
    if (policy.requiredAuditCompletenessPct < 0) {
      failures.add(BusinessDataConsentGovernanceFailure.invalidAuditThreshold);
    }

    if (snapshot.observedConsentCoveragePct < policy.minConsentCoveragePct) {
      failures.add(
          BusinessDataConsentGovernanceFailure.consentCoverageBelowThreshold);
    }
    if (snapshot.unauthorizedProcessingEvents > 0) {
      failures.add(
          BusinessDataConsentGovernanceFailure.unauthorizedProcessingDetected);
    }
    if (snapshot.observedDpBudgetUsagePct > policy.maxDpBudgetUsagePct) {
      failures.add(BusinessDataConsentGovernanceFailure.dpBudgetExceeded);
    }
    if (snapshot.epsilonExceededEvents > 0) {
      failures
          .add(BusinessDataConsentGovernanceFailure.epsilonExceededDetected);
    }
    if (snapshot.observedAuditCompletenessPct <
        policy.requiredAuditCompletenessPct) {
      failures.add(
        BusinessDataConsentGovernanceFailure.auditCompletenessBelowThreshold,
      );
    }
    if (!snapshot.retentionPolicyPassed) {
      failures.add(BusinessDataConsentGovernanceFailure.retentionPolicyFailed);
    }

    if (failures.isEmpty) {
      return BusinessDataConsentGovernanceValidationResult.pass();
    }
    return BusinessDataConsentGovernanceValidationResult.fail(failures);
  }
}

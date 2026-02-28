// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
enum IntegrationGovernanceSecurityFailure {
  invalidContractThreshold,
  invalidSecurityThreshold,
  invalidReleaseThreshold,
  contractPassRateBelowThreshold,
  criticalBreakingChangeDetected,
  securityPassRateBelowThreshold,
  criticalSecurityFindingDetected,
  releaseGatePassRateBelowThreshold,
  criticalOpenReleaseFindingDetected,
}

class IntegrationGovernanceSecurityPolicy {
  const IntegrationGovernanceSecurityPolicy({
    required this.minContractPassRatePct,
    required this.requiredSecurityPassRatePct,
    required this.requiredReleaseGatePassRatePct,
  });

  final double minContractPassRatePct;
  final double requiredSecurityPassRatePct;
  final double requiredReleaseGatePassRatePct;
}

class IntegrationGovernanceSecuritySnapshot {
  const IntegrationGovernanceSecuritySnapshot({
    required this.observedContractPassRatePct,
    required this.criticalBreakingChanges,
    required this.observedSecurityPassRatePct,
    required this.criticalSecurityFindings,
    required this.observedReleaseGatePassRatePct,
    required this.criticalOpenReleaseFindings,
  });

  final double observedContractPassRatePct;
  final int criticalBreakingChanges;
  final double observedSecurityPassRatePct;
  final int criticalSecurityFindings;
  final double observedReleaseGatePassRatePct;
  final int criticalOpenReleaseFindings;
}

class IntegrationGovernanceSecurityValidationResult {
  const IntegrationGovernanceSecurityValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory IntegrationGovernanceSecurityValidationResult.pass() {
    return const IntegrationGovernanceSecurityValidationResult._(
      isPassing: true,
      failures: <IntegrationGovernanceSecurityFailure>[],
    );
  }

  factory IntegrationGovernanceSecurityValidationResult.fail(
    List<IntegrationGovernanceSecurityFailure> failures,
  ) {
    return IntegrationGovernanceSecurityValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<IntegrationGovernanceSecurityFailure> failures;
}

class IntegrationGovernanceSecurityValidator {
  const IntegrationGovernanceSecurityValidator();

  IntegrationGovernanceSecurityValidationResult validate({
    required IntegrationGovernanceSecuritySnapshot snapshot,
    required IntegrationGovernanceSecurityPolicy policy,
  }) {
    final failures = <IntegrationGovernanceSecurityFailure>[];

    if (policy.minContractPassRatePct < 0) {
      failures
          .add(IntegrationGovernanceSecurityFailure.invalidContractThreshold);
    }
    if (policy.requiredSecurityPassRatePct < 0) {
      failures
          .add(IntegrationGovernanceSecurityFailure.invalidSecurityThreshold);
    }
    if (policy.requiredReleaseGatePassRatePct < 0) {
      failures
          .add(IntegrationGovernanceSecurityFailure.invalidReleaseThreshold);
    }

    if (snapshot.observedContractPassRatePct < policy.minContractPassRatePct) {
      failures.add(
        IntegrationGovernanceSecurityFailure.contractPassRateBelowThreshold,
      );
    }
    if (snapshot.criticalBreakingChanges > 0) {
      failures.add(
        IntegrationGovernanceSecurityFailure.criticalBreakingChangeDetected,
      );
    }

    if (snapshot.observedSecurityPassRatePct <
        policy.requiredSecurityPassRatePct) {
      failures.add(
        IntegrationGovernanceSecurityFailure.securityPassRateBelowThreshold,
      );
    }
    if (snapshot.criticalSecurityFindings > 0) {
      failures.add(
        IntegrationGovernanceSecurityFailure.criticalSecurityFindingDetected,
      );
    }

    if (snapshot.observedReleaseGatePassRatePct <
        policy.requiredReleaseGatePassRatePct) {
      failures.add(
        IntegrationGovernanceSecurityFailure.releaseGatePassRateBelowThreshold,
      );
    }
    if (snapshot.criticalOpenReleaseFindings > 0) {
      failures.add(
        IntegrationGovernanceSecurityFailure.criticalOpenReleaseFindingDetected,
      );
    }

    if (failures.isEmpty) {
      return IntegrationGovernanceSecurityValidationResult.pass();
    }
    return IntegrationGovernanceSecurityValidationResult.fail(failures);
  }
}

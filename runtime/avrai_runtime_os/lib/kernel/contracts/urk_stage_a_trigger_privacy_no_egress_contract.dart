// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkStageATriggerPrivacyNoEgressFailure {
  invalidTriggerCoverageThreshold,
  invalidPrivacyPolicyThreshold,
  invalidConsentGateThreshold,
  invalidNoEgressThreshold,
  triggerCoverageBelowThreshold,
  privacyPolicyCoverageBelowThreshold,
  consentGateCoverageBelowThreshold,
  localSovereignCoverageBelowThreshold,
  noEgressViolationExceeded,
}

class UrkStageATriggerPrivacyNoEgressPolicy {
  const UrkStageATriggerPrivacyNoEgressPolicy({
    required this.requiredTriggerCoveragePct,
    required this.requiredPrivacyModePolicyCoveragePct,
    required this.requiredConsentGateCoveragePct,
    required this.requiredLocalSovereignCoveragePct,
    required this.maxNoEgressViolations,
  });

  final double requiredTriggerCoveragePct;
  final double requiredPrivacyModePolicyCoveragePct;
  final double requiredConsentGateCoveragePct;
  final double requiredLocalSovereignCoveragePct;
  final int maxNoEgressViolations;
}

class UrkStageATriggerPrivacyNoEgressSnapshot {
  const UrkStageATriggerPrivacyNoEgressSnapshot({
    required this.observedTriggerCoveragePct,
    required this.observedPrivacyModePolicyCoveragePct,
    required this.observedConsentGateCoveragePct,
    required this.observedLocalSovereignCoveragePct,
    required this.observedNoEgressViolations,
  });

  final double observedTriggerCoveragePct;
  final double observedPrivacyModePolicyCoveragePct;
  final double observedConsentGateCoveragePct;
  final double observedLocalSovereignCoveragePct;
  final int observedNoEgressViolations;
}

class UrkStageATriggerPrivacyNoEgressValidationResult {
  const UrkStageATriggerPrivacyNoEgressValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkStageATriggerPrivacyNoEgressValidationResult.pass() {
    return const UrkStageATriggerPrivacyNoEgressValidationResult._(
      isPassing: true,
      failures: <UrkStageATriggerPrivacyNoEgressFailure>[],
    );
  }

  factory UrkStageATriggerPrivacyNoEgressValidationResult.fail(
    List<UrkStageATriggerPrivacyNoEgressFailure> failures,
  ) {
    return UrkStageATriggerPrivacyNoEgressValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkStageATriggerPrivacyNoEgressFailure> failures;
}

class UrkStageATriggerPrivacyNoEgressValidator {
  const UrkStageATriggerPrivacyNoEgressValidator();

  UrkStageATriggerPrivacyNoEgressValidationResult validate({
    required UrkStageATriggerPrivacyNoEgressSnapshot snapshot,
    required UrkStageATriggerPrivacyNoEgressPolicy policy,
  }) {
    final failures = <UrkStageATriggerPrivacyNoEgressFailure>[];

    if (policy.requiredTriggerCoveragePct < 0) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure.invalidTriggerCoverageThreshold,
      );
    }
    if (policy.requiredPrivacyModePolicyCoveragePct < 0) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure.invalidPrivacyPolicyThreshold,
      );
    }
    if (policy.requiredConsentGateCoveragePct < 0) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure.invalidConsentGateThreshold,
      );
    }
    if (policy.requiredLocalSovereignCoveragePct < 0 ||
        policy.maxNoEgressViolations < 0) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure.invalidNoEgressThreshold,
      );
    }

    if (snapshot.observedTriggerCoveragePct <
        policy.requiredTriggerCoveragePct) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure.triggerCoverageBelowThreshold,
      );
    }
    if (snapshot.observedPrivacyModePolicyCoveragePct <
        policy.requiredPrivacyModePolicyCoveragePct) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure
            .privacyPolicyCoverageBelowThreshold,
      );
    }
    if (snapshot.observedConsentGateCoveragePct <
        policy.requiredConsentGateCoveragePct) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure
            .consentGateCoverageBelowThreshold,
      );
    }
    if (snapshot.observedLocalSovereignCoveragePct <
        policy.requiredLocalSovereignCoveragePct) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure
            .localSovereignCoverageBelowThreshold,
      );
    }
    if (snapshot.observedNoEgressViolations > policy.maxNoEgressViolations) {
      failures.add(
        UrkStageATriggerPrivacyNoEgressFailure.noEgressViolationExceeded,
      );
    }

    if (failures.isEmpty) {
      return UrkStageATriggerPrivacyNoEgressValidationResult.pass();
    }
    return UrkStageATriggerPrivacyNoEgressValidationResult.fail(failures);
  }
}

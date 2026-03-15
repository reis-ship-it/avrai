// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkGovernanceInspectionFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  governanceStrataCoverageBelowThreshold,
  summaryVisibilityCoverageBelowThreshold,
  breakGlassAuditCoverageBelowThreshold,
  unauditedBreakGlassInspectionDetected,
  hiddenInspectionPathDetected,
}

class UrkGovernanceInspectionPolicy {
  const UrkGovernanceInspectionPolicy({
    required this.requiredGovernanceStrataCoveragePct,
    required this.requiredSummaryVisibilityCoveragePct,
    required this.requiredBreakGlassAuditCoveragePct,
    required this.maxUnauditedBreakGlassInspections,
    required this.maxHiddenInspectionPaths,
  });

  final double requiredGovernanceStrataCoveragePct;
  final double requiredSummaryVisibilityCoveragePct;
  final double requiredBreakGlassAuditCoveragePct;
  final int maxUnauditedBreakGlassInspections;
  final int maxHiddenInspectionPaths;
}

class UrkGovernanceInspectionSnapshot {
  const UrkGovernanceInspectionSnapshot({
    required this.observedGovernanceStrataCoveragePct,
    required this.observedSummaryVisibilityCoveragePct,
    required this.observedBreakGlassAuditCoveragePct,
    required this.observedUnauditedBreakGlassInspections,
    required this.observedHiddenInspectionPaths,
  });

  final double observedGovernanceStrataCoveragePct;
  final double observedSummaryVisibilityCoveragePct;
  final double observedBreakGlassAuditCoveragePct;
  final int observedUnauditedBreakGlassInspections;
  final int observedHiddenInspectionPaths;
}

class UrkGovernanceInspectionValidationResult {
  const UrkGovernanceInspectionValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkGovernanceInspectionValidationResult.pass() {
    return const UrkGovernanceInspectionValidationResult._(
      isPassing: true,
      failures: <UrkGovernanceInspectionFailure>[],
    );
  }

  factory UrkGovernanceInspectionValidationResult.fail(
    List<UrkGovernanceInspectionFailure> failures,
  ) {
    return UrkGovernanceInspectionValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkGovernanceInspectionFailure> failures;
}

class UrkGovernanceInspectionValidator {
  const UrkGovernanceInspectionValidator();

  UrkGovernanceInspectionValidationResult validate({
    required UrkGovernanceInspectionSnapshot snapshot,
    required UrkGovernanceInspectionPolicy policy,
  }) {
    final failures = <UrkGovernanceInspectionFailure>[];

    if (policy.requiredGovernanceStrataCoveragePct < 0 ||
        policy.requiredSummaryVisibilityCoveragePct < 0 ||
        policy.requiredBreakGlassAuditCoveragePct < 0) {
      failures.add(UrkGovernanceInspectionFailure.invalidCoverageThreshold);
    }
    if (policy.maxUnauditedBreakGlassInspections < 0 ||
        policy.maxHiddenInspectionPaths < 0) {
      failures.add(UrkGovernanceInspectionFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedGovernanceStrataCoveragePct <
        policy.requiredGovernanceStrataCoveragePct) {
      failures.add(
        UrkGovernanceInspectionFailure.governanceStrataCoverageBelowThreshold,
      );
    }
    if (snapshot.observedSummaryVisibilityCoveragePct <
        policy.requiredSummaryVisibilityCoveragePct) {
      failures.add(
        UrkGovernanceInspectionFailure.summaryVisibilityCoverageBelowThreshold,
      );
    }
    if (snapshot.observedBreakGlassAuditCoveragePct <
        policy.requiredBreakGlassAuditCoveragePct) {
      failures.add(
        UrkGovernanceInspectionFailure.breakGlassAuditCoverageBelowThreshold,
      );
    }
    if (snapshot.observedUnauditedBreakGlassInspections >
        policy.maxUnauditedBreakGlassInspections) {
      failures.add(
        UrkGovernanceInspectionFailure.unauditedBreakGlassInspectionDetected,
      );
    }
    if (snapshot.observedHiddenInspectionPaths >
        policy.maxHiddenInspectionPaths) {
      failures.add(UrkGovernanceInspectionFailure.hiddenInspectionPathDetected);
    }

    if (failures.isEmpty) {
      return UrkGovernanceInspectionValidationResult.pass();
    }
    return UrkGovernanceInspectionValidationResult.fail(failures);
  }
}

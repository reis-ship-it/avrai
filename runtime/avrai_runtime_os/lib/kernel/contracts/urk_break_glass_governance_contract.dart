// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkBreakGlassGovernanceFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  signedDirectiveCoverageBelowThreshold,
  dualApprovalCoverageBelowThreshold,
  governanceChannelSeparationBelowThreshold,
  unauthorizedBreakGlassActionDetected,
  learningPathTunnelingDetected,
}

class UrkBreakGlassGovernancePolicy {
  const UrkBreakGlassGovernancePolicy({
    required this.requiredSignedDirectiveCoveragePct,
    required this.requiredDualApprovalCoveragePct,
    required this.requiredGovernanceChannelSeparationPct,
    required this.maxUnauthorizedBreakGlassActions,
    required this.maxLearningPathTunnelingEvents,
  });

  final double requiredSignedDirectiveCoveragePct;
  final double requiredDualApprovalCoveragePct;
  final double requiredGovernanceChannelSeparationPct;
  final int maxUnauthorizedBreakGlassActions;
  final int maxLearningPathTunnelingEvents;
}

class UrkBreakGlassGovernanceSnapshot {
  const UrkBreakGlassGovernanceSnapshot({
    required this.observedSignedDirectiveCoveragePct,
    required this.observedDualApprovalCoveragePct,
    required this.observedGovernanceChannelSeparationPct,
    required this.observedUnauthorizedBreakGlassActions,
    required this.observedLearningPathTunnelingEvents,
  });

  final double observedSignedDirectiveCoveragePct;
  final double observedDualApprovalCoveragePct;
  final double observedGovernanceChannelSeparationPct;
  final int observedUnauthorizedBreakGlassActions;
  final int observedLearningPathTunnelingEvents;
}

class UrkBreakGlassGovernanceValidationResult {
  const UrkBreakGlassGovernanceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkBreakGlassGovernanceValidationResult.pass() {
    return const UrkBreakGlassGovernanceValidationResult._(
      isPassing: true,
      failures: <UrkBreakGlassGovernanceFailure>[],
    );
  }

  factory UrkBreakGlassGovernanceValidationResult.fail(
    List<UrkBreakGlassGovernanceFailure> failures,
  ) {
    return UrkBreakGlassGovernanceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkBreakGlassGovernanceFailure> failures;
}

class UrkBreakGlassGovernanceValidator {
  const UrkBreakGlassGovernanceValidator();

  UrkBreakGlassGovernanceValidationResult validate({
    required UrkBreakGlassGovernanceSnapshot snapshot,
    required UrkBreakGlassGovernancePolicy policy,
  }) {
    final failures = <UrkBreakGlassGovernanceFailure>[];

    if (policy.requiredSignedDirectiveCoveragePct < 0 ||
        policy.requiredDualApprovalCoveragePct < 0 ||
        policy.requiredGovernanceChannelSeparationPct < 0) {
      failures.add(UrkBreakGlassGovernanceFailure.invalidCoverageThreshold);
    }
    if (policy.maxUnauthorizedBreakGlassActions < 0 ||
        policy.maxLearningPathTunnelingEvents < 0) {
      failures.add(UrkBreakGlassGovernanceFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedSignedDirectiveCoveragePct <
        policy.requiredSignedDirectiveCoveragePct) {
      failures.add(
        UrkBreakGlassGovernanceFailure.signedDirectiveCoverageBelowThreshold,
      );
    }
    if (snapshot.observedDualApprovalCoveragePct <
        policy.requiredDualApprovalCoveragePct) {
      failures.add(
        UrkBreakGlassGovernanceFailure.dualApprovalCoverageBelowThreshold,
      );
    }
    if (snapshot.observedGovernanceChannelSeparationPct <
        policy.requiredGovernanceChannelSeparationPct) {
      failures.add(UrkBreakGlassGovernanceFailure
          .governanceChannelSeparationBelowThreshold);
    }
    if (snapshot.observedUnauthorizedBreakGlassActions >
        policy.maxUnauthorizedBreakGlassActions) {
      failures.add(
        UrkBreakGlassGovernanceFailure.unauthorizedBreakGlassActionDetected,
      );
    }
    if (snapshot.observedLearningPathTunnelingEvents >
        policy.maxLearningPathTunnelingEvents) {
      failures.add(
        UrkBreakGlassGovernanceFailure.learningPathTunnelingDetected,
      );
    }

    if (failures.isEmpty) {
      return UrkBreakGlassGovernanceValidationResult.pass();
    }
    return UrkBreakGlassGovernanceValidationResult.fail(failures);
  }
}

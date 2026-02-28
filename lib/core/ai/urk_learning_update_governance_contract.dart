enum UrkLearningUpdateGovernanceFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  updateValidationCoverageBelowThreshold,
  dataLineageCoverageBelowThreshold,
  unreviewedHighImpactLearningUpdateDetected,
  failedRollbackRecoveryDetected,
}

class UrkLearningUpdateGovernancePolicy {
  const UrkLearningUpdateGovernancePolicy({
    required this.requiredUpdateValidationCoveragePct,
    required this.requiredDataLineageCoveragePct,
    required this.maxUnreviewedHighImpactLearningUpdates,
    required this.maxFailedRollbackRecoveryEvents,
  });

  final double requiredUpdateValidationCoveragePct;
  final double requiredDataLineageCoveragePct;
  final int maxUnreviewedHighImpactLearningUpdates;
  final int maxFailedRollbackRecoveryEvents;
}

class UrkLearningUpdateGovernanceSnapshot {
  const UrkLearningUpdateGovernanceSnapshot({
    required this.observedUpdateValidationCoveragePct,
    required this.observedDataLineageCoveragePct,
    required this.observedUnreviewedHighImpactLearningUpdates,
    required this.observedFailedRollbackRecoveryEvents,
  });

  final double observedUpdateValidationCoveragePct;
  final double observedDataLineageCoveragePct;
  final int observedUnreviewedHighImpactLearningUpdates;
  final int observedFailedRollbackRecoveryEvents;
}

class UrkLearningUpdateGovernanceValidationResult {
  const UrkLearningUpdateGovernanceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkLearningUpdateGovernanceValidationResult.pass() {
    return const UrkLearningUpdateGovernanceValidationResult._(
      isPassing: true,
      failures: <UrkLearningUpdateGovernanceFailure>[],
    );
  }

  factory UrkLearningUpdateGovernanceValidationResult.fail(
    List<UrkLearningUpdateGovernanceFailure> failures,
  ) {
    return UrkLearningUpdateGovernanceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkLearningUpdateGovernanceFailure> failures;
}

class UrkLearningUpdateGovernanceValidator {
  const UrkLearningUpdateGovernanceValidator();

  UrkLearningUpdateGovernanceValidationResult validate({
    required UrkLearningUpdateGovernanceSnapshot snapshot,
    required UrkLearningUpdateGovernancePolicy policy,
  }) {
    final failures = <UrkLearningUpdateGovernanceFailure>[];

    if (policy.requiredUpdateValidationCoveragePct < 0 ||
        policy.requiredDataLineageCoveragePct < 0) {
      failures.add(UrkLearningUpdateGovernanceFailure.invalidCoverageThreshold);
    }
    if (policy.maxUnreviewedHighImpactLearningUpdates < 0 ||
        policy.maxFailedRollbackRecoveryEvents < 0) {
      failures.add(UrkLearningUpdateGovernanceFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedUpdateValidationCoveragePct <
        policy.requiredUpdateValidationCoveragePct) {
      failures.add(
        UrkLearningUpdateGovernanceFailure
            .updateValidationCoverageBelowThreshold,
      );
    }
    if (snapshot.observedDataLineageCoveragePct <
        policy.requiredDataLineageCoveragePct) {
      failures
          .add(UrkLearningUpdateGovernanceFailure.dataLineageCoverageBelowThreshold);
    }
    if (snapshot.observedUnreviewedHighImpactLearningUpdates >
        policy.maxUnreviewedHighImpactLearningUpdates) {
      failures.add(
        UrkLearningUpdateGovernanceFailure
            .unreviewedHighImpactLearningUpdateDetected,
      );
    }
    if (snapshot.observedFailedRollbackRecoveryEvents >
        policy.maxFailedRollbackRecoveryEvents) {
      failures
          .add(UrkLearningUpdateGovernanceFailure.failedRollbackRecoveryDetected);
    }

    if (failures.isEmpty) {
      return UrkLearningUpdateGovernanceValidationResult.pass();
    }
    return UrkLearningUpdateGovernanceValidationResult.fail(failures);
  }
}

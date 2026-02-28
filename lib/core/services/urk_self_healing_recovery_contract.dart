enum UrkSelfHealingRecoveryFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  detectContainRecoverCoverageBelowThreshold,
  rollbackPathCoverageBelowThreshold,
  uncontainedIncidentDetected,
  failedRecoveryDetected,
}

class UrkSelfHealingRecoveryPolicy {
  const UrkSelfHealingRecoveryPolicy({
    required this.requiredDetectContainRecoverCoveragePct,
    required this.requiredRollbackPathCoveragePct,
    required this.maxUncontainedIncidentEvents,
    required this.maxFailedRecoveryEvents,
  });

  final double requiredDetectContainRecoverCoveragePct;
  final double requiredRollbackPathCoveragePct;
  final int maxUncontainedIncidentEvents;
  final int maxFailedRecoveryEvents;
}

class UrkSelfHealingRecoverySnapshot {
  const UrkSelfHealingRecoverySnapshot({
    required this.observedDetectContainRecoverCoveragePct,
    required this.observedRollbackPathCoveragePct,
    required this.observedUncontainedIncidentEvents,
    required this.observedFailedRecoveryEvents,
  });

  final double observedDetectContainRecoverCoveragePct;
  final double observedRollbackPathCoveragePct;
  final int observedUncontainedIncidentEvents;
  final int observedFailedRecoveryEvents;
}

class UrkSelfHealingRecoveryValidationResult {
  const UrkSelfHealingRecoveryValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkSelfHealingRecoveryValidationResult.pass() {
    return const UrkSelfHealingRecoveryValidationResult._(
      isPassing: true,
      failures: <UrkSelfHealingRecoveryFailure>[],
    );
  }

  factory UrkSelfHealingRecoveryValidationResult.fail(
    List<UrkSelfHealingRecoveryFailure> failures,
  ) {
    return UrkSelfHealingRecoveryValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkSelfHealingRecoveryFailure> failures;
}

class UrkSelfHealingRecoveryValidator {
  const UrkSelfHealingRecoveryValidator();

  UrkSelfHealingRecoveryValidationResult validate({
    required UrkSelfHealingRecoverySnapshot snapshot,
    required UrkSelfHealingRecoveryPolicy policy,
  }) {
    final failures = <UrkSelfHealingRecoveryFailure>[];

    if (policy.requiredDetectContainRecoverCoveragePct < 0 ||
        policy.requiredRollbackPathCoveragePct < 0) {
      failures.add(UrkSelfHealingRecoveryFailure.invalidCoverageThreshold);
    }
    if (policy.maxUncontainedIncidentEvents < 0 ||
        policy.maxFailedRecoveryEvents < 0) {
      failures.add(UrkSelfHealingRecoveryFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedDetectContainRecoverCoveragePct <
        policy.requiredDetectContainRecoverCoveragePct) {
      failures.add(
        UrkSelfHealingRecoveryFailure
            .detectContainRecoverCoverageBelowThreshold,
      );
    }
    if (snapshot.observedRollbackPathCoveragePct <
        policy.requiredRollbackPathCoveragePct) {
      failures.add(
          UrkSelfHealingRecoveryFailure.rollbackPathCoverageBelowThreshold);
    }
    if (snapshot.observedUncontainedIncidentEvents >
        policy.maxUncontainedIncidentEvents) {
      failures.add(UrkSelfHealingRecoveryFailure.uncontainedIncidentDetected);
    }
    if (snapshot.observedFailedRecoveryEvents >
        policy.maxFailedRecoveryEvents) {
      failures.add(UrkSelfHealingRecoveryFailure.failedRecoveryDetected);
    }

    if (failures.isEmpty) {
      return UrkSelfHealingRecoveryValidationResult.pass();
    }
    return UrkSelfHealingRecoveryValidationResult.fail(failures);
  }
}

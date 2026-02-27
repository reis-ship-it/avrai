enum PlannerGuardrailRollbackFailure {
  invalidGuardrailThreshold,
  invalidRollbackThreshold,
  hardConstraintViolationRateExceeded,
  hardConstraintEnvelopeFailed,
  rollbackSuccessRateFailed,
  rollbackRecoveryLatencyExceeded,
  softRollbackIntegrityFailed,
  hardRollbackIntegrityFailed,
  provenanceCompletenessFailed,
}

class PlannerGuardrailRollbackPolicy {
  const PlannerGuardrailRollbackPolicy({
    required this.maxHardConstraintViolationRatePct,
    required this.requiredRollbackSuccessRatePct,
    required this.maxRecoveryLatencySeconds,
  });

  final double maxHardConstraintViolationRatePct;
  final double requiredRollbackSuccessRatePct;
  final double maxRecoveryLatencySeconds;
}

class PlannerGuardrailRollbackSnapshot {
  const PlannerGuardrailRollbackSnapshot({
    required this.observedHardConstraintViolationRatePct,
    required this.hardConstraintEnvelopePassed,
    required this.observedRollbackSuccessRatePct,
    required this.observedP95RecoveryLatencySeconds,
    required this.softRollbackIntegrityPassed,
    required this.hardRollbackIntegrityPassed,
    required this.provenanceCompletenessPassed,
  });

  final double observedHardConstraintViolationRatePct;
  final bool hardConstraintEnvelopePassed;
  final double observedRollbackSuccessRatePct;
  final double observedP95RecoveryLatencySeconds;
  final bool softRollbackIntegrityPassed;
  final bool hardRollbackIntegrityPassed;
  final bool provenanceCompletenessPassed;
}

class PlannerGuardrailRollbackValidationResult {
  const PlannerGuardrailRollbackValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory PlannerGuardrailRollbackValidationResult.pass() {
    return const PlannerGuardrailRollbackValidationResult._(
      isPassing: true,
      failures: <PlannerGuardrailRollbackFailure>[],
    );
  }

  factory PlannerGuardrailRollbackValidationResult.fail(
    List<PlannerGuardrailRollbackFailure> failures,
  ) {
    return PlannerGuardrailRollbackValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<PlannerGuardrailRollbackFailure> failures;
}

class PlannerGuardrailRollbackValidator {
  const PlannerGuardrailRollbackValidator();

  PlannerGuardrailRollbackValidationResult validate({
    required PlannerGuardrailRollbackSnapshot snapshot,
    required PlannerGuardrailRollbackPolicy policy,
  }) {
    final failures = <PlannerGuardrailRollbackFailure>[];

    if (policy.maxHardConstraintViolationRatePct < 0) {
      failures.add(PlannerGuardrailRollbackFailure.invalidGuardrailThreshold);
    }
    if (policy.requiredRollbackSuccessRatePct < 0 ||
        policy.maxRecoveryLatencySeconds < 0) {
      failures.add(PlannerGuardrailRollbackFailure.invalidRollbackThreshold);
    }

    if (snapshot.observedHardConstraintViolationRatePct >
        policy.maxHardConstraintViolationRatePct) {
      failures.add(
        PlannerGuardrailRollbackFailure.hardConstraintViolationRateExceeded,
      );
    }
    if (!snapshot.hardConstraintEnvelopePassed) {
      failures
          .add(PlannerGuardrailRollbackFailure.hardConstraintEnvelopeFailed);
    }

    if (snapshot.observedRollbackSuccessRatePct <
        policy.requiredRollbackSuccessRatePct) {
      failures.add(PlannerGuardrailRollbackFailure.rollbackSuccessRateFailed);
    }
    if (snapshot.observedP95RecoveryLatencySeconds >
        policy.maxRecoveryLatencySeconds) {
      failures
          .add(PlannerGuardrailRollbackFailure.rollbackRecoveryLatencyExceeded);
    }

    if (!snapshot.softRollbackIntegrityPassed) {
      failures.add(PlannerGuardrailRollbackFailure.softRollbackIntegrityFailed);
    }
    if (!snapshot.hardRollbackIntegrityPassed) {
      failures.add(PlannerGuardrailRollbackFailure.hardRollbackIntegrityFailed);
    }
    if (!snapshot.provenanceCompletenessPassed) {
      failures
          .add(PlannerGuardrailRollbackFailure.provenanceCompletenessFailed);
    }

    if (failures.isEmpty) {
      return PlannerGuardrailRollbackValidationResult.pass();
    }
    return PlannerGuardrailRollbackValidationResult.fail(failures);
  }
}

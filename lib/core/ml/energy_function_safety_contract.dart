// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
enum EnergyFunctionSafetyFailure {
  invalidSafetyThreshold,
  invalidRegressionThreshold,
  invalidWeightPolicy,
  safetyViolationRateExceeded,
  safetyBoundsFailed,
  regressionDeltaExceeded,
  failClosedDisabled,
  rollbackReadinessFailed,
}

class EnergyFunctionSafetyPolicy {
  const EnergyFunctionSafetyPolicy({
    required this.maxPolicyViolationRatePct,
    required this.maxRegressionDeltaPct,
    required this.minNegativeOutcomeWeight,
    required this.minModelFailureWeight,
  });

  final double maxPolicyViolationRatePct;
  final double maxRegressionDeltaPct;
  final double minNegativeOutcomeWeight;
  final double minModelFailureWeight;
}

class EnergyFunctionSafetySnapshot {
  const EnergyFunctionSafetySnapshot({
    required this.observedPolicyViolationRatePct,
    required this.safetyBoundsPassed,
    required this.observedRegressionDeltaPct,
    required this.positiveOutcomeWeight,
    required this.negativeOutcomeWeight,
    required this.modelFailureWeight,
    required this.failClosedEnabled,
    required this.rollbackReadinessPassed,
  });

  final double observedPolicyViolationRatePct;
  final bool safetyBoundsPassed;
  final double observedRegressionDeltaPct;
  final double positiveOutcomeWeight;
  final double negativeOutcomeWeight;
  final double modelFailureWeight;
  final bool failClosedEnabled;
  final bool rollbackReadinessPassed;
}

class EnergyFunctionSafetyValidationResult {
  const EnergyFunctionSafetyValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory EnergyFunctionSafetyValidationResult.pass() {
    return const EnergyFunctionSafetyValidationResult._(
      isPassing: true,
      failures: <EnergyFunctionSafetyFailure>[],
    );
  }

  factory EnergyFunctionSafetyValidationResult.fail(
    List<EnergyFunctionSafetyFailure> failures,
  ) {
    return EnergyFunctionSafetyValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<EnergyFunctionSafetyFailure> failures;
}

class EnergyFunctionSafetyValidator {
  const EnergyFunctionSafetyValidator();

  EnergyFunctionSafetyValidationResult validate({
    required EnergyFunctionSafetySnapshot snapshot,
    required EnergyFunctionSafetyPolicy policy,
  }) {
    final failures = <EnergyFunctionSafetyFailure>[];

    if (policy.maxPolicyViolationRatePct < 0) {
      failures.add(EnergyFunctionSafetyFailure.invalidSafetyThreshold);
    }
    if (policy.maxRegressionDeltaPct < 0) {
      failures.add(EnergyFunctionSafetyFailure.invalidRegressionThreshold);
    }

    final weightPolicyInvalid = policy.minNegativeOutcomeWeight < 0 ||
        policy.minModelFailureWeight < 0 ||
        policy.minModelFailureWeight < policy.minNegativeOutcomeWeight;
    if (weightPolicyInvalid) {
      failures.add(EnergyFunctionSafetyFailure.invalidWeightPolicy);
    }

    if (snapshot.observedPolicyViolationRatePct >
        policy.maxPolicyViolationRatePct) {
      failures.add(EnergyFunctionSafetyFailure.safetyViolationRateExceeded);
    }
    if (!snapshot.safetyBoundsPassed) {
      failures.add(EnergyFunctionSafetyFailure.safetyBoundsFailed);
    }
    if (snapshot.observedRegressionDeltaPct > policy.maxRegressionDeltaPct) {
      failures.add(EnergyFunctionSafetyFailure.regressionDeltaExceeded);
    }

    final weightsValid = snapshot.positiveOutcomeWeight > 0 &&
        snapshot.negativeOutcomeWeight >= policy.minNegativeOutcomeWeight &&
        snapshot.modelFailureWeight >= policy.minModelFailureWeight &&
        snapshot.negativeOutcomeWeight >= snapshot.positiveOutcomeWeight &&
        snapshot.modelFailureWeight >= snapshot.negativeOutcomeWeight;
    if (!weightsValid) {
      failures.add(EnergyFunctionSafetyFailure.invalidWeightPolicy);
    }

    if (!snapshot.failClosedEnabled) {
      failures.add(EnergyFunctionSafetyFailure.failClosedDisabled);
    }
    if (!snapshot.rollbackReadinessPassed) {
      failures.add(EnergyFunctionSafetyFailure.rollbackReadinessFailed);
    }

    if (failures.isEmpty) {
      return EnergyFunctionSafetyValidationResult.pass();
    }
    return EnergyFunctionSafetyValidationResult.fail(failures);
  }
}

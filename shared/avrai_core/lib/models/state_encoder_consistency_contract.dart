// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
enum StateEncoderConsistencyFailure {
  freshnessThresholdInvalid,
  mismatchThresholdInvalid,
  staleFeatureAgeExceeded,
  mismatchRateExceeded,
  atomicSnapshotNonMonotonic,
  lineageIncomplete,
}

class StateEncoderConsistencyPolicy {
  const StateEncoderConsistencyPolicy({
    required this.maxP95FeatureAgeMinutes,
    required this.maxMismatchRatePct,
  });

  final double maxP95FeatureAgeMinutes;
  final double maxMismatchRatePct;
}

class StateEncoderConsistencySnapshot {
  const StateEncoderConsistencySnapshot({
    required this.observedP95FeatureAgeMinutes,
    required this.observedMismatchRatePct,
    required this.monotonicSequencePassed,
    required this.lineageCompletenessPassed,
  });

  final double observedP95FeatureAgeMinutes;
  final double observedMismatchRatePct;
  final bool monotonicSequencePassed;
  final bool lineageCompletenessPassed;
}

class StateEncoderConsistencyValidationResult {
  const StateEncoderConsistencyValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory StateEncoderConsistencyValidationResult.pass() {
    return const StateEncoderConsistencyValidationResult._(
      isPassing: true,
      failures: <StateEncoderConsistencyFailure>[],
    );
  }

  factory StateEncoderConsistencyValidationResult.fail(
    List<StateEncoderConsistencyFailure> failures,
  ) {
    return StateEncoderConsistencyValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<StateEncoderConsistencyFailure> failures;
}

class StateEncoderConsistencyValidator {
  const StateEncoderConsistencyValidator();

  StateEncoderConsistencyValidationResult validate({
    required StateEncoderConsistencySnapshot snapshot,
    required StateEncoderConsistencyPolicy policy,
  }) {
    final failures = <StateEncoderConsistencyFailure>[];

    if (policy.maxP95FeatureAgeMinutes < 0) {
      failures.add(StateEncoderConsistencyFailure.freshnessThresholdInvalid);
    }
    if (policy.maxMismatchRatePct < 0) {
      failures.add(StateEncoderConsistencyFailure.mismatchThresholdInvalid);
    }

    if (snapshot.observedP95FeatureAgeMinutes >
        policy.maxP95FeatureAgeMinutes) {
      failures.add(StateEncoderConsistencyFailure.staleFeatureAgeExceeded);
    }
    if (snapshot.observedMismatchRatePct > policy.maxMismatchRatePct) {
      failures.add(StateEncoderConsistencyFailure.mismatchRateExceeded);
    }
    if (!snapshot.monotonicSequencePassed) {
      failures.add(StateEncoderConsistencyFailure.atomicSnapshotNonMonotonic);
    }
    if (!snapshot.lineageCompletenessPassed) {
      failures.add(StateEncoderConsistencyFailure.lineageIncomplete);
    }

    if (failures.isEmpty) {
      return StateEncoderConsistencyValidationResult.pass();
    }
    return StateEncoderConsistencyValidationResult.fail(failures);
  }
}

// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkQuantumAtomicTimeValidityFailure {
  invalidCoverageThreshold,
  invalidTimingThreshold,
  timestampCoverageBelowThreshold,
  highImpactValidityCoverageBelowThreshold,
  reconciliationValidityCoverageBelowThreshold,
  uncertaintyWindowExceeded,
  clockRegressionDetected,
}

class UrkQuantumAtomicTimeValidityPolicy {
  const UrkQuantumAtomicTimeValidityPolicy({
    required this.requiredTimestampCoveragePct,
    required this.requiredHighImpactValidityCoveragePct,
    required this.requiredReconciliationValidityCoveragePct,
    required this.maxUncertaintyWindowMs,
    required this.maxClockRegressionEvents,
  });

  final double requiredTimestampCoveragePct;
  final double requiredHighImpactValidityCoveragePct;
  final double requiredReconciliationValidityCoveragePct;
  final int maxUncertaintyWindowMs;
  final int maxClockRegressionEvents;
}

class UrkQuantumAtomicTimeValiditySnapshot {
  const UrkQuantumAtomicTimeValiditySnapshot({
    required this.observedTimestampCoveragePct,
    required this.observedHighImpactValidityCoveragePct,
    required this.observedReconciliationValidityCoveragePct,
    required this.observedMaxUncertaintyWindowMs,
    required this.observedClockRegressionEvents,
  });

  final double observedTimestampCoveragePct;
  final double observedHighImpactValidityCoveragePct;
  final double observedReconciliationValidityCoveragePct;
  final int observedMaxUncertaintyWindowMs;
  final int observedClockRegressionEvents;
}

class UrkQuantumAtomicTimeValidityValidationResult {
  const UrkQuantumAtomicTimeValidityValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkQuantumAtomicTimeValidityValidationResult.pass() {
    return const UrkQuantumAtomicTimeValidityValidationResult._(
      isPassing: true,
      failures: <UrkQuantumAtomicTimeValidityFailure>[],
    );
  }

  factory UrkQuantumAtomicTimeValidityValidationResult.fail(
    List<UrkQuantumAtomicTimeValidityFailure> failures,
  ) {
    return UrkQuantumAtomicTimeValidityValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkQuantumAtomicTimeValidityFailure> failures;
}

class UrkQuantumAtomicTimeValidityValidator {
  const UrkQuantumAtomicTimeValidityValidator();

  UrkQuantumAtomicTimeValidityValidationResult validate({
    required UrkQuantumAtomicTimeValiditySnapshot snapshot,
    required UrkQuantumAtomicTimeValidityPolicy policy,
  }) {
    final failures = <UrkQuantumAtomicTimeValidityFailure>[];

    if (policy.requiredTimestampCoveragePct < 0 ||
        policy.requiredHighImpactValidityCoveragePct < 0 ||
        policy.requiredReconciliationValidityCoveragePct < 0) {
      failures
          .add(UrkQuantumAtomicTimeValidityFailure.invalidCoverageThreshold);
    }
    if (policy.maxUncertaintyWindowMs < 0 ||
        policy.maxClockRegressionEvents < 0) {
      failures.add(UrkQuantumAtomicTimeValidityFailure.invalidTimingThreshold);
    }

    if (snapshot.observedTimestampCoveragePct <
        policy.requiredTimestampCoveragePct) {
      failures.add(
        UrkQuantumAtomicTimeValidityFailure.timestampCoverageBelowThreshold,
      );
    }
    if (snapshot.observedHighImpactValidityCoveragePct <
        policy.requiredHighImpactValidityCoveragePct) {
      failures.add(UrkQuantumAtomicTimeValidityFailure
          .highImpactValidityCoverageBelowThreshold);
    }
    if (snapshot.observedReconciliationValidityCoveragePct <
        policy.requiredReconciliationValidityCoveragePct) {
      failures.add(UrkQuantumAtomicTimeValidityFailure
          .reconciliationValidityCoverageBelowThreshold);
    }
    if (snapshot.observedMaxUncertaintyWindowMs >
        policy.maxUncertaintyWindowMs) {
      failures.add(
        UrkQuantumAtomicTimeValidityFailure.uncertaintyWindowExceeded,
      );
    }
    if (snapshot.observedClockRegressionEvents >
        policy.maxClockRegressionEvents) {
      failures.add(
        UrkQuantumAtomicTimeValidityFailure.clockRegressionDetected,
      );
    }

    if (failures.isEmpty) {
      return UrkQuantumAtomicTimeValidityValidationResult.pass();
    }
    return UrkQuantumAtomicTimeValidityValidationResult.fail(failures);
  }
}

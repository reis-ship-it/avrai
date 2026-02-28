// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkRealityTemporalTruthFailure {
  invalidAlignmentThreshold,
  invalidSafetyThreshold,
  atomicSemanticAlignmentBelowThreshold,
  timezoneNormalizationCoverageBelowThreshold,
  temporalContradictionDetected,
  clockRegressionDetected,
}

class UrkRealityTemporalTruthPolicy {
  const UrkRealityTemporalTruthPolicy({
    required this.requiredAtomicSemanticAlignmentPct,
    required this.requiredTimezoneNormalizationCoveragePct,
    required this.maxTemporalContradictionEvents,
    required this.maxClockRegressionEvents,
  });

  final double requiredAtomicSemanticAlignmentPct;
  final double requiredTimezoneNormalizationCoveragePct;
  final int maxTemporalContradictionEvents;
  final int maxClockRegressionEvents;
}

class UrkRealityTemporalTruthSnapshot {
  const UrkRealityTemporalTruthSnapshot({
    required this.observedAtomicSemanticAlignmentPct,
    required this.observedTimezoneNormalizationCoveragePct,
    required this.observedTemporalContradictionEvents,
    required this.observedClockRegressionEvents,
  });

  final double observedAtomicSemanticAlignmentPct;
  final double observedTimezoneNormalizationCoveragePct;
  final int observedTemporalContradictionEvents;
  final int observedClockRegressionEvents;
}

class UrkRealityTemporalTruthValidationResult {
  const UrkRealityTemporalTruthValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkRealityTemporalTruthValidationResult.pass() {
    return const UrkRealityTemporalTruthValidationResult._(
      isPassing: true,
      failures: <UrkRealityTemporalTruthFailure>[],
    );
  }

  factory UrkRealityTemporalTruthValidationResult.fail(
    List<UrkRealityTemporalTruthFailure> failures,
  ) {
    return UrkRealityTemporalTruthValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkRealityTemporalTruthFailure> failures;
}

class UrkRealityTemporalTruthValidator {
  const UrkRealityTemporalTruthValidator();

  UrkRealityTemporalTruthValidationResult validate({
    required UrkRealityTemporalTruthSnapshot snapshot,
    required UrkRealityTemporalTruthPolicy policy,
  }) {
    final failures = <UrkRealityTemporalTruthFailure>[];

    if (policy.requiredAtomicSemanticAlignmentPct < 0 ||
        policy.requiredTimezoneNormalizationCoveragePct < 0) {
      failures.add(UrkRealityTemporalTruthFailure.invalidAlignmentThreshold);
    }
    if (policy.maxTemporalContradictionEvents < 0 ||
        policy.maxClockRegressionEvents < 0) {
      failures.add(UrkRealityTemporalTruthFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedAtomicSemanticAlignmentPct <
        policy.requiredAtomicSemanticAlignmentPct) {
      failures.add(
          UrkRealityTemporalTruthFailure.atomicSemanticAlignmentBelowThreshold);
    }
    if (snapshot.observedTimezoneNormalizationCoveragePct <
        policy.requiredTimezoneNormalizationCoveragePct) {
      failures.add(UrkRealityTemporalTruthFailure
          .timezoneNormalizationCoverageBelowThreshold);
    }
    if (snapshot.observedTemporalContradictionEvents >
        policy.maxTemporalContradictionEvents) {
      failures.add(UrkRealityTemporalTruthFailure.temporalContradictionDetected);
    }
    if (snapshot.observedClockRegressionEvents > policy.maxClockRegressionEvents) {
      failures.add(UrkRealityTemporalTruthFailure.clockRegressionDetected);
    }

    if (failures.isEmpty) {
      return UrkRealityTemporalTruthValidationResult.pass();
    }
    return UrkRealityTemporalTruthValidationResult.fail(failures);
  }
}

// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkRealityWorldStateCoherenceFailure {
  invalidCoverageThreshold,
  invalidStabilityThreshold,
  planeConsistencyCoverageBelowThreshold,
  knotStringConstraintCoverageBelowThreshold,
  crossPlaneConflictDetected,
  unresolvedStateTransitionDetected,
}

class UrkRealityWorldStateCoherencePolicy {
  const UrkRealityWorldStateCoherencePolicy({
    required this.requiredPlaneConsistencyCoveragePct,
    required this.requiredKnotStringConstraintCoveragePct,
    required this.maxCrossPlaneConflicts,
    required this.maxUnresolvedStateTransitions,
  });

  final double requiredPlaneConsistencyCoveragePct;
  final double requiredKnotStringConstraintCoveragePct;
  final int maxCrossPlaneConflicts;
  final int maxUnresolvedStateTransitions;
}

class UrkRealityWorldStateCoherenceSnapshot {
  const UrkRealityWorldStateCoherenceSnapshot({
    required this.observedPlaneConsistencyCoveragePct,
    required this.observedKnotStringConstraintCoveragePct,
    required this.observedCrossPlaneConflicts,
    required this.observedUnresolvedStateTransitions,
  });

  final double observedPlaneConsistencyCoveragePct;
  final double observedKnotStringConstraintCoveragePct;
  final int observedCrossPlaneConflicts;
  final int observedUnresolvedStateTransitions;
}

class UrkRealityWorldStateCoherenceValidationResult {
  const UrkRealityWorldStateCoherenceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkRealityWorldStateCoherenceValidationResult.pass() {
    return const UrkRealityWorldStateCoherenceValidationResult._(
      isPassing: true,
      failures: <UrkRealityWorldStateCoherenceFailure>[],
    );
  }

  factory UrkRealityWorldStateCoherenceValidationResult.fail(
    List<UrkRealityWorldStateCoherenceFailure> failures,
  ) {
    return UrkRealityWorldStateCoherenceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkRealityWorldStateCoherenceFailure> failures;
}

class UrkRealityWorldStateCoherenceValidator {
  const UrkRealityWorldStateCoherenceValidator();

  UrkRealityWorldStateCoherenceValidationResult validate({
    required UrkRealityWorldStateCoherenceSnapshot snapshot,
    required UrkRealityWorldStateCoherencePolicy policy,
  }) {
    final failures = <UrkRealityWorldStateCoherenceFailure>[];

    if (policy.requiredPlaneConsistencyCoveragePct < 0 ||
        policy.requiredKnotStringConstraintCoveragePct < 0) {
      failures.add(UrkRealityWorldStateCoherenceFailure.invalidCoverageThreshold);
    }
    if (policy.maxCrossPlaneConflicts < 0 ||
        policy.maxUnresolvedStateTransitions < 0) {
      failures.add(UrkRealityWorldStateCoherenceFailure.invalidStabilityThreshold);
    }

    if (snapshot.observedPlaneConsistencyCoveragePct <
        policy.requiredPlaneConsistencyCoveragePct) {
      failures.add(
          UrkRealityWorldStateCoherenceFailure.planeConsistencyCoverageBelowThreshold);
    }
    if (snapshot.observedKnotStringConstraintCoveragePct <
        policy.requiredKnotStringConstraintCoveragePct) {
      failures.add(UrkRealityWorldStateCoherenceFailure
          .knotStringConstraintCoverageBelowThreshold);
    }
    if (snapshot.observedCrossPlaneConflicts > policy.maxCrossPlaneConflicts) {
      failures.add(UrkRealityWorldStateCoherenceFailure.crossPlaneConflictDetected);
    }
    if (snapshot.observedUnresolvedStateTransitions >
        policy.maxUnresolvedStateTransitions) {
      failures.add(
          UrkRealityWorldStateCoherenceFailure.unresolvedStateTransitionDetected);
    }

    if (failures.isEmpty) {
      return UrkRealityWorldStateCoherenceValidationResult.pass();
    }
    return UrkRealityWorldStateCoherenceValidationResult.fail(failures);
  }
}

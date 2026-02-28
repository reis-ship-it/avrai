// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkSelfLearningGovernanceFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  signalValidationCoverageBelowThreshold,
  approvalPathCoverageBelowThreshold,
  unboundedSelfLearningUpdateDetected,
  unverifiedTrainingLineageDetected,
}

class UrkSelfLearningGovernancePolicy {
  const UrkSelfLearningGovernancePolicy({
    required this.requiredSignalValidationCoveragePct,
    required this.requiredApprovalPathCoveragePct,
    required this.maxUnboundedSelfLearningUpdates,
    required this.maxUnverifiedTrainingLineageEvents,
  });

  final double requiredSignalValidationCoveragePct;
  final double requiredApprovalPathCoveragePct;
  final int maxUnboundedSelfLearningUpdates;
  final int maxUnverifiedTrainingLineageEvents;
}

class UrkSelfLearningGovernanceSnapshot {
  const UrkSelfLearningGovernanceSnapshot({
    required this.observedSignalValidationCoveragePct,
    required this.observedApprovalPathCoveragePct,
    required this.observedUnboundedSelfLearningUpdates,
    required this.observedUnverifiedTrainingLineageEvents,
  });

  final double observedSignalValidationCoveragePct;
  final double observedApprovalPathCoveragePct;
  final int observedUnboundedSelfLearningUpdates;
  final int observedUnverifiedTrainingLineageEvents;
}

class UrkSelfLearningGovernanceValidationResult {
  const UrkSelfLearningGovernanceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkSelfLearningGovernanceValidationResult.pass() {
    return const UrkSelfLearningGovernanceValidationResult._(
      isPassing: true,
      failures: <UrkSelfLearningGovernanceFailure>[],
    );
  }

  factory UrkSelfLearningGovernanceValidationResult.fail(
    List<UrkSelfLearningGovernanceFailure> failures,
  ) {
    return UrkSelfLearningGovernanceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkSelfLearningGovernanceFailure> failures;
}

class UrkSelfLearningGovernanceValidator {
  const UrkSelfLearningGovernanceValidator();

  UrkSelfLearningGovernanceValidationResult validate({
    required UrkSelfLearningGovernanceSnapshot snapshot,
    required UrkSelfLearningGovernancePolicy policy,
  }) {
    final failures = <UrkSelfLearningGovernanceFailure>[];

    if (policy.requiredSignalValidationCoveragePct < 0 ||
        policy.requiredApprovalPathCoveragePct < 0) {
      failures.add(UrkSelfLearningGovernanceFailure.invalidCoverageThreshold);
    }
    if (policy.maxUnboundedSelfLearningUpdates < 0 ||
        policy.maxUnverifiedTrainingLineageEvents < 0) {
      failures.add(UrkSelfLearningGovernanceFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedSignalValidationCoveragePct <
        policy.requiredSignalValidationCoveragePct) {
      failures.add(
        UrkSelfLearningGovernanceFailure.signalValidationCoverageBelowThreshold,
      );
    }
    if (snapshot.observedApprovalPathCoveragePct <
        policy.requiredApprovalPathCoveragePct) {
      failures.add(
          UrkSelfLearningGovernanceFailure.approvalPathCoverageBelowThreshold);
    }
    if (snapshot.observedUnboundedSelfLearningUpdates >
        policy.maxUnboundedSelfLearningUpdates) {
      failures.add(
          UrkSelfLearningGovernanceFailure.unboundedSelfLearningUpdateDetected);
    }
    if (snapshot.observedUnverifiedTrainingLineageEvents >
        policy.maxUnverifiedTrainingLineageEvents) {
      failures.add(
          UrkSelfLearningGovernanceFailure.unverifiedTrainingLineageDetected);
    }

    if (failures.isEmpty) {
      return UrkSelfLearningGovernanceValidationResult.pass();
    }
    return UrkSelfLearningGovernanceValidationResult.fail(failures);
  }
}

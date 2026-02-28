// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkLearningHealingBridgeFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  incidentToLearningLinkageCoverageBelowThreshold,
  lineageReferenceCoverageBelowThreshold,
  orphanIncidentLearningRecordDetected,
  missingRecoveryLinkbackDetected,
}

class UrkLearningHealingBridgePolicy {
  const UrkLearningHealingBridgePolicy({
    required this.requiredIncidentToLearningLinkageCoveragePct,
    required this.requiredLineageReferenceCoveragePct,
    required this.maxOrphanIncidentLearningRecords,
    required this.maxMissingRecoveryLinkbacks,
  });

  final double requiredIncidentToLearningLinkageCoveragePct;
  final double requiredLineageReferenceCoveragePct;
  final int maxOrphanIncidentLearningRecords;
  final int maxMissingRecoveryLinkbacks;
}

class UrkLearningHealingBridgeSnapshot {
  const UrkLearningHealingBridgeSnapshot({
    required this.observedIncidentToLearningLinkageCoveragePct,
    required this.observedLineageReferenceCoveragePct,
    required this.observedOrphanIncidentLearningRecords,
    required this.observedMissingRecoveryLinkbacks,
  });

  final double observedIncidentToLearningLinkageCoveragePct;
  final double observedLineageReferenceCoveragePct;
  final int observedOrphanIncidentLearningRecords;
  final int observedMissingRecoveryLinkbacks;
}

class UrkLearningHealingBridgeValidationResult {
  const UrkLearningHealingBridgeValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkLearningHealingBridgeValidationResult.pass() {
    return const UrkLearningHealingBridgeValidationResult._(
      isPassing: true,
      failures: <UrkLearningHealingBridgeFailure>[],
    );
  }

  factory UrkLearningHealingBridgeValidationResult.fail(
    List<UrkLearningHealingBridgeFailure> failures,
  ) {
    return UrkLearningHealingBridgeValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkLearningHealingBridgeFailure> failures;
}

class UrkLearningHealingBridgeValidator {
  const UrkLearningHealingBridgeValidator();

  UrkLearningHealingBridgeValidationResult validate({
    required UrkLearningHealingBridgeSnapshot snapshot,
    required UrkLearningHealingBridgePolicy policy,
  }) {
    final failures = <UrkLearningHealingBridgeFailure>[];

    if (policy.requiredIncidentToLearningLinkageCoveragePct < 0 ||
        policy.requiredLineageReferenceCoveragePct < 0) {
      failures.add(UrkLearningHealingBridgeFailure.invalidCoverageThreshold);
    }
    if (policy.maxOrphanIncidentLearningRecords < 0 ||
        policy.maxMissingRecoveryLinkbacks < 0) {
      failures.add(UrkLearningHealingBridgeFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedIncidentToLearningLinkageCoveragePct <
        policy.requiredIncidentToLearningLinkageCoveragePct) {
      failures.add(UrkLearningHealingBridgeFailure
          .incidentToLearningLinkageCoverageBelowThreshold);
    }
    if (snapshot.observedLineageReferenceCoveragePct <
        policy.requiredLineageReferenceCoveragePct) {
      failures.add(UrkLearningHealingBridgeFailure
          .lineageReferenceCoverageBelowThreshold);
    }
    if (snapshot.observedOrphanIncidentLearningRecords >
        policy.maxOrphanIncidentLearningRecords) {
      failures.add(
          UrkLearningHealingBridgeFailure.orphanIncidentLearningRecordDetected);
    }
    if (snapshot.observedMissingRecoveryLinkbacks >
        policy.maxMissingRecoveryLinkbacks) {
      failures
          .add(UrkLearningHealingBridgeFailure.missingRecoveryLinkbackDetected);
    }

    if (failures.isEmpty) {
      return UrkLearningHealingBridgeValidationResult.pass();
    }
    return UrkLearningHealingBridgeValidationResult.fail(failures);
  }
}

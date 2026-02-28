// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
enum UrkStageCPrivateMeshPolicyConformanceFailure {
  invalidPayloadThreshold,
  invalidEncryptionThreshold,
  invalidLineagePolicyThreshold,
  payloadSchemaCoverageBelowThreshold,
  directIdentifierLeakDetected,
  doubleEncryptionCoverageBelowThreshold,
  keyRotationCoverageBelowThreshold,
  lineageTagCoverageBelowThreshold,
  policyGateCoverageBelowThreshold,
  policyBypassDetected,
}

class UrkStageCPrivateMeshPolicyConformancePolicy {
  const UrkStageCPrivateMeshPolicyConformancePolicy({
    required this.requiredSchemaConformancePct,
    required this.maxDirectIdentifierLeaks,
    required this.requiredDoubleEncryptionCoveragePct,
    required this.requiredKeyRotationCoveragePct,
    required this.requiredLineageTagCoveragePct,
    required this.requiredPolicyGateCoveragePct,
    required this.maxPolicyBypassEvents,
  });

  final double requiredSchemaConformancePct;
  final int maxDirectIdentifierLeaks;
  final double requiredDoubleEncryptionCoveragePct;
  final double requiredKeyRotationCoveragePct;
  final double requiredLineageTagCoveragePct;
  final double requiredPolicyGateCoveragePct;
  final int maxPolicyBypassEvents;
}

class UrkStageCPrivateMeshPolicyConformanceSnapshot {
  const UrkStageCPrivateMeshPolicyConformanceSnapshot({
    required this.observedSchemaConformancePct,
    required this.observedDirectIdentifierLeaks,
    required this.observedDoubleEncryptionCoveragePct,
    required this.observedKeyRotationCoveragePct,
    required this.observedLineageTagCoveragePct,
    required this.observedPolicyGateCoveragePct,
    required this.observedPolicyBypassEvents,
  });

  final double observedSchemaConformancePct;
  final int observedDirectIdentifierLeaks;
  final double observedDoubleEncryptionCoveragePct;
  final double observedKeyRotationCoveragePct;
  final double observedLineageTagCoveragePct;
  final double observedPolicyGateCoveragePct;
  final int observedPolicyBypassEvents;
}

class UrkStageCPrivateMeshPolicyConformanceValidationResult {
  const UrkStageCPrivateMeshPolicyConformanceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkStageCPrivateMeshPolicyConformanceValidationResult.pass() {
    return const UrkStageCPrivateMeshPolicyConformanceValidationResult._(
      isPassing: true,
      failures: <UrkStageCPrivateMeshPolicyConformanceFailure>[],
    );
  }

  factory UrkStageCPrivateMeshPolicyConformanceValidationResult.fail(
    List<UrkStageCPrivateMeshPolicyConformanceFailure> failures,
  ) {
    return UrkStageCPrivateMeshPolicyConformanceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkStageCPrivateMeshPolicyConformanceFailure> failures;
}

class UrkStageCPrivateMeshPolicyConformanceValidator {
  const UrkStageCPrivateMeshPolicyConformanceValidator();

  UrkStageCPrivateMeshPolicyConformanceValidationResult validate({
    required UrkStageCPrivateMeshPolicyConformanceSnapshot snapshot,
    required UrkStageCPrivateMeshPolicyConformancePolicy policy,
  }) {
    final failures = <UrkStageCPrivateMeshPolicyConformanceFailure>[];

    if (policy.requiredSchemaConformancePct < 0 ||
        policy.maxDirectIdentifierLeaks < 0) {
      failures
          .add(UrkStageCPrivateMeshPolicyConformanceFailure.invalidPayloadThreshold);
    }
    if (policy.requiredDoubleEncryptionCoveragePct < 0 ||
        policy.requiredKeyRotationCoveragePct < 0) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure.invalidEncryptionThreshold,
      );
    }
    if (policy.requiredLineageTagCoveragePct < 0 ||
        policy.requiredPolicyGateCoveragePct < 0 ||
        policy.maxPolicyBypassEvents < 0) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure
            .invalidLineagePolicyThreshold,
      );
    }

    if (snapshot.observedSchemaConformancePct <
        policy.requiredSchemaConformancePct) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure
            .payloadSchemaCoverageBelowThreshold,
      );
    }
    if (snapshot.observedDirectIdentifierLeaks >
        policy.maxDirectIdentifierLeaks) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure.directIdentifierLeakDetected,
      );
    }
    if (snapshot.observedDoubleEncryptionCoveragePct <
        policy.requiredDoubleEncryptionCoveragePct) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure
            .doubleEncryptionCoverageBelowThreshold,
      );
    }
    if (snapshot.observedKeyRotationCoveragePct <
        policy.requiredKeyRotationCoveragePct) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure
            .keyRotationCoverageBelowThreshold,
      );
    }
    if (snapshot.observedLineageTagCoveragePct <
        policy.requiredLineageTagCoveragePct) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure
            .lineageTagCoverageBelowThreshold,
      );
    }
    if (snapshot.observedPolicyGateCoveragePct <
        policy.requiredPolicyGateCoveragePct) {
      failures.add(
        UrkStageCPrivateMeshPolicyConformanceFailure
            .policyGateCoverageBelowThreshold,
      );
    }
    if (snapshot.observedPolicyBypassEvents > policy.maxPolicyBypassEvents) {
      failures
          .add(UrkStageCPrivateMeshPolicyConformanceFailure.policyBypassDetected);
    }

    if (failures.isEmpty) {
      return UrkStageCPrivateMeshPolicyConformanceValidationResult.pass();
    }
    return UrkStageCPrivateMeshPolicyConformanceValidationResult.fail(failures);
  }
}

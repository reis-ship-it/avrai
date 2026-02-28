enum UrkStageECrossRuntimeConformanceFailure {
  invalidRuntimeCountThreshold,
  invalidCoverageThreshold,
  runtimeCountBelowThreshold,
  contractCoverageBelowThreshold,
  replayDeterminismBelowThreshold,
  policyDivergenceDetected,
}

class UrkStageECrossRuntimeConformancePolicy {
  const UrkStageECrossRuntimeConformancePolicy({
    required this.requiredRuntimeCount,
    required this.requiredContractCoveragePct,
    required this.requiredReplayDeterminismPct,
    required this.maxPolicyDivergenceEvents,
  });

  final int requiredRuntimeCount;
  final double requiredContractCoveragePct;
  final double requiredReplayDeterminismPct;
  final int maxPolicyDivergenceEvents;
}

class UrkStageECrossRuntimeConformanceSnapshot {
  const UrkStageECrossRuntimeConformanceSnapshot({
    required this.observedRuntimeCount,
    required this.observedContractCoveragePct,
    required this.observedReplayDeterminismPct,
    required this.observedPolicyDivergenceEvents,
  });

  final int observedRuntimeCount;
  final double observedContractCoveragePct;
  final double observedReplayDeterminismPct;
  final int observedPolicyDivergenceEvents;
}

class UrkStageECrossRuntimeConformanceValidationResult {
  const UrkStageECrossRuntimeConformanceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkStageECrossRuntimeConformanceValidationResult.pass() {
    return const UrkStageECrossRuntimeConformanceValidationResult._(
      isPassing: true,
      failures: <UrkStageECrossRuntimeConformanceFailure>[],
    );
  }

  factory UrkStageECrossRuntimeConformanceValidationResult.fail(
    List<UrkStageECrossRuntimeConformanceFailure> failures,
  ) {
    return UrkStageECrossRuntimeConformanceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkStageECrossRuntimeConformanceFailure> failures;
}

class UrkStageECrossRuntimeConformanceValidator {
  const UrkStageECrossRuntimeConformanceValidator();

  UrkStageECrossRuntimeConformanceValidationResult validate({
    required UrkStageECrossRuntimeConformanceSnapshot snapshot,
    required UrkStageECrossRuntimeConformancePolicy policy,
  }) {
    final failures = <UrkStageECrossRuntimeConformanceFailure>[];

    if (policy.requiredRuntimeCount <= 0 || policy.maxPolicyDivergenceEvents < 0) {
      failures
          .add(UrkStageECrossRuntimeConformanceFailure.invalidRuntimeCountThreshold);
    }
    if (policy.requiredContractCoveragePct < 0 ||
        policy.requiredReplayDeterminismPct < 0) {
      failures.add(UrkStageECrossRuntimeConformanceFailure.invalidCoverageThreshold);
    }

    if (snapshot.observedRuntimeCount < policy.requiredRuntimeCount) {
      failures.add(UrkStageECrossRuntimeConformanceFailure.runtimeCountBelowThreshold);
    }
    if (snapshot.observedContractCoveragePct < policy.requiredContractCoveragePct) {
      failures.add(
          UrkStageECrossRuntimeConformanceFailure.contractCoverageBelowThreshold);
    }
    if (snapshot.observedReplayDeterminismPct <
        policy.requiredReplayDeterminismPct) {
      failures.add(
          UrkStageECrossRuntimeConformanceFailure.replayDeterminismBelowThreshold);
    }
    if (snapshot.observedPolicyDivergenceEvents > policy.maxPolicyDivergenceEvents) {
      failures.add(UrkStageECrossRuntimeConformanceFailure.policyDivergenceDetected);
    }

    if (failures.isEmpty) {
      return UrkStageECrossRuntimeConformanceValidationResult.pass();
    }
    return UrkStageECrossRuntimeConformanceValidationResult.fail(failures);
  }
}

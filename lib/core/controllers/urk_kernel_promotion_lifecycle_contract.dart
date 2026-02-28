enum UrkKernelLifecycleState {
  draft,
  shadow,
  enforced,
  replicated,
}

enum UrkKernelPromotionLifecycleFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  lifecycleTransitionCoverageBelowThreshold,
  approvalChainCoverageBelowThreshold,
  unapprovedEnforcedPromotionDetected,
  stageSkipPromotionDetected,
}

class UrkKernelPromotionLifecyclePolicy {
  const UrkKernelPromotionLifecyclePolicy({
    required this.requiredLifecycleTransitionCoveragePct,
    required this.requiredApprovalChainCoveragePct,
    required this.maxUnapprovedEnforcedPromotions,
    required this.maxStageSkipPromotions,
  });

  final double requiredLifecycleTransitionCoveragePct;
  final double requiredApprovalChainCoveragePct;
  final int maxUnapprovedEnforcedPromotions;
  final int maxStageSkipPromotions;
}

class UrkKernelPromotionLifecycleSnapshot {
  const UrkKernelPromotionLifecycleSnapshot({
    required this.observedLifecycleTransitionCoveragePct,
    required this.observedApprovalChainCoveragePct,
    required this.observedUnapprovedEnforcedPromotions,
    required this.observedStageSkipPromotions,
  });

  final double observedLifecycleTransitionCoveragePct;
  final double observedApprovalChainCoveragePct;
  final int observedUnapprovedEnforcedPromotions;
  final int observedStageSkipPromotions;
}

class UrkKernelPromotionLifecycleValidationResult {
  const UrkKernelPromotionLifecycleValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkKernelPromotionLifecycleValidationResult.pass() {
    return const UrkKernelPromotionLifecycleValidationResult._(
      isPassing: true,
      failures: <UrkKernelPromotionLifecycleFailure>[],
    );
  }

  factory UrkKernelPromotionLifecycleValidationResult.fail(
    List<UrkKernelPromotionLifecycleFailure> failures,
  ) {
    return UrkKernelPromotionLifecycleValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkKernelPromotionLifecycleFailure> failures;
}

class UrkKernelPromotionLifecycleValidator {
  const UrkKernelPromotionLifecycleValidator();

  UrkKernelPromotionLifecycleValidationResult validate({
    required UrkKernelPromotionLifecycleSnapshot snapshot,
    required UrkKernelPromotionLifecyclePolicy policy,
  }) {
    final failures = <UrkKernelPromotionLifecycleFailure>[];

    if (policy.requiredLifecycleTransitionCoveragePct < 0 ||
        policy.requiredApprovalChainCoveragePct < 0) {
      failures.add(UrkKernelPromotionLifecycleFailure.invalidCoverageThreshold);
    }
    if (policy.maxUnapprovedEnforcedPromotions < 0 ||
        policy.maxStageSkipPromotions < 0) {
      failures.add(UrkKernelPromotionLifecycleFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedLifecycleTransitionCoveragePct <
        policy.requiredLifecycleTransitionCoveragePct) {
      failures.add(
        UrkKernelPromotionLifecycleFailure
            .lifecycleTransitionCoverageBelowThreshold,
      );
    }
    if (snapshot.observedApprovalChainCoveragePct <
        policy.requiredApprovalChainCoveragePct) {
      failures.add(
        UrkKernelPromotionLifecycleFailure.approvalChainCoverageBelowThreshold,
      );
    }
    if (snapshot.observedUnapprovedEnforcedPromotions >
        policy.maxUnapprovedEnforcedPromotions) {
      failures.add(
        UrkKernelPromotionLifecycleFailure.unapprovedEnforcedPromotionDetected,
      );
    }
    if (snapshot.observedStageSkipPromotions > policy.maxStageSkipPromotions) {
      failures
          .add(UrkKernelPromotionLifecycleFailure.stageSkipPromotionDetected);
    }

    if (failures.isEmpty) {
      return UrkKernelPromotionLifecycleValidationResult.pass();
    }
    return UrkKernelPromotionLifecycleValidationResult.fail(failures);
  }
}

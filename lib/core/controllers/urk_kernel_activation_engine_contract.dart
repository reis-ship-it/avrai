enum UrkKernelActivationEngineFailure {
  invalidCoverageThreshold,
  invalidSafetyThreshold,
  triggerRoutingCoverageBelowThreshold,
  policyGateCoverageBelowThreshold,
  receiptCoverageBelowThreshold,
  unauthorizedActivationDetected,
  dependencyBypassDetected,
}

enum UrkPrivacyMode {
  localSovereign,
  privateMesh,
  federatedCloud,
  multiMode,
}

class UrkKernelActivationEnginePolicy {
  const UrkKernelActivationEnginePolicy({
    required this.requiredTriggerRoutingCoveragePct,
    required this.requiredPolicyGateCoveragePct,
    required this.requiredReceiptCoveragePct,
    required this.maxUnauthorizedActivations,
    required this.maxDependencyBypasses,
  });

  final double requiredTriggerRoutingCoveragePct;
  final double requiredPolicyGateCoveragePct;
  final double requiredReceiptCoveragePct;
  final int maxUnauthorizedActivations;
  final int maxDependencyBypasses;
}

class UrkKernelActivationEngineSnapshot {
  const UrkKernelActivationEngineSnapshot({
    required this.observedTriggerRoutingCoveragePct,
    required this.observedPolicyGateCoveragePct,
    required this.observedReceiptCoveragePct,
    required this.observedUnauthorizedActivations,
    required this.observedDependencyBypasses,
  });

  final double observedTriggerRoutingCoveragePct;
  final double observedPolicyGateCoveragePct;
  final double observedReceiptCoveragePct;
  final int observedUnauthorizedActivations;
  final int observedDependencyBypasses;
}

class UrkKernelActivationEngineValidationResult {
  const UrkKernelActivationEngineValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory UrkKernelActivationEngineValidationResult.pass() {
    return const UrkKernelActivationEngineValidationResult._(
      isPassing: true,
      failures: <UrkKernelActivationEngineFailure>[],
    );
  }

  factory UrkKernelActivationEngineValidationResult.fail(
    List<UrkKernelActivationEngineFailure> failures,
  ) {
    return UrkKernelActivationEngineValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<UrkKernelActivationEngineFailure> failures;
}

class UrkKernelActivationEngineValidator {
  const UrkKernelActivationEngineValidator();

  UrkKernelActivationEngineValidationResult validate({
    required UrkKernelActivationEngineSnapshot snapshot,
    required UrkKernelActivationEnginePolicy policy,
  }) {
    final failures = <UrkKernelActivationEngineFailure>[];

    if (policy.requiredTriggerRoutingCoveragePct < 0 ||
        policy.requiredPolicyGateCoveragePct < 0 ||
        policy.requiredReceiptCoveragePct < 0) {
      failures.add(UrkKernelActivationEngineFailure.invalidCoverageThreshold);
    }
    if (policy.maxUnauthorizedActivations < 0 ||
        policy.maxDependencyBypasses < 0) {
      failures.add(UrkKernelActivationEngineFailure.invalidSafetyThreshold);
    }

    if (snapshot.observedTriggerRoutingCoveragePct <
        policy.requiredTriggerRoutingCoveragePct) {
      failures.add(
        UrkKernelActivationEngineFailure.triggerRoutingCoverageBelowThreshold,
      );
    }
    if (snapshot.observedPolicyGateCoveragePct <
        policy.requiredPolicyGateCoveragePct) {
      failures.add(
        UrkKernelActivationEngineFailure.policyGateCoverageBelowThreshold,
      );
    }
    if (snapshot.observedReceiptCoveragePct <
        policy.requiredReceiptCoveragePct) {
      failures.add(
        UrkKernelActivationEngineFailure.receiptCoverageBelowThreshold,
      );
    }
    if (snapshot.observedUnauthorizedActivations >
        policy.maxUnauthorizedActivations) {
      failures.add(
        UrkKernelActivationEngineFailure.unauthorizedActivationDetected,
      );
    }
    if (snapshot.observedDependencyBypasses > policy.maxDependencyBypasses) {
      failures.add(UrkKernelActivationEngineFailure.dependencyBypassDetected);
    }

    if (failures.isEmpty) {
      return UrkKernelActivationEngineValidationResult.pass();
    }
    return UrkKernelActivationEngineValidationResult.fail(failures);
  }
}

class UrkKernelActivationRule {
  const UrkKernelActivationRule({
    required this.kernelId,
    required this.activationTriggers,
    required this.privacyModes,
    this.dependencies = const <String>[],
  });

  final String kernelId;
  final List<String> activationTriggers;
  final List<UrkPrivacyMode> privacyModes;
  final List<String> dependencies;
}

class UrkKernelActivationRequest {
  const UrkKernelActivationRequest({
    required this.requestId,
    required this.trigger,
    required this.privacyMode,
    this.activeKernels = const <String>{},
  });

  final String requestId;
  final String trigger;
  final UrkPrivacyMode privacyMode;
  final Set<String> activeKernels;
}

class UrkKernelActivationDecision {
  const UrkKernelActivationDecision({
    required this.kernelId,
    required this.activated,
    required this.reason,
  });

  final String kernelId;
  final bool activated;
  final String reason;
}

class UrkKernelActivationReceipt {
  const UrkKernelActivationReceipt({
    required this.requestId,
    required this.trigger,
    required this.privacyMode,
    required this.decisions,
  });

  final String requestId;
  final String trigger;
  final UrkPrivacyMode privacyMode;
  final List<UrkKernelActivationDecision> decisions;
}

class UrkKernelActivationEngine {
  const UrkKernelActivationEngine();

  UrkKernelActivationReceipt evaluate({
    required UrkKernelActivationRequest request,
    required List<UrkKernelActivationRule> rules,
  }) {
    final decisions = <UrkKernelActivationDecision>[];

    for (final rule in rules) {
      if (!rule.activationTriggers.contains(request.trigger)) {
        continue;
      }
      if (!rule.privacyModes.contains(request.privacyMode)) {
        decisions.add(
          UrkKernelActivationDecision(
            kernelId: rule.kernelId,
            activated: false,
            reason: 'privacy_mode_not_allowed',
          ),
        );
        continue;
      }

      final hasMissingDependency =
          rule.dependencies.any((dep) => !request.activeKernels.contains(dep));
      if (hasMissingDependency) {
        decisions.add(
          UrkKernelActivationDecision(
            kernelId: rule.kernelId,
            activated: false,
            reason: 'missing_dependency',
          ),
        );
        continue;
      }

      decisions.add(
        UrkKernelActivationDecision(
          kernelId: rule.kernelId,
          activated: true,
          reason: 'activated',
        ),
      );
    }

    decisions.sort((a, b) => a.kernelId.compareTo(b.kernelId));
    return UrkKernelActivationReceipt(
      requestId: request.requestId,
      trigger: request.trigger,
      privacyMode: request.privacyMode,
      decisions: List.unmodifiable(decisions),
    );
  }
}

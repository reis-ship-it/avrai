enum SecurityCryptographicAssuranceFailure {
  invalidPostQuantumThreshold,
  invalidAttestationThreshold,
  invalidKillSwitchThreshold,
  postQuantumCoverageBelowThreshold,
  attestationCoverageBelowThreshold,
  unsignedUpdateDetected,
  killSwitchDrillPassRateBelowThreshold,
  killSwitchActivationLatencyExceeded,
}

class SecurityCryptographicAssurancePolicy {
  const SecurityCryptographicAssurancePolicy({
    required this.requiredPostQuantumCoveragePct,
    required this.requiredAttestationCoveragePct,
    required this.requiredKillSwitchDrillPassRatePct,
    required this.maxKillSwitchActivationLatencyMs,
  });

  final double requiredPostQuantumCoveragePct;
  final double requiredAttestationCoveragePct;
  final double requiredKillSwitchDrillPassRatePct;
  final double maxKillSwitchActivationLatencyMs;
}

class SecurityCryptographicAssuranceSnapshot {
  const SecurityCryptographicAssuranceSnapshot({
    required this.observedPostQuantumCoveragePct,
    required this.observedAttestationCoveragePct,
    required this.unsignedUpdatesDetected,
    required this.observedKillSwitchDrillPassRatePct,
    required this.observedKillSwitchActivationLatencyMs,
  });

  final double observedPostQuantumCoveragePct;
  final double observedAttestationCoveragePct;
  final int unsignedUpdatesDetected;
  final double observedKillSwitchDrillPassRatePct;
  final double observedKillSwitchActivationLatencyMs;
}

class SecurityCryptographicAssuranceValidationResult {
  const SecurityCryptographicAssuranceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory SecurityCryptographicAssuranceValidationResult.pass() {
    return const SecurityCryptographicAssuranceValidationResult._(
      isPassing: true,
      failures: <SecurityCryptographicAssuranceFailure>[],
    );
  }

  factory SecurityCryptographicAssuranceValidationResult.fail(
    List<SecurityCryptographicAssuranceFailure> failures,
  ) {
    return SecurityCryptographicAssuranceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<SecurityCryptographicAssuranceFailure> failures;
}

class SecurityCryptographicAssuranceValidator {
  const SecurityCryptographicAssuranceValidator();

  SecurityCryptographicAssuranceValidationResult validate({
    required SecurityCryptographicAssuranceSnapshot snapshot,
    required SecurityCryptographicAssurancePolicy policy,
  }) {
    final failures = <SecurityCryptographicAssuranceFailure>[];

    if (policy.requiredPostQuantumCoveragePct < 0) {
      failures.add(
        SecurityCryptographicAssuranceFailure.invalidPostQuantumThreshold,
      );
    }
    if (policy.requiredAttestationCoveragePct < 0) {
      failures.add(
        SecurityCryptographicAssuranceFailure.invalidAttestationThreshold,
      );
    }
    if (policy.requiredKillSwitchDrillPassRatePct < 0 ||
        policy.maxKillSwitchActivationLatencyMs < 0) {
      failures.add(
        SecurityCryptographicAssuranceFailure.invalidKillSwitchThreshold,
      );
    }

    if (snapshot.observedPostQuantumCoveragePct <
        policy.requiredPostQuantumCoveragePct) {
      failures.add(
        SecurityCryptographicAssuranceFailure.postQuantumCoverageBelowThreshold,
      );
    }
    if (snapshot.observedAttestationCoveragePct <
        policy.requiredAttestationCoveragePct) {
      failures.add(
        SecurityCryptographicAssuranceFailure.attestationCoverageBelowThreshold,
      );
    }
    if (snapshot.unsignedUpdatesDetected > 0) {
      failures
          .add(SecurityCryptographicAssuranceFailure.unsignedUpdateDetected);
    }
    if (snapshot.observedKillSwitchDrillPassRatePct <
        policy.requiredKillSwitchDrillPassRatePct) {
      failures.add(
        SecurityCryptographicAssuranceFailure
            .killSwitchDrillPassRateBelowThreshold,
      );
    }
    if (snapshot.observedKillSwitchActivationLatencyMs >
        policy.maxKillSwitchActivationLatencyMs) {
      failures.add(
        SecurityCryptographicAssuranceFailure
            .killSwitchActivationLatencyExceeded,
      );
    }

    if (failures.isEmpty) {
      return SecurityCryptographicAssuranceValidationResult.pass();
    }
    return SecurityCryptographicAssuranceValidationResult.fail(failures);
  }
}

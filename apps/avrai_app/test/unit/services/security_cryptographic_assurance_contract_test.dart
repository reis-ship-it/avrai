import 'package:avrai_runtime_os/services/security/security_cryptographic_assurance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityCryptographicAssuranceValidator', () {
    const validator = SecurityCryptographicAssuranceValidator();

    test('passes when PQ, attestation, and kill-switch checks are healthy', () {
      const snapshot = SecurityCryptographicAssuranceSnapshot(
        observedPostQuantumCoveragePct: 100.0,
        observedAttestationCoveragePct: 100.0,
        unsignedUpdatesDetected: 0,
        observedKillSwitchDrillPassRatePct: 100.0,
        observedKillSwitchActivationLatencyMs: 180.0,
      );

      const policy = SecurityCryptographicAssurancePolicy(
        requiredPostQuantumCoveragePct: 100.0,
        requiredAttestationCoveragePct: 100.0,
        requiredKillSwitchDrillPassRatePct: 100.0,
        maxKillSwitchActivationLatencyMs: 300.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when post-quantum and attestation coverage drop', () {
      const snapshot = SecurityCryptographicAssuranceSnapshot(
        observedPostQuantumCoveragePct: 97.0,
        observedAttestationCoveragePct: 96.0,
        unsignedUpdatesDetected: 0,
        observedKillSwitchDrillPassRatePct: 100.0,
        observedKillSwitchActivationLatencyMs: 180.0,
      );

      const policy = SecurityCryptographicAssurancePolicy(
        requiredPostQuantumCoveragePct: 100.0,
        requiredAttestationCoveragePct: 100.0,
        requiredKillSwitchDrillPassRatePct: 100.0,
        maxKillSwitchActivationLatencyMs: 300.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          SecurityCryptographicAssuranceFailure
              .postQuantumCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          SecurityCryptographicAssuranceFailure
              .attestationCoverageBelowThreshold,
        ),
      );
    });

    test('fails when unsigned updates are detected', () {
      const snapshot = SecurityCryptographicAssuranceSnapshot(
        observedPostQuantumCoveragePct: 100.0,
        observedAttestationCoveragePct: 100.0,
        unsignedUpdatesDetected: 2,
        observedKillSwitchDrillPassRatePct: 100.0,
        observedKillSwitchActivationLatencyMs: 180.0,
      );

      const policy = SecurityCryptographicAssurancePolicy(
        requiredPostQuantumCoveragePct: 100.0,
        requiredAttestationCoveragePct: 100.0,
        requiredKillSwitchDrillPassRatePct: 100.0,
        maxKillSwitchActivationLatencyMs: 300.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(SecurityCryptographicAssuranceFailure.unsignedUpdateDetected),
      );
    });

    test('fails when kill-switch drills regress', () {
      const snapshot = SecurityCryptographicAssuranceSnapshot(
        observedPostQuantumCoveragePct: 100.0,
        observedAttestationCoveragePct: 100.0,
        unsignedUpdatesDetected: 0,
        observedKillSwitchDrillPassRatePct: 92.0,
        observedKillSwitchActivationLatencyMs: 500.0,
      );

      const policy = SecurityCryptographicAssurancePolicy(
        requiredPostQuantumCoveragePct: 100.0,
        requiredAttestationCoveragePct: 100.0,
        requiredKillSwitchDrillPassRatePct: 100.0,
        maxKillSwitchActivationLatencyMs: 300.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          SecurityCryptographicAssuranceFailure
              .killSwitchDrillPassRateBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          SecurityCryptographicAssuranceFailure
              .killSwitchActivationLatencyExceeded,
        ),
      );
    });
  });
}

import 'package:avrai_runtime_os/kernel/contracts/urk_quantum_atomic_time_validity_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkQuantumAtomicTimeValidityValidator', () {
    const validator = UrkQuantumAtomicTimeValidityValidator();

    test('passes when quantum atomic time validity checks are healthy', () {
      const snapshot = UrkQuantumAtomicTimeValiditySnapshot(
        observedTimestampCoveragePct: 100.0,
        observedHighImpactValidityCoveragePct: 100.0,
        observedReconciliationValidityCoveragePct: 100.0,
        observedMaxUncertaintyWindowMs: 10,
        observedClockRegressionEvents: 0,
      );
      const policy = UrkQuantumAtomicTimeValidityPolicy(
        requiredTimestampCoveragePct: 100.0,
        requiredHighImpactValidityCoveragePct: 100.0,
        requiredReconciliationValidityCoveragePct: 100.0,
        maxUncertaintyWindowMs: 15,
        maxClockRegressionEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when timing coverage regresses', () {
      const snapshot = UrkQuantumAtomicTimeValiditySnapshot(
        observedTimestampCoveragePct: 90.0,
        observedHighImpactValidityCoveragePct: 92.0,
        observedReconciliationValidityCoveragePct: 95.0,
        observedMaxUncertaintyWindowMs: 10,
        observedClockRegressionEvents: 0,
      );
      const policy = UrkQuantumAtomicTimeValidityPolicy(
        requiredTimestampCoveragePct: 100.0,
        requiredHighImpactValidityCoveragePct: 100.0,
        requiredReconciliationValidityCoveragePct: 100.0,
        maxUncertaintyWindowMs: 15,
        maxClockRegressionEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkQuantumAtomicTimeValidityFailure.timestampCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(UrkQuantumAtomicTimeValidityFailure
            .highImpactValidityCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(UrkQuantumAtomicTimeValidityFailure
            .reconciliationValidityCoverageBelowThreshold),
      );
    });

    test('fails when uncertainty or clock regression exceeds policy', () {
      const snapshot = UrkQuantumAtomicTimeValiditySnapshot(
        observedTimestampCoveragePct: 100.0,
        observedHighImpactValidityCoveragePct: 100.0,
        observedReconciliationValidityCoveragePct: 100.0,
        observedMaxUncertaintyWindowMs: 25,
        observedClockRegressionEvents: 1,
      );
      const policy = UrkQuantumAtomicTimeValidityPolicy(
        requiredTimestampCoveragePct: 100.0,
        requiredHighImpactValidityCoveragePct: 100.0,
        requiredReconciliationValidityCoveragePct: 100.0,
        maxUncertaintyWindowMs: 15,
        maxClockRegressionEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkQuantumAtomicTimeValidityFailure.uncertaintyWindowExceeded,
        ),
      );
      expect(
        result.failures,
        contains(UrkQuantumAtomicTimeValidityFailure.clockRegressionDetected),
      );
    });
  });
}

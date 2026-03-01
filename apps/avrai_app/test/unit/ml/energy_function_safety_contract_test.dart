import 'package:avrai_runtime_os/ml/energy_function_safety_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnergyFunctionSafetyValidator', () {
    const validator = EnergyFunctionSafetyValidator();

    test(
        'passes when safety regression and weight policy are within guardrails',
        () {
      const snapshot = EnergyFunctionSafetySnapshot(
        observedPolicyViolationRatePct: 0.03,
        safetyBoundsPassed: true,
        observedRegressionDeltaPct: 0.2,
        positiveOutcomeWeight: 1.0,
        negativeOutcomeWeight: 2.0,
        modelFailureWeight: 3.0,
        failClosedEnabled: true,
        rollbackReadinessPassed: true,
      );

      const policy = EnergyFunctionSafetyPolicy(
        maxPolicyViolationRatePct: 0.25,
        maxRegressionDeltaPct: 0.8,
        minNegativeOutcomeWeight: 2.0,
        minModelFailureWeight: 3.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when policy violation rate exceeds threshold', () {
      const snapshot = EnergyFunctionSafetySnapshot(
        observedPolicyViolationRatePct: 0.5,
        safetyBoundsPassed: true,
        observedRegressionDeltaPct: 0.2,
        positiveOutcomeWeight: 1.0,
        negativeOutcomeWeight: 2.0,
        modelFailureWeight: 3.0,
        failClosedEnabled: true,
        rollbackReadinessPassed: true,
      );

      const policy = EnergyFunctionSafetyPolicy(
        maxPolicyViolationRatePct: 0.25,
        maxRegressionDeltaPct: 0.8,
        minNegativeOutcomeWeight: 2.0,
        minModelFailureWeight: 3.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(EnergyFunctionSafetyFailure.safetyViolationRateExceeded),
      );
    });

    test('fails when regression delta exceeds threshold', () {
      const snapshot = EnergyFunctionSafetySnapshot(
        observedPolicyViolationRatePct: 0.03,
        safetyBoundsPassed: true,
        observedRegressionDeltaPct: 1.1,
        positiveOutcomeWeight: 1.0,
        negativeOutcomeWeight: 2.0,
        modelFailureWeight: 3.0,
        failClosedEnabled: true,
        rollbackReadinessPassed: true,
      );

      const policy = EnergyFunctionSafetyPolicy(
        maxPolicyViolationRatePct: 0.25,
        maxRegressionDeltaPct: 0.8,
        minNegativeOutcomeWeight: 2.0,
        minModelFailureWeight: 3.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(EnergyFunctionSafetyFailure.regressionDeltaExceeded),
      );
    });

    test('fails when asymmetric loss weights do not satisfy policy', () {
      const snapshot = EnergyFunctionSafetySnapshot(
        observedPolicyViolationRatePct: 0.03,
        safetyBoundsPassed: true,
        observedRegressionDeltaPct: 0.2,
        positiveOutcomeWeight: 1.0,
        negativeOutcomeWeight: 1.4,
        modelFailureWeight: 2.4,
        failClosedEnabled: true,
        rollbackReadinessPassed: true,
      );

      const policy = EnergyFunctionSafetyPolicy(
        maxPolicyViolationRatePct: 0.25,
        maxRegressionDeltaPct: 0.8,
        minNegativeOutcomeWeight: 2.0,
        minModelFailureWeight: 3.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(EnergyFunctionSafetyFailure.invalidWeightPolicy),
      );
    });

    test('fails when fail-closed or rollback readiness checks fail', () {
      const snapshot = EnergyFunctionSafetySnapshot(
        observedPolicyViolationRatePct: 0.03,
        safetyBoundsPassed: true,
        observedRegressionDeltaPct: 0.2,
        positiveOutcomeWeight: 1.0,
        negativeOutcomeWeight: 2.0,
        modelFailureWeight: 3.0,
        failClosedEnabled: false,
        rollbackReadinessPassed: false,
      );

      const policy = EnergyFunctionSafetyPolicy(
        maxPolicyViolationRatePct: 0.25,
        maxRegressionDeltaPct: 0.8,
        minNegativeOutcomeWeight: 2.0,
        minModelFailureWeight: 3.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(EnergyFunctionSafetyFailure.failClosedDisabled),
      );
      expect(
        result.failures,
        contains(EnergyFunctionSafetyFailure.rollbackReadinessFailed),
      );
    });
  });
}

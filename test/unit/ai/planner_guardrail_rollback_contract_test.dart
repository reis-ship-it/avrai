import 'package:avrai/core/ai/planner_guardrail_rollback_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlannerGuardrailRollbackValidator', () {
    const validator = PlannerGuardrailRollbackValidator();

    test('passes when guardrail and rollback checks are healthy', () {
      const snapshot = PlannerGuardrailRollbackSnapshot(
        observedHardConstraintViolationRatePct: 0.01,
        hardConstraintEnvelopePassed: true,
        observedRollbackSuccessRatePct: 100.0,
        observedP95RecoveryLatencySeconds: 40,
        softRollbackIntegrityPassed: true,
        hardRollbackIntegrityPassed: true,
        provenanceCompletenessPassed: true,
      );

      const policy = PlannerGuardrailRollbackPolicy(
        maxHardConstraintViolationRatePct: 0.2,
        requiredRollbackSuccessRatePct: 100.0,
        maxRecoveryLatencySeconds: 120,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when hard-constraint violation rate exceeds threshold', () {
      const snapshot = PlannerGuardrailRollbackSnapshot(
        observedHardConstraintViolationRatePct: 0.8,
        hardConstraintEnvelopePassed: true,
        observedRollbackSuccessRatePct: 100.0,
        observedP95RecoveryLatencySeconds: 40,
        softRollbackIntegrityPassed: true,
        hardRollbackIntegrityPassed: true,
        provenanceCompletenessPassed: true,
      );

      const policy = PlannerGuardrailRollbackPolicy(
        maxHardConstraintViolationRatePct: 0.2,
        requiredRollbackSuccessRatePct: 100.0,
        maxRecoveryLatencySeconds: 120,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          PlannerGuardrailRollbackFailure.hardConstraintViolationRateExceeded,
        ),
      );
    });

    test('fails when rollback success/latency checks fail', () {
      const snapshot = PlannerGuardrailRollbackSnapshot(
        observedHardConstraintViolationRatePct: 0.01,
        hardConstraintEnvelopePassed: true,
        observedRollbackSuccessRatePct: 92.0,
        observedP95RecoveryLatencySeconds: 180,
        softRollbackIntegrityPassed: true,
        hardRollbackIntegrityPassed: true,
        provenanceCompletenessPassed: true,
      );

      const policy = PlannerGuardrailRollbackPolicy(
        maxHardConstraintViolationRatePct: 0.2,
        requiredRollbackSuccessRatePct: 100.0,
        maxRecoveryLatencySeconds: 120,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(PlannerGuardrailRollbackFailure.rollbackSuccessRateFailed),
      );
      expect(
        result.failures,
        contains(
          PlannerGuardrailRollbackFailure.rollbackRecoveryLatencyExceeded,
        ),
      );
    });

    test('fails when rollback bundle integrity checks fail', () {
      const snapshot = PlannerGuardrailRollbackSnapshot(
        observedHardConstraintViolationRatePct: 0.01,
        hardConstraintEnvelopePassed: true,
        observedRollbackSuccessRatePct: 100.0,
        observedP95RecoveryLatencySeconds: 40,
        softRollbackIntegrityPassed: false,
        hardRollbackIntegrityPassed: false,
        provenanceCompletenessPassed: false,
      );

      const policy = PlannerGuardrailRollbackPolicy(
        maxHardConstraintViolationRatePct: 0.2,
        requiredRollbackSuccessRatePct: 100.0,
        maxRecoveryLatencySeconds: 120,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(PlannerGuardrailRollbackFailure.softRollbackIntegrityFailed),
      );
      expect(
        result.failures,
        contains(PlannerGuardrailRollbackFailure.hardRollbackIntegrityFailed),
      );
      expect(
        result.failures,
        contains(
          PlannerGuardrailRollbackFailure.provenanceCompletenessFailed,
        ),
      );
    });
  });
}

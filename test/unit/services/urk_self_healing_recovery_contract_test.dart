import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_self_healing_recovery_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkSelfHealingRecoveryValidator', () {
    const validator = UrkSelfHealingRecoveryValidator();

    test('passes when self-healing recovery checks are healthy', () {
      const snapshot = UrkSelfHealingRecoverySnapshot(
        observedDetectContainRecoverCoveragePct: 100.0,
        observedRollbackPathCoveragePct: 100.0,
        observedUncontainedIncidentEvents: 0,
        observedFailedRecoveryEvents: 0,
      );
      const policy = UrkSelfHealingRecoveryPolicy(
        requiredDetectContainRecoverCoveragePct: 100.0,
        requiredRollbackPathCoveragePct: 100.0,
        maxUncontainedIncidentEvents: 0,
        maxFailedRecoveryEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when recovery pipeline coverage regresses', () {
      const snapshot = UrkSelfHealingRecoverySnapshot(
        observedDetectContainRecoverCoveragePct: 90.0,
        observedRollbackPathCoveragePct: 88.0,
        observedUncontainedIncidentEvents: 0,
        observedFailedRecoveryEvents: 0,
      );
      const policy = UrkSelfHealingRecoveryPolicy(
        requiredDetectContainRecoverCoveragePct: 100.0,
        requiredRollbackPathCoveragePct: 100.0,
        maxUncontainedIncidentEvents: 0,
        maxFailedRecoveryEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkSelfHealingRecoveryFailure
              .detectContainRecoverCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
            UrkSelfHealingRecoveryFailure.rollbackPathCoverageBelowThreshold),
      );
    });

    test('fails when incidents are uncontained or recovery fails', () {
      const snapshot = UrkSelfHealingRecoverySnapshot(
        observedDetectContainRecoverCoveragePct: 100.0,
        observedRollbackPathCoveragePct: 100.0,
        observedUncontainedIncidentEvents: 2,
        observedFailedRecoveryEvents: 1,
      );
      const policy = UrkSelfHealingRecoveryPolicy(
        requiredDetectContainRecoverCoveragePct: 100.0,
        requiredRollbackPathCoveragePct: 100.0,
        maxUncontainedIncidentEvents: 0,
        maxFailedRecoveryEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkSelfHealingRecoveryFailure.uncontainedIncidentDetected),
      );
      expect(
        result.failures,
        contains(UrkSelfHealingRecoveryFailure.failedRecoveryDetected),
      );
    });
  });
}

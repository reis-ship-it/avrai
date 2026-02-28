import 'package:avrai/core/ai/urk_learning_update_governance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkLearningUpdateGovernanceValidator', () {
    const validator = UrkLearningUpdateGovernanceValidator();

    test('passes when learning update governance is healthy', () {
      const snapshot = UrkLearningUpdateGovernanceSnapshot(
        observedUpdateValidationCoveragePct: 100.0,
        observedDataLineageCoveragePct: 100.0,
        observedUnreviewedHighImpactLearningUpdates: 0,
        observedFailedRollbackRecoveryEvents: 0,
      );
      const policy = UrkLearningUpdateGovernancePolicy(
        requiredUpdateValidationCoveragePct: 100.0,
        requiredDataLineageCoveragePct: 100.0,
        maxUnreviewedHighImpactLearningUpdates: 0,
        maxFailedRollbackRecoveryEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when learning validation or lineage coverage regresses', () {
      const snapshot = UrkLearningUpdateGovernanceSnapshot(
        observedUpdateValidationCoveragePct: 91.0,
        observedDataLineageCoveragePct: 95.0,
        observedUnreviewedHighImpactLearningUpdates: 0,
        observedFailedRollbackRecoveryEvents: 0,
      );
      const policy = UrkLearningUpdateGovernancePolicy(
        requiredUpdateValidationCoveragePct: 100.0,
        requiredDataLineageCoveragePct: 100.0,
        maxUnreviewedHighImpactLearningUpdates: 0,
        maxFailedRollbackRecoveryEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkLearningUpdateGovernanceFailure
              .updateValidationCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkLearningUpdateGovernanceFailure.dataLineageCoverageBelowThreshold,
        ),
      );
    });

    test('fails when unsafe learning updates appear', () {
      const snapshot = UrkLearningUpdateGovernanceSnapshot(
        observedUpdateValidationCoveragePct: 100.0,
        observedDataLineageCoveragePct: 100.0,
        observedUnreviewedHighImpactLearningUpdates: 2,
        observedFailedRollbackRecoveryEvents: 1,
      );
      const policy = UrkLearningUpdateGovernancePolicy(
        requiredUpdateValidationCoveragePct: 100.0,
        requiredDataLineageCoveragePct: 100.0,
        maxUnreviewedHighImpactLearningUpdates: 0,
        maxFailedRollbackRecoveryEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkLearningUpdateGovernanceFailure
              .unreviewedHighImpactLearningUpdateDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkLearningUpdateGovernanceFailure.failedRollbackRecoveryDetected,
        ),
      );
    });
  });
}

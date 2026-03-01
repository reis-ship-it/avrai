import 'package:avrai_runtime_os/kernel/contracts/urk_self_learning_governance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkSelfLearningGovernanceValidator', () {
    const validator = UrkSelfLearningGovernanceValidator();

    test('passes when self-learning governance checks are healthy', () {
      const snapshot = UrkSelfLearningGovernanceSnapshot(
        observedSignalValidationCoveragePct: 100.0,
        observedApprovalPathCoveragePct: 100.0,
        observedUnboundedSelfLearningUpdates: 0,
        observedUnverifiedTrainingLineageEvents: 0,
      );
      const policy = UrkSelfLearningGovernancePolicy(
        requiredSignalValidationCoveragePct: 100.0,
        requiredApprovalPathCoveragePct: 100.0,
        maxUnboundedSelfLearningUpdates: 0,
        maxUnverifiedTrainingLineageEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when validation/approval coverage regresses', () {
      const snapshot = UrkSelfLearningGovernanceSnapshot(
        observedSignalValidationCoveragePct: 92.0,
        observedApprovalPathCoveragePct: 90.0,
        observedUnboundedSelfLearningUpdates: 0,
        observedUnverifiedTrainingLineageEvents: 0,
      );
      const policy = UrkSelfLearningGovernancePolicy(
        requiredSignalValidationCoveragePct: 100.0,
        requiredApprovalPathCoveragePct: 100.0,
        maxUnboundedSelfLearningUpdates: 0,
        maxUnverifiedTrainingLineageEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkSelfLearningGovernanceFailure
              .signalValidationCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(UrkSelfLearningGovernanceFailure
            .approvalPathCoverageBelowThreshold),
      );
    });

    test('fails when unsafe self-learning updates appear', () {
      const snapshot = UrkSelfLearningGovernanceSnapshot(
        observedSignalValidationCoveragePct: 100.0,
        observedApprovalPathCoveragePct: 100.0,
        observedUnboundedSelfLearningUpdates: 1,
        observedUnverifiedTrainingLineageEvents: 2,
      );
      const policy = UrkSelfLearningGovernancePolicy(
        requiredSignalValidationCoveragePct: 100.0,
        requiredApprovalPathCoveragePct: 100.0,
        maxUnboundedSelfLearningUpdates: 0,
        maxUnverifiedTrainingLineageEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkSelfLearningGovernanceFailure
            .unboundedSelfLearningUpdateDetected),
      );
      expect(
        result.failures,
        contains(
            UrkSelfLearningGovernanceFailure.unverifiedTrainingLineageDetected),
      );
    });
  });
}

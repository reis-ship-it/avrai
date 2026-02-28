import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_learning_healing_bridge_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkLearningHealingBridgeValidator', () {
    const validator = UrkLearningHealingBridgeValidator();

    test('passes when learning-healing bridge checks are healthy', () {
      const snapshot = UrkLearningHealingBridgeSnapshot(
        observedIncidentToLearningLinkageCoveragePct: 100.0,
        observedLineageReferenceCoveragePct: 100.0,
        observedOrphanIncidentLearningRecords: 0,
        observedMissingRecoveryLinkbacks: 0,
      );
      const policy = UrkLearningHealingBridgePolicy(
        requiredIncidentToLearningLinkageCoveragePct: 100.0,
        requiredLineageReferenceCoveragePct: 100.0,
        maxOrphanIncidentLearningRecords: 0,
        maxMissingRecoveryLinkbacks: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when bridge coverage regresses', () {
      const snapshot = UrkLearningHealingBridgeSnapshot(
        observedIncidentToLearningLinkageCoveragePct: 94.0,
        observedLineageReferenceCoveragePct: 91.0,
        observedOrphanIncidentLearningRecords: 0,
        observedMissingRecoveryLinkbacks: 0,
      );
      const policy = UrkLearningHealingBridgePolicy(
        requiredIncidentToLearningLinkageCoveragePct: 100.0,
        requiredLineageReferenceCoveragePct: 100.0,
        maxOrphanIncidentLearningRecords: 0,
        maxMissingRecoveryLinkbacks: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkLearningHealingBridgeFailure
            .incidentToLearningLinkageCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(UrkLearningHealingBridgeFailure
            .lineageReferenceCoverageBelowThreshold),
      );
    });

    test('fails when orphan/missing-linkback records exist', () {
      const snapshot = UrkLearningHealingBridgeSnapshot(
        observedIncidentToLearningLinkageCoveragePct: 100.0,
        observedLineageReferenceCoveragePct: 100.0,
        observedOrphanIncidentLearningRecords: 3,
        observedMissingRecoveryLinkbacks: 2,
      );
      const policy = UrkLearningHealingBridgePolicy(
        requiredIncidentToLearningLinkageCoveragePct: 100.0,
        requiredLineageReferenceCoveragePct: 100.0,
        maxOrphanIncidentLearningRecords: 0,
        maxMissingRecoveryLinkbacks: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkLearningHealingBridgeFailure
            .orphanIncidentLearningRecordDetected),
      );
      expect(
        result.failures,
        contains(
            UrkLearningHealingBridgeFailure.missingRecoveryLinkbackDetected),
      );
    });
  });
}

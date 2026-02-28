import 'package:avrai/core/services/business/urk_stage_d_business_runtime_replication_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkStageDBusinessRuntimeReplicationValidator', () {
    const validator = UrkStageDBusinessRuntimeReplicationValidator();

    test('passes when business runtime replication controls are healthy', () {
      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails on pipeline/policy coverage regressions', () {
      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 88.0,
        observedPolicyGateCoveragePct: 93.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure.pipelineCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure.policyGateCoverageBelowThreshold,
        ),
      );
    });

    test('fails on lineage and high-impact review guard regressions', () {
      const snapshot = UrkStageDBusinessRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 92.0,
        observedUnattributedActions: 2,
        observedHighImpactReviewCoveragePct: 90.0,
        observedUnreviewedHighImpactCommits: 1,
      );
      const policy = UrkStageDBusinessRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure.lineageCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure.unattributedActionsDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .highImpactReviewCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDBusinessRuntimeReplicationFailure
              .unreviewedHighImpactCommitDetected,
        ),
      );
    });
  });
}

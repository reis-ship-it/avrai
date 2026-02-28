import 'package:avrai/core/services/expertise/urk_stage_d_expert_runtime_replication_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkStageDExpertRuntimeReplicationValidator', () {
    const validator = UrkStageDExpertRuntimeReplicationValidator();

    test('passes when expert runtime replication controls are healthy', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedProvenanceCoveragePct: 100.0,
        observedUnverifiedOutputs: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails on pipeline, policy, and lineage regressions', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 91.0,
        observedPolicyGateCoveragePct: 92.0,
        observedLineageCoveragePct: 93.0,
        observedUnattributedActions: 2,
        observedProvenanceCoveragePct: 100.0,
        observedUnverifiedOutputs: 0,
        observedHighImpactReviewCoveragePct: 100.0,
        observedUnreviewedHighImpactCommits: 0,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.pipelineCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.policyGateCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.lineageCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.unattributedActionsDetected,
        ),
      );
    });

    test('fails on provenance and high-impact review safety regressions', () {
      const snapshot = UrkStageDExpertRuntimeReplicationSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedPolicyGateCoveragePct: 100.0,
        observedLineageCoveragePct: 100.0,
        observedUnattributedActions: 0,
        observedProvenanceCoveragePct: 94.0,
        observedUnverifiedOutputs: 3,
        observedHighImpactReviewCoveragePct: 96.0,
        observedUnreviewedHighImpactCommits: 1,
      );
      const policy = UrkStageDExpertRuntimeReplicationPolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredPolicyGateCoveragePct: 100.0,
        requiredLineageCoveragePct: 100.0,
        maxUnattributedActions: 0,
        requiredProvenanceCoveragePct: 100.0,
        maxUnverifiedOutputs: 0,
        requiredHighImpactReviewCoveragePct: 100.0,
        maxUnreviewedHighImpactCommits: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.provenanceCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure.unverifiedOutputsDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .highImpactReviewCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageDExpertRuntimeReplicationFailure
              .unreviewedHighImpactCommitDetected,
        ),
      );
    });
  });
}

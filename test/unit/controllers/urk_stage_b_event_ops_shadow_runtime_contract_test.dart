import 'package:avrai/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkStageBEventOpsShadowRuntimeValidator', () {
    const validator = UrkStageBEventOpsShadowRuntimeValidator();

    test('passes when shadow runtime pipeline, lineage, and guard checks are healthy', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when ingest-plan-gate-observe pipeline coverage regresses', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 82.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure.pipelineCoverageBelowThreshold,
        ),
      );
    });

    test('fails when decision envelopes/lineage are incomplete', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 94.0,
        observedLineageCompletenessPct: 91.0,
        observedOrphanActionStates: 2,
        observedHighImpactAutocommits: 0,
        observedShadowBlockCoveragePct: 100.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure
              .decisionEnvelopeCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure.lineageCompletenessBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(UrkStageBEventOpsShadowRuntimeFailure.orphanActionStatesDetected),
      );
    });

    test('fails when high-impact autocommits occur in shadow mode', () {
      const snapshot = UrkStageBEventOpsShadowRuntimeSnapshot(
        observedPipelineCoveragePct: 100.0,
        observedDecisionEnvelopeCoveragePct: 100.0,
        observedLineageCompletenessPct: 100.0,
        observedOrphanActionStates: 0,
        observedHighImpactAutocommits: 1,
        observedShadowBlockCoveragePct: 89.0,
      );
      const policy = UrkStageBEventOpsShadowRuntimePolicy(
        requiredPipelineCoveragePct: 100.0,
        requiredDecisionEnvelopeCoveragePct: 100.0,
        requiredLineageCompletenessPct: 100.0,
        maxOrphanActionStates: 0,
        maxHighImpactAutocommits: 0,
        requiredShadowBlockCoveragePct: 100.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure.highImpactAutocommitDetected,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageBEventOpsShadowRuntimeFailure.shadowBlockCoverageBelowThreshold,
        ),
      );
    });
  });
}

import 'package:avrai_runtime_os/kernel/contracts/urk_break_glass_governance_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkBreakGlassGovernanceValidator', () {
    const validator = UrkBreakGlassGovernanceValidator();

    test('passes when break-glass governance is healthy', () {
      const snapshot = UrkBreakGlassGovernanceSnapshot(
        observedSignedDirectiveCoveragePct: 100.0,
        observedDualApprovalCoveragePct: 100.0,
        observedGovernanceChannelSeparationPct: 100.0,
        observedUnauthorizedBreakGlassActions: 0,
        observedLearningPathTunnelingEvents: 0,
      );
      const policy = UrkBreakGlassGovernancePolicy(
        requiredSignedDirectiveCoveragePct: 100.0,
        requiredDualApprovalCoveragePct: 100.0,
        requiredGovernanceChannelSeparationPct: 100.0,
        maxUnauthorizedBreakGlassActions: 0,
        maxLearningPathTunnelingEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when directive, approval, or separation coverage regresses',
        () {
      const snapshot = UrkBreakGlassGovernanceSnapshot(
        observedSignedDirectiveCoveragePct: 95.0,
        observedDualApprovalCoveragePct: 90.0,
        observedGovernanceChannelSeparationPct: 80.0,
        observedUnauthorizedBreakGlassActions: 0,
        observedLearningPathTunnelingEvents: 0,
      );
      const policy = UrkBreakGlassGovernancePolicy(
        requiredSignedDirectiveCoveragePct: 100.0,
        requiredDualApprovalCoveragePct: 100.0,
        requiredGovernanceChannelSeparationPct: 100.0,
        maxUnauthorizedBreakGlassActions: 0,
        maxLearningPathTunnelingEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkBreakGlassGovernanceFailure
            .signedDirectiveCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(
            UrkBreakGlassGovernanceFailure.dualApprovalCoverageBelowThreshold),
      );
      expect(
        result.failures,
        contains(UrkBreakGlassGovernanceFailure
            .governanceChannelSeparationBelowThreshold),
      );
    });

    test('fails when unauthorized or tunneled break-glass actions appear', () {
      const snapshot = UrkBreakGlassGovernanceSnapshot(
        observedSignedDirectiveCoveragePct: 100.0,
        observedDualApprovalCoveragePct: 100.0,
        observedGovernanceChannelSeparationPct: 100.0,
        observedUnauthorizedBreakGlassActions: 1,
        observedLearningPathTunnelingEvents: 1,
      );
      const policy = UrkBreakGlassGovernancePolicy(
        requiredSignedDirectiveCoveragePct: 100.0,
        requiredDualApprovalCoveragePct: 100.0,
        requiredGovernanceChannelSeparationPct: 100.0,
        maxUnauthorizedBreakGlassActions: 0,
        maxLearningPathTunnelingEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkBreakGlassGovernanceFailure
            .unauthorizedBreakGlassActionDetected),
      );
      expect(
        result.failures,
        contains(UrkBreakGlassGovernanceFailure.learningPathTunnelingDetected),
      );
    });
  });
}

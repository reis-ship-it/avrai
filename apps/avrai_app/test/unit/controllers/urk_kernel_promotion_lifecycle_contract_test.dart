import 'package:avrai_runtime_os/kernel/contracts/urk_kernel_promotion_lifecycle_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkKernelPromotionLifecycleValidator', () {
    const validator = UrkKernelPromotionLifecycleValidator();

    test('passes when lifecycle and promotion safety are healthy', () {
      const snapshot = UrkKernelPromotionLifecycleSnapshot(
        observedLifecycleTransitionCoveragePct: 100.0,
        observedApprovalChainCoveragePct: 100.0,
        observedUnapprovedEnforcedPromotions: 0,
        observedStageSkipPromotions: 0,
      );
      const policy = UrkKernelPromotionLifecyclePolicy(
        requiredLifecycleTransitionCoveragePct: 100.0,
        requiredApprovalChainCoveragePct: 100.0,
        maxUnapprovedEnforcedPromotions: 0,
        maxStageSkipPromotions: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails on lifecycle/approval coverage regressions', () {
      const snapshot = UrkKernelPromotionLifecycleSnapshot(
        observedLifecycleTransitionCoveragePct: 92.0,
        observedApprovalChainCoveragePct: 88.0,
        observedUnapprovedEnforcedPromotions: 0,
        observedStageSkipPromotions: 0,
      );
      const policy = UrkKernelPromotionLifecyclePolicy(
        requiredLifecycleTransitionCoveragePct: 100.0,
        requiredApprovalChainCoveragePct: 100.0,
        maxUnapprovedEnforcedPromotions: 0,
        maxStageSkipPromotions: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkKernelPromotionLifecycleFailure
              .lifecycleTransitionCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkKernelPromotionLifecycleFailure
              .approvalChainCoverageBelowThreshold,
        ),
      );
    });

    test('fails on unsafe promotions', () {
      const snapshot = UrkKernelPromotionLifecycleSnapshot(
        observedLifecycleTransitionCoveragePct: 100.0,
        observedApprovalChainCoveragePct: 100.0,
        observedUnapprovedEnforcedPromotions: 1,
        observedStageSkipPromotions: 2,
      );
      const policy = UrkKernelPromotionLifecyclePolicy(
        requiredLifecycleTransitionCoveragePct: 100.0,
        requiredApprovalChainCoveragePct: 100.0,
        maxUnapprovedEnforcedPromotions: 0,
        maxStageSkipPromotions: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkKernelPromotionLifecycleFailure
              .unapprovedEnforcedPromotionDetected,
        ),
      );
      expect(
        result.failures,
        contains(UrkKernelPromotionLifecycleFailure.stageSkipPromotionDetected),
      );
    });
  });
}

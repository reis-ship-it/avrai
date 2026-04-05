import 'package:avrai_runtime_os/kernel/contracts/urk_stage_a_trigger_privacy_no_egress_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkStageATriggerPrivacyNoEgressValidator', () {
    const validator = UrkStageATriggerPrivacyNoEgressValidator();

    test('passes when trigger, privacy, consent, and no-egress are healthy',
        () {
      const snapshot = UrkStageATriggerPrivacyNoEgressSnapshot(
        observedTriggerCoveragePct: 100.0,
        observedPrivacyModePolicyCoveragePct: 100.0,
        observedConsentGateCoveragePct: 100.0,
        observedLocalSovereignCoveragePct: 100.0,
        observedNoEgressViolations: 0,
      );
      const policy = UrkStageATriggerPrivacyNoEgressPolicy(
        requiredTriggerCoveragePct: 100.0,
        requiredPrivacyModePolicyCoveragePct: 100.0,
        requiredConsentGateCoveragePct: 100.0,
        requiredLocalSovereignCoveragePct: 100.0,
        maxNoEgressViolations: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when trigger coverage drops below threshold', () {
      const snapshot = UrkStageATriggerPrivacyNoEgressSnapshot(
        observedTriggerCoveragePct: 80.0,
        observedPrivacyModePolicyCoveragePct: 100.0,
        observedConsentGateCoveragePct: 100.0,
        observedLocalSovereignCoveragePct: 100.0,
        observedNoEgressViolations: 0,
      );
      const policy = UrkStageATriggerPrivacyNoEgressPolicy(
        requiredTriggerCoveragePct: 100.0,
        requiredPrivacyModePolicyCoveragePct: 100.0,
        requiredConsentGateCoveragePct: 100.0,
        requiredLocalSovereignCoveragePct: 100.0,
        maxNoEgressViolations: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageATriggerPrivacyNoEgressFailure.triggerCoverageBelowThreshold,
        ),
      );
    });

    test('fails when consent/privacypolicy gates regress', () {
      const snapshot = UrkStageATriggerPrivacyNoEgressSnapshot(
        observedTriggerCoveragePct: 100.0,
        observedPrivacyModePolicyCoveragePct: 95.0,
        observedConsentGateCoveragePct: 92.0,
        observedLocalSovereignCoveragePct: 100.0,
        observedNoEgressViolations: 0,
      );
      const policy = UrkStageATriggerPrivacyNoEgressPolicy(
        requiredTriggerCoveragePct: 100.0,
        requiredPrivacyModePolicyCoveragePct: 100.0,
        requiredConsentGateCoveragePct: 100.0,
        requiredLocalSovereignCoveragePct: 100.0,
        maxNoEgressViolations: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageATriggerPrivacyNoEgressFailure
              .privacyPolicyCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageATriggerPrivacyNoEgressFailure
              .consentGateCoverageBelowThreshold,
        ),
      );
    });

    test('fails when no-egress enforcement is violated', () {
      const snapshot = UrkStageATriggerPrivacyNoEgressSnapshot(
        observedTriggerCoveragePct: 100.0,
        observedPrivacyModePolicyCoveragePct: 100.0,
        observedConsentGateCoveragePct: 100.0,
        observedLocalSovereignCoveragePct: 70.0,
        observedNoEgressViolations: 2,
      );
      const policy = UrkStageATriggerPrivacyNoEgressPolicy(
        requiredTriggerCoveragePct: 100.0,
        requiredPrivacyModePolicyCoveragePct: 100.0,
        requiredConsentGateCoveragePct: 100.0,
        requiredLocalSovereignCoveragePct: 100.0,
        maxNoEgressViolations: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkStageATriggerPrivacyNoEgressFailure
              .localSovereignCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkStageATriggerPrivacyNoEgressFailure.noEgressViolationExceeded,
        ),
      );
    });
  });
}

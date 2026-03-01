import 'package:avrai_runtime_os/ai/knowledge_lifecycle/claim_lifecycle_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClaimLifecycleTransitionValidator', () {
    const validator = ClaimLifecycleTransitionValidator();

    test('allows adjacent promotion with required evidence', () {
      const request = ClaimTransitionRequest(
        fromState: ClaimLifecycleState.hypothesis,
        toState: ClaimLifecycleState.observed,
        decisionType: ClaimDecisionType.promote,
        evidenceCount: 1,
      );

      final result = validator.validate(request);
      expect(result.isAllowed, isTrue);
      expect(result.reasonCode, isNull);
    });

    test('rejects promotion step skipping', () {
      const request = ClaimTransitionRequest(
        fromState: ClaimLifecycleState.hypothesis,
        toState: ClaimLifecycleState.reproduced,
        decisionType: ClaimDecisionType.promote,
        evidenceCount: 2,
      );

      final result = validator.validate(request);
      expect(result.isAllowed, isFalse);
      expect(result.reasonCode, equals('promotion_step_skip_not_allowed'));
    });

    test('rejects insufficient evidence for promotion', () {
      const request = ClaimTransitionRequest(
        fromState: ClaimLifecycleState.reproduced,
        toState: ClaimLifecycleState.operational,
        decisionType: ClaimDecisionType.promote,
        evidenceCount: 2,
      );

      final result = validator.validate(request);
      expect(result.isAllowed, isFalse);
      expect(
          result.reasonCode, equals('insufficient_evidence_for_target_state'));
    });

    test('allows demotion with evidence', () {
      const request = ClaimTransitionRequest(
        fromState: ClaimLifecycleState.operational,
        toState: ClaimLifecycleState.reproduced,
        decisionType: ClaimDecisionType.demote,
        evidenceCount: 1,
      );

      final result = validator.validate(request);
      expect(result.isAllowed, isTrue);
    });

    test('rejects demotion without evidence', () {
      const request = ClaimTransitionRequest(
        fromState: ClaimLifecycleState.operational,
        toState: ClaimLifecycleState.reproduced,
        decisionType: ClaimDecisionType.demote,
        evidenceCount: 0,
      );

      final result = validator.validate(request);
      expect(result.isAllowed, isFalse);
      expect(result.reasonCode, equals('demotion_requires_evidence'));
    });

    test('rejects transitions out of deprecated', () {
      const request = ClaimTransitionRequest(
        fromState: ClaimLifecycleState.deprecated,
        toState: ClaimLifecycleState.hypothesis,
        decisionType: ClaimDecisionType.rollback,
        evidenceCount: 1,
      );

      final result = validator.validate(request);
      expect(result.isAllowed, isFalse);
      expect(result.reasonCode, equals('deprecated_terminal_state'));
    });
  });
}

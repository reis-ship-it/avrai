import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/controllers/conviction_shadow_gate.dart';

void main() {
  group('ConvictionGateEvaluator', () {
    test('shadow mode records block decision but allows serving', () async {
      final sink = InMemoryConvictionGateTelemetrySink();
      final evaluator = ConvictionGateEvaluator(
        mode: ConvictionGateMode.shadow,
        telemetrySink: sink,
      );

      final decision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'ListCreationController',
          requestId: 'req-1',
          claimState: ClaimLifecycleState.hypothesis,
          isHighImpact: true,
          policyChecksPassed: false,
        ),
      );

      expect(decision.wouldAllow, isFalse);
      expect(decision.servingAllowed, isTrue);
      expect(decision.shadowBypassApplied, isTrue);
      expect(
        decision.reasonCodes,
        contains('high_impact_requires_canonical_conviction'),
      );
      expect(decision.reasonCodes, contains('policy_checks_failed'));
      expect(sink.events.length, equals(1));
    });

    test('enforce mode blocks serving when requirements are not met', () async {
      final evaluator =
          ConvictionGateEvaluator(mode: ConvictionGateMode.enforce);

      final decision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'ListCreationController',
          requestId: 'req-2',
          claimState: ClaimLifecycleState.operational,
          isHighImpact: true,
          policyChecksPassed: true,
        ),
      );

      expect(decision.wouldAllow, isFalse);
      expect(decision.servingAllowed, isFalse);
      expect(decision.shadowBypassApplied, isFalse);
    });

    test('canonical high-impact with policy pass is allow decision', () async {
      final evaluator =
          ConvictionGateEvaluator(mode: ConvictionGateMode.shadow);

      final decision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'ListCreationController',
          requestId: 'req-3',
          claimState: ClaimLifecycleState.canonical,
          isHighImpact: true,
          policyChecksPassed: true,
        ),
      );

      expect(decision.wouldAllow, isTrue);
      expect(decision.servingAllowed, isTrue);
      expect(decision.shadowBypassApplied, isFalse);
      expect(decision.reasonCodes, isEmpty);
    });

    test('mode resolver can enforce high-impact requests', () async {
      final evaluator = ConvictionGateEvaluator(
        mode: ConvictionGateMode.shadow,
        modeResolver: (request) async => request.isHighImpact
            ? ConvictionGateMode.enforce
            : ConvictionGateMode.shadow,
      );

      final decision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'CheckoutController',
          requestId: 'req-4',
          claimState: ClaimLifecycleState.observed,
          isHighImpact: true,
          policyChecksPassed: true,
        ),
      );

      expect(decision.mode, ConvictionGateMode.enforce);
      expect(decision.wouldAllow, isFalse);
      expect(decision.servingAllowed, isFalse);
      expect(decision.shadowBypassApplied, isFalse);
    });

    test('mode resolver keeps low-impact requests in shadow mode', () async {
      final evaluator = ConvictionGateEvaluator(
        mode: ConvictionGateMode.enforce,
        modeResolver: (request) async => request.isHighImpact
            ? ConvictionGateMode.enforce
            : ConvictionGateMode.shadow,
      );

      final decision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'AIRecommendationController',
          requestId: 'req-5',
          claimState: ClaimLifecycleState.hypothesis,
          isHighImpact: false,
          policyChecksPassed: true,
        ),
      );

      expect(decision.mode, ConvictionGateMode.shadow);
      expect(decision.wouldAllow, isTrue);
      expect(decision.servingAllowed, isTrue);
      expect(decision.shadowBypassApplied, isFalse);
    });

    test('subjectId can drive canary enforcement routing', () async {
      const targetedSubject = 'user-canary-1';
      final evaluator = ConvictionGateEvaluator(
        mode: ConvictionGateMode.shadow,
        modeResolver: (request) async => request.subjectId == targetedSubject
            ? ConvictionGateMode.enforce
            : ConvictionGateMode.shadow,
      );

      final canaryDecision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'CheckoutController',
          requestId: 'req-6',
          claimState: ClaimLifecycleState.observed,
          isHighImpact: true,
          policyChecksPassed: true,
          subjectId: targetedSubject,
        ),
      );
      final controlDecision = await evaluator.evaluate(
        const ConvictionGateRequest(
          controllerName: 'CheckoutController',
          requestId: 'req-7',
          claimState: ClaimLifecycleState.observed,
          isHighImpact: true,
          policyChecksPassed: true,
          subjectId: 'user-control-1',
        ),
      );

      expect(canaryDecision.mode, ConvictionGateMode.enforce);
      expect(canaryDecision.servingAllowed, isFalse);
      expect(controlDecision.mode, ConvictionGateMode.shadow);
      expect(controlDecision.servingAllowed, isTrue);
      expect(controlDecision.shadowBypassApplied, isTrue);
    });
  });
}

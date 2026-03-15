import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultWhyKernelSupport', () {
    const support = DefaultWhyKernelSupport();

    test('builds canonical policy explanations with trace refs', () {
      final snapshot = support.explain(
        const WhyKernelRequest(
          goal: 'enforce_policy',
          queryKind: WhyQueryKind.policyAction,
          requestedPerspective: WhyRequestedPerspective.governance,
          policyContext: <String, dynamic>{
            'policyRefs': <String>['policy-1'],
            'escalationThresholds': <String>['severity>0.9'],
          },
          evidenceBundle: WhyEvidenceBundle(
            entries: <WhyEvidence>[
              WhyEvidence(
                id: 'policy_block',
                label: 'policy threshold exceeded',
                weight: 0.93,
                polarity: WhyEvidencePolarity.positive,
                sourceKernel: WhyEvidenceSourceKernel.policy,
                sourceSubsystem: 'safety_gate',
                durability: 'durable',
                confidence: 0.91,
              ),
            ],
          ),
        ),
      );

      expect(snapshot.queryKind, WhyQueryKind.policyAction);
      expect(snapshot.rootCauseType, WhyRootCauseType.policyDriven);
      expect(snapshot.governanceEnvelope.policyRefs, contains('policy-1'));
      expect(snapshot.traceRefs, isNotEmpty);
      expect(snapshot.validationIssues, isEmpty);
    });

    test('redacts user-safe explanations while preserving attribution', () {
      final snapshot = support.explain(
        const WhyKernelRequest(
          requestedPerspective: WhyRequestedPerspective.userSafe,
          evidenceBundle: WhyEvidenceBundle(
            entries: <WhyEvidence>[
              WhyEvidence(
                id: 'step_failure',
                label: 'validation blocked execute',
                weight: 0.88,
                polarity: WhyEvidencePolarity.negative,
                sourceKernel: WhyEvidenceSourceKernel.how,
                sourceSubsystem: 'execution_path',
                durability: 'transient',
                confidence: 0.72,
              ),
            ],
          ),
        ),
      );

      expect(snapshot.rootCauseType, WhyRootCauseType.mechanistic);
      expect(snapshot.traceRefs, isEmpty);
      expect(snapshot.conflicts, isEmpty);
      expect(snapshot.governanceEnvelope.redacted, isTrue);
      expect(
        snapshot.governanceEnvelope.redactionReason,
        'user_safe_redaction',
      );
    });
  });
}

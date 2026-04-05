import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_telemetry_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_why_projection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelGovernanceWhyProjectionService', () {
    const service = KernelGovernanceWhyProjectionService();

    test('projects blocked telemetry into canonical why snapshot', () {
      final snapshot = service.explainEvent(
        KernelGovernanceTelemetryEvent(
          timestamp: DateTime.utc(2026, 3, 6, 15, 30),
          decisionId: 'kgd_1',
          action: 'modelSwitch',
          mode: 'enforce',
          wouldAllow: false,
          servingAllowed: false,
          shadowBypassApplied: false,
          reasonCodes: const <String>['missing_target_version'],
          policyVersion: 'v-policy',
          modelType: 'calling_score',
          fromVersion: 'v1',
          toVersion: 'v2',
        ),
      );

      expect(snapshot.queryKind, WhyQueryKind.policyAction);
      expect(snapshot.rootCauseType, WhyRootCauseType.mixed);
      expect(snapshot.governanceEnvelope.policyRefs, contains('v-policy'));
      expect(
        snapshot.traceRefs.map((entry) => entry.kernel),
        containsAll(<WhyEvidenceSourceKernel>[
          WhyEvidenceSourceKernel.policy,
          WhyEvidenceSourceKernel.when,
          WhyEvidenceSourceKernel.how,
        ]),
      );
      expect(snapshot.inhibitors.map((entry) => entry.label).join(' '),
          contains('missing_target_version'));
    });

    test('user safe projection redacts trace refs and conflicts', () {
      final snapshot = service.explainEvent(
        KernelGovernanceTelemetryEvent(
          timestamp: DateTime.utc(2026, 3, 6, 8),
          decisionId: 'kgd_2',
          action: 'modelSwitch',
          mode: 'shadow',
          wouldAllow: false,
          servingAllowed: true,
          shadowBypassApplied: true,
          reasonCodes: const <String>['missing_model_type'],
          policyVersion: 'v-shadow',
        ),
        perspective: WhyRequestedPerspective.userSafe,
      );

      expect(snapshot.governanceEnvelope.redacted, isTrue);
      expect(snapshot.traceRefs, isEmpty);
      expect(snapshot.conflicts, isEmpty);
    });
  });
}

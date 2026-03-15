import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/why/why_evidence_adapters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhyEvidenceAdapters', () {
    test('temporal adapter emits when evidence', () {
      final adapter = const TemporalWhyEvidenceAdapter();
      final instant = TemporalInstant(
        referenceTime: DateTime.utc(2026, 3, 7, 9),
        civilTime: DateTime.utc(2026, 3, 7, 9),
        timezoneId: 'UTC',
        provenance: const TemporalProvenance(
          authority: TemporalAuthority.device,
          source: 'test',
        ),
        uncertainty: const TemporalUncertainty.zero(),
      );
      final snapshot = TemporalSnapshot(
        observedAt: instant,
        recordedAt: instant,
        effectiveAt: instant,
        semanticBand: SemanticTimeBand.morning,
        lineageRef: 'decision-1',
      );

      final evidence = adapter.toWhyEvidence(snapshot);

      expect(evidence.sourceKernel, WhyEvidenceSourceKernel.when);
      expect(evidence.label, contains('morning'));
      expect(evidence.timeRef, instant.referenceTime.toIso8601String());
    });

    test('how adapter emits mechanism evidence', () {
      final adapter = const HowMechanismWhyEvidenceAdapter();
      const context = HowMechanismContext(
        executionPath: 'governance_gate',
        workflowStage: 'policy_eval',
        failureMechanism: 'missing_model_type',
        mechanismConfidence: 0.88,
        interventionChain: <String>['validate', 'gate', 'telemetry'],
        modelFamily: 'calling_score',
      );

      final evidence = adapter.toWhyEvidence(context);

      expect(evidence.sourceKernel, WhyEvidenceSourceKernel.how);
      expect(evidence.polarity, WhyEvidencePolarity.negative);
      expect(evidence.label, contains('missing_model_type'));
      expect(evidence.tags, contains('validate'));
    });
  });
}

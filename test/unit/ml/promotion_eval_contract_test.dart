import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ml/promotion_eval_contract.dart';

void main() {
  group('MandatoryEvalSuiteManifestCodec', () {
    test('round-trips manifest suite names', () {
      for (final suite in MandatoryEvalSuite.values) {
        final encoded = suite.manifestName;
        final decoded = MandatoryEvalSuiteManifestCodec.fromManifestName(
          encoded,
        );
        expect(decoded, suite);
      }
    });
  });

  group('PromotionEvalManifestContract', () {
    test('exports required manifest suite names in policy order', () {
      expect(
        PromotionEvalManifestContract.requiredSuiteManifestNames(),
        equals(<String>[
          'offline_replay',
          'adversarial_robustness',
          'contradiction_stress',
        ]),
      );
    });
  });

  group('PromotionEvalGate', () {
    const gate = PromotionEvalGate();

    test('eligible when all required suites pass with artifacts', () {
      const results = <EvalSuiteResult>[
        EvalSuiteResult(
          suite: MandatoryEvalSuite.offlineReplay,
          passed: true,
          artifactPath: 'artifacts/replay.json',
        ),
        EvalSuiteResult(
          suite: MandatoryEvalSuite.adversarialRobustness,
          passed: true,
          artifactPath: 'artifacts/adversarial.json',
        ),
        EvalSuiteResult(
          suite: MandatoryEvalSuite.contradictionStress,
          passed: true,
          artifactPath: 'artifacts/contradiction.json',
        ),
      ];

      final out = gate.validate(results);
      expect(out.isEligible, isTrue);
      expect(out.reasonCode, 'eligible');
    });

    test('ineligible when required suite is missing', () {
      const results = <EvalSuiteResult>[
        EvalSuiteResult(
          suite: MandatoryEvalSuite.offlineReplay,
          passed: true,
          artifactPath: 'artifacts/replay.json',
        ),
        EvalSuiteResult(
          suite: MandatoryEvalSuite.adversarialRobustness,
          passed: true,
          artifactPath: 'artifacts/adversarial.json',
        ),
      ];

      final out = gate.validate(results);
      expect(out.isEligible, isFalse);
      expect(out.reasonCode, 'missing_required_suites');
      expect(
          out.missingSuites, contains(MandatoryEvalSuite.contradictionStress));
    });

    test('ineligible when suite fails or has no artifact', () {
      const results = <EvalSuiteResult>[
        EvalSuiteResult(
          suite: MandatoryEvalSuite.offlineReplay,
          passed: true,
          artifactPath: 'artifacts/replay.json',
        ),
        EvalSuiteResult(
          suite: MandatoryEvalSuite.adversarialRobustness,
          passed: false,
          artifactPath: 'artifacts/adversarial.json',
        ),
        EvalSuiteResult(
          suite: MandatoryEvalSuite.contradictionStress,
          passed: true,
          artifactPath: '',
        ),
      ];

      final out = gate.validate(results);
      expect(out.isEligible, isFalse);
      expect(out.reasonCode, 'failed_or_unattested_required_suites');
      expect(
        out.failedSuites,
        containsAll(<MandatoryEvalSuite>[
          MandatoryEvalSuite.adversarialRobustness,
          MandatoryEvalSuite.contradictionStress,
        ]),
      );
    });
  });
}

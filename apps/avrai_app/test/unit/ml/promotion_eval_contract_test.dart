import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_runtime_os/ml/promotion_eval_contract.dart';

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

  group('CompressionRegressionSuiteManifestCodec', () {
    test('round-trips compression regression suite names', () {
      for (final suite in CompressionRegressionSuite.values) {
        final encoded = suite.manifestName;
        final decoded =
            CompressionRegressionSuiteManifestCodec.fromManifestName(encoded);
        expect(decoded, suite);
      }
    });
  });

  group('PromotionEvalManifestContract', () {
    test('pins the manifest version for compression-aware promotion gating',
        () {
      expect(PromotionEvalManifestContract.manifestVersion, 'v2');
    });

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

    test('exports required compression regression suite names in policy order',
        () {
      expect(
        PromotionEvalManifestContract.requiredCompressionSuiteManifestNames(),
        equals(<String>[
          'ranking_drift',
          'calibration_drift',
          'contradiction_detection_degradation',
          'uncertainty_honesty_regression',
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

  group('CompressionRegressionGate', () {
    const gate = CompressionRegressionGate();

    test('eligible when all required compression suites pass within budget',
        () {
      const results = <CompressionRegressionSuiteResult>[
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.rankingDrift,
          passed: true,
          artifactPath: 'artifacts/ranking.json',
          observedRegression: 0.01,
          maxAllowedRegression: 0.02,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.calibrationDrift,
          passed: true,
          artifactPath: 'artifacts/calibration.json',
          observedRegression: 0.005,
          maxAllowedRegression: 0.01,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.contradictionDetectionDegradation,
          passed: true,
          artifactPath: 'artifacts/contradiction.json',
          observedRegression: 0.01,
          maxAllowedRegression: 0.015,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.uncertaintyHonestyRegression,
          passed: true,
          artifactPath: 'artifacts/uncertainty.json',
          observedRegression: 0.002,
          maxAllowedRegression: 0.005,
        ),
      ];

      final out = gate.validate(results);
      expect(out.isEligible, isTrue);
      expect(out.reasonCode, 'eligible');
    });

    test('ineligible when required compression suite is missing', () {
      const results = <CompressionRegressionSuiteResult>[
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.rankingDrift,
          passed: true,
          artifactPath: 'artifacts/ranking.json',
          observedRegression: 0.01,
          maxAllowedRegression: 0.02,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.calibrationDrift,
          passed: true,
          artifactPath: 'artifacts/calibration.json',
          observedRegression: 0.005,
          maxAllowedRegression: 0.01,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.contradictionDetectionDegradation,
          passed: true,
          artifactPath: 'artifacts/contradiction.json',
          observedRegression: 0.01,
          maxAllowedRegression: 0.015,
        ),
      ];

      final out = gate.validate(results);
      expect(out.isEligible, isFalse);
      expect(out.reasonCode, 'missing_required_compression_suites');
      expect(
        out.missingSuites,
        contains(CompressionRegressionSuite.uncertaintyHonestyRegression),
      );
    });

    test('ineligible when suite exceeds budget or lacks artifact', () {
      const results = <CompressionRegressionSuiteResult>[
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.rankingDrift,
          passed: true,
          artifactPath: 'artifacts/ranking.json',
          observedRegression: 0.025,
          maxAllowedRegression: 0.02,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.calibrationDrift,
          passed: true,
          artifactPath: 'artifacts/calibration.json',
          observedRegression: 0.005,
          maxAllowedRegression: 0.01,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.contradictionDetectionDegradation,
          passed: false,
          artifactPath: 'artifacts/contradiction.json',
          observedRegression: 0.01,
          maxAllowedRegression: 0.015,
        ),
        CompressionRegressionSuiteResult(
          suite: CompressionRegressionSuite.uncertaintyHonestyRegression,
          passed: true,
          artifactPath: '',
          observedRegression: 0.002,
          maxAllowedRegression: 0.005,
        ),
      ];

      final out = gate.validate(results);
      expect(out.isEligible, isFalse);
      expect(
        out.reasonCode,
        'failed_or_budget_exceeded_required_compression_suites',
      );
      expect(
        out.failedSuites,
        containsAll(<CompressionRegressionSuite>[
          CompressionRegressionSuite.contradictionDetectionDegradation,
          CompressionRegressionSuite.uncertaintyHonestyRegression,
        ]),
      );
      expect(
        out.budgetExceededSuites,
        contains(CompressionRegressionSuite.rankingDrift),
      );
    });
  });
}

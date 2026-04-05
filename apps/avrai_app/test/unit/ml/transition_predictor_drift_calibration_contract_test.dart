import 'package:avrai_runtime_os/ml/transition_predictor_drift_calibration_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransitionPredictorCalibrationValidator', () {
    const validator = TransitionPredictorCalibrationValidator();

    test('passes when drift and calibration checks are healthy', () {
      const snapshot = TransitionPredictorCalibrationSnapshot(
        observedResidualEmaRatio: 1.2,
        driftEventTriggered: false,
        observedExpectedCalibrationError: 0.03,
        observedConfidenceAccuracyGapPct: 1.2,
        confidenceOutcomeDivergenceDetected: false,
        autoThrottleTriggered: false,
        verificationEscalationTriggered: false,
      );

      const policy = TransitionPredictorCalibrationPolicy(
        maxResidualEmaRatio: 2.0,
        maxExpectedCalibrationError: 0.08,
        maxConfidenceAccuracyGapPct: 4.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when residual drift exceeds threshold', () {
      const snapshot = TransitionPredictorCalibrationSnapshot(
        observedResidualEmaRatio: 2.5,
        driftEventTriggered: false,
        observedExpectedCalibrationError: 0.03,
        observedConfidenceAccuracyGapPct: 1.2,
        confidenceOutcomeDivergenceDetected: false,
        autoThrottleTriggered: false,
        verificationEscalationTriggered: false,
      );

      const policy = TransitionPredictorCalibrationPolicy(
        maxResidualEmaRatio: 2.0,
        maxExpectedCalibrationError: 0.08,
        maxConfidenceAccuracyGapPct: 4.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(TransitionPredictorCalibrationFailure.residualDriftExceeded),
      );
    });

    test('fails when calibration error exceeds threshold', () {
      const snapshot = TransitionPredictorCalibrationSnapshot(
        observedResidualEmaRatio: 1.2,
        driftEventTriggered: false,
        observedExpectedCalibrationError: 0.2,
        observedConfidenceAccuracyGapPct: 1.2,
        confidenceOutcomeDivergenceDetected: false,
        autoThrottleTriggered: false,
        verificationEscalationTriggered: false,
      );

      const policy = TransitionPredictorCalibrationPolicy(
        maxResidualEmaRatio: 2.0,
        maxExpectedCalibrationError: 0.08,
        maxConfidenceAccuracyGapPct: 4.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
            TransitionPredictorCalibrationFailure.calibrationErrorExceeded),
      );
    });

    test('fails when confidence-accuracy gap exceeds threshold', () {
      const snapshot = TransitionPredictorCalibrationSnapshot(
        observedResidualEmaRatio: 1.2,
        driftEventTriggered: false,
        observedExpectedCalibrationError: 0.03,
        observedConfidenceAccuracyGapPct: 7.4,
        confidenceOutcomeDivergenceDetected: false,
        autoThrottleTriggered: false,
        verificationEscalationTriggered: false,
      );

      const policy = TransitionPredictorCalibrationPolicy(
        maxResidualEmaRatio: 2.0,
        maxExpectedCalibrationError: 0.08,
        maxConfidenceAccuracyGapPct: 4.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          TransitionPredictorCalibrationFailure.confidenceAccuracyGapExceeded,
        ),
      );
    });

    test('fails when divergence gate signals are triggered', () {
      const snapshot = TransitionPredictorCalibrationSnapshot(
        observedResidualEmaRatio: 1.2,
        driftEventTriggered: false,
        observedExpectedCalibrationError: 0.03,
        observedConfidenceAccuracyGapPct: 1.2,
        confidenceOutcomeDivergenceDetected: true,
        autoThrottleTriggered: true,
        verificationEscalationTriggered: true,
      );

      const policy = TransitionPredictorCalibrationPolicy(
        maxResidualEmaRatio: 2.0,
        maxExpectedCalibrationError: 0.08,
        maxConfidenceAccuracyGapPct: 4.0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          TransitionPredictorCalibrationFailure
              .confidenceOutcomeDivergenceDetected,
        ),
      );
      expect(
        result.failures,
        contains(TransitionPredictorCalibrationFailure.autoThrottleTriggered),
      );
      expect(
        result.failures,
        contains(
          TransitionPredictorCalibrationFailure.verificationEscalationTriggered,
        ),
      );
    });
  });
}

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
enum TransitionPredictorCalibrationFailure {
  invalidResidualThreshold,
  invalidCalibrationThreshold,
  residualDriftExceeded,
  driftEventTriggered,
  calibrationErrorExceeded,
  confidenceAccuracyGapExceeded,
  confidenceOutcomeDivergenceDetected,
  autoThrottleTriggered,
  verificationEscalationTriggered,
}

class TransitionPredictorCalibrationPolicy {
  const TransitionPredictorCalibrationPolicy({
    required this.maxResidualEmaRatio,
    required this.maxExpectedCalibrationError,
    required this.maxConfidenceAccuracyGapPct,
  });

  final double maxResidualEmaRatio;
  final double maxExpectedCalibrationError;
  final double maxConfidenceAccuracyGapPct;
}

class TransitionPredictorCalibrationSnapshot {
  const TransitionPredictorCalibrationSnapshot({
    required this.observedResidualEmaRatio,
    required this.driftEventTriggered,
    required this.observedExpectedCalibrationError,
    required this.observedConfidenceAccuracyGapPct,
    required this.confidenceOutcomeDivergenceDetected,
    required this.autoThrottleTriggered,
    required this.verificationEscalationTriggered,
  });

  final double observedResidualEmaRatio;
  final bool driftEventTriggered;
  final double observedExpectedCalibrationError;
  final double observedConfidenceAccuracyGapPct;
  final bool confidenceOutcomeDivergenceDetected;
  final bool autoThrottleTriggered;
  final bool verificationEscalationTriggered;
}

class TransitionPredictorCalibrationValidationResult {
  const TransitionPredictorCalibrationValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory TransitionPredictorCalibrationValidationResult.pass() {
    return const TransitionPredictorCalibrationValidationResult._(
      isPassing: true,
      failures: <TransitionPredictorCalibrationFailure>[],
    );
  }

  factory TransitionPredictorCalibrationValidationResult.fail(
    List<TransitionPredictorCalibrationFailure> failures,
  ) {
    return TransitionPredictorCalibrationValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<TransitionPredictorCalibrationFailure> failures;
}

class TransitionPredictorCalibrationValidator {
  const TransitionPredictorCalibrationValidator();

  TransitionPredictorCalibrationValidationResult validate({
    required TransitionPredictorCalibrationSnapshot snapshot,
    required TransitionPredictorCalibrationPolicy policy,
  }) {
    final failures = <TransitionPredictorCalibrationFailure>[];

    if (policy.maxResidualEmaRatio < 0) {
      failures
          .add(TransitionPredictorCalibrationFailure.invalidResidualThreshold);
    }
    if (policy.maxExpectedCalibrationError < 0 ||
        policy.maxConfidenceAccuracyGapPct < 0) {
      failures.add(
          TransitionPredictorCalibrationFailure.invalidCalibrationThreshold);
    }

    if (snapshot.observedResidualEmaRatio > policy.maxResidualEmaRatio) {
      failures.add(TransitionPredictorCalibrationFailure.residualDriftExceeded);
    }
    if (snapshot.driftEventTriggered) {
      failures.add(TransitionPredictorCalibrationFailure.driftEventTriggered);
    }
    if (snapshot.observedExpectedCalibrationError >
        policy.maxExpectedCalibrationError) {
      failures
          .add(TransitionPredictorCalibrationFailure.calibrationErrorExceeded);
    }
    if (snapshot.observedConfidenceAccuracyGapPct >
        policy.maxConfidenceAccuracyGapPct) {
      failures.add(
        TransitionPredictorCalibrationFailure.confidenceAccuracyGapExceeded,
      );
    }

    if (snapshot.confidenceOutcomeDivergenceDetected) {
      failures.add(
        TransitionPredictorCalibrationFailure
            .confidenceOutcomeDivergenceDetected,
      );
    }
    if (snapshot.autoThrottleTriggered) {
      failures.add(TransitionPredictorCalibrationFailure.autoThrottleTriggered);
    }
    if (snapshot.verificationEscalationTriggered) {
      failures.add(
        TransitionPredictorCalibrationFailure.verificationEscalationTriggered,
      );
    }

    if (failures.isEmpty) {
      return TransitionPredictorCalibrationValidationResult.pass();
    }
    return TransitionPredictorCalibrationValidationResult.fail(failures);
  }
}

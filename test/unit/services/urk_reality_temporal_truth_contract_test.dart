import 'package:avrai/runtime/avrai_runtime_os/kernel/service_contracts/urk_reality_temporal_truth_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrkRealityTemporalTruthValidator', () {
    const validator = UrkRealityTemporalTruthValidator();

    test('passes when temporal truth checks are healthy', () {
      const snapshot = UrkRealityTemporalTruthSnapshot(
        observedAtomicSemanticAlignmentPct: 100.0,
        observedTimezoneNormalizationCoveragePct: 100.0,
        observedTemporalContradictionEvents: 0,
        observedClockRegressionEvents: 0,
      );
      const policy = UrkRealityTemporalTruthPolicy(
        requiredAtomicSemanticAlignmentPct: 100.0,
        requiredTimezoneNormalizationCoveragePct: 100.0,
        maxTemporalContradictionEvents: 0,
        maxClockRegressionEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when temporal alignment coverage regresses', () {
      const snapshot = UrkRealityTemporalTruthSnapshot(
        observedAtomicSemanticAlignmentPct: 92.0,
        observedTimezoneNormalizationCoveragePct: 94.0,
        observedTemporalContradictionEvents: 0,
        observedClockRegressionEvents: 0,
      );
      const policy = UrkRealityTemporalTruthPolicy(
        requiredAtomicSemanticAlignmentPct: 100.0,
        requiredTimezoneNormalizationCoveragePct: 100.0,
        maxTemporalContradictionEvents: 0,
        maxClockRegressionEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          UrkRealityTemporalTruthFailure.atomicSemanticAlignmentBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(
          UrkRealityTemporalTruthFailure
              .timezoneNormalizationCoverageBelowThreshold,
        ),
      );
    });

    test('fails when contradiction or clock regression events exist', () {
      const snapshot = UrkRealityTemporalTruthSnapshot(
        observedAtomicSemanticAlignmentPct: 100.0,
        observedTimezoneNormalizationCoveragePct: 100.0,
        observedTemporalContradictionEvents: 1,
        observedClockRegressionEvents: 2,
      );
      const policy = UrkRealityTemporalTruthPolicy(
        requiredAtomicSemanticAlignmentPct: 100.0,
        requiredTimezoneNormalizationCoveragePct: 100.0,
        maxTemporalContradictionEvents: 0,
        maxClockRegressionEvents: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(UrkRealityTemporalTruthFailure.temporalContradictionDetected),
      );
      expect(
        result.failures,
        contains(UrkRealityTemporalTruthFailure.clockRegressionDetected),
      );
    });
  });
}

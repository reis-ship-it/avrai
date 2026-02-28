import 'package:avrai/core/models/state_encoder_consistency_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StateEncoderConsistencyValidator', () {
    const validator = StateEncoderConsistencyValidator();

    test('passes when freshness and snapshot consistency are within policy',
        () {
      const snapshot = StateEncoderConsistencySnapshot(
        observedP95FeatureAgeMinutes: 18,
        observedMismatchRatePct: 0.2,
        monotonicSequencePassed: true,
        lineageCompletenessPassed: true,
      );

      const policy = StateEncoderConsistencyPolicy(
        maxP95FeatureAgeMinutes: 60,
        maxMismatchRatePct: 0.5,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when p95 feature age exceeds threshold', () {
      const snapshot = StateEncoderConsistencySnapshot(
        observedP95FeatureAgeMinutes: 75,
        observedMismatchRatePct: 0.2,
        monotonicSequencePassed: true,
        lineageCompletenessPassed: true,
      );

      const policy = StateEncoderConsistencyPolicy(
        maxP95FeatureAgeMinutes: 60,
        maxMismatchRatePct: 0.5,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(StateEncoderConsistencyFailure.staleFeatureAgeExceeded),
      );
    });

    test('fails when mismatch rate exceeds threshold', () {
      const snapshot = StateEncoderConsistencySnapshot(
        observedP95FeatureAgeMinutes: 18,
        observedMismatchRatePct: 0.7,
        monotonicSequencePassed: true,
        lineageCompletenessPassed: true,
      );

      const policy = StateEncoderConsistencyPolicy(
        maxP95FeatureAgeMinutes: 60,
        maxMismatchRatePct: 0.5,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(StateEncoderConsistencyFailure.mismatchRateExceeded),
      );
    });

    test('fails when atomic monotonic sequence check fails', () {
      const snapshot = StateEncoderConsistencySnapshot(
        observedP95FeatureAgeMinutes: 18,
        observedMismatchRatePct: 0.2,
        monotonicSequencePassed: false,
        lineageCompletenessPassed: true,
      );

      const policy = StateEncoderConsistencyPolicy(
        maxP95FeatureAgeMinutes: 60,
        maxMismatchRatePct: 0.5,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(StateEncoderConsistencyFailure.atomicSnapshotNonMonotonic),
      );
    });

    test('fails when lineage completeness check fails', () {
      const snapshot = StateEncoderConsistencySnapshot(
        observedP95FeatureAgeMinutes: 18,
        observedMismatchRatePct: 0.2,
        monotonicSequencePassed: true,
        lineageCompletenessPassed: false,
      );

      const policy = StateEncoderConsistencyPolicy(
        maxP95FeatureAgeMinutes: 60,
        maxMismatchRatePct: 0.5,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(StateEncoderConsistencyFailure.lineageIncomplete),
      );
    });
  });
}

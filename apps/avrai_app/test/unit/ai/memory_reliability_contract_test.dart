import 'package:avrai_runtime_os/ai/memory/memory_reliability_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryReliabilityValidator', () {
    const validator = MemoryReliabilityValidator();

    test('passes when schema dedupe and replay are within policy', () {
      const snapshot = MemoryReliabilitySnapshot(
        totalRecords: 1000,
        missingRequiredFields: 3,
        inputRecords: 1000,
        uniqueRecords: 994,
        scenariosTested: 24,
        scenariosPassed: 24,
        deterministicHashMatch: true,
      );

      const policy = MemoryReliabilityPolicy(
        maxMissingFieldRatePct: 0.5,
        maxDuplicateRatePct: 1.0,
        maxReplayFailures: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failureReasons, isEmpty);
    });

    test('fails when schema missing rate exceeds threshold', () {
      const snapshot = MemoryReliabilitySnapshot(
        totalRecords: 100,
        missingRequiredFields: 2,
        inputRecords: 100,
        uniqueRecords: 100,
        scenariosTested: 10,
        scenariosPassed: 10,
        deterministicHashMatch: true,
      );

      const policy = MemoryReliabilityPolicy(
        maxMissingFieldRatePct: 1.0,
        maxDuplicateRatePct: 1.0,
        maxReplayFailures: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failureReasons,
        contains(MemoryReliabilityFailureReason.schemaMissingRateExceeded),
      );
    });

    test('fails when dedupe duplicate rate exceeds threshold', () {
      const snapshot = MemoryReliabilitySnapshot(
        totalRecords: 100,
        missingRequiredFields: 0,
        inputRecords: 100,
        uniqueRecords: 97,
        scenariosTested: 10,
        scenariosPassed: 10,
        deterministicHashMatch: true,
      );

      const policy = MemoryReliabilityPolicy(
        maxMissingFieldRatePct: 1.0,
        maxDuplicateRatePct: 2.0,
        maxReplayFailures: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failureReasons,
        contains(MemoryReliabilityFailureReason.dedupeDuplicateRateExceeded),
      );
    });

    test('fails when replay failures exceed threshold', () {
      const snapshot = MemoryReliabilitySnapshot(
        totalRecords: 100,
        missingRequiredFields: 0,
        inputRecords: 100,
        uniqueRecords: 100,
        scenariosTested: 10,
        scenariosPassed: 9,
        deterministicHashMatch: true,
      );

      const policy = MemoryReliabilityPolicy(
        maxMissingFieldRatePct: 1.0,
        maxDuplicateRatePct: 1.0,
        maxReplayFailures: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failureReasons,
        contains(MemoryReliabilityFailureReason.replayFailuresExceeded),
      );
    });

    test('fails when deterministic replay hash mismatches', () {
      const snapshot = MemoryReliabilitySnapshot(
        totalRecords: 100,
        missingRequiredFields: 0,
        inputRecords: 100,
        uniqueRecords: 100,
        scenariosTested: 10,
        scenariosPassed: 10,
        deterministicHashMatch: false,
      );

      const policy = MemoryReliabilityPolicy(
        maxMissingFieldRatePct: 1.0,
        maxDuplicateRatePct: 1.0,
        maxReplayFailures: 0,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failureReasons,
        contains(MemoryReliabilityFailureReason.replayDeterminismMismatch),
      );
    });
  });
}

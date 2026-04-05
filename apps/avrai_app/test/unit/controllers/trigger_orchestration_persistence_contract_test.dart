import 'package:avrai_runtime_os/controllers/trigger_orchestration_persistence_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TriggerOrchestrationPersistenceValidator', () {
    const validator = TriggerOrchestrationPersistenceValidator();

    test('passes when reliability persistence and latency checks are healthy',
        () {
      const snapshot = TriggerOrchestrationPersistenceSnapshot(
        observedDroppedTriggerRatePct: 0.02,
        observedDuplicateTriggerRatePct: 0.05,
        observedIdempotencyCoveragePct: 100.0,
        replayOnRestartPassed: true,
        unrecoveredStateRecords: 0,
        observedP95TriggerToActionLatencyMs: 120,
      );

      const policy = TriggerOrchestrationPersistencePolicy(
        maxDroppedTriggerRatePct: 0.1,
        maxDuplicateTriggerRatePct: 0.2,
        requiredIdempotencyCoveragePct: 100.0,
        maxP95TriggerToActionLatencyMs: 250,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isTrue);
      expect(result.failures, isEmpty);
    });

    test('fails when dropped/duplicate trigger rates exceed thresholds', () {
      const snapshot = TriggerOrchestrationPersistenceSnapshot(
        observedDroppedTriggerRatePct: 0.5,
        observedDuplicateTriggerRatePct: 0.4,
        observedIdempotencyCoveragePct: 100.0,
        replayOnRestartPassed: true,
        unrecoveredStateRecords: 0,
        observedP95TriggerToActionLatencyMs: 120,
      );

      const policy = TriggerOrchestrationPersistencePolicy(
        maxDroppedTriggerRatePct: 0.1,
        maxDuplicateTriggerRatePct: 0.2,
        requiredIdempotencyCoveragePct: 100.0,
        maxP95TriggerToActionLatencyMs: 250,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
            TriggerOrchestrationPersistenceFailure.droppedTriggerRateExceeded),
      );
      expect(
        result.failures,
        contains(
          TriggerOrchestrationPersistenceFailure.duplicateTriggerRateExceeded,
        ),
      );
    });

    test('fails when persistence recovery checks fail', () {
      const snapshot = TriggerOrchestrationPersistenceSnapshot(
        observedDroppedTriggerRatePct: 0.02,
        observedDuplicateTriggerRatePct: 0.05,
        observedIdempotencyCoveragePct: 80.0,
        replayOnRestartPassed: false,
        unrecoveredStateRecords: 7,
        observedP95TriggerToActionLatencyMs: 120,
      );

      const policy = TriggerOrchestrationPersistencePolicy(
        maxDroppedTriggerRatePct: 0.1,
        maxDuplicateTriggerRatePct: 0.2,
        requiredIdempotencyCoveragePct: 100.0,
        maxP95TriggerToActionLatencyMs: 250,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          TriggerOrchestrationPersistenceFailure
              .idempotencyCoverageBelowThreshold,
        ),
      );
      expect(
        result.failures,
        contains(TriggerOrchestrationPersistenceFailure.replayOnRestartFailed),
      );
      expect(
        result.failures,
        contains(
          TriggerOrchestrationPersistenceFailure
              .unrecoveredStateRecordsDetected,
        ),
      );
    });

    test('fails when trigger-to-action latency exceeds threshold', () {
      const snapshot = TriggerOrchestrationPersistenceSnapshot(
        observedDroppedTriggerRatePct: 0.02,
        observedDuplicateTriggerRatePct: 0.05,
        observedIdempotencyCoveragePct: 100.0,
        replayOnRestartPassed: true,
        unrecoveredStateRecords: 0,
        observedP95TriggerToActionLatencyMs: 480,
      );

      const policy = TriggerOrchestrationPersistencePolicy(
        maxDroppedTriggerRatePct: 0.1,
        maxDuplicateTriggerRatePct: 0.2,
        requiredIdempotencyCoveragePct: 100.0,
        maxP95TriggerToActionLatencyMs: 250,
      );

      final result = validator.validate(snapshot: snapshot, policy: policy);
      expect(result.isPassing, isFalse);
      expect(
        result.failures,
        contains(
          TriggerOrchestrationPersistenceFailure.triggerToActionLatencyExceeded,
        ),
      );
    });
  });
}

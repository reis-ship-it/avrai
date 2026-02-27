enum TriggerOrchestrationPersistenceFailure {
  invalidReliabilityThreshold,
  invalidPersistenceThreshold,
  invalidLatencyThreshold,
  droppedTriggerRateExceeded,
  duplicateTriggerRateExceeded,
  idempotencyCoverageBelowThreshold,
  replayOnRestartFailed,
  unrecoveredStateRecordsDetected,
  triggerToActionLatencyExceeded,
}

class TriggerOrchestrationPersistencePolicy {
  const TriggerOrchestrationPersistencePolicy({
    required this.maxDroppedTriggerRatePct,
    required this.maxDuplicateTriggerRatePct,
    required this.requiredIdempotencyCoveragePct,
    required this.maxP95TriggerToActionLatencyMs,
  });

  final double maxDroppedTriggerRatePct;
  final double maxDuplicateTriggerRatePct;
  final double requiredIdempotencyCoveragePct;
  final double maxP95TriggerToActionLatencyMs;
}

class TriggerOrchestrationPersistenceSnapshot {
  const TriggerOrchestrationPersistenceSnapshot({
    required this.observedDroppedTriggerRatePct,
    required this.observedDuplicateTriggerRatePct,
    required this.observedIdempotencyCoveragePct,
    required this.replayOnRestartPassed,
    required this.unrecoveredStateRecords,
    required this.observedP95TriggerToActionLatencyMs,
  });

  final double observedDroppedTriggerRatePct;
  final double observedDuplicateTriggerRatePct;
  final double observedIdempotencyCoveragePct;
  final bool replayOnRestartPassed;
  final int unrecoveredStateRecords;
  final double observedP95TriggerToActionLatencyMs;
}

class TriggerOrchestrationPersistenceValidationResult {
  const TriggerOrchestrationPersistenceValidationResult._({
    required this.isPassing,
    required this.failures,
  });

  factory TriggerOrchestrationPersistenceValidationResult.pass() {
    return const TriggerOrchestrationPersistenceValidationResult._(
      isPassing: true,
      failures: <TriggerOrchestrationPersistenceFailure>[],
    );
  }

  factory TriggerOrchestrationPersistenceValidationResult.fail(
    List<TriggerOrchestrationPersistenceFailure> failures,
  ) {
    return TriggerOrchestrationPersistenceValidationResult._(
      isPassing: false,
      failures: List.unmodifiable(failures),
    );
  }

  final bool isPassing;
  final List<TriggerOrchestrationPersistenceFailure> failures;
}

class TriggerOrchestrationPersistenceValidator {
  const TriggerOrchestrationPersistenceValidator();

  TriggerOrchestrationPersistenceValidationResult validate({
    required TriggerOrchestrationPersistenceSnapshot snapshot,
    required TriggerOrchestrationPersistencePolicy policy,
  }) {
    final failures = <TriggerOrchestrationPersistenceFailure>[];

    if (policy.maxDroppedTriggerRatePct < 0 ||
        policy.maxDuplicateTriggerRatePct < 0) {
      failures.add(
          TriggerOrchestrationPersistenceFailure.invalidReliabilityThreshold);
    }
    if (policy.requiredIdempotencyCoveragePct < 0) {
      failures.add(
          TriggerOrchestrationPersistenceFailure.invalidPersistenceThreshold);
    }
    if (policy.maxP95TriggerToActionLatencyMs < 0) {
      failures
          .add(TriggerOrchestrationPersistenceFailure.invalidLatencyThreshold);
    }

    if (snapshot.observedDroppedTriggerRatePct >
        policy.maxDroppedTriggerRatePct) {
      failures.add(
          TriggerOrchestrationPersistenceFailure.droppedTriggerRateExceeded);
    }
    if (snapshot.observedDuplicateTriggerRatePct >
        policy.maxDuplicateTriggerRatePct) {
      failures.add(
          TriggerOrchestrationPersistenceFailure.duplicateTriggerRateExceeded);
    }
    if (snapshot.observedIdempotencyCoveragePct <
        policy.requiredIdempotencyCoveragePct) {
      failures.add(
        TriggerOrchestrationPersistenceFailure
            .idempotencyCoverageBelowThreshold,
      );
    }
    if (!snapshot.replayOnRestartPassed) {
      failures
          .add(TriggerOrchestrationPersistenceFailure.replayOnRestartFailed);
    }
    if (snapshot.unrecoveredStateRecords > 0) {
      failures.add(
        TriggerOrchestrationPersistenceFailure.unrecoveredStateRecordsDetected,
      );
    }
    if (snapshot.observedP95TriggerToActionLatencyMs >
        policy.maxP95TriggerToActionLatencyMs) {
      failures.add(
        TriggerOrchestrationPersistenceFailure.triggerToActionLatencyExceeded,
      );
    }

    if (failures.isEmpty) {
      return TriggerOrchestrationPersistenceValidationResult.pass();
    }
    return TriggerOrchestrationPersistenceValidationResult.fail(failures);
  }
}

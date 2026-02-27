enum MemoryReliabilityFailureReason {
  invalidSchemaThreshold,
  invalidDedupeThreshold,
  invalidReplayThreshold,
  schemaMissingRateExceeded,
  dedupeDuplicateRateExceeded,
  replayFailuresExceeded,
  replayDeterminismMismatch,
}

class MemoryReliabilitySnapshot {
  const MemoryReliabilitySnapshot({
    required this.totalRecords,
    required this.missingRequiredFields,
    required this.inputRecords,
    required this.uniqueRecords,
    required this.scenariosTested,
    required this.scenariosPassed,
    required this.deterministicHashMatch,
  });

  final int totalRecords;
  final int missingRequiredFields;
  final int inputRecords;
  final int uniqueRecords;
  final int scenariosTested;
  final int scenariosPassed;
  final bool deterministicHashMatch;

  double get schemaMissingRatePct {
    if (totalRecords <= 0) {
      return 100.0;
    }
    return (missingRequiredFields / totalRecords) * 100.0;
  }

  int get duplicateRecords {
    final duplicates = inputRecords - uniqueRecords;
    return duplicates < 0 ? 0 : duplicates;
  }

  double get duplicateRatePct {
    if (inputRecords <= 0) {
      return 100.0;
    }
    return (duplicateRecords / inputRecords) * 100.0;
  }

  int get replayFailures {
    final failures = scenariosTested - scenariosPassed;
    return failures < 0 ? 0 : failures;
  }
}

class MemoryReliabilityPolicy {
  const MemoryReliabilityPolicy({
    required this.maxMissingFieldRatePct,
    required this.maxDuplicateRatePct,
    required this.maxReplayFailures,
  });

  final double maxMissingFieldRatePct;
  final double maxDuplicateRatePct;
  final int maxReplayFailures;
}

class MemoryReliabilityResult {
  const MemoryReliabilityResult._({
    required this.isPassing,
    required this.failureReasons,
  });

  factory MemoryReliabilityResult.pass() {
    return const MemoryReliabilityResult._(isPassing: true, failureReasons: []);
  }

  factory MemoryReliabilityResult.fail(
    List<MemoryReliabilityFailureReason> failureReasons,
  ) {
    return MemoryReliabilityResult._(
      isPassing: false,
      failureReasons: List.unmodifiable(failureReasons),
    );
  }

  final bool isPassing;
  final List<MemoryReliabilityFailureReason> failureReasons;
}

class MemoryReliabilityValidator {
  const MemoryReliabilityValidator();

  MemoryReliabilityResult validate({
    required MemoryReliabilitySnapshot snapshot,
    required MemoryReliabilityPolicy policy,
  }) {
    final failures = <MemoryReliabilityFailureReason>[];

    if (policy.maxMissingFieldRatePct < 0) {
      failures.add(MemoryReliabilityFailureReason.invalidSchemaThreshold);
    }
    if (policy.maxDuplicateRatePct < 0) {
      failures.add(MemoryReliabilityFailureReason.invalidDedupeThreshold);
    }
    if (policy.maxReplayFailures < 0) {
      failures.add(MemoryReliabilityFailureReason.invalidReplayThreshold);
    }

    if (snapshot.schemaMissingRatePct > policy.maxMissingFieldRatePct) {
      failures.add(MemoryReliabilityFailureReason.schemaMissingRateExceeded);
    }
    if (snapshot.duplicateRatePct > policy.maxDuplicateRatePct) {
      failures.add(MemoryReliabilityFailureReason.dedupeDuplicateRateExceeded);
    }
    if (snapshot.replayFailures > policy.maxReplayFailures) {
      failures.add(MemoryReliabilityFailureReason.replayFailuresExceeded);
    }
    if (!snapshot.deterministicHashMatch) {
      failures.add(MemoryReliabilityFailureReason.replayDeterminismMismatch);
    }

    if (failures.isEmpty) {
      return MemoryReliabilityResult.pass();
    }
    return MemoryReliabilityResult.fail(failures);
  }
}

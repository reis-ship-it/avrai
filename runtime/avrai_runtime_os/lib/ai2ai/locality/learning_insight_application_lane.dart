// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class LearningInsightApplicationLane {
  const LearningInsightApplicationLane._();

  static Future<bool> apply({
    required bool eventModeEnabled,
    required Future<void> Function() evolveFromAi2AiLearning,
    required void Function() onEventModeBuffer,
    required void Function() onApplied,
  }) async {
    if (eventModeEnabled) {
      onEventModeBuffer();
      return false;
    }

    await evolveFromAi2AiLearning();
    onApplied();
    return true;
  }
}

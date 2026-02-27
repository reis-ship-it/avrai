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

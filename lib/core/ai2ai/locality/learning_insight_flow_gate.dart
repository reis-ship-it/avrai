// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class LearningInsightFlowGate {
  const LearningInsightFlowGate._();

  static bool markSeenIfFresh({
    required Map<String, int> seenLearningInsightIds,
    required String insightId,
    required int nowMs,
    required int expiresAtMs,
  }) {
    final seenExpiry = seenLearningInsightIds[insightId];
    if (seenExpiry != null && seenExpiry > nowMs) {
      return false;
    }
    seenLearningInsightIds[insightId] = expiresAtMs;
    return true;
  }

  static bool isPeerLearningThrottled({
    required Map<String, DateTime> lastAi2AiLearningAtByPeerId,
    required String peerId,
    required DateTime now,
    Duration minInterval = const Duration(minutes: 20),
  }) {
    final last = lastAi2AiLearningAtByPeerId[peerId];
    return last != null && now.difference(last) < minInterval;
  }
}

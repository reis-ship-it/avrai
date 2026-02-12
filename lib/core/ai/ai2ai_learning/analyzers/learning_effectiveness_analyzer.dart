import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai/core/ai/ai2ai_learning.dart';

/// Analyzes learning effectiveness metrics
class LearningEffectivenessAnalyzer {
  static const String _logName = 'LearningEffectivenessAnalyzer';

  LearningEffectivenessAnalyzer();

  /// Calculate personality evolution rate
  Future<double> calculatePersonalityEvolutionRate(
    String userId,
    DateTime cutoff,
    Future<List<AI2AIChatEvent>> Function(String, DateTime) getRecentChats,
    Future<List<CrossPersonalityInsight>> Function(String) getLearningInsights,
  ) async {
    try {
      // Get recent chats since cutoff
      final recentChats = await getRecentChats(userId, cutoff);
      final learningInsights = await getLearningInsights(userId);

      if (recentChats.isEmpty && learningInsights.isEmpty) {
        return 0.0; // No activity = no evolution
      }

      // Calculate time window in days
      final timeWindow = DateTime.now().difference(cutoff).inDays;
      if (timeWindow <= 0) return 0.0;

      // Count evolution indicators
      int evolutionIndicators = 0;

      // 1. Chat frequency (more chats = more learning opportunities)
      evolutionIndicators += min(10, recentChats.length);

      // 2. Learning insights count
      evolutionIndicators += min(10, learningInsights.length);

      // 3. Conversation depth (deeper conversations = more learning)
      final avgDepth = recentChats.isEmpty
          ? 0.0
          : recentChats
                  .map((c) => c.messages.length)
                  .reduce((a, b) => a + b) /
              recentChats.length;
      evolutionIndicators += (avgDepth / 5.0 * 5).round(); // Normalize to 0-5

      // 4. Insight quality (higher quality insights = better evolution)
      final avgInsightQuality = learningInsights.isEmpty
          ? 0.0
          : learningInsights
                  .map((i) => i.reliability)
                  .reduce((a, b) => a + b) /
              learningInsights.length;
      evolutionIndicators += (avgInsightQuality * 5).round();

      // Normalize to 0-1 scale (max indicators = 30)
      final normalizedRate = min(1.0, evolutionIndicators / 30.0 / timeWindow * 7.0); // Per week

      return normalizedRate;
    } catch (e) {
      developer.log('Error calculating personality evolution rate: $e',
          name: _logName);
      return 0.0;
    }
  }

  /// Measure knowledge acquisition speed
  Future<double> measureKnowledgeAcquisition(
    String userId,
    List<AI2AIChatEvent> recentChats,
    List<CrossPersonalityInsight> learningInsights,
  ) async {
    try {
      if (recentChats.isEmpty && learningInsights.isEmpty) return 0.0;

      // Calculate insights per conversation
      final insightsPerChat = recentChats.isEmpty
          ? 0.0
          : learningInsights.length / recentChats.length;

      // Calculate average conversation depth
      final avgDepth = recentChats.isEmpty
          ? 0.0
          : recentChats
                  .map((c) => c.messages.length)
                  .reduce((a, b) => a + b) /
              recentChats.length;

      // Knowledge acquisition combines insights rate and conversation depth
      final acquisitionScore = (insightsPerChat * 0.6 + min(1.0, avgDepth / 10.0) * 0.4);

      return acquisitionScore.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error measuring knowledge acquisition: $e', name: _logName);
      return 0.0;
    }
  }

  /// Assess insight quality
  Future<double> assessInsightQuality(
      List<CrossPersonalityInsight> insights) async {
    try {
      if (insights.isEmpty) return 0.0;

      // Calculate average reliability
      final avgReliability = insights
              .map((i) => i.reliability)
              .reduce((a, b) => a + b) /
          insights.length;

      // Factor in consistency (how many insights have high reliability)
      final highQualityCount = insights.where((i) => i.reliability >= 0.7).length;
      final consistencyScore = highQualityCount / insights.length;

      // Factor in diversity (variety of insight types)
      final uniqueTypes = insights.map((i) => i.type).toSet().length;
      final diversityScore = min(1.0, uniqueTypes / insights.length);

      // Weighted combination: reliability (50%), consistency (30%), diversity (20%)
      final qualityScore = (avgReliability * 0.5 +
              consistencyScore * 0.3 +
              diversityScore * 0.2)
          .clamp(0.0, 1.0);

      return qualityScore;
    } catch (e) {
      developer.log('Error assessing insight quality: $e', name: _logName);
      return 0.0;
    }
  }

  /// Calculate trust network growth
  Future<double> calculateTrustNetworkGrowth(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    // Simplified - would analyze actual network growth
    // For now, returns a score based on number of unique participants
    if (chats.isEmpty) return 0.0;

    final uniqueParticipants = chats
        .expand((c) => c.participants)
        .where((p) => p != userId)
        .toSet()
        .length;

    return min(1.0, uniqueParticipants / 10.0);
  }

  /// Measure collective contribution
  Future<double> measureCollectiveContribution(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    // Simplified - would measure actual contribution to collective knowledge
    // For now, returns a score based on participation
    if (chats.isEmpty) return 0.0;

    final totalMessages = chats.map((c) => c.messages.length).reduce((a, b) => a + b);
    final userMessages = chats
        .expand((c) => c.messages)
        .where((m) => m.senderId == userId)
        .length;

    final contributionRatio = totalMessages > 0 ? userMessages / totalMessages : 0.0;
    return contributionRatio.clamp(0.0, 1.0);
  }

  /// Calculate overall effectiveness from individual metrics
  double calculateOverallEffectiveness(
    double evolutionRate,
    double knowledgeAcquisition,
    double insightQuality,
    double trustNetworkGrowth,
  ) {
    // Weighted average of all metrics
    final overall = (evolutionRate * 0.3 +
            knowledgeAcquisition * 0.25 +
            insightQuality * 0.25 +
            trustNetworkGrowth * 0.2)
        .clamp(0.0, 1.0);

    return overall;
  }
}

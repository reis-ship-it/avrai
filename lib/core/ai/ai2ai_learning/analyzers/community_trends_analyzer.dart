import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai/core/ai/ai2ai_learning.dart';

/// Analyzes community-level trends from AI2AI conversations
class CommunityTrendsAnalyzer {
  static const String _logName = 'CommunityTrendsAnalyzer';

  /// Identify emerging patterns across conversations
  Future<List<EmergingPattern>> identifyEmergingPatterns(
      List<AI2AIChatEvent> chats) async {
    if (chats.length < 3) return [];

    final patterns = <String, int>{};

    // Count pattern occurrences
    for (final chat in chats) {
      // Pattern: frequent short messages
      if (chat.messages.length >= 5 && chat.duration.inMinutes < 10) {
        patterns['rapid_exchange'] = (patterns['rapid_exchange'] ?? 0) + 1;
      }

      // Pattern: deep conversations
      if (chat.messages.length >= 10) {
        patterns['deep_conversation'] = (patterns['deep_conversation'] ?? 0) + 1;
      }

      // Pattern: multi-participant
      if (chat.participants.length >= 3) {
        patterns['group_interaction'] = (patterns['group_interaction'] ?? 0) + 1;
      }
    }

    // Return patterns that appear in at least 30% of chats
    final threshold = (chats.length * 0.3).ceil();
    final result = patterns.entries
        .where((e) => e.value >= threshold)
        .map((e) => EmergingPattern(e.key, e.value / chats.length))
        .toList();

    developer.log('Identified ${result.length} emerging patterns',
        name: _logName);
    return result;
  }

  /// Analyze community-level trends
  Future<List<CommunityTrend>> analyzeCommunityTrends(
      List<AI2AIChatEvent> chats) async {
    if (chats.length < 5) return [];

    final trends = <CommunityTrend>[];

    // Analyze temporal trends
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Trend: Increasing conversation depth over time
    if (sortedChats.length >= 3) {
      final earlyDepth = sortedChats
              .take(sortedChats.length ~/ 3)
              .map((c) => c.messages.length)
              .reduce((a, b) => a + b) /
          (sortedChats.length ~/ 3);
      final lateDepth = sortedChats
              .skip(sortedChats.length * 2 ~/ 3)
              .map((c) => c.messages.length)
              .reduce((a, b) => a + b) /
          (sortedChats.length ~/ 3);

      if (lateDepth > earlyDepth * 1.2) {
        trends.add(CommunityTrend('increasing_conversation_depth', 1.0));
      } else if (lateDepth < earlyDepth * 0.8) {
        trends.add(CommunityTrend('decreasing_conversation_depth', -1.0));
      }
    }

    // Trend: Growing network size
    final avgParticipants = chats
            .map((c) => c.participants.length)
            .reduce((a, b) => a + b) /
        chats.length;
    if (avgParticipants >= 2.5) {
      trends.add(CommunityTrend('growing_network', 1.0));
    }

    developer.log('Analyzed ${trends.length} community trends', name: _logName);
    return trends;
  }

  // Note: analyzeCollaborativeActivity is complex and remains in main class
  // This method requires detailed analysis of planning keywords, list creation, etc.
  // Will be handled by orchestrator or kept in main class for now

  /// Calculate personality evolution rate based on chat activity
  Future<double> calculatePersonalityEvolutionRate(
    String userId,
    DateTime cutoff,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.isEmpty) return 0.0;

    // Filter chats after cutoff
    final recentChats =
        chats.where((c) => c.timestamp.isAfter(cutoff)).toList();

    if (recentChats.isEmpty) return 0.0;

    // Calculate evolution indicators
    final totalInteractions = recentChats.length;
    final totalMessages = recentChats
        .map((c) => c.messages.length)
        .reduce((a, b) => a + b);

    final daysSinceCutoff = DateTime.now().difference(cutoff).inDays;
    if (daysSinceCutoff == 0) return 0.0;

    // Evolution rate: interactions per day + messages per interaction
    final interactionRate = totalInteractions / daysSinceCutoff;
    final messageRate = totalMessages / totalInteractions;

    // Normalize to 0-1 scale
    final normalizedRate = min(1.0, (interactionRate * 0.5 + messageRate * 0.5));

    return normalizedRate;
  }
}

import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai/core/ai/ai2ai_learning.dart';

/// Detects emerging patterns across AI2AI conversations
class EmergingPatternsDetector {
  static const String _logName = 'EmergingPatternsDetector';

  /// Analyze interaction frequency patterns
  Future<CrossPersonalityLearningPattern?> analyzeInteractionFrequency(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 3) return null;

    // Calculate average time between interactions
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final intervals = <Duration>[];
    for (int i = 1; i < sortedChats.length; i++) {
      intervals
          .add(sortedChats[i].timestamp.difference(sortedChats[i - 1].timestamp));
    }

    if (intervals.isEmpty) return null;

    // Calculate average interval: sum all durations, then divide by count
    final totalDuration = intervals.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
    final avgInterval = Duration(
      microseconds: totalDuration.inMicroseconds ~/ intervals.length,
    );
    final frequencyScore =
        1.0 - min(1.0, avgInterval.inHours / 168.0); // Normalize to weekly

    return CrossPersonalityLearningPattern(
      patternType: 'interaction_frequency',
      characteristics: {
        'avg_interval_hours': avgInterval.inHours,
        'total_interactions': chats.length,
        'frequency_score': frequencyScore,
      },
      strength: frequencyScore,
      confidence: min(1.0, chats.length / 10.0),
      identified: DateTime.now(),
    );
  }

  /// Analyze compatibility evolution patterns
  Future<CrossPersonalityLearningPattern?> analyzeCompatibilityEvolution(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 3) return null;

    // Analyze if conversations are getting longer/deeper over time
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final earlyDepth = sortedChats
            .take(sortedChats.length ~/ 2)
            .map((c) => c.messages.length)
            .reduce((a, b) => a + b) /
        (sortedChats.length ~/ 2);
    final lateDepth = sortedChats
            .skip(sortedChats.length ~/ 2)
            .map((c) => c.messages.length)
            .reduce((a, b) => a + b) /
        (sortedChats.length ~/ 2);

    final evolutionScore = lateDepth > earlyDepth
        ? (lateDepth / earlyDepth - 1.0).clamp(0.0, 1.0)
        : 0.0;

    if (evolutionScore < 0.1) return null; // No significant evolution

    return CrossPersonalityLearningPattern(
      patternType: 'compatibility_evolution',
      characteristics: {
        'early_depth': earlyDepth,
        'late_depth': lateDepth,
        'evolution_rate': evolutionScore,
      },
      strength: evolutionScore,
      confidence: min(1.0, chats.length / 10.0),
      identified: DateTime.now(),
    );
  }

  /// Analyze knowledge sharing patterns
  Future<CrossPersonalityLearningPattern?> analyzeKnowledgeSharing(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.isEmpty) return null;

    // Count insights and learning opportunities
    int totalInsights = 0;
    for (final chat in chats) {
      // Estimate insights from message count and depth
      totalInsights += (chat.messages.length / 2).round();
    }

    final sharingScore = min(1.0, totalInsights / (chats.length * 3.0));

    if (sharingScore < 0.2) return null;

    return CrossPersonalityLearningPattern(
      patternType: 'knowledge_sharing',
      characteristics: {
        'total_insights': totalInsights,
        'avg_insights_per_chat': totalInsights / chats.length,
        'sharing_score': sharingScore,
      },
      strength: sharingScore,
      confidence: min(1.0, chats.length / 5.0),
      identified: DateTime.now(),
    );
  }

  /// Analyze trust building patterns
  Future<CrossPersonalityLearningPattern?> analyzeTrustBuilding(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 3) return null;

    // Trust building indicators: repeated interactions with same participants
    final participantCounts = <String, int>{};
    for (final chat in chats) {
      for (final participant in chat.participants) {
        if (participant != userId) {
          participantCounts[participant] = (participantCounts[participant] ?? 0) + 1;
        }
      }
    }

    final repeatedConnections =
        participantCounts.values.where((c) => c >= 2).length;
    final trustScore =
        min(1.0, repeatedConnections / max(1, participantCounts.length));

    if (trustScore < 0.3) return null;

    return CrossPersonalityLearningPattern(
      patternType: 'trust_building',
      characteristics: {
        'unique_participants': participantCounts.length,
        'repeated_connections': repeatedConnections,
        'trust_score': trustScore,
      },
      strength: trustScore,
      confidence: min(1.0, chats.length / 5.0),
      identified: DateTime.now(),
    );
  }

  /// Analyze learning acceleration patterns
  Future<CrossPersonalityLearningPattern?> analyzeLearningAcceleration(
    String userId,
    List<AI2AIChatEvent> chats,
  ) async {
    if (chats.length < 5) return null;

    // Check if learning rate is increasing over time
    final sortedChats = List<AI2AIChatEvent>.from(chats)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate learning indicators per time period
    final earlyPeriod = sortedChats.take(sortedChats.length ~/ 2);
    final latePeriod = sortedChats.skip(sortedChats.length ~/ 2);

    final earlyLearning = earlyPeriod
        .map((c) => c.messages.length * c.participants.length)
        .reduce((a, b) => a + b);
    final lateLearning = latePeriod
        .map((c) => c.messages.length * c.participants.length)
        .reduce((a, b) => a + b);

    final earlyTime = earlyPeriod.last.timestamp
        .difference(earlyPeriod.first.timestamp)
        .inDays;
    final lateTime =
        latePeriod.last.timestamp.difference(latePeriod.first.timestamp).inDays;

    if (earlyTime == 0 || lateTime == 0) return null;

    final earlyRate = earlyLearning / earlyTime;
    final lateRate = lateLearning / lateTime;

    final acceleration = lateRate > earlyRate
        ? ((lateRate / earlyRate - 1.0) / 2.0).clamp(0.0, 1.0)
        : 0.0;

    if (acceleration < 0.1) return null;

    return CrossPersonalityLearningPattern(
      patternType: 'learning_acceleration',
      characteristics: {
        'early_rate': earlyRate,
        'late_rate': lateRate,
        'acceleration_factor': acceleration,
      },
      strength: acceleration,
      confidence: min(1.0, chats.length / 10.0),
      identified: DateTime.now(),
    );
  }

  /// Extract all learning patterns from chat history
  Future<List<CrossPersonalityLearningPattern>> extractLearningPatterns(
    String userId,
    List<AI2AIChatEvent> recentChats,
  ) async {
    try {
      developer.log(
          'Extracting cross-personality learning patterns for: $userId',
          name: _logName);

      final patterns = <CrossPersonalityLearningPattern>[];

      // Analyze interaction frequency patterns
      final frequencyPattern =
          await analyzeInteractionFrequency(userId, recentChats);
      if (frequencyPattern != null) patterns.add(frequencyPattern);

      // Analyze compatibility evolution patterns
      final compatibilityPattern =
          await analyzeCompatibilityEvolution(userId, recentChats);
      if (compatibilityPattern != null) patterns.add(compatibilityPattern);

      // Analyze knowledge sharing patterns
      final sharingPattern = await analyzeKnowledgeSharing(userId, recentChats);
      if (sharingPattern != null) patterns.add(sharingPattern);

      // Analyze trust building patterns
      final trustPattern = await analyzeTrustBuilding(userId, recentChats);
      if (trustPattern != null) patterns.add(trustPattern);

      // Analyze learning acceleration patterns
      final accelerationPattern =
          await analyzeLearningAcceleration(userId, recentChats);
      if (accelerationPattern != null) patterns.add(accelerationPattern);

      developer.log('Extracted ${patterns.length} cross-personality learning patterns',
          name: _logName);
      return patterns;
    } catch (e) {
      developer.log('Error extracting learning patterns: $e', name: _logName);
      return [];
    }
  }
}

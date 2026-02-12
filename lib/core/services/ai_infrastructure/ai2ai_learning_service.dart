import 'dart:developer' as developer;
import 'dart:convert';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// AI2AI Learning Service
///
/// Phase 7, Week 38: Wrapper service for AI2AI learning methods UI
/// Provides simplified interface for UI components to access AI2AI learning data
class AI2AILearning {
  static const String _logName = 'AI2AILearning';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final AI2AIChatAnalyzer _chatAnalyzer;

  AI2AILearning({
    required AI2AIChatAnalyzer chatAnalyzer,
  }) : _chatAnalyzer = chatAnalyzer;

  /// Factory constructor to create service with dependencies
  factory AI2AILearning.create({
    required SharedPreferencesCompat prefs,
    required PersonalityLearning personalityLearning,
  }) {
    developer.log(
      'Creating AI2AILearning service',
      name: _logName,
    );
    final chatAnalyzer = AI2AIChatAnalyzer(
      prefs: prefs,
      personalityLearning: personalityLearning,
    );
    return AI2AILearning(chatAnalyzer: chatAnalyzer);
  }

  /// Get learning insights for a user
  /// Returns list of cross-personality insights
  Future<List<CrossPersonalityInsight>> getLearningInsights(
      String userId) async {
    try {
      developer.log(
        jsonEncode({
          'event': 'get_learning_insights_started',
          'userId': userId,
        }),
        name: _logName,
      );
      _logger.info('Getting learning insights for user: $userId',
          tag: _logName);

      // Get chat history to extract insights
      final chatHistory = await _chatAnalyzer.getChatHistoryForAdmin(userId);
      developer.log(
        jsonEncode({
          'event': 'chat_history_retrieved',
          'userId': userId,
          'chatHistoryCount': chatHistory.length,
        }),
        name: _logName,
      );

      // Extract learning patterns from chat history
      final learningPatterns =
          await _chatAnalyzer.extractLearningPatterns(userId, chatHistory);
      developer.log(
        jsonEncode({
          'event': 'learning_patterns_extracted',
          'userId': userId,
          'patternCount': learningPatterns.length,
        }),
        name: _logName,
      );

      // Convert patterns to insights
      final insights = <CrossPersonalityInsight>[];
      for (final pattern in learningPatterns) {
        insights.add(CrossPersonalityInsight(
          insight:
              '${pattern.patternType}: ${pattern.strength.toStringAsFixed(2)}',
          value: pattern.strength,
          reliability: pattern.confidence,
          type: pattern.patternType,
          timestamp: pattern.identified,
        ));
      }

      developer.log(
        jsonEncode({
          'event': 'get_learning_insights_completed',
          'userId': userId,
          'insightCount': insights.length,
        }),
        name: _logName,
      );
      _logger.info('Retrieved ${insights.length} learning insights',
          tag: _logName);
      return insights;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting learning insights: $userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get learning recommendations for a user
  /// Returns recommendations including optimal partners, topics, and development areas
  Future<AI2AILearningRecommendations> getLearningRecommendations(
      String userId) async {
    try {
      developer.log(
        jsonEncode({
          'event': 'get_learning_recommendations_started',
          'userId': userId,
        }),
        name: _logName,
      );
      _logger.info('Getting learning recommendations for user: $userId',
          tag: _logName);

      // Get current personality profile using PersonalityLearning service
      // Phase 8.3: Use agentId for privacy protection
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Try to get existing profile, otherwise create default
      // Note: We need access to PersonalityLearning, but it's encapsulated in _chatAnalyzer
      // For now, create a default profile with agentId
      final currentPersonality =
          PersonalityProfile.initial(agentId, userId: userId);

      final recommendations =
          await _chatAnalyzer.generateLearningRecommendations(
        userId,
        currentPersonality,
      );

      developer.log(
        jsonEncode({
          'event': 'get_learning_recommendations_completed',
          'userId': userId,
          'optimalPartnersCount': recommendations.optimalPartners.length,
          'topicsCount': recommendations.learningTopics.length,
          'developmentAreasCount': recommendations.developmentAreas.length,
        }),
        name: _logName,
      );
      _logger.info(
          'Retrieved learning recommendations: ${recommendations.optimalPartners.length} partners',
          tag: _logName);
      return recommendations;
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting learning recommendations: $userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return AI2AILearningRecommendations.empty(userId);
    }
  }

  /// Analyze learning effectiveness for a user
  /// Returns metrics about how effective AI2AI learning has been
  Future<LearningEffectivenessMetrics> analyzeLearningEffectiveness(
      String userId) async {
    try {
      developer.log(
        jsonEncode({
          'event': 'analyze_learning_effectiveness_started',
          'userId': userId,
          'timeWindowDays': 30,
        }),
        name: _logName,
      );
      _logger.info('Analyzing learning effectiveness for user: $userId',
          tag: _logName);

      // Use 30-day time window for effectiveness analysis
      const timeWindow = Duration(days: 30);

      final metrics = await _chatAnalyzer.measureLearningEffectiveness(
        userId,
        timeWindow,
      );

      developer.log(
        jsonEncode({
          'event': 'analyze_learning_effectiveness_completed',
          'userId': userId,
          'overallEffectiveness': metrics.overallEffectiveness,
          'totalInteractions': metrics.totalInteractions,
          'knowledgeAcquisition': metrics.knowledgeAcquisition,
        }),
        name: _logName,
      );
      _logger.info(
          'Learning effectiveness: ${(metrics.overallEffectiveness * 100).round()}%',
          tag: _logName);
      return metrics;
    } catch (e, stackTrace) {
      _logger.error(
        'Error analyzing learning effectiveness: $userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return LearningEffectivenessMetrics.zero(
          userId, const Duration(days: 30));
    }
  }

  /// Get chat history for admin access
  /// Returns all chat events for a given user
  Future<List<AI2AIChatEvent>> getChatHistoryForAdmin(String userId) async {
    try {
      developer.log(
        jsonEncode({
          'event': 'get_chat_history_started',
          'userId': userId,
        }),
        name: _logName,
      );
      final chatHistory = await _chatAnalyzer.getChatHistoryForAdmin(userId);
      developer.log(
        jsonEncode({
          'event': 'get_chat_history_completed',
          'userId': userId,
          'chatHistoryCount': chatHistory.length,
        }),
        name: _logName,
      );
      return chatHistory;
    } catch (e, stackTrace) {
      developer.log(
        jsonEncode({
          'event': 'get_chat_history_error',
          'userId': userId,
          'error': e.toString(),
        }),
        name: _logName,
      );
      _logger.error(
        'Error getting chat history: $userId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return [];
    }
  }
}

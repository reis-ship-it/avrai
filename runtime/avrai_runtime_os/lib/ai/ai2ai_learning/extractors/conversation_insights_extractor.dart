import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai_core/models/quantum/connection_metrics.dart'
    hide SharedInsight, ChatMessage;
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning/utils/ai2ai_learning_utils.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning/validators/ai2ai_data_validator.dart';

/// Extracts insights from AI2AI conversations
class ConversationInsightsExtractor {
  static const String _logName = 'ConversationInsightsExtractor';

  /// Analyze conversation patterns from chat event and history
  Future<ConversationPatterns> analyzeConversationPatterns(
    String userId,
    AI2AIChatEvent chatEvent,
    List<AI2AIChatEvent> chatHistory,
  ) async {
    // Analyze message exchange patterns
    final exchangeFrequency = _analyzeExchangeFrequency(chatHistory);
    final responseLatency = _analyzeResponseLatency(chatHistory);
    final conversationDepth = _analyzeConversationDepth(chatEvent);
    final topicConsistency = _analyzeTopicConsistency(chatHistory);

    return ConversationPatterns(
      exchangeFrequency: exchangeFrequency,
      responseLatency: responseLatency,
      conversationDepth: conversationDepth,
      topicConsistency: topicConsistency,
      patternStrength: AI2AILearningUtils.calculatePatternStrength(
          exchangeFrequency, topicConsistency),
    );
  }

  /// Extract shared insights from chat event
  Future<List<SharedInsight>> extractSharedInsights(
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) async {
    final insights = <SharedInsight>[];

    // Extract insights from message content and context
    for (final message in chatEvent.messages) {
      // Analyze dimension-related insights
      final dimensionInsights = await extractDimensionInsights(message);
      insights.addAll(dimensionInsights);

      // Analyze preference sharing insights
      final preferenceInsights = await extractPreferenceInsights(message);
      insights.addAll(preferenceInsights);

      // Analyze experience sharing insights
      final experienceInsights = await extractExperienceInsights(message);
      insights.addAll(experienceInsights);
    }

    // Validate insights against connection context
    final validatedInsights =
        await AI2AIDataValidator.validateInsights(insights, connectionContext);

    developer.log('Extracted ${validatedInsights.length} shared insights',
        name: _logName);
    return validatedInsights;
  }

  /// Extract dimension-related insights from chat message
  Future<List<SharedInsight>> extractDimensionInsights(
      ChatMessage message) async {
    final insights = <SharedInsight>[];
    final content = message.content.toLowerCase();

    // Map keywords to dimensions
    final dimensionKeywords = {
      'exploration_eagerness': [
        'explore',
        'adventure',
        'new',
        'discover',
        'try',
        'visit',
        'check out'
      ],
      'community_orientation': [
        'together',
        'group',
        'friends',
        'community',
        'share',
        'we',
        'us'
      ],
      'authenticity_preference': [
        'authentic',
        'local',
        'hidden',
        'gem',
        'secret',
        'real',
        'genuine'
      ],
      'social_discovery_style': [
        'social',
        'meet',
        'hangout',
        'connect',
        'network'
      ],
      'temporal_flexibility': [
        'spontaneous',
        'spur',
        'moment',
        'now',
        'flexible',
        'anytime'
      ],
      'location_adventurousness': [
        'far',
        'travel',
        'distant',
        'road trip',
        'journey',
        'explore'
      ],
      'curation_tendency': [
        'curate',
        'list',
        'recommend',
        'suggest',
        'favorite',
        'best'
      ],
      'trust_network_reliance': [
        'trust',
        'friend',
        'recommended',
        'suggested',
        'heard'
      ],
    };

    // Check for dimension keywords in message
    for (final entry in dimensionKeywords.entries) {
      final dimension = entry.key;
      final keywords = entry.value;

      int matches = 0;
      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          matches++;
        }
      }

      if (matches > 0) {
        // Calculate value based on keyword frequency
        final value = min(1.0, (matches / keywords.length) * 0.8 + 0.2);
        final reliability =
            min(1.0, matches / 3.0); // More matches = more reliable

        insights.add(SharedInsight(
          category: 'dimension_evolution',
          dimension: dimension,
          value: value,
          description:
              'Dimension insight from message: ${message.content.substring(0, min(50, message.content.length))}...',
          reliability: reliability,
          timestamp: message.timestamp,
        ));
      }
    }

    return insights;
  }

  /// Extract preference-related insights from chat message
  Future<List<SharedInsight>> extractPreferenceInsights(
      ChatMessage message) async {
    final insights = <SharedInsight>[];
    final content = message.content.toLowerCase();

    // Look for preference indicators
    final preferencePatterns = {
      'like': ['like', 'love', 'enjoy', 'prefer', 'favorite'],
      'dislike': ['dislike', 'hate', 'avoid', 'not my thing', "don't like"],
      'want': ['want', 'wish', 'hope', 'looking for', 'seeking'],
      'need': ['need', 'require', 'must have', 'essential'],
    };

    for (final entry in preferencePatterns.entries) {
      final preferenceType = entry.key;
      final keywords = entry.value;

      bool found = false;
      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          found = true;
          break;
        }
      }

      if (found) {
        // Extract what they're referring to (simplified - in production would use NLP)
        final value =
            preferenceType == 'like' || preferenceType == 'want' ? 0.8 : 0.2;

        insights.add(SharedInsight(
          category: 'preference_discovery',
          dimension: preferenceType,
          value: value,
          description:
              'Preference insight: $preferenceType mentioned in conversation',
          reliability: 0.6,
          timestamp: message.timestamp,
        ));
      }
    }

    return insights;
  }

  /// Extract experience-related insights from chat message
  Future<List<SharedInsight>> extractExperienceInsights(
      ChatMessage message) async {
    final insights = <SharedInsight>[];
    final content = message.content.toLowerCase();

    // Look for experience indicators
    final experienceKeywords = [
      'went',
      'visited',
      'tried',
      'experienced',
      'saw',
      'did',
      'learned',
      'discovered',
      'found',
      'realized',
      'noticed',
    ];

    bool hasExperience = false;
    for (final keyword in experienceKeywords) {
      if (content.contains(keyword)) {
        hasExperience = true;
        break;
      }
    }

    if (hasExperience) {
      // Extract experience type (simplified)
      String experienceType = 'general';
      if (content.contains('spot') ||
          content.contains('place') ||
          content.contains('location')) {
        experienceType = 'location_experience';
      } else if (content.contains('food') ||
          content.contains('eat') ||
          content.contains('drink')) {
        experienceType = 'food_experience';
      } else if (content.contains('activity') || content.contains('event')) {
        experienceType = 'activity_experience';
      }

      insights.add(SharedInsight(
        category: 'experience_sharing',
        dimension: experienceType,
        value: 0.7,
        description:
            'Experience shared: ${message.content.substring(0, min(60, message.content.length))}...',
        reliability: 0.7,
        timestamp: message.timestamp,
      ));
    }

    return insights;
  }

  /// Analyze exchange frequency from chat history
  double _analyzeExchangeFrequency(List<AI2AIChatEvent> history) =>
      min(1.0, history.length / 10.0);

  /// Analyze response latency from chat history
  double _analyzeResponseLatency(List<AI2AIChatEvent> history) {
    if (history.isEmpty) return 0.5; // Default for no history

    final latencies = <Duration>[];

    for (final event in history) {
      if (event.messages.length < 2) continue;

      // Sort messages by timestamp
      final sortedMessages = List<ChatMessage>.from(event.messages)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Calculate time between consecutive messages
      for (int i = 1; i < sortedMessages.length; i++) {
        final current = sortedMessages[i];
        final previous = sortedMessages[i - 1];
        final latency = current.timestamp.difference(previous.timestamp);
        if (latency.inSeconds > 0 && latency.inHours < 24) {
          // Only count reasonable latencies (not same sender, not too long)
          if (current.senderId != previous.senderId) {
            latencies.add(latency);
          }
        }
      }
    }

    if (latencies.isEmpty) return 0.5; // Default if no valid latencies

    // Calculate average latency in seconds
    final avgLatencySeconds =
        latencies.map((d) => d.inSeconds).reduce((a, b) => a + b) /
            latencies.length;

    // Normalize: faster responses = higher score
    // Target: < 60 seconds = excellent (1.0), > 300 seconds = poor (0.0)
    final normalizedScore = 1.0 - min(1.0, avgLatencySeconds / 300.0);
    return normalizedScore.clamp(0.0, 1.0);
  }

  /// Analyze conversation depth from event
  double _analyzeConversationDepth(AI2AIChatEvent event) =>
      min(1.0, event.messages.length / 5.0);

  /// Analyze topic consistency across conversation history
  double _analyzeTopicConsistency(List<AI2AIChatEvent> history) {
    if (history.isEmpty) return 0.5; // Default for no history

    // Extract topics from message content
    final allTopics = <String>[];
    for (final event in history) {
      for (final message in event.messages) {
        // Simple keyword extraction (in production, could use NLP)
        final content = message.content.toLowerCase();
        final words = content.split(RegExp(r'\s+'));

        // Extract meaningful words (length > 3, not common stop words)
        final stopWords = {
          'the',
          'and',
          'for',
          'are',
          'but',
          'not',
          'you',
          'all',
          'can',
          'her',
          'was',
          'one',
          'our',
          'out',
          'day',
          'get',
          'has',
          'him',
          'his',
          'how',
          'its',
          'may',
          'new',
          'now',
          'old',
          'see',
          'two',
          'who',
          'way',
          'use',
          'she',
          'man',
          'boy',
          'did',
          'let',
          'put',
          'say',
          'too'
        };

        for (final word in words) {
          final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
          if (cleaned.length > 3 && !stopWords.contains(cleaned)) {
            allTopics.add(cleaned);
          }
        }
      }
    }

    if (allTopics.isEmpty) return 0.5; // Default if no topics extracted

    // Count topic frequencies
    final topicFreq = <String, int>{};
    for (final topic in allTopics) {
      topicFreq[topic] = (topicFreq[topic] ?? 0) + 1;
    }

    // Calculate consistency: higher frequency topics = more consistent
    final totalTopics = allTopics.length;
    final uniqueTopics = topicFreq.length;

    if (uniqueTopics == 0) return 0.5;

    // Consistency score: fewer unique topics relative to total = more consistent
    // But also reward repeated topics
    final repetitionRatio = (totalTopics - uniqueTopics) / totalTopics;
    final diversityPenalty =
        min(1.0, uniqueTopics / 20.0); // Penalize too many unique topics

    final consistencyScore =
        (repetitionRatio * 0.7 + (1.0 - diversityPenalty) * 0.3)
            .clamp(0.0, 1.0);
    return consistencyScore;
  }
}

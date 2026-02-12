import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai/core/ai/ai2ai_learning.dart';

/// Builds consensus knowledge from aggregated insights
class ConsensusKnowledgeBuilder {
  static const String _logName = 'ConsensusKnowledgeBuilder';

  /// Aggregate insights from multiple conversations
  Future<List<SharedInsight>> aggregateConversationInsights(
      List<AI2AIChatEvent> chats) async {
    if (chats.isEmpty) return [];

    final aggregated = <String, SharedInsight>{};

    for (final chat in chats) {
      // Extract insights from messages
      for (final message in chat.messages) {
        // Simple keyword-based insight extraction
        final content = message.content.toLowerCase();

        // Look for dimension-related keywords
        final dimensionKeywords = {
          'adventure': 'adventure',
          'social': 'social',
          'relax': 'relaxation',
          'explore': 'exploration',
          'creative': 'creativity',
          'active': 'activity',
        };

        for (final entry in dimensionKeywords.entries) {
          if (content.contains(entry.key)) {
            final insightId = '${entry.value}_${chat.eventId}';
            if (!aggregated.containsKey(insightId)) {
              aggregated[insightId] = SharedInsight(
                category: 'dimension_evolution',
                dimension: entry.value,
                value: 0.6,
                description: 'Insight about ${entry.value} from conversation',
                reliability: 0.7,
                timestamp: message.timestamp,
              );
            }
          }
        }
      }
    }

    developer.log(
        'Aggregated ${aggregated.length} insights from ${chats.length} chats',
        name: _logName);
    return aggregated.values.toList();
  }

  /// Build consensus knowledge from aggregated insights
  Future<Map<String, dynamic>> buildConsensusKnowledge(
      List<SharedInsight> insights) async {
    if (insights.isEmpty) return {};

    final consensus = <String, dynamic>{};

    // Group insights by dimension
    final dimensionGroups = <String, List<SharedInsight>>{};
    for (final insight in insights) {
      final dim = insight.dimension;
      dimensionGroups.putIfAbsent(dim, () => []).add(insight);
    }

    // Calculate consensus values for each dimension
    for (final entry in dimensionGroups.entries) {
      final dimInsights = entry.value;
      if (dimInsights.length >= 2) {
        final avgValue = dimInsights.map((i) => i.value).reduce((a, b) => a + b) /
            dimInsights.length;
        final avgReliability = dimInsights
                .map((i) => i.reliability)
                .reduce((a, b) => a + b) /
            dimInsights.length;

        consensus[entry.key] = {
          'value': avgValue,
          'reliability': avgReliability,
          'supporting_insights': dimInsights.length,
        };
      }
    }

    developer.log(
        'Built consensus knowledge for ${consensus.length} dimensions',
        name: _logName);
    return consensus;
  }

  /// Calculate reliability scores for knowledge
  Future<Map<String, double>> calculateKnowledgeReliability(
    List<SharedInsight> insights,
    List<EmergingPattern> patterns,
  ) async {
    final reliability = <String, double>{};

    // Calculate reliability based on insight count and quality
    if (insights.isNotEmpty) {
      final avgReliability = insights
              .map((i) => i.reliability)
              .reduce((a, b) => a + b) /
          insights.length;
      reliability['insight_quality'] = avgReliability;
      reliability['insight_count'] = min(1.0, insights.length / 20.0);
    }

    // Calculate reliability based on pattern strength
    if (patterns.isNotEmpty) {
      final avgPatternStrength = patterns
              .map((p) => p.strength)
              .reduce((a, b) => a + b) /
          patterns.length;
      reliability['pattern_strength'] = avgPatternStrength;
    }

    developer.log(
        'Calculated reliability scores for ${reliability.length} metrics',
        name: _logName);
    return reliability;
  }
}

import 'dart:developer' as developer;
import 'dart:math';
import 'package:avrai_core/models/quantum/connection_metrics.dart'
    hide SharedInsight;
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';

/// Validates AI2AI learning data
class AI2AIDataValidator {
  static const String _logName = 'AI2AIDataValidator';

  /// Validate insights against connection context
  /// Filters and adjusts insights based on connection quality and reliability
  static Future<List<SharedInsight>> validateInsights(
    List<SharedInsight> insights,
    ConnectionMetrics context,
  ) async {
    final validated = <SharedInsight>[];

    for (final insight in insights) {
      // Only include insights with sufficient reliability
      if (insight.reliability >= 0.5) {
        // Boost reliability if connection context supports it
        double adjustedReliability = insight.reliability;

        // If connection has high compatibility, insights are more reliable
        if (context.currentCompatibility >= 0.7) {
          adjustedReliability = min(1.0, adjustedReliability + 0.1);
        }

        // If learning effectiveness is high, insights are more reliable
        if (context.learningEffectiveness >= 0.7) {
          adjustedReliability = min(1.0, adjustedReliability + 0.1);
        }

        validated.add(SharedInsight(
          category: insight.category,
          dimension: insight.dimension,
          value: insight.value,
          description: insight.description,
          reliability: adjustedReliability,
          timestamp: insight.timestamp,
        ));
      }
    }

    developer.log(
        'Validated ${validated.length} of ${insights.length} insights',
        name: _logName);
    return validated;
  }

  /// Validate chat event has required fields
  static bool validateChatEvent(AI2AIChatEvent chatEvent) {
    if (chatEvent.eventId.isEmpty) return false;
    if (chatEvent.participants.isEmpty) return false;
    if (chatEvent.messages.isEmpty) return false;
    return true;
  }

  /// Validate connection metrics
  static bool validateConnectionMetrics(ConnectionMetrics metrics) {
    // Current compatibility should be between 0 and 1
    if (metrics.currentCompatibility < 0.0 ||
        metrics.currentCompatibility > 1.0) {
      return false;
    }
    // Learning effectiveness should be between 0 and 1
    if (metrics.learningEffectiveness < 0.0 ||
        metrics.learningEffectiveness > 1.0) {
      return false;
    }
    return true;
  }
}

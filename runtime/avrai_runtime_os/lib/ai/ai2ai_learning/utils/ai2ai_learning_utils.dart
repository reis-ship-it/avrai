import 'dart:math';
import 'package:avrai_core/models/quantum/connection_metrics.dart'
    hide SharedInsight, ChatMessage;
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';

/// Shared utility functions for AI2AI learning
class AI2AILearningUtils {
  /// Calculate pattern strength from frequency and consistency
  static double calculatePatternStrength(
          double frequency, double consistency) =>
      (frequency + consistency) / 2.0;

  /// Calculate network effect based on participant count
  static double calculateNetworkEffect(int participantCount) =>
      min(1.0, participantCount / 5.0);

  /// Calculate knowledge synergy from insights
  static double calculateKnowledgeSynergy(List<SharedInsight> insights) =>
      min(1.0, insights.length / 10.0);

  /// Assess communication quality from messages
  static double assessCommunicationQuality(List<ChatMessage> messages) =>
      min(1.0, messages.length / 3.0);

  /// Calculate knowledge depth from insights
  static double calculateKnowledgeDepth(List<SharedInsight> insights) =>
      min(1.0, insights.length / 20.0);

  /// Calculate analysis confidence from chat event and connection context
  static double calculateAnalysisConfidence(
    AI2AIChatEvent chatEvent,
    ConnectionMetrics connectionContext,
  ) {
    var confidence = 0.5; // Base confidence

    // Increase confidence based on conversation depth
    confidence += min(0.2, chatEvent.messages.length / 10.0);

    // Increase confidence based on connection quality
    confidence += connectionContext.learningEffectiveness * 0.2;

    // Increase confidence based on compatibility
    confidence += connectionContext.currentCompatibility * 0.1;

    return confidence.clamp(0.0, 1.0);
  }
}

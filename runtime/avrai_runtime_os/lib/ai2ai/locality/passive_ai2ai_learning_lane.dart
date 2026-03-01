// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/locality/learning_insight_flow_gate.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';

class PassiveAi2AiLearningLane {
  const PassiveAi2AiLearningLane._();

  static Future<void> apply({
    required SharedPreferencesCompat prefs,
    required String prefsKeyAi2AiLearningEnabled,
    required PersonalityLearning? personalityLearning,
    required String userId,
    required PersonalityProfile localPersonality,
    required List<AIPersonalityNode> nodes,
    required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    required Map<String, DateTime> lastAi2AiLearningAtByPeerId,
    required Future<bool> Function({
      required String userId,
      required PersonalityLearning personalityLearning,
      required String peerId,
      required AI2AILearningInsight insight,
      required DateTime now,
      required String source,
      required String? insightId,
      required double learningQuality,
      required Map<String, double> deltas,
    }) applyInsightForPeer,
    required Future<void> Function({
      required String peerId,
      required AI2AILearningInsight insight,
      required double learningQuality,
    }) sendLearningInsightToPeer,
    required AppLogger logger,
    required String logName,
  }) async {
    final bool learningEnabled =
        prefs.getBool(prefsKeyAi2AiLearningEnabled) ?? true;
    if (!learningEnabled) return;
    if (personalityLearning == null) return;

    final DateTime now = DateTime.now();
    for (final AIPersonalityNode node in nodes) {
      if (LearningInsightFlowGate.isPeerLearningThrottled(
        lastAi2AiLearningAtByPeerId: lastAi2AiLearningAtByPeerId,
        peerId: node.nodeId,
        now: now,
      )) {
        continue;
      }

      final Map<String, double> remoteDims = node.vibe.anonymizedDimensions;
      final Map<String, double> localDims = localPersonality.dimensions;
      final Map<String, double> deltas = <String, double>{};

      for (final String dimension in VibeConstants.coreDimensions) {
        final double localValue =
            localDims[dimension] ?? VibeConstants.defaultDimensionValue;
        final double? remoteValue = remoteDims[dimension];
        if (remoteValue == null) continue;

        final double diff = remoteValue - localValue;
        if (diff.abs() < 0.22) continue;
        deltas[dimension] = diff;
      }
      if (deltas.isEmpty) continue;

      final VibeCompatibilityResult? compat =
          compatibilityByNodeId[node.nodeId];
      final double learningQuality = compat != null
          ? (compat.basicCompatibility * 0.6 + compat.aiPleasurePotential * 0.4)
              .clamp(0.0, 1.0)
          : 0.5;
      if (learningQuality < 0.65) continue;

      final AI2AILearningInsight insight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: deltas,
        learningQuality: learningQuality,
        timestamp: now,
      );

      try {
        final bool applied = await applyInsightForPeer(
          userId: userId,
          personalityLearning: personalityLearning,
          peerId: node.nodeId,
          insight: insight,
          now: now,
          source: 'passive',
          insightId: null,
          learningQuality: learningQuality,
          deltas: deltas,
        );
        if (!applied) continue;

        await sendLearningInsightToPeer(
          peerId: node.nodeId,
          insight: insight,
          learningQuality: learningQuality,
        );
      } catch (e) {
        logger.debug(
          'AI2AI passive learning skipped for ${node.nodeId}: $e',
          tag: logName,
        );
      }
    }
  }
}

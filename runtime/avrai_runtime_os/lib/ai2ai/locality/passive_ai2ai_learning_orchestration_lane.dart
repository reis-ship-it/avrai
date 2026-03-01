// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/locality/passive_ai2ai_learning_lane.dart';
import 'package:avrai_runtime_os/ai2ai/locality/learning_insight_peer_dispatch_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';

class PassiveAi2AiLearningOrchestrationLane {
  const PassiveAi2AiLearningOrchestrationLane._();

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
    required bool allowBleSideEffects,
    required bool eventModeEnabled,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? deviceDiscovery,
    required Map<String, String> peerNodeIdByDeviceId,
    required String localBleNodeId,
    required Future<void> Function(Map<String, dynamic> payload)
        enqueueFederatedDeltaForCloudFromInsightPayload,
    required AppLogger logger,
    required String logName,
  }) async {
    await PassiveAi2AiLearningLane.apply(
      prefs: prefs,
      prefsKeyAi2AiLearningEnabled: prefsKeyAi2AiLearningEnabled,
      personalityLearning: personalityLearning,
      userId: userId,
      localPersonality: localPersonality,
      nodes: nodes,
      compatibilityByNodeId: compatibilityByNodeId,
      lastAi2AiLearningAtByPeerId: lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: applyInsightForPeer,
      sendLearningInsightToPeer: ({
        required String peerId,
        required AI2AILearningInsight insight,
        required double learningQuality,
      }) async {
        await LearningInsightPeerDispatchLane.send(
          allowBleSideEffects: allowBleSideEffects,
          eventModeEnabled: eventModeEnabled,
          protocol: protocol,
          deviceDiscovery: deviceDiscovery,
          peerId: peerId,
          prefs: prefs,
          prefsKeyAi2AiLearningEnabled: prefsKeyAi2AiLearningEnabled,
          peerNodeIdByDeviceId: peerNodeIdByDeviceId,
          localBleNodeId: localBleNodeId,
          insight: insight,
          learningQuality: learningQuality,
          enqueueFederatedDeltaForCloudFromInsightPayload:
              enqueueFederatedDeltaForCloudFromInsightPayload,
          logger: logger,
          logName: logName,
        );
      },
      logger: logger,
      logName: logName,
    );
  }
}

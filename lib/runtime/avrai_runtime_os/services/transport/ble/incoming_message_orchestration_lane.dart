// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/core/ai2ai/chat/incoming_business_business_chat_lane.dart';
import 'package:avrai/core/ai2ai/chat/incoming_business_expert_chat_lane.dart';
import 'package:avrai/core/ai2ai/chat/incoming_user_chat_processing_lane.dart';
import 'package:avrai/core/ai2ai/locality/incoming_learning_insight_processing_lane.dart';
import 'package:avrai/core/ai2ai/locality/incoming_mesh_signal_handlers_lane.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_network/avra_network.dart';

class IncomingMessageOrchestrationLane {
  const IncomingMessageOrchestrationLane._();

  static Future<void> handleLearningInsight({
    required ProtocolMessage message,
    required SharedPreferencesCompat prefs,
    required String prefsKeyAi2AiLearningEnabled,
    required String? currentUserId,
    required PersonalityLearning? personalityLearning,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required Map<String, int> seenLearningInsightIds,
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
    })
        applyInsightForPeer,
    required Future<void> Function({
      required Map<String, dynamic> payload,
      required String originId,
      required int hop,
      required String receivedFromDeviceId,
    })
        maybeForwardLearningInsightGossip,
    required AppLogger logger,
    required String logName,
  }) {
    return IncomingLearningInsightProcessingLane.handle(
      message: message,
      prefs: prefs,
      prefsKeyAi2AiLearningEnabled: prefsKeyAi2AiLearningEnabled,
      currentUserId: currentUserId,
      personalityLearning: personalityLearning,
      adaptiveMeshService: adaptiveMeshService,
      seenLearningInsightIds: seenLearningInsightIds,
      lastAi2AiLearningAtByPeerId: lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: applyInsightForPeer,
      maybeForwardLearningInsightGossip: maybeForwardLearningInsightGossip,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> handleUserChat({
    required ProtocolMessage message,
    required AppLogger logger,
    required String logName,
  }) {
    return IncomingUserChatProcessingLane.handle(
      message: message,
      handleIncomingBusinessExpertChat: (_, payload) {
        return IncomingBusinessExpertChatLane.handle(
          payload: payload,
          logger: logger,
          logName: logName,
        );
      },
      handleIncomingBusinessBusinessChat: (_, payload) {
        return IncomingBusinessBusinessChatLane.handle(
          payload: payload,
          logger: logger,
          logName: logName,
        );
      },
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> handleLocalityAgentUpdate({
    required ProtocolMessage message,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required Future<void> Function({
      required Map<String, dynamic> payload,
      required String originId,
      required int hop,
      required String receivedFromDeviceId,
    })
        maybeForwardLocalityAgentUpdateGossip,
    required AppLogger logger,
    required String logName,
  }) {
    return IncomingMeshSignalHandlersLane.handleLocalityAgentUpdate(
      message: message,
      adaptiveMeshService: adaptiveMeshService,
      maybeForwardLocalityAgentUpdateGossip:
          maybeForwardLocalityAgentUpdateGossip,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> handleOrganicSpotDiscovery({
    required ProtocolMessage message,
    required String? currentUserId,
    required AppLogger logger,
    required String logName,
  }) {
    return IncomingMeshSignalHandlersLane.handleOrganicSpotDiscovery(
      message: message,
      currentUserId: currentUserId,
      logger: logger,
      logName: logName,
    );
  }
}

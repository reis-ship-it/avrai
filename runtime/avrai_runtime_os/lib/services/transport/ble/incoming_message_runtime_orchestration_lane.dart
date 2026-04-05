// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:async';

import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/incoming_message_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/ble_inbox_processing_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_inbound_decode_lane.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class IncomingMessageRuntimeOrchestrationLane {
  static Timer? startBleInboxProcessing({
    required bool allowBleSideEffects,
    required Timer? existingPoller,
    required MeshInboundDecodeLane inboundDecodeLane,
    required Map<String, int> seenBleMessageHashes,
    required SharedPreferencesCompat prefs,
    required String prefsKeyAi2AiLearningEnabled,
    required String? currentUserId,
    String? currentAgentId,
    Ai2AiChatEventIntakeService? ai2aiChatEventIntakeService,
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
    }) applyInsightForPeer,
    required bool federatedLearningParticipationEnabled,
    required String localNodeId,
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
    GovernedMeshPacketCodec? packetCodec,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    bool trustedAnnounceEnforcementEnabled = false,
    required Future<void> Function() persistSeenBleHashesIfNeeded,
    required Future<void> Function() persistSeenLearningInsightIdsIfNeeded,
    required AppLogger logger,
    required String logName,
  }) {
    return BleInboxProcessingOrchestrationLane.start(
      allowBleSideEffects: allowBleSideEffects,
      existingPoller: existingPoller,
      inboundDecodeLane: inboundDecodeLane,
      seenBleMessageHashes: seenBleMessageHashes,
      handleIncomingLocalityAgentUpdate: (message) {
        return IncomingMessageOrchestrationLane.handleLocalityAgentUpdate(
          message: message,
          adaptiveMeshService: adaptiveMeshService,
          maybeForwardLocalityAgentUpdateGossip: ({
            required Map<String, dynamic> payload,
            required String originId,
            required int hop,
            required String receivedFromDeviceId,
          }) async {
            await MeshForwardingOrchestrationLane
                .forwardLocalityAgentUpdateGossip(
              allowBleSideEffects: allowBleSideEffects,
              federatedLearningParticipationEnabled:
                  federatedLearningParticipationEnabled,
              originId: originId,
              localNodeId: localNodeId,
              payload: payload,
              hop: hop,
              receivedFromDeviceId: receivedFromDeviceId,
              adaptiveMeshService: adaptiveMeshService,
              bloomFilters: bloomFilters,
              logger: logger,
              logName: logName,
              discoveredNodes: discoveredNodes,
              packetCodec: packetCodec,
              discovery: discovery,
              peerNodeIdByDeviceId: peerNodeIdByDeviceId,
              governanceBindingService: governanceBindingService,
              localUserId: currentUserId,
              localAgentId: currentAgentId ?? localNodeId,
              trustedAnnounceEnforcementEnabled:
                  trustedAnnounceEnforcementEnabled,
            );
          },
          logger: logger,
          logName: logName,
        );
      },
      handleIncomingOrganicSpotDiscovery: (message) {
        return IncomingMessageOrchestrationLane.handleOrganicSpotDiscovery(
          message: message,
          currentUserId: currentUserId,
          logger: logger,
          logName: logName,
        );
      },
      handleIncomingLearningInsight: (message) {
        return IncomingMessageOrchestrationLane.handleLearningInsight(
          message: message,
          prefs: prefs,
          prefsKeyAi2AiLearningEnabled: prefsKeyAi2AiLearningEnabled,
          currentUserId: currentUserId,
          personalityLearning: personalityLearning,
          adaptiveMeshService: adaptiveMeshService,
          seenLearningInsightIds: seenLearningInsightIds,
          lastAi2AiLearningAtByPeerId: lastAi2AiLearningAtByPeerId,
          applyInsightForPeer: applyInsightForPeer,
          maybeForwardLearningInsightGossip: ({
            required Map<String, dynamic> payload,
            required String originId,
            required int hop,
            required String receivedFromDeviceId,
          }) async {
            await MeshForwardingOrchestrationLane.forwardLearningInsightGossip(
              allowBleSideEffects: allowBleSideEffects,
              federatedLearningParticipationEnabled:
                  federatedLearningParticipationEnabled,
              originId: originId,
              localNodeId: localNodeId,
              payload: payload,
              hop: hop,
              receivedFromDeviceId: receivedFromDeviceId,
              adaptiveMeshService: adaptiveMeshService,
              bloomFilters: bloomFilters,
              logger: logger,
              logName: logName,
              discoveredNodes: discoveredNodes,
              packetCodec: packetCodec,
              discovery: discovery,
              peerNodeIdByDeviceId: peerNodeIdByDeviceId,
              governanceBindingService: governanceBindingService,
              localUserId: currentUserId,
              localAgentId: currentAgentId ?? localNodeId,
              trustedAnnounceEnforcementEnabled:
                  trustedAnnounceEnforcementEnabled,
            );
          },
          logger: logger,
          logName: logName,
        );
      },
      handleIncomingUserChat: (message) {
        return IncomingMessageOrchestrationLane.handleUserChat(
          message: message,
          ai2aiChatEventIntakeService: ai2aiChatEventIntakeService,
          logger: logger,
          logName: logName,
        );
      },
      persistSeenBleHashesIfNeeded: persistSeenBleHashesIfNeeded,
      persistSeenLearningInsightIdsIfNeeded:
          persistSeenLearningInsightIdsIfNeeded,
      logger: logger,
      logName: logName,
    );
  }
}

import 'dart:async';

import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/incoming_message_runtime_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/federated_cloud_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/federated_cloud_sync_start_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_replay_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_inbound_decode_lane.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RuntimeServicesStartupOrchestrationLane {
  const RuntimeServicesStartupOrchestrationLane._();

  static bool isFederatedLearningParticipationEnabled({
    required SharedPreferencesCompat prefs,
    required String prefsKeyFederatedLearningParticipation,
  }) {
    return FederatedCloudOrchestrationLane.isParticipationEnabled(
      prefs: prefs,
      prefsKeyFederatedLearningParticipation:
          prefsKeyFederatedLearningParticipation,
    );
  }

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
    return IncomingMessageRuntimeOrchestrationLane.startBleInboxProcessing(
      allowBleSideEffects: allowBleSideEffects,
      existingPoller: existingPoller,
      inboundDecodeLane: inboundDecodeLane,
      seenBleMessageHashes: seenBleMessageHashes,
      prefs: prefs,
      prefsKeyAi2AiLearningEnabled: prefsKeyAi2AiLearningEnabled,
      currentUserId: currentUserId,
      currentAgentId: currentAgentId,
      ai2aiChatEventIntakeService: ai2aiChatEventIntakeService,
      personalityLearning: personalityLearning,
      adaptiveMeshService: adaptiveMeshService,
      seenLearningInsightIds: seenLearningInsightIds,
      lastAi2AiLearningAtByPeerId: lastAi2AiLearningAtByPeerId,
      applyInsightForPeer: applyInsightForPeer,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      localNodeId: localNodeId,
      bloomFilters: bloomFilters,
      discoveredNodes: discoveredNodes,
      discovery: discovery,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      packetCodec: packetCodec,
      governanceBindingService: governanceBindingService,
      trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
      persistSeenBleHashesIfNeeded: persistSeenBleHashesIfNeeded,
      persistSeenLearningInsightIdsIfNeeded:
          persistSeenLearningInsightIdsIfNeeded,
      logger: logger,
      logName: logName,
    );
  }

  static Timer? startMeshCustodyReplay({
    required bool allowBleSideEffects,
    required Timer? existingPoller,
    required DeviceDiscoveryService? discovery,
    GovernedMeshPacketCodec? packetCodec,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
    required AppLogger logger,
    required String logName,
    Duration interval = const Duration(seconds: 15),
  }) {
    existingPoller?.cancel();

    if (!allowBleSideEffects || discovery == null) {
      return null;
    }

    var replayInFlight = false;

    Future<void> replayOnce() async {
      if (replayInFlight) {
        return;
      }
      replayInFlight = true;
      try {
        final context = MeshForwardingContext.tryCreate(
          discovery: discovery,
          packetCodec: packetCodec,
          governanceBindingService: governanceBindingService,
          localUserId: localUserId,
          localAgentId: localAgentId,
          privacyMode: privacyMode,
          reticulumTransportControlPlaneEnabled:
              reticulumTransportControlPlaneEnabled,
          trustedAnnounceEnforcementEnabled:
              trustedAnnounceEnforcementEnabled,
        );
        if (context == null) {
          return;
        }

        if (reticulumTransportControlPlaneEnabled) {
          final recovered = await MeshCustodyReplayLane.replayForRecoveredReachability(
            context: context,
            discoveredNodeIds: discoveredNodes.values.map((node) => node.nodeId),
            localNodeId: localNodeId,
            peerNodeIdByDeviceId: peerNodeIdByDeviceId,
            logger: logger,
            logName: logName,
          );
          if (recovered > 0) {
            logger.debug(
              'Released $recovered mesh custody entries after reachability recovery',
              tag: logName,
            );
          }
        }

        final replayed = await MeshCustodyReplayLane.replayDueEntries(
          context: context,
          discoveredNodeIds: discoveredNodes.values.map((node) => node.nodeId),
          localNodeId: localNodeId,
          peerNodeIdByDeviceId: peerNodeIdByDeviceId,
          logger: logger,
          logName: logName,
        );
        if (replayed > 0) {
          logger.debug(
            'Released $replayed mesh custody entries from deferred outbox',
            tag: logName,
          );
        }
      } catch (e) {
        logger.debug('Mesh custody replay tick failed: $e', tag: logName);
      } finally {
        replayInFlight = false;
      }
    }

    final poller = Timer.periodic(interval, (_) {
      unawaited(replayOnce());
    });
    unawaited(replayOnce());
    return poller;
  }

  static Future<FederatedCloudSyncStartResult> startFederatedCloudSync({
    required bool isTestBinding,
    required Connectivity connectivity,
    required Future<void> Function() syncFederatedCloudQueue,
    required Timer? existingTimer,
    required StreamSubscription<List<ConnectivityResult>>? existingSubscription,
    required AppLogger logger,
    required String logName,
  }) {
    return FederatedCloudOrchestrationLane.startSync(
      isTestBinding: isTestBinding,
      connectivity: connectivity,
      syncFederatedCloudQueue: syncFederatedCloudQueue,
      existingTimer: existingTimer,
      existingSubscription: existingSubscription,
      logger: logger,
      logName: logName,
    );
  }
}

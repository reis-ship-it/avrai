import 'dart:async';

import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/services/transport/ble/incoming_message_runtime_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/federated_cloud_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/federated_cloud_sync_start_lane.dart';
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
    required AI2AIProtocol? protocol,
    required Map<String, int> seenBleMessageHashes,
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
    }) applyInsightForPeer,
    required bool federatedLearningParticipationEnabled,
    required String localNodeId,
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
    required Future<void> Function() persistSeenBleHashesIfNeeded,
    required Future<void> Function() persistSeenLearningInsightIdsIfNeeded,
    required AppLogger logger,
    required String logName,
  }) {
    return IncomingMessageRuntimeOrchestrationLane.startBleInboxProcessing(
      allowBleSideEffects: allowBleSideEffects,
      existingPoller: existingPoller,
      protocol: protocol,
      seenBleMessageHashes: seenBleMessageHashes,
      prefs: prefs,
      prefsKeyAi2AiLearningEnabled: prefsKeyAi2AiLearningEnabled,
      currentUserId: currentUserId,
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
      persistSeenBleHashesIfNeeded: persistSeenBleHashesIfNeeded,
      persistSeenLearningInsightIdsIfNeeded:
          persistSeenLearningInsightIdsIfNeeded,
      logger: logger,
      logName: logName,
    );
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

import 'dart:async';

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/ble/ble_inbox_processing_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_inbound_decode_lane.dart';

class BleInboxProcessingOrchestrationLane {
  const BleInboxProcessingOrchestrationLane._();

  static Timer? start({
    required bool allowBleSideEffects,
    required Timer? existingPoller,
    required MeshInboundDecodeLane inboundDecodeLane,
    required Map<String, int> seenBleMessageHashes,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingLocalityAgentUpdate,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingOrganicSpotDiscovery,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingLearningInsight,
    required Future<void> Function(ProtocolMessage decoded)
        handleIncomingUserChat,
    required Future<void> Function() persistSeenBleHashesIfNeeded,
    required Future<void> Function() persistSeenLearningInsightIdsIfNeeded,
    required AppLogger logger,
    required String logName,
  }) {
    if (!allowBleSideEffects) return existingPoller;
    existingPoller?.cancel();
    return BleInboxProcessingLane.start(
      inboundDecodeLane: inboundDecodeLane,
      seenBleMessageHashes: seenBleMessageHashes,
      handleIncomingLocalityAgentUpdate: handleIncomingLocalityAgentUpdate,
      handleIncomingOrganicSpotDiscovery: handleIncomingOrganicSpotDiscovery,
      handleIncomingLearningInsight: handleIncomingLearningInsight,
      handleIncomingUserChat: handleIncomingUserChat,
      persistSeenBleHashesIfNeeded: persistSeenBleHashesIfNeeded,
      persistSeenLearningInsightIdsIfNeeded:
          persistSeenLearningInsightIdsIfNeeded,
      logger: logger,
      logName: logName,
    );
  }
}

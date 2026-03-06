// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_orchestration_lane.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class MeshPublicForwardingOrchestrationLane {
  const MeshPublicForwardingOrchestrationLane._();

  static Future<void> forwardOrganicSpotDiscovery({
    required Map<String, dynamic> signal,
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
  }) {
    return MeshForwardingOrchestrationLane.forwardOrganicSpotDiscovery(
      signal: signal,
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      protocol: protocol,
      discovery: discovery,
      discoveredNodes: discoveredNodes,
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> forwardLocalityAgentUpdate({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required String localNodeId,
    required Map<String, dynamic> message,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
  }) {
    return MeshForwardingOrchestrationLane.forwardLocalityAgentUpdate(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      localNodeId: localNodeId,
      message: message,
      adaptiveMeshService: adaptiveMeshService,
      bloomFilters: bloomFilters,
      protocol: protocol,
      discovery: discovery,
      discoveredNodes: discoveredNodes,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      logger: logger,
      logName: logName,
    );
  }
}

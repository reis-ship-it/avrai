import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_outbound_forwarding_lane.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class MeshForwardingOrchestrationLane {
  const MeshForwardingOrchestrationLane._();

  static Future<void> forwardLearningInsightGossip({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required String originId,
    required String localNodeId,
    required Map<String, dynamic> payload,
    required int hop,
    required String receivedFromDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required OptimizedBloomFilter Function(String scope) getOrCreateBloomFilter,
    required AppLogger logger,
    required String logName,
    required Iterable<String> discoveredNodeIds,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
  }) {
    return MeshOutboundForwardingLane.forwardLearningInsightGossip(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      originId: originId,
      localNodeId: localNodeId,
      payload: payload,
      hop: hop,
      receivedFromDeviceId: receivedFromDeviceId,
      adaptiveMeshService: adaptiveMeshService,
      getOrCreateBloomFilter: getOrCreateBloomFilter,
      logger: logger,
      logName: logName,
      discoveredNodeIds: discoveredNodeIds,
      protocol: protocol,
      discovery: discovery,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
    );
  }

  static Future<void> forwardOrganicSpotDiscovery({
    required Map<String, dynamic> signal,
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required MeshForwardingContext? Function() tryCreateMeshForwardingContext,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
  }) {
    return MeshOutboundForwardingLane.forwardOrganicSpotDiscovery(
      signal: signal,
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      tryCreateMeshForwardingContext: tryCreateMeshForwardingContext,
      discoveredNodeIds: discoveredNodeIds,
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
    required OptimizedBloomFilter Function(String scope) getOrCreateBloomFilter,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
    required Iterable<String> discoveredNodeIds,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
  }) {
    return MeshOutboundForwardingLane.forwardLocalityAgentUpdate(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      localNodeId: localNodeId,
      message: message,
      adaptiveMeshService: adaptiveMeshService,
      getOrCreateBloomFilter: getOrCreateBloomFilter,
      protocol: protocol,
      discovery: discovery,
      discoveredNodeIds: discoveredNodeIds,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> forwardLocalityAgentUpdateGossip({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required String originId,
    required String localNodeId,
    required Map<String, dynamic> payload,
    required int hop,
    required String receivedFromDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required OptimizedBloomFilter Function(String scope) getOrCreateBloomFilter,
    required AppLogger logger,
    required String logName,
    required Iterable<String> discoveredNodeIds,
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
  }) {
    return MeshOutboundForwardingLane.forwardLocalityAgentUpdateGossip(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      originId: originId,
      localNodeId: localNodeId,
      payload: payload,
      hop: hop,
      receivedFromDeviceId: receivedFromDeviceId,
      adaptiveMeshService: adaptiveMeshService,
      getOrCreateBloomFilter: getOrCreateBloomFilter,
      logger: logger,
      logName: logName,
      discoveredNodeIds: discoveredNodeIds,
      protocol: protocol,
      discovery: discovery,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
    );
  }
}

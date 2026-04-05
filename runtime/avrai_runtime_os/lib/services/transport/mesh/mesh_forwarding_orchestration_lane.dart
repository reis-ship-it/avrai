import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_outbound_forwarding_lane.dart';
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
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required AppLogger logger,
    required String logName,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
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
      getOrCreateBloomFilter: (scope) {
        return MeshForwardingContextOrchestrationLane.getOrCreateBloomFilter(
          bloomFilters: bloomFilters,
          scope: scope,
        );
      },
      logger: logger,
      logName: logName,
      discoveredNodeIds:
          MeshForwardingContextOrchestrationLane.discoveredNodeIds(
              discoveredNodes: discoveredNodes),
      packetCodec: packetCodec,
      discovery: discovery,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      governanceBindingService: governanceBindingService,
      localUserId: localUserId,
      localAgentId: localAgentId,
      privacyMode: privacyMode,
      reticulumTransportControlPlaneEnabled:
          reticulumTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
    );
  }

  static Future<void> forwardOrganicSpotDiscovery({
    required Map<String, dynamic> signal,
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
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
  }) {
    return MeshOutboundForwardingLane.forwardOrganicSpotDiscovery(
      signal: signal,
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      tryCreateMeshForwardingContext: () {
        return MeshForwardingContextOrchestrationLane.tryCreate(
          packetCodec: packetCodec,
          discovery: discovery,
          governanceBindingService: governanceBindingService,
          localUserId: localUserId,
          localAgentId: localAgentId,
          privacyMode: privacyMode,
          reticulumTransportControlPlaneEnabled:
              reticulumTransportControlPlaneEnabled,
          trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
        );
      },
      discoveredNodeIds:
          MeshForwardingContextOrchestrationLane.discoveredNodeIds(
              discoveredNodes: discoveredNodes),
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
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
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
      getOrCreateBloomFilter: (scope) {
        return MeshForwardingContextOrchestrationLane.getOrCreateBloomFilter(
          bloomFilters: bloomFilters,
          scope: scope,
        );
      },
      packetCodec: packetCodec,
      discovery: discovery,
      discoveredNodeIds:
          MeshForwardingContextOrchestrationLane.discoveredNodeIds(
              discoveredNodes: discoveredNodes),
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      governanceBindingService: governanceBindingService,
      localUserId: localUserId,
      localAgentId: localAgentId,
      privacyMode: privacyMode,
      reticulumTransportControlPlaneEnabled:
          reticulumTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
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
    required Map<String, OptimizedBloomFilter> bloomFilters,
    required AppLogger logger,
    required String logName,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
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
      getOrCreateBloomFilter: (scope) {
        return MeshForwardingContextOrchestrationLane.getOrCreateBloomFilter(
          bloomFilters: bloomFilters,
          scope: scope,
        );
      },
      logger: logger,
      logName: logName,
      discoveredNodeIds:
          MeshForwardingContextOrchestrationLane.discoveredNodeIds(
              discoveredNodes: discoveredNodes),
      packetCodec: packetCodec,
      discovery: discovery,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      governanceBindingService: governanceBindingService,
      localUserId: localUserId,
      localAgentId: localAgentId,
      privacyMode: privacyMode,
      reticulumTransportControlPlaneEnabled:
          reticulumTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled: trustedAnnounceEnforcementEnabled,
    );
  }
}

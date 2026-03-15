import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class MeshPublicForwardingOrchestrationLane {
  const MeshPublicForwardingOrchestrationLane._();

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
    return MeshForwardingOrchestrationLane.forwardOrganicSpotDiscovery(
      signal: signal,
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      packetCodec: packetCodec,
      discovery: discovery,
      discoveredNodes: discoveredNodes,
      localNodeId: localNodeId,
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
    return MeshForwardingOrchestrationLane.forwardLocalityAgentUpdate(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      localNodeId: localNodeId,
      message: message,
      adaptiveMeshService: adaptiveMeshService,
      bloomFilters: bloomFilters,
      packetCodec: packetCodec,
      discovery: discovery,
      discoveredNodes: discoveredNodes,
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
}

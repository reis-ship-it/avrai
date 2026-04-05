// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/federated_forwarding_guard.dart';
import 'package:avrai_runtime_os/services/transport/mesh/federated_gossip_forwarding_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/locality_agent_update_mesh_forwarding_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/organic_spot_discovery_forwarding_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class MeshOutboundForwardingLane {
  const MeshOutboundForwardingLane._();

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
  }) async {
    if (!FederatedForwardingGuard.isEnabled(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
    )) {
      return;
    }

    final MeshForwardingContext? forwardingContext =
        tryCreateMeshForwardingContext();
    if (forwardingContext == null) return;

    await OrganicSpotDiscoveryForwardingLane.forward(
      signal: signal,
      discoveredNodeIds: discoveredNodeIds,
      context: forwardingContext,
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      logger: logger,
      logName: logName,
      maxCandidates: 2,
    );
  }

  static Future<void> forwardLocalityAgentUpdate({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required String localNodeId,
    required Map<String, dynamic> message,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required OptimizedBloomFilter Function(String scope) getOrCreateBloomFilter,
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required Iterable<String> discoveredNodeIds,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
    required AppLogger logger,
    required String logName,
  }) async {
    await LocalityAgentUpdateMeshForwardingLane.forward(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      localNodeId: localNodeId,
      message: message,
      adaptiveMeshService: adaptiveMeshService,
      getOrCreateBloomFilter: getOrCreateBloomFilter,
      packetCodec: packetCodec,
      discovery: discovery,
      discoveredNodeIds: discoveredNodeIds,
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
      maxCandidates: 2,
    );
  }

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
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
  }) async {
    await FederatedGossipForwardingLane.forward(
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
      priority: mesh_policy.MessagePriority.medium,
      messageType: mesh_policy.MessageType.learningInsight,
      fallbackMaxHopExclusive: 1,
      discoveredNodeIds: discoveredNodeIds,
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
      failureLabel: 'Learning insight gossip forward failed',
      maxCandidates: 2,
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
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required Map<String, String> peerNodeIdByDeviceId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
  }) async {
    await FederatedGossipForwardingLane.forward(
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
      priority: mesh_policy.MessagePriority.high,
      messageType: mesh_policy.MessageType.localityAgentUpdate,
      fallbackMaxHopExclusive: 2,
      duplicateLabel: 'locality agent update',
      discoveredNodeIds: discoveredNodeIds,
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
      failureLabel: 'Locality agent update gossip forward failed',
      maxCandidates: 2,
    );
  }
}

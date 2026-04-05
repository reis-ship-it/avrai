// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/federated_gossip_forwarding_gate.dart';
import 'package:avrai_runtime_os/services/transport/mesh/gossip_learning_forwarding_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/federated_forwarding_precheck.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class FederatedGossipForwardingLane {
  const FederatedGossipForwardingLane._();

  static Future<void> forward({
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
    required mesh_policy.MessagePriority priority,
    required mesh_policy.MessageType messageType,
    int? fallbackMaxHopExclusive,
    String duplicateLabel = 'message',
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
    required String failureLabel,
    int maxCandidates = 2,
  }) async {
    if (!FederatedForwardingPrecheck.allow(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      originId: originId,
      localNodeId: localNodeId,
    )) {
      return;
    }

    if (!FederatedGossipForwardingGate.allow(
      payload: payload,
      hop: hop,
      adaptiveMeshService: adaptiveMeshService,
      getOrCreateBloomFilter: getOrCreateBloomFilter,
      logger: logger,
      logName: logName,
      priority: priority,
      messageType: messageType,
      fallbackMaxHopExclusive: fallbackMaxHopExclusive,
      duplicateLabel: duplicateLabel,
    )) {
      return;
    }

    final forwardingContext = MeshForwardingContext.tryCreate(
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
    if (forwardingContext == null) return;

    await GossipLearningForwardingLane.forward(
      payload: payload,
      hop: hop,
      originId: originId,
      receivedFromDeviceId: receivedFromDeviceId,
      discoveredNodeIds: discoveredNodeIds,
      context: forwardingContext,
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      logger: logger,
      logName: logName,
      failureLabel: failureLabel,
      maxCandidates: maxCandidates,
    );
  }
}

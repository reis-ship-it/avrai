import 'package:avrai/core/ai2ai/adaptive_mesh_hop_policy.dart' as mesh_policy;
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/resilience/federated_gossip_forwarding_gate.dart';
import 'package:avrai/core/ai2ai/routing/federated_forwarding_precheck.dart';
import 'package:avrai/core/ai2ai/routing/locality_agent_update_forwarding_lane.dart';
import 'package:avrai/core/ai2ai/routing/mesh_forwarding_context.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class LocalityAgentUpdateMeshForwardingLane {
  const LocalityAgentUpdateMeshForwardingLane._();

  static Future<void> forward({
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
    int maxCandidates = 2,
  }) async {
    final originId =
        message['origin_id'] as String? ?? message['agent_id'] as String?;

    if (!FederatedForwardingPrecheck.allow(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      originId: originId,
      localNodeId: localNodeId,
    )) {
      return;
    }

    final hop = (message['hop'] as num?)?.toInt() ?? 0;

    if (!FederatedGossipForwardingGate.allow(
      payload: message,
      hop: hop,
      adaptiveMeshService: adaptiveMeshService,
      getOrCreateBloomFilter: getOrCreateBloomFilter,
      logger: logger,
      logName: logName,
      priority: mesh_policy.MessagePriority.high,
      messageType: mesh_policy.MessageType.localityAgentUpdate,
      duplicateLabel: 'locality agent update',
    )) {
      return;
    }

    final forwardingContext = MeshForwardingContext.tryCreate(
      protocol: protocol,
      discovery: discovery,
    );
    if (forwardingContext == null) return;

    await LocalityAgentUpdateForwardingLane.forward(
      message: message,
      hop: hop,
      originId: originId,
      discoveredNodeIds: discoveredNodeIds,
      context: forwardingContext,
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      logger: logger,
      logName: logName,
      maxCandidates: maxCandidates,
    );
  }
}

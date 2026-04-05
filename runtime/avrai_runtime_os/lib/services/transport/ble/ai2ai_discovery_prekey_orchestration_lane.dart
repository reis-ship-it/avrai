// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/ai2ai_discovery_execution_lane.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/prekey_session_prime_lane.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/prekey_mesh_forward_bridge_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/ai2ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_network/avra_network.dart';

class Ai2AiDiscoveryPrekeyOrchestrationLane {
  const Ai2AiDiscoveryPrekeyOrchestrationLane._();

  static Future<List<AIPersonalityNode>> performDiscovery({
    required DeviceDiscoveryService? deviceDiscovery,
    required bool allowBleSideEffects,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    }) primeOfflineSignalPreKeyBundleInSession,
    required AI2AIBroadcastService? realtimeService,
    required AppLogger logger,
    required String logName,
  }) {
    return AI2AIDiscoveryExecutionLane.discover(
      deviceDiscovery: deviceDiscovery,
      allowBleSideEffects: allowBleSideEffects,
      primeOfflineSignalPreKeyBundleInSession:
          primeOfflineSignalPreKeyBundleInSession,
      realtimeService: realtimeService,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> primeOfflineSignalPreKeyBundleInSession({
    required bool allowBleSideEffects,
    required SignalKeyManager? signalKeyManager,
    required GovernedMeshPacketCodec? packetCodec,
    required DiscoveredDevice device,
    required BleGattSession session,
    required Map<String, String> peerNodeIdByDeviceId,
    required bool federatedLearningParticipationEnabled,
    required Future<void> Function({
      required SignalPreKeyBundle bundle,
      required String recipientId,
      required DiscoveredDevice device,
    }) forwardPreKeyBundleThroughMesh,
    required String localBleNodeId,
    required AppLogger logger,
    required String logName,
  }) {
    return PrekeySessionPrimeLane.run(
      allowBleSideEffects: allowBleSideEffects,
      signalKeyManager: signalKeyManager,
      packetCodec: packetCodec,
      device: device,
      session: session,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      forwardPreKeyBundleThroughMesh: forwardPreKeyBundleThroughMesh,
      localBleNodeId: localBleNodeId,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> forwardPreKeyBundleThroughMesh({
    required bool allowBleSideEffects,
    required GovernedMeshPacketCodec? packetCodec,
    required DeviceDiscoveryService? discovery,
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
    required AppLogger logger,
    required String logName,
  }) {
    return PrekeyMeshForwardBridgeLane.forward(
      allowBleSideEffects: allowBleSideEffects,
      tryCreateMeshForwardingContext: () {
        return MeshForwardingContextOrchestrationLane.tryCreate(
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
      },
      bundle: bundle,
      recipientId: recipientId,
      discoveredNodeIds:
          MeshForwardingContextOrchestrationLane.discoveredNodeIds(
              discoveredNodes: discoveredNodes),
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      adaptiveMeshService: adaptiveMeshService,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> primeOfflineSignalPreKeyBundleInSessionForOrchestrator({
    required bool allowBleSideEffects,
    required SignalKeyManager? signalKeyManager,
    required GovernedMeshPacketCodec? packetCodec,
    required DiscoveredDevice device,
    required BleGattSession session,
    required Map<String, String> peerNodeIdByDeviceId,
    required bool federatedLearningParticipationEnabled,
    required String localBleNodeId,
    required DeviceDiscoveryService? discovery,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    String? localUserId,
    String? localAgentId,
    String privacyMode = MeshTransportPrivacyMode.privateMesh,
    bool reticulumTransportControlPlaneEnabled = false,
    bool trustedAnnounceEnforcementEnabled = false,
    required AppLogger logger,
    required String logName,
  }) {
    return primeOfflineSignalPreKeyBundleInSession(
      allowBleSideEffects: allowBleSideEffects,
      signalKeyManager: signalKeyManager,
      packetCodec: packetCodec,
      device: device,
      session: session,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
      forwardPreKeyBundleThroughMesh: ({
        required SignalPreKeyBundle bundle,
        required String recipientId,
        required DiscoveredDevice device,
      }) {
        return forwardPreKeyBundleThroughMesh(
          allowBleSideEffects: allowBleSideEffects,
          packetCodec: packetCodec,
          discovery: discovery,
          bundle: bundle,
          recipientId: recipientId,
          discoveredNodes: discoveredNodes,
          localNodeId: localBleNodeId,
          peerNodeIdByDeviceId: peerNodeIdByDeviceId,
          adaptiveMeshService: adaptiveMeshService,
          governanceBindingService: governanceBindingService,
          localUserId: localUserId,
          localAgentId: localAgentId,
          privacyMode: privacyMode,
          reticulumTransportControlPlaneEnabled:
              reticulumTransportControlPlaneEnabled,
          trustedAnnounceEnforcementEnabled:
              trustedAnnounceEnforcementEnabled,
          logger: logger,
          logName: logName,
        );
      },
      localBleNodeId: localBleNodeId,
      logger: logger,
      logName: logName,
    );
  }
}

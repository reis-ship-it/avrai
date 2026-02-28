import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/discovery/ai2ai_discovery_execution_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/mesh_forwarding_context_orchestration_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/prekey_session_prime_lane.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/prekey_mesh_forward_bridge_lane.dart';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_network/avra_network.dart';

class Ai2AiDiscoveryPrekeyOrchestrationLane {
  const Ai2AiDiscoveryPrekeyOrchestrationLane._();

  static Future<List<AIPersonalityNode>> performDiscovery({
    required DeviceDiscoveryService? deviceDiscovery,
    required bool allowBleSideEffects,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    })
        primeOfflineSignalPreKeyBundleInSession,
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
    required AI2AIProtocol? protocol,
    required DiscoveredDevice device,
    required BleGattSession session,
    required Map<String, String> peerNodeIdByDeviceId,
    required bool federatedLearningParticipationEnabled,
    required Future<void> Function({
      required SignalPreKeyBundle bundle,
      required String recipientId,
      required DiscoveredDevice device,
    })
        forwardPreKeyBundleThroughMesh,
    required String localBleNodeId,
    required AppLogger logger,
    required String logName,
  }) {
    return PrekeySessionPrimeLane.run(
      allowBleSideEffects: allowBleSideEffects,
      signalKeyManager: signalKeyManager,
      protocol: protocol,
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
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required AppLogger logger,
    required String logName,
  }) {
    return PrekeyMeshForwardBridgeLane.forward(
      allowBleSideEffects: allowBleSideEffects,
      tryCreateMeshForwardingContext: () {
        return MeshForwardingContextOrchestrationLane.tryCreate(
          protocol: protocol,
          discovery: discovery,
        );
      },
      bundle: bundle,
      recipientId: recipientId,
      discoveredNodeIds: MeshForwardingContextOrchestrationLane
          .discoveredNodeIds(discoveredNodes: discoveredNodes),
      localNodeId: localNodeId,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      adaptiveMeshService: adaptiveMeshService,
      logger: logger,
      logName: logName,
    );
  }
}

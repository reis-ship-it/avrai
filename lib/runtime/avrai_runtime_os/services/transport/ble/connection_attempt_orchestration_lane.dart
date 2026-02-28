// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_attempt_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_establishment_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_management_orchestration_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_worthiness_validation_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_routing_policy.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_network/avra_network.dart';

class ConnectionAttemptOrchestrationLane {
  const ConnectionAttemptOrchestrationLane._();

  static Future<ConnectionMetrics?> establish({
    required bool isConnecting,
    required void Function(bool value) setIsConnecting,
    required Map<String, DateTime> connectionCooldowns,
    required Map<String, ConnectionMetrics> activeConnections,
    required String localUserId,
    required PersonalityProfile localPersonality,
    required AIPersonalityNode remoteNode,
    required UserVibeAnalyzer vibeAnalyzer,
    required ConnectionManager connectionManager,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required AI2AIProtocol? protocol,
    required SignalKeyManager? signalKeyManager,
    required KnotWeavingService? knotWeavingService,
    required KnotStorageService? knotStorageService,
    required AppLogger logger,
    required String logName,
  }) async {
    return ConnectionAttemptLane.run(
      isConnecting: isConnecting,
      isInCooldown: ConnectionRoutingPolicy.isInCooldown(
        cooldowns: connectionCooldowns,
        nodeId: remoteNode.nodeId,
      ),
      hasReachedMaxConnections:
          activeConnections.length >= VibeConstants.maxSimultaneousConnections,
      remoteNodeId: remoteNode.nodeId,
      validateWorthiness: () async {
        return ConnectionWorthinessValidationLane.validateOrCooldown(
          vibeAnalyzer: vibeAnalyzer,
          localUserId: localUserId,
          localPersonality: localPersonality,
          remoteNode: remoteNode,
          isConnectionWorthy: isConnectionWorthy,
          setCooldown: (nodeId) {
            ConnectionRoutingPolicy.setCooldown(
              cooldowns: connectionCooldowns,
              nodeId: nodeId,
            );
          },
          logger: logger,
          logName: logName,
        );
      },
      setIsConnecting: setIsConnecting,
      establishConnection: () {
        return connectionManager.establish(
          localUserId,
          localPersonality,
          remoteNode,
          (localVibe, remote, comp, metrics) =>
              ConnectionEstablishmentLane.establish(
            protocol: protocol,
            signalKeyManager: signalKeyManager,
            knotWeavingService: knotWeavingService,
            knotStorageService: knotStorageService,
            localVibe: localVibe,
            remoteNode: remote,
            compatibility: comp,
            initialMetrics: metrics,
            localAgentId: localPersonality.agentId,
            remoteAgentId: remoteNode.nodeId,
            logger: logger,
            logName: logName,
          ),
        );
      },
      onEstablished: (connection) {
        activeConnections[connection.connectionId] = connection;
        ConnectionManagementOrchestrationLane.schedule(
          connection: connection,
          logger: logger,
          logName: logName,
        );
      },
      setCooldown: (nodeId) {
        ConnectionRoutingPolicy.setCooldown(
          cooldowns: connectionCooldowns,
          nodeId: nodeId,
        );
      },
      logger: logger,
      logName: logName,
    );
  }
}

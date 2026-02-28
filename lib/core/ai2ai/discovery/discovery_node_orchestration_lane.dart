import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/discovery/discovered_node_registry.dart';
import 'package:avrai/core/ai2ai/routing/connection_routing_policy.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';

class DiscoveryNodeOrchestrationLane {
  const DiscoveryNodeOrchestrationLane._();

  static void updateDiscoveredNodes({
    required List<AIPersonalityNode> nodes,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required Map<String, UserVibe> nearbyVibes,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
  }) {
    DiscoveredNodeRegistry.mergeAndPrune(
      incomingNodes: nodes,
      discoveredNodes: discoveredNodes,
      nearbyVibes: nearbyVibes,
      onDensityChanged: (density) {
        adaptiveMeshService?.updateNetworkDensity(density);
      },
    );
  }

  static Future<List<AIPersonalityNode>> prioritizeConnections({
    required List<AIPersonalityNode> nodes,
    required Map<String, VibeCompatibilityResult> compatibilityResults,
    required AppLogger logger,
    required String logName,
  }) async {
    final prioritized = DiscoveredNodeRegistry.prioritizeConnections(
      nodes: nodes,
      compatibilityResults: compatibilityResults,
      maxConnections: 5,
    );
    logger.debug(
      'Prioritized ${nodes.length} nodes to top ${prioritized.length} connections',
      tag: logName,
    );
    return prioritized;
  }

  static bool isConnectionWorthy({
    required VibeCompatibilityResult compatibility,
    required AppLogger logger,
    required String logName,
  }) {
    final result = ConnectionRoutingPolicy.evaluateWorthiness(compatibility);
    if (!result.isWorthy) {
      logger.debug(
        'Connection not worthy: ${result.reason}; opportunities=${compatibility.learningOpportunities.length}',
        tag: logName,
      );
    }
    return result.isWorthy;
  }
}

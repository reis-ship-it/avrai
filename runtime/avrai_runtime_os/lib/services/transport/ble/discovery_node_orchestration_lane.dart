// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/discovered_node_registry.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_routing_policy.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';

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

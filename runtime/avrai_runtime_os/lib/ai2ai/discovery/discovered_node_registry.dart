// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

class DiscoveredNodeRegistry {
  const DiscoveredNodeRegistry._();

  static void mergeAndPrune({
    required List<AIPersonalityNode> incomingNodes,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required Map<String, UserVibe> nearbyVibes,
    required void Function(int density)? onDensityChanged,
    DateTime? now,
    Duration maxAge = const Duration(minutes: 10),
  }) {
    for (final node in incomingNodes) {
      discoveredNodes[node.nodeId] = node;
      nearbyVibes[node.nodeId] = node.vibe;
      onDensityChanged?.call(discoveredNodes.length);
    }

    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    final expiredNodeIds = discoveredNodes.entries
        .where((entry) => entry.value.lastSeen.isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();

    for (final nodeId in expiredNodeIds) {
      discoveredNodes.remove(nodeId);
      nearbyVibes.remove(nodeId);
      onDensityChanged?.call(discoveredNodes.length);
    }
  }

  static List<AIPersonalityNode> prioritizeConnections({
    required List<AIPersonalityNode> nodes,
    required Map<String, VibeCompatibilityResult> compatibilityResults,
    int maxConnections = 5,
  }) {
    nodes.sort((a, b) {
      final aResult = compatibilityResults[a.nodeId];
      final bResult = compatibilityResults[b.nodeId];
      if (aResult == null || bResult == null) return 0;

      final aPriority = _calculateConnectionPriority(aResult, a.trustScore);
      final bPriority = _calculateConnectionPriority(bResult, b.trustScore);
      return bPriority.compareTo(aPriority);
    });

    return nodes.take(maxConnections).toList();
  }

  static double _calculateConnectionPriority(
    VibeCompatibilityResult compatibility,
    double trustScore,
  ) {
    return (compatibility.basicCompatibility * 0.4) +
        (compatibility.aiPleasurePotential * 0.3) +
        (compatibility.learningOpportunities.length / 8.0 * 0.2) +
        (trustScore * 0.1);
  }
}

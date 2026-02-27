import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/discovery/node_compatibility_analyzer.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';

class DiscoveryPostprocessLane {
  const DiscoveryPostprocessLane._();

  static Future<List<AIPersonalityNode>> process({
    required List<AIPersonalityNode> nodes,
    required String userId,
    required PersonalityProfile personality,
    required UserVibeAnalyzer vibeAnalyzer,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required void Function(
      List<AIPersonalityNode> worthyNodes,
      Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    )
    onWorthyNodes,
    required AppLogger logger,
    required String logName,
  }) async {
    if (nodes.isEmpty) {
      updateDiscoveredNodes(nodes);
      logger.info(
        'Discovered ${nodes.length} compatible AI personalities',
        tag: logName,
      );
      return nodes;
    }

    final localVibe = await vibeAnalyzer.compileUserVibe(userId, personality);
    final compatibilityResults = await NodeCompatibilityAnalyzer.analyze(
      vibeAnalyzer: vibeAnalyzer,
      localVibe: localVibe,
      nodes: nodes,
    );

    final worthyNodes = nodes.where((node) {
      final compatibility = compatibilityResults[node.nodeId];
      return compatibility != null && isConnectionWorthy(compatibility);
    }).toList();

    logger.info(
      'Discovered ${nodes.length} nodes, ${worthyNodes.length} connection-worthy after filtering',
      tag: logName,
    );

    updateDiscoveredNodes(worthyNodes);
    onWorthyNodes(worthyNodes, compatibilityResults);
    return worthyNodes;
  }
}

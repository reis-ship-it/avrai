// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

class NodeCompatibilityAnalyzer {
  const NodeCompatibilityAnalyzer._();

  static Future<Map<String, VibeCompatibilityResult>> analyze({
    required UserVibeAnalyzer vibeAnalyzer,
    required UserVibe localVibe,
    required List<AIPersonalityNode> nodes,
  }) async {
    final compatibilityResults = <String, VibeCompatibilityResult>{};

    for (final node in nodes) {
      final compatibility = await vibeAnalyzer.analyzeVibeCompatibility(
        localVibe,
        node.vibe,
      );
      compatibilityResults[node.nodeId] = compatibility;
    }

    return compatibilityResults;
  }
}

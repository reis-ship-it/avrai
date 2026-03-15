// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/deterministic_matcher_service.dart';
import 'package:avrai_core/constants/vibe_constants.dart';

class NodeCompatibilityAnalyzer {
  const NodeCompatibilityAnalyzer._();

  static Future<Map<String, VibeCompatibilityResult>> analyze({
    required UserVibeAnalyzer vibeAnalyzer,
    required UserVibe localVibe,
    required List<AIPersonalityNode> nodes,
    PersonalityProfile? localPersonality,
    PersonalityKnot? localKnot,
    CanonicalPeerResolutionService? canonicalPeerResolutionService,
  }) async {
    final compatibilityResults = <String, VibeCompatibilityResult>{};
    final peerResolutionService =
        canonicalPeerResolutionService ?? CanonicalPeerResolutionService();
    final localPayload = localPersonality == null
        ? null
        : peerResolutionService.buildLocalPayload(
            localPersonality: localPersonality,
          );

    for (final node in nodes) {
      if (localPayload != null && node.resolvedPeerContext != null) {
        final canonicalCompatibility = peerResolutionService.computeCompatibility(
          localPayload: localPayload,
          remoteContext: node.resolvedPeerContext!,
        );
        compatibilityResults[node.nodeId] =
            peerResolutionService.toLegacyCompatibilityResult(
          canonicalCompatibility,
          localPayload: localPayload,
          remoteContext: node.resolvedPeerContext!,
        );
      } else if (localKnot != null && node.knot != null) {
        // Phase 0.1 Pivot: Use fast deterministic math if both knots are available
        final matcher = DeterministicMatcherService();
        final matchScore = matcher.calculateVibeMatch(localKnot, node.knot!);

        compatibilityResults[node.nodeId] = VibeCompatibilityResult(
          basicCompatibility: matchScore,
          aiPleasurePotential: matchScore,
          learningOpportunities: [],
          connectionStrength: matchScore,
          interactionStyle: AI2AIInteractionStyle.focusedExchange,
          trustBuildingPotential: matchScore,
          recommendedConnectionDuration: const Duration(seconds: 300),
          connectionPriority:
              matchScore >= VibeConstants.minimumCompatibilityThreshold
                  ? ConnectionPriority.high
                  : ConnectionPriority.low,
        );
      } else {
        // Fallback to legacy analyzer
        final compatibility = await vibeAnalyzer.analyzeVibeCompatibility(
          localVibe,
          node.vibe,
        );
        compatibilityResults[node.nodeId] = compatibility;
      }
    }

    return compatibilityResults;
  }
}

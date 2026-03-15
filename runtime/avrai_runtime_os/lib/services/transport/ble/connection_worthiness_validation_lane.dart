// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/deterministic_matcher_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_core/constants/vibe_constants.dart';

class ConnectionWorthinessValidationLane {
  const ConnectionWorthinessValidationLane._();

  static Future<bool> validateOrCooldown({
    required UserVibeAnalyzer vibeAnalyzer,
    required String localUserId,
    required PersonalityProfile localPersonality,
    required AIPersonalityNode remoteNode,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(String nodeId) setCooldown,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      VibeCompatibilityResult compatibility;

      // Phase 0.1 Pivot: Try fast deterministic math first
      if (remoteNode.resolvedPeerContext != null) {
        final canonicalPeerResolutionService = CanonicalPeerResolutionService();
        final localPayload = canonicalPeerResolutionService.buildLocalPayload(
          localPersonality: localPersonality,
        );
        compatibility =
            canonicalPeerResolutionService.toLegacyCompatibilityResult(
          canonicalPeerResolutionService.computeCompatibility(
            localPayload: localPayload,
            remoteContext: remoteNode.resolvedPeerContext!,
          ),
          localPayload: localPayload,
          remoteContext: remoteNode.resolvedPeerContext!,
        );
      } else if (remoteNode.knot != null) {
        try {
          final knotService =
              GetIt.instance.isRegistered<PersonalityKnotService>()
                  ? GetIt.instance<PersonalityKnotService>()
                  : PersonalityKnotService();
          final localKnot = await knotService.generateKnot(localPersonality);

          final matcher = DeterministicMatcherService();
          final matchScore =
              matcher.calculateVibeMatch(localKnot, remoteNode.knot!);

          compatibility = VibeCompatibilityResult(
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
        } catch (e) {
          logger.warn(
              'Failed to calculate knot match: $e, falling back to legacy vibe match',
              tag: logName);
          final UserVibe localVibe =
              await vibeAnalyzer.compileUserVibe(localUserId, localPersonality);
          compatibility = await vibeAnalyzer.analyzeVibeCompatibility(
              localVibe, remoteNode.vibe);
        }
      } else {
        final UserVibe localVibe =
            await vibeAnalyzer.compileUserVibe(localUserId, localPersonality);
        compatibility = await vibeAnalyzer.analyzeVibeCompatibility(
            localVibe, remoteNode.vibe);
      }

      if (!isConnectionWorthy(compatibility)) {
        logger.debug(
          'Connection to ${remoteNode.nodeId} not worthy (compatibility: ${(compatibility.basicCompatibility * 100).round()}%, pleasure: ${(compatibility.aiPleasurePotential * 100).round()}%)',
          tag: logName,
        );
        setCooldown(remoteNode.nodeId);
        return false;
      }
      return true;
    } catch (e) {
      logger.warn(
        'Error checking connection worthiness: $e, proceeding anyway',
        tag: logName,
      );
      return true;
    }
  }
}

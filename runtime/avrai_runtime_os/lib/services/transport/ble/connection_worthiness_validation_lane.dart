// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';

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
      final UserVibe localVibe =
          await vibeAnalyzer.compileUserVibe(localUserId, localPersonality);
      final VibeCompatibilityResult compatibility = await vibeAnalyzer
          .analyzeVibeCompatibility(localVibe, remoteNode.vibe);

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

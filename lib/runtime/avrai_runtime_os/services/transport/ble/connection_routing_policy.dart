import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionWorthinessResult {
  final bool isWorthy;
  final String? reason;

  const ConnectionWorthinessResult({
    required this.isWorthy,
    this.reason,
  });
}

class ConnectionRoutingPolicy {
  const ConnectionRoutingPolicy._();

  static bool isConnected(List<ConnectivityResult> result) {
    return result
        .any((connectivity) => connectivity != ConnectivityResult.none);
  }

  static bool isInCooldown({
    required Map<String, DateTime> cooldowns,
    required String nodeId,
    DateTime? now,
  }) {
    final cooldownEnd = cooldowns[nodeId];
    if (cooldownEnd == null) return false;
    return (now ?? DateTime.now()).isBefore(cooldownEnd);
  }

  static void setCooldown({
    required Map<String, DateTime> cooldowns,
    required String nodeId,
    DateTime? now,
  }) {
    cooldowns[nodeId] = (now ?? DateTime.now()).add(
      const Duration(seconds: VibeConstants.connectionCooldownSeconds),
    );
  }

  static ConnectionWorthinessResult evaluateWorthiness(
    VibeCompatibilityResult compatibility,
  ) {
    if (compatibility.basicCompatibility <
        VibeConstants.minimumCompatibilityThreshold) {
      return ConnectionWorthinessResult(
        isWorthy: false,
        reason:
            'compatibility ${(compatibility.basicCompatibility * 100).round()}% '
            '< ${(VibeConstants.minimumCompatibilityThreshold * 100).round()}%',
      );
    }

    if (compatibility.aiPleasurePotential < VibeConstants.minAIPleasureScore) {
      return ConnectionWorthinessResult(
        isWorthy: false,
        reason:
            'pleasure ${(compatibility.aiPleasurePotential * 100).round()}% '
            '< ${(VibeConstants.minAIPleasureScore * 100).round()}%',
      );
    }

    if (compatibility.learningOpportunities.isEmpty) {
      return const ConnectionWorthinessResult(
        isWorthy: false,
        reason: 'no learning opportunities',
      );
    }

    return const ConnectionWorthinessResult(isWorthy: true);
  }
}

import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/recommendations/agent_happiness_service.dart';

class AIPleasureScoreLane {
  const AIPleasureScoreLane._();

  static Future<double> calculate({
    required ConnectionMetrics connection,
    required SharedPreferencesCompat prefs,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      logger.debug(
        'Calculating AI pleasure score for ${connection.connectionId}',
        tag: logName,
      );

      double pleasureScore = connection.currentCompatibility * 0.4;
      pleasureScore += connection.learningEffectiveness * 0.3;

      final int successfulExchanges =
          connection.learningOutcomes['successful_exchanges'] as int? ?? 0;
      final int totalExchanges = connection.interactionHistory.length;
      final double successRate =
          totalExchanges > 0 ? successfulExchanges / totalExchanges : 0.0;
      pleasureScore += successRate * 0.2;

      final int dimensionEvolutionCount = connection.dimensionEvolution.length;
      final double evolutionBonus =
          (dimensionEvolutionCount / VibeConstants.coreDimensions.length) * 0.1;
      pleasureScore += evolutionBonus;

      final double finalScore = pleasureScore.clamp(0.0, 1.0);
      logger.debug(
        'AI pleasure score: ${(finalScore * 100).round()}%',
        tag: logName,
      );

      try {
        final AgentHappinessService happiness = AgentHappinessService(
          prefs: prefs,
        );
        await happiness.recordSignal(
          source: 'ai2ai_pleasure',
          score: finalScore,
          metadata: <String, dynamic>{'connection_id': connection.connectionId},
        );
      } catch (_) {
        // Ignore.
      }

      return finalScore;
    } catch (e) {
      logger.error('Error calculating AI pleasure score', error: e, tag: logName);
      return 0.5;
    }
  }
}

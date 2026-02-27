import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:get_it/get_it.dart';

class QualityChangeKeyRotationLane {
  const QualityChangeKeyRotationLane._();

  static Future<void> run({
    required SignalSessionManager sessionManager,
    required Iterable<ConnectionMetrics> activeConnections,
    required Map<String, double> previousQualityScores,
    required double qualityChangeThreshold,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final sl = GetIt.instance;
      final signalProtocolService = sl.isRegistered<SignalProtocolService>()
          ? sl<SignalProtocolService>()
          : null;

      if (signalProtocolService == null) {
        return;
      }

      for (final connection in activeConnections) {
        if (connection.status != ConnectionStatus.active &&
            connection.status != ConnectionStatus.learning) {
          continue;
        }

        final agentId = connection.remoteAISignature;
        final currentQuality = connection.qualityScore;
        final previousQuality = previousQualityScores[agentId];

        if (previousQuality == null) {
          previousQualityScores[agentId] = currentQuality;
          continue;
        }

        final qualityChange = (currentQuality - previousQuality).abs();
        if (qualityChange < qualityChangeThreshold) {
          continue;
        }

        logger.info(
          'Significant quality change detected for agent $agentId: '
          '${previousQuality.toStringAsFixed(2)} -> ${currentQuality.toStringAsFixed(2)} '
          '(change: ${(qualityChange * 100).toStringAsFixed(1)}%)',
          tag: logName,
        );

        final session = await sessionManager.getSession(agentId);
        if (session != null) {
          logger.info(
            'Triggering key rotation for agent $agentId due to quality change',
            tag: logName,
          );

          await sessionManager.markRekeyed(agentId);

          if (await sessionManager.needsRekeying(agentId)) {
            logger.debug(
              'Key rotation triggered for agent $agentId (quality change: ${(qualityChange * 100).toStringAsFixed(1)}%)',
              tag: logName,
            );
          }
        }

        previousQualityScores[agentId] = currentQuality;
      }

      final activeAgentIds = activeConnections
          .where((c) =>
              c.status == ConnectionStatus.active ||
              c.status == ConnectionStatus.learning)
          .map((c) => c.remoteAISignature)
          .toSet();

      previousQualityScores.removeWhere(
        (agentId, _) => !activeAgentIds.contains(agentId),
      );
    } catch (e, st) {
      logger.error(
        'Error rotating keys based on quality changes: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}

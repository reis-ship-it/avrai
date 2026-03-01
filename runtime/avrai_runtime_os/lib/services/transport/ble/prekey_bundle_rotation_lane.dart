// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class PrekeyBundleRotationLane {
  const PrekeyBundleRotationLane._();

  static Future<void> run({
    required SignalKeyManager? signalKeyManager,
    required Iterable<ConnectionMetrics> activeConnections,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      if (signalKeyManager == null) {
        return;
      }

      await signalKeyManager.cleanupExpiredPreKeyBundles();

      final recipientsNeedingRefresh =
          signalKeyManager.getRecipientsNeedingRefresh();

      for (final recipientId in recipientsNeedingRefresh) {
        final hasActiveConnection = activeConnections.any(
          (connection) =>
              connection.remoteAISignature == recipientId &&
              (connection.status == ConnectionStatus.active ||
                  connection.status == ConnectionStatus.learning),
        );

        if (!hasActiveConnection) continue;

        logger.debug(
          'Proactively refreshing prekey bundle for active connection: $recipientId',
          tag: logName,
        );

        unawaited(_refreshRecipient(
          signalKeyManager: signalKeyManager,
          recipientId: recipientId,
          logger: logger,
          logName: logName,
        ));
      }
    } catch (e, st) {
      logger.error(
        'Error managing prekey bundle rotation: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  static Future<void> _refreshRecipient({
    required SignalKeyManager signalKeyManager,
    required String recipientId,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      await signalKeyManager.fetchPreKeyBundle(recipientId);
      logger.debug(
        'Successfully refreshed prekey bundle for recipient: $recipientId',
        tag: logName,
      );
    } catch (e) {
      logger.warn(
        'Failed to refresh prekey bundle for $recipientId: $e',
        tag: logName,
      );
    }
  }
}

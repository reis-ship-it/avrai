import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class ConnectionAttemptLane {
  const ConnectionAttemptLane._();

  static Future<ConnectionMetrics?> run({
    required bool isConnecting,
    required bool isInCooldown,
    required bool hasReachedMaxConnections,
    required String remoteNodeId,
    required Future<bool> Function() validateWorthiness,
    required void Function(bool value) setIsConnecting,
    required Future<ConnectionMetrics?> Function() establishConnection,
    required void Function(ConnectionMetrics connection) onEstablished,
    required void Function(String nodeId) setCooldown,
    required AppLogger logger,
    required String logName,
  }) async {
    if (isConnecting) {
      logger.debug('Connection establishment already in progress', tag: logName);
      return null;
    }

    if (isInCooldown) {
      logger.debug('Connection to $remoteNodeId is in cooldown period',
          tag: logName);
      return null;
    }

    if (hasReachedMaxConnections) {
      logger.warn('Maximum simultaneous connections reached', tag: logName);
      return null;
    }

    if (!await validateWorthiness()) {
      return null;
    }

    setIsConnecting(true);
    try {
      logger.info('Establishing connection with node: $remoteNodeId',
          tag: logName);

      final ConnectionMetrics? establishedConnection =
          await establishConnection();
      if (establishedConnection != null) {
        onEstablished(establishedConnection);
        logger.info(
          'Connection established (ID: ${establishedConnection.connectionId})',
          tag: logName,
        );
        return establishedConnection;
      }

      logger.warn('Failed to establish connection', tag: logName);
      setCooldown(remoteNodeId);
      return null;
    } catch (e) {
      logger.error('Error establishing connection', error: e, tag: logName);
      setCooldown(remoteNodeId);
      return null;
    } finally {
      setIsConnecting(false);
    }
  }
}

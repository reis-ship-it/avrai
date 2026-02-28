// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/models/quantum/connection_metrics.dart';

class ActiveConnectionMetricsIndex {
  const ActiveConnectionMetricsIndex._();

  static Map<String, ConnectionMetrics> byAgentId(
    Iterable<ConnectionMetrics> connections,
  ) {
    final metricsByAgentId = <String, ConnectionMetrics>{};
    for (final connection in connections) {
      if (connection.status != ConnectionStatus.active &&
          connection.status != ConnectionStatus.learning) {
        continue;
      }

      metricsByAgentId[connection.remoteAISignature] = connection;
    }
    return metricsByAgentId;
  }
}

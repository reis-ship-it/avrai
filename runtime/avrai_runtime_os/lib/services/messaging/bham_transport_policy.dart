import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';

class BhamTransportPolicy {
  const BhamTransportPolicy();

  Duration get standardTtl => BhamBetaDefaults.relay.ttl;

  int get queueCap => BhamBetaDefaults.relay.queueCap;

  int get maxQueueBytes => BhamBetaDefaults.relay.maxQueueBytes;

  int get quarantineAfterFailures =>
      BhamBetaDefaults.relay.quarantineAfterFailures;

  Duration ttlForThreadKind(
    ChatThreadKind kind, {
    DateTime? eventEndsAtUtc,
  }) {
    if (kind != ChatThreadKind.event) {
      return standardTtl;
    }
    if (eventEndsAtUtc == null) {
      return standardTtl;
    }
    final untilEventEnd = eventEndsAtUtc.difference(DateTime.now().toUtc());
    final ttl = untilEventEnd + const Duration(hours: 2);
    if (ttl.isNegative) {
      return const Duration(hours: 2);
    }
    return ttl > standardTtl ? standardTtl : ttl;
  }
}

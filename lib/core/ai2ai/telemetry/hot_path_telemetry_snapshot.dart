// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/ai2ai/telemetry/hot_latency_window.dart';

class HotPathTelemetrySnapshot {
  final HotLatencySummary queue;
  final HotLatencySummary open;
  final HotLatencySummary vibe;
  final HotLatencySummary compat;
  final HotLatencySummary total;

  const HotPathTelemetrySnapshot({
    required this.queue,
    required this.open,
    required this.vibe,
    required this.compat,
    required this.total,
  });

  int get count => total.count;

  String formatLogLine() {
    return 'HotPath latency ms '
        '(n=${total.count}) '
        'queue(p50=${queue.p50},p95=${queue.p95}) '
        'open(p50=${open.p50},p95=${open.p95}) '
        'vibe(p50=${vibe.p50},p95=${vibe.p95}) '
        'compat(p50=${compat.p50},p95=${compat.p95}) '
        'total(p50=${total.p50},p95=${total.p95})';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'count': total.count,
      'queue': queue.toJson(),
      'open': open.toJson(),
      'vibe': vibe.toJson(),
      'compat': compat.toJson(),
      'total': total.toJson(),
    };
  }
}

class HotPathTelemetrySnapshotBuilder {
  const HotPathTelemetrySnapshotBuilder._();

  static HotPathTelemetrySnapshot build({
    required HotLatencyWindow queueWait,
    required HotLatencyWindow sessionOpen,
    required HotLatencyWindow vibeRead,
    required HotLatencyWindow compatibility,
    required HotLatencyWindow total,
  }) {
    return HotPathTelemetrySnapshot(
      queue: queueWait.summary(),
      open: sessionOpen.summary(),
      vibe: vibeRead.summary(),
      compat: compatibility.summary(),
      total: total.summary(),
    );
  }

  static bool shouldLog({
    required int nowMs,
    required int lastLogAtMs,
    required Duration minInterval,
  }) {
    return nowMs - lastLogAtMs >= minInterval.inMilliseconds;
  }
}

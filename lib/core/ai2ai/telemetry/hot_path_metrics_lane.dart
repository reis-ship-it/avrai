import 'package:avrai/core/ai2ai/telemetry/hot_latency_window.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_path_telemetry_snapshot.dart';

class HotPathMetricsLane {
  const HotPathMetricsLane._();

  static HotPathTelemetrySnapshot buildSnapshot({
    required HotLatencyWindow queueWait,
    required HotLatencyWindow sessionOpen,
    required HotLatencyWindow vibeRead,
    required HotLatencyWindow compatibility,
    required HotLatencyWindow total,
  }) {
    return HotPathTelemetrySnapshotBuilder.build(
      queueWait: queueWait,
      sessionOpen: sessionOpen,
      vibeRead: vibeRead,
      compatibility: compatibility,
      total: total,
    );
  }

  static int maybeEmitSnapshot({
    required int nowMs,
    required int lastLogAtMs,
    required Duration minInterval,
    required HotLatencyWindow queueWait,
    required HotLatencyWindow sessionOpen,
    required HotLatencyWindow vibeRead,
    required HotLatencyWindow compatibility,
    required HotLatencyWindow total,
    required void Function(HotPathTelemetrySnapshot snapshot) onSnapshot,
  }) {
    if (!HotPathTelemetrySnapshotBuilder.shouldLog(
      nowMs: nowMs,
      lastLogAtMs: lastLogAtMs,
      minInterval: minInterval,
    )) {
      return lastLogAtMs;
    }

    final snapshot = buildSnapshot(
      queueWait: queueWait,
      sessionOpen: sessionOpen,
      vibeRead: vibeRead,
      compatibility: compatibility,
      total: total,
    );
    if (snapshot.count == 0) return nowMs;

    onSnapshot(snapshot);
    return nowMs;
  }
}

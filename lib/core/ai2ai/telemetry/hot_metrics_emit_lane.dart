import 'dart:async';

import 'package:avrai/core/ai2ai/telemetry/hot_latency_window.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_path_metrics_lane.dart';

class HotMetricsEmitLane {
  const HotMetricsEmitLane._();

  static int emit({
    required int nowMs,
    required int lastLogAtMs,
    required Duration minInterval,
    required HotLatencyWindow queueWait,
    required HotLatencyWindow sessionOpen,
    required HotLatencyWindow vibeRead,
    required HotLatencyWindow compatibility,
    required HotLatencyWindow total,
    required void Function(String line) onDebugLogLine,
    required Future<void> Function(Map<String, Object?> payload)?
        onLedgerAppend,
  }) {
    final int nextLogAtMs = HotPathMetricsLane.maybeEmitSnapshot(
      nowMs: nowMs,
      lastLogAtMs: lastLogAtMs,
      minInterval: minInterval,
      queueWait: queueWait,
      sessionOpen: sessionOpen,
      vibeRead: vibeRead,
      compatibility: compatibility,
      total: total,
      onSnapshot: (snapshot) {
        onDebugLogLine(snapshot.formatLogLine());
        if (onLedgerAppend != null) {
          unawaited(onLedgerAppend(snapshot.toJson().cast<String, Object?>()));
        }
      },
    );
    return nextLogAtMs;
  }
}

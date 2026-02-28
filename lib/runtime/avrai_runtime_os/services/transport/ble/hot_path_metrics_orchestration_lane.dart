// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/core/ai2ai/telemetry/hot_latency_window.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_metrics_emit_lane.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_path_metrics_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';

class HotPathMetricsOrchestrationLane {
  const HotPathMetricsOrchestrationLane._();

  static int maybeLog({
    required int lastLogAtMs,
    required Duration minInterval,
    required HotLatencyWindow queueWait,
    required HotLatencyWindow sessionOpen,
    required HotLatencyWindow vibeRead,
    required HotLatencyWindow compatibility,
    required HotLatencyWindow total,
    required AppLogger logger,
    required String logName,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return HotMetricsEmitLane.emit(
      nowMs: nowMs,
      lastLogAtMs: lastLogAtMs,
      minInterval: minInterval,
      queueWait: queueWait,
      sessionOpen: sessionOpen,
      vibeRead: vibeRead,
      compatibility: compatibility,
      total: total,
      onDebugLogLine: (line) => logger.debug(line, tag: logName),
      onLedgerAppend: LedgerAuditV0.isEnabled
          ? (payload) => LedgerAuditV0.tryAppend(
                domain: LedgerDomainV0.deviceCapability,
                eventType: 'ai2ai_hotpath_latency_summary',
                occurredAt: DateTime.now(),
                payload: payload,
              )
          : null,
    );
  }

  static Map<String, dynamic> summarySnapshotJson({
    required HotLatencyWindow queueWait,
    required HotLatencyWindow sessionOpen,
    required HotLatencyWindow vibeRead,
    required HotLatencyWindow compatibility,
    required HotLatencyWindow total,
  }) {
    return HotPathMetricsLane.buildSnapshot(
      queueWait: queueWait,
      sessionOpen: sessionOpen,
      vibeRead: vibeRead,
      compatibility: compatibility,
      total: total,
    ).toJson();
  }
}

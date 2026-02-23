import 'dart:developer' as developer;

import 'package:avrai/core/services/ai_infrastructure/ai_improvement_tracking_service.dart';

class ConsolidationMetricsSnapshot {
  final String agentId;
  final int episodesScanned;
  final int episodesCompressed;
  final int episodesPruned;
  final int rulesExtracted;
  final int memorySizeBefore;
  final int memorySizeAfter;
  final Duration duration;
  final DateTime recordedAt;

  const ConsolidationMetricsSnapshot({
    required this.agentId,
    required this.episodesScanned,
    required this.episodesCompressed,
    required this.episodesPruned,
    required this.rulesExtracted,
    required this.memorySizeBefore,
    required this.memorySizeAfter,
    required this.duration,
    required this.recordedAt,
  });
}

/// Phase 1.1C.5 metrics logging for nightly memory consolidation.
class ConsolidationMetricsService {
  static const String _logName = 'ConsolidationMetricsService';

  const ConsolidationMetricsService({
    AIImprovementTrackingService? trackingService,
  }) : _trackingService = trackingService;

  final AIImprovementTrackingService? _trackingService;

  Future<void> logSnapshot(ConsolidationMetricsSnapshot snapshot) async {
    developer.log(
      'Consolidation metrics: '
      'agent=${snapshot.agentId}, '
      'scanned=${snapshot.episodesScanned}, '
      'compressed=${snapshot.episodesCompressed}, '
      'pruned=${snapshot.episodesPruned}, '
      'rules=${snapshot.rulesExtracted}, '
      'size=${snapshot.memorySizeBefore}->${snapshot.memorySizeAfter}, '
      'duration_ms=${snapshot.duration.inMilliseconds}',
      name: _logName,
    );

    final tracking = _trackingService;
    if (tracking == null) return;

    final dimensions = <String, Object>{
      'agent_id': snapshot.agentId,
      'memory_size_before': snapshot.memorySizeBefore,
      'memory_size_after': snapshot.memorySizeAfter,
      'duration_ms': snapshot.duration.inMilliseconds,
    };

    await Future.wait([
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_episodes_scanned',
        value: snapshot.episodesScanned.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_episodes_compressed',
        value: snapshot.episodesCompressed.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_episodes_pruned',
        value: snapshot.episodesPruned.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_rules_extracted',
        value: snapshot.rulesExtracted.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_duration_ms',
        value: snapshot.duration.inMilliseconds.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_memory_size_before',
        value: snapshot.memorySizeBefore.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
      tracking.recordOperationalMetric(
        userId: snapshot.agentId,
        metricName: 'memory_consolidation_memory_size_after',
        value: snapshot.memorySizeAfter.toDouble(),
        dimensions: dimensions,
        timestamp: snapshot.recordedAt,
      ),
    ]);
  }
}

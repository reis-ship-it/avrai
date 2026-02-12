import 'dart:developer' as developer;
import 'dart:math';

import 'package:avrai/core/monitoring/connection_monitor.dart';

/// Phase 20.5: AI Pleasure network analysis (distribution, trends, correlation, optimization).
class AIPleasureNetworkAnalysis {
  static const String _logName = 'AIPleasureNetworkAnalysis';

  final ConnectionMonitor _connectionMonitor;

  AIPleasureNetworkAnalysis({
    required ConnectionMonitor connectionMonitor,
  }) : _connectionMonitor = connectionMonitor;

  /// Pleasure distribution across network (mean, median, std dev, percentiles).
  Future<PleasureNetworkMetrics> analyzePleasureMetrics() async {
    try {
      final sessions = _connectionMonitor.getAllMonitoringSessions();
      if (sessions.isEmpty) {
        return PleasureNetworkMetrics.empty();
      }
      final scores =
          sessions.map((s) => s.currentMetrics.aiPleasureScore.clamp(0.0, 1.0)).toList();
      final sorted = List<double>.from(scores)..sort();
      final n = sorted.length;
      final mean = scores.reduce((a, b) => a + b) / n;
      final median = n.isOdd ? sorted[n ~/ 2] : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
      final variance =
          scores.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
      final stdDev = sqrt(variance);
      final p25 = sorted[(n * 0.25).floor().clamp(0, n - 1)];
      final p75 = sorted[(n * 0.75).floor().clamp(0, n - 1)];
      final highClusters = scores.where((s) => s >= 0.8).length;
      final lowClusters = scores.where((s) => s < 0.4).length;
      return PleasureNetworkMetrics(
        mean: mean,
        median: median,
        stdDev: stdDev,
        percentile25: p25,
        percentile75: p75,
        sampleCount: n,
        highPleasureCount: highClusters,
        lowPleasureCount: lowClusters,
        computedAt: DateTime.now(),
      );
    } catch (e, st) {
      developer.log('analyzePleasureMetrics failed', name: _logName, error: e, stackTrace: st);
      return PleasureNetworkMetrics.empty();
    }
  }

  /// Pleasure trends over time (snapshot-based; no persistent history in this impl).
  Future<List<PleasureTrend>> analyzePleasureTrends() async {
    try {
      final metrics = await analyzePleasureMetrics();
      if (metrics.sampleCount == 0) return [];
      final now = DateTime.now();
      return [
        PleasureTrend(
          period: 'current',
          averagePleasure: metrics.mean,
          trendDirection: TrendDirection.stable,
          sampleCount: metrics.sampleCount,
          periodStart: now,
          periodEnd: now,
        ),
      ];
    } catch (e, st) {
      developer.log('analyzePleasureTrends failed', name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  /// Correlate pleasure with connection quality and learning effectiveness.
  Future<List<PleasureCorrelation>> analyzePleasureCorrelation() async {
    try {
      final sessions = _connectionMonitor.getAllMonitoringSessions();
      if (sessions.length < 2) return [];
      final pleasure = sessions.map((s) => s.currentMetrics.aiPleasureScore).toList();
      final quality = sessions.map((s) => s.currentMetrics.currentCompatibility).toList();
      final learning = sessions.map((s) => s.currentMetrics.learningEffectiveness).toList();
      final corrQuality = _pearson(pleasure, quality);
      final corrLearning = _pearson(pleasure, learning);
      final now = DateTime.now();
      return [
        PleasureCorrelation(
          metric: 'connection_quality',
          correlation: corrQuality,
          sampleCount: sessions.length,
          computedAt: now,
        ),
        PleasureCorrelation(
          metric: 'learning_effectiveness',
          correlation: corrLearning,
          sampleCount: sessions.length,
          computedAt: now,
        ),
      ];
    } catch (e, st) {
      developer.log('analyzePleasureCorrelation failed', name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  /// Generate optimization recommendations for low-pleasure connections.
  Future<List<PleasureOptimizationRecommendation>> generatePleasureOptimizations() async {
    try {
      final sessions = _connectionMonitor.getAllMonitoringSessions();
      final lowPleasure = sessions
          .where((s) => s.currentMetrics.aiPleasureScore < 0.4)
          .toList();
      final now = DateTime.now();
      final recommendations = <PleasureOptimizationRecommendation>[];
      for (final s in lowPleasure) {
        recommendations.add(PleasureOptimizationRecommendation(
          connectionId: s.connectionId,
          currentPleasure: s.currentMetrics.aiPleasureScore,
          recommendation: 'Improve learning interaction or compatibility alignment',
          priority: Priority.medium,
          computedAt: now,
        ));
      }
      if (recommendations.isEmpty && sessions.isNotEmpty) {
        final avg = sessions.map((s) => s.currentMetrics.aiPleasureScore).reduce((a, b) => a + b) / sessions.length;
        if (avg < 0.6) {
          recommendations.add(PleasureOptimizationRecommendation(
            connectionId: '',
            currentPleasure: avg,
            recommendation: 'Network-wide pleasure is moderate; consider more diverse matching',
            priority: Priority.low,
            computedAt: now,
          ));
        }
      }
      return recommendations;
    } catch (e, st) {
      developer.log('generatePleasureOptimizations failed', name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  static double _pearson(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);
    double sumXY = 0.0;
    for (int i = 0; i < n; i++) {
      sumXY += x[i] * y[i];
    }
    final num = n * sumXY - sumX * sumY;
    final den = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    if (den == 0) return 0.0;
    return (num / den).clamp(-1.0, 1.0);
  }
}

/// Distribution metrics for AI pleasure across the network.
class PleasureNetworkMetrics {
  final double mean;
  final double median;
  final double stdDev;
  final double percentile25;
  final double percentile75;
  final int sampleCount;
  final int highPleasureCount;
  final int lowPleasureCount;
  final DateTime computedAt;

  const PleasureNetworkMetrics({
    required this.mean,
    required this.median,
    required this.stdDev,
    required this.percentile25,
    required this.percentile75,
    required this.sampleCount,
    required this.highPleasureCount,
    required this.lowPleasureCount,
    required this.computedAt,
  });

  static PleasureNetworkMetrics empty() {
    final now = DateTime.now();
    return PleasureNetworkMetrics(
      mean: 0.5,
      median: 0.5,
      stdDev: 0.0,
      percentile25: 0.5,
      percentile75: 0.5,
      sampleCount: 0,
      highPleasureCount: 0,
      lowPleasureCount: 0,
      computedAt: now,
    );
  }
}

/// Pleasure trend over a time period.
class PleasureTrend {
  final String period;
  final double averagePleasure;
  final TrendDirection trendDirection;
  final int sampleCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const PleasureTrend({
    required this.period,
    required this.averagePleasure,
    required this.trendDirection,
    required this.sampleCount,
    required this.periodStart,
    required this.periodEnd,
  });
}

enum TrendDirection { increasing, decreasing, stable }

/// Correlation between pleasure and another metric.
class PleasureCorrelation {
  final String metric;
  final double correlation;
  final int sampleCount;
  final DateTime computedAt;

  const PleasureCorrelation({
    required this.metric,
    required this.correlation,
    required this.sampleCount,
    required this.computedAt,
  });
}

/// Optimization recommendation (pleasure-based).
class PleasureOptimizationRecommendation {
  final String connectionId;
  final double currentPleasure;
  final String recommendation;
  final Priority priority;
  final DateTime computedAt;

  const PleasureOptimizationRecommendation({
    required this.connectionId,
    required this.currentPleasure,
    required this.recommendation,
    required this.priority,
    required this.computedAt,
  });
}

enum Priority { low, medium, high, critical }

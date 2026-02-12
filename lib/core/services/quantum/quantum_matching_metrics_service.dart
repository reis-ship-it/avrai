// Quantum Matching Metrics Service
//
// Tracks A/B testing metrics for quantum vs. classical matching
// Part of Phase 19 Section 19.15: Integration with Existing Matching Systems
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Metrics for a single matching operation
class MatchingMetrics {
  /// User ID
  final String userId;

  /// Matching method used ('quantum' or 'classical')
  final String method;

  /// Compatibility score
  final double compatibility;

  /// Execution time in milliseconds
  final int executionTimeMs;

  /// Atomic timestamp of matching operation
  final AtomicTimestamp timestamp;

  /// Service name (e.g., 'EventMatchingService', 'PartnershipMatchingService')
  final String serviceName;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  MatchingMetrics({
    required this.userId,
    required this.method,
    required this.compatibility,
    required this.executionTimeMs,
    required this.timestamp,
    required this.serviceName,
    this.metadata,
  });

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'method': method,
      'compatibility': compatibility,
      'executionTimeMs': executionTimeMs,
      'timestamp': timestamp.toJson(),
      'serviceName': serviceName,
      'metadata': metadata,
    };
  }
}

/// Service for tracking A/B testing metrics for quantum vs. classical matching
///
/// **Purpose:**
/// - Track which method was used (quantum vs. classical)
/// - Log performance metrics (execution time, compatibility scores)
/// - Compare results for validation
/// - Support gradual rollout decisions
///
/// **Usage:**
/// ```dart
/// final metricsService = sl<QuantumMatchingMetricsService>();
///
/// // Track quantum matching
/// await metricsService.trackMatching(
///   userId: userId,
///   method: 'quantum',
///   compatibility: 0.85,
///   executionTimeMs: 45,
///   serviceName: 'EventMatchingService',
/// );
/// ```
class QuantumMatchingMetricsService {
  static const String _logName = 'QuantumMatchingMetricsService';

  final AtomicClockService _atomicClock;

  // In-memory storage for metrics (in production, persist to database)
  final List<MatchingMetrics> _metrics = [];

  // Maximum metrics to keep in memory (prevent unbounded growth)
  static const int _maxMetrics = 10000;

  QuantumMatchingMetricsService({
    required AtomicClockService atomicClock,
  }) : _atomicClock = atomicClock;

  /// Track a matching operation
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `method`: Matching method ('quantum' or 'classical')
  /// - `compatibility`: Compatibility score (0.0 to 1.0)
  /// - `executionTimeMs`: Execution time in milliseconds
  /// - `serviceName`: Name of the service (e.g., 'EventMatchingService')
  /// - `metadata`: Additional metadata (optional)
  Future<void> trackMatching({
    required String userId,
    required String method,
    required double compatibility,
    required int executionTimeMs,
    required String serviceName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      final metrics = MatchingMetrics(
        userId: userId,
        method: method,
        compatibility: compatibility,
        executionTimeMs: executionTimeMs,
        timestamp: tAtomic,
        serviceName: serviceName,
        metadata: metadata,
      );

      _metrics.add(metrics);

      // Prevent unbounded growth
      if (_metrics.length > _maxMetrics) {
        _metrics.removeAt(0); // Remove oldest
      }

      developer.log(
        'Tracked matching: service=$serviceName, method=$method, compatibility=${compatibility.toStringAsFixed(3)}, time=${executionTimeMs}ms',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error tracking matching metrics: $e',
        name: _logName,
      );
    }
  }

  /// Get metrics summary for a service
  ///
  /// **Parameters:**
  /// - `serviceName`: Name of the service (optional, filters by service)
  /// - `method`: Matching method ('quantum' or 'classical', optional)
  ///
  /// **Returns:**
  /// Map with summary statistics
  Future<Map<String, dynamic>> getMetricsSummary({
    String? serviceName,
    String? method,
  }) async {
    try {
      var filteredMetrics = _metrics;

      if (serviceName != null) {
        filteredMetrics = filteredMetrics
            .where((m) => m.serviceName == serviceName)
            .toList();
      }

      if (method != null) {
        filteredMetrics =
            filteredMetrics.where((m) => m.method == method).toList();
      }

      if (filteredMetrics.isEmpty) {
        return {
          'count': 0,
          'avgCompatibility': 0.0,
          'avgExecutionTimeMs': 0.0,
        };
      }

      final avgCompatibility = filteredMetrics
              .map((m) => m.compatibility)
              .fold(0.0, (sum, score) => sum + score) /
          filteredMetrics.length;

      final avgExecutionTime = filteredMetrics
              .map((m) => m.executionTimeMs)
              .fold(0, (sum, time) => sum + time) /
          filteredMetrics.length;

      return {
        'count': filteredMetrics.length,
        'avgCompatibility': avgCompatibility,
        'avgExecutionTimeMs': avgExecutionTime.toInt(),
        'minCompatibility': filteredMetrics
            .map((m) => m.compatibility)
            .reduce((a, b) => a < b ? a : b),
        'maxCompatibility': filteredMetrics
            .map((m) => m.compatibility)
            .reduce((a, b) => a > b ? a : b),
        'minExecutionTimeMs': filteredMetrics
            .map((m) => m.executionTimeMs)
            .reduce((a, b) => a < b ? a : b),
        'maxExecutionTimeMs': filteredMetrics
            .map((m) => m.executionTimeMs)
            .reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      developer.log(
        'Error getting metrics summary: $e',
        name: _logName,
      );
      return {'error': e.toString()};
    }
  }

  /// Compare quantum vs. classical metrics for a service
  ///
  /// **Parameters:**
  /// - `serviceName`: Name of the service
  ///
  /// **Returns:**
  /// Map with comparison statistics
  Future<Map<String, dynamic>> compareMethods({
    required String serviceName,
  }) async {
    try {
      final quantumSummary = await getMetricsSummary(
        serviceName: serviceName,
        method: 'quantum',
      );
      final classicalSummary = await getMetricsSummary(
        serviceName: serviceName,
        method: 'classical',
      );

      final quantumCount = quantumSummary['count'] as int? ?? 0;
      final classicalCount = classicalSummary['count'] as int? ?? 0;

      if (quantumCount == 0 || classicalCount == 0) {
        return {
          'quantum': quantumSummary,
          'classical': classicalSummary,
          'comparison': 'insufficient_data',
        };
      }

      final quantumAvgCompat = quantumSummary['avgCompatibility'] as double? ?? 0.0;
      final classicalAvgCompat = classicalSummary['avgCompatibility'] as double? ?? 0.0;
      final compatibilityImprovement = quantumAvgCompat - classicalAvgCompat;
      final compatibilityImprovementPercent =
          classicalAvgCompat > 0
              ? (compatibilityImprovement / classicalAvgCompat) * 100
              : 0.0;

      final quantumAvgTime = quantumSummary['avgExecutionTimeMs'] as int? ?? 0;
      final classicalAvgTime = classicalSummary['avgExecutionTimeMs'] as int? ?? 0;
      final timeDifference = quantumAvgTime - classicalAvgTime;
      final timeDifferencePercent =
          classicalAvgTime > 0
              ? (timeDifference / classicalAvgTime) * 100
              : 0.0;

      return {
        'quantum': quantumSummary,
        'classical': classicalSummary,
        'comparison': {
          'compatibilityImprovement': compatibilityImprovement,
          'compatibilityImprovementPercent':
              compatibilityImprovementPercent,
          'timeDifference': timeDifference,
          'timeDifferencePercent': timeDifferencePercent,
          'quantumFaster': timeDifference < 0,
          'quantumBetter': compatibilityImprovement > 0,
        },
      };
    } catch (e) {
      developer.log(
        'Error comparing methods: $e',
        name: _logName,
      );
      return {'error': e.toString()};
    }
  }

  /// Get all metrics (for debugging/analysis)
  List<MatchingMetrics> getAllMetrics() {
    return List.unmodifiable(_metrics);
  }

  /// Clear all metrics (for testing)
  void clearMetrics() {
    _metrics.clear();
  }
}

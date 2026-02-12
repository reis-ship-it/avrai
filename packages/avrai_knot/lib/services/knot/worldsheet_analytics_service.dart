// Worldsheet Analytics Service
//
// Service for detecting patterns, cycles, and trends in worldsheet evolution
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/services/knot/worldsheet_evolution_dynamics.dart';

/// Analytics result for worldsheet
class WorldsheetAnalytics {
  /// Detected patterns
  final List<String> patterns;

  /// Detected cycles (repeating patterns)
  final List<Cycle> cycles;

  /// Trends (increasing, decreasing, stable)
  final Map<String, Trend> trends;

  /// Evolution rate over time
  final double averageEvolutionRate;

  /// Stability trend
  final Trend stabilityTrend;

  /// Density trend
  final Trend densityTrend;

  WorldsheetAnalytics({
    required this.patterns,
    required this.cycles,
    required this.trends,
    required this.averageEvolutionRate,
    required this.stabilityTrend,
    required this.densityTrend,
  });
}

/// Trend information
class Trend {
  /// Trend direction
  final String direction; // 'increasing', 'decreasing', 'stable'

  /// Trend strength (0.0-1.0)
  final double strength;

  /// Rate of change
  final double rate;

  Trend({required this.direction, required this.strength, required this.rate});
}

/// Cycle information
class Cycle {
  /// Cycle type
  final String type;

  /// Cycle period (duration)
  final Duration period;

  /// Cycle amplitude (variation magnitude)
  final double amplitude;

  /// Confidence level (0.0-1.0)
  final double confidence;

  Cycle({
    required this.type,
    required this.period,
    required this.amplitude,
    required this.confidence,
  });
}

/// Service for analyzing worldsheet evolution
///
/// **Responsibilities:**
/// - Detect patterns in worldsheet evolution
/// - Identify cycles (repeating patterns)
/// - Analyze trends (stability, density, evolution rate)
/// - Predict future group dynamics
///
/// **Performance Optimizations (Phase 4):**
/// - Sampling: Samples snapshots for very large datasets to improve performance
/// - Cache: Caches pattern detection results
class WorldsheetAnalyticsService {
  static const String _logName = 'WorldsheetAnalyticsService';

  final WorldsheetEvolutionDynamics _evolutionDynamics;

  // Performance optimization: Sampling threshold
  // If snapshots exceed this count, sample them for analysis
  static const int _samplingThreshold = 1000;
  static const int _maxSampledSnapshots = 500; // Maximum snapshots to analyze

  // Performance optimization: Cache pattern detection results
  // Cache key: worldsheet.groupId
  final Map<String, WorldsheetAnalytics> _analyticsCache = {};
  static const int _maxCacheSize = 500;

  WorldsheetAnalyticsService({WorldsheetEvolutionDynamics? evolutionDynamics})
    : _evolutionDynamics = evolutionDynamics ?? WorldsheetEvolutionDynamics();

  /// Analyze worldsheet for patterns, cycles, and trends
  ///
  /// **Returns:**
  /// - WorldsheetAnalytics with all detected patterns
  ///
  /// **Parameters:**
  /// - `worldsheet`: Worldsheet to analyze
  /// - `useCache`: Whether to use cached results (default: true)
  Future<WorldsheetAnalytics> analyzeWorldsheet({
    required KnotWorldsheet worldsheet,
    bool useCache = true,
  }) async {
    // Performance optimization: Check cache first
    if (useCache) {
      final cached = _analyticsCache[worldsheet.groupId];
      if (cached != null) {
        developer.log(
          '✅ Using cached analytics for ${worldsheet.groupId}',
          name: _logName,
        );
        return cached;
      }
    }

    developer.log(
      'Analyzing worldsheet: ${worldsheet.groupId} (${worldsheet.snapshots.length} snapshots)',
      name: _logName,
    );

    try {
      // Detect patterns
      final patterns = _detectPatterns(worldsheet);

      // Detect cycles
      final cycles = _detectCycles(worldsheet);

      // Analyze trends
      final trends = _analyzeTrends(worldsheet);

      // Calculate average evolution rate
      final avgEvolutionRate = await _calculateAverageEvolutionRate(worldsheet);

      // Analyze stability trend
      final stabilityTrend = _analyzeStabilityTrend(worldsheet);

      // Analyze density trend
      final densityTrend = _analyzeDensityTrend(worldsheet);

      final analytics = WorldsheetAnalytics(
        patterns: patterns,
        cycles: cycles,
        trends: trends,
        averageEvolutionRate: avgEvolutionRate,
        stabilityTrend: stabilityTrend,
        densityTrend: densityTrend,
      );

      developer.log(
        '✅ Worldsheet analytics complete: ${patterns.length} patterns, ${cycles.length} cycles',
        name: _logName,
      );

      // Performance optimization: Cache result
      if (useCache) {
        _addToCache(worldsheet.groupId, analytics);
      }

      return analytics;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to analyze worldsheet: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Detect patterns in worldsheet evolution
  List<String> _detectPatterns(KnotWorldsheet worldsheet) {
    final patterns = <String>[];

    if (worldsheet.snapshots.length < 2) {
      return patterns;
    }

    // Performance optimization: Sample snapshots if too many
    final sorted = _sampleSnapshots(worldsheet.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Pattern: Increasing stability
    final initialStability = worldsheet.initialFabric.stability;
    final finalStability = sorted.last.fabric.stability;
    if (finalStability > initialStability + 0.1) {
      patterns.add('increasing_stability');
    } else if (finalStability < initialStability - 0.1) {
      patterns.add('decreasing_stability');
    }

    // Pattern: Increasing density
    final initialDensity = worldsheet.initialFabric.density;
    final finalDensity = sorted.last.fabric.density;
    if (finalDensity > initialDensity + 0.1) {
      patterns.add('increasing_density');
    } else if (finalDensity < initialDensity - 0.1) {
      patterns.add('decreasing_density');
    }

    // Pattern: Rapid evolution
    if (sorted.length >= 3) {
      final timeSpan = sorted.last.timestamp.difference(sorted.first.timestamp);
      final snapshotRate = sorted.length / (timeSpan.inDays + 1);
      if (snapshotRate > 1.0) {
        patterns.add('rapid_evolution');
      }
    }

    // Pattern: Stable group (low variation)
    if (sorted.length >= 3) {
      final stabilities = sorted.map((s) => s.fabric.stability).toList();
      final avg = stabilities.reduce((a, b) => a + b) / stabilities.length;
      final variance =
          stabilities
              .map((s) => (s - avg) * (s - avg))
              .reduce((a, b) => a + b) /
          stabilities.length;

      if (variance < 0.01) {
        patterns.add('stable_group');
      }
    }

    return patterns;
  }

  /// Detect cycles in worldsheet evolution
  List<Cycle> _detectCycles(KnotWorldsheet worldsheet) {
    final cycles = <Cycle>[];

    if (worldsheet.snapshots.length < 4) {
      return cycles; // Need at least 4 points to detect cycles
    }

    // Performance optimization: Sample snapshots if too many
    final sorted = _sampleSnapshots(worldsheet.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Analyze stability cycles
    final stabilityCycle = _detectStabilityCycle(sorted);
    if (stabilityCycle != null) {
      cycles.add(stabilityCycle);
    }

    // Analyze density cycles
    final densityCycle = _detectDensityCycle(sorted);
    if (densityCycle != null) {
      cycles.add(densityCycle);
    }

    return cycles;
  }

  /// Detect stability cycle
  Cycle? _detectStabilityCycle(List sorted) {
    final stabilities = sorted.map((s) => s.fabric.stability).toList();

    // Simple cycle detection: look for repeating patterns
    if (stabilities.length < 4) return null;

    // Check for period-2 cycle (alternating pattern)
    bool isPeriod2 = true;
    for (int i = 2; i < stabilities.length; i++) {
      if ((stabilities[i] - stabilities[i - 2]).abs() > 0.05) {
        isPeriod2 = false;
        break;
      }
    }

    if (isPeriod2 && sorted.length >= 2) {
      final period = sorted[2].timestamp.difference(sorted[0].timestamp);
      final amplitude = (stabilities[0] - stabilities[1]).abs();

      return Cycle(
        type: 'stability_cycle',
        period: period,
        amplitude: amplitude,
        confidence: 0.7,
      );
    }

    return null;
  }

  /// Detect density cycle
  Cycle? _detectDensityCycle(List sorted) {
    final densities = sorted.map((s) => s.fabric.density).toList();

    if (densities.length < 4) return null;

    // Similar cycle detection for density
    bool isPeriod2 = true;
    for (int i = 2; i < densities.length; i++) {
      if ((densities[i] - densities[i - 2]).abs() > 0.05) {
        isPeriod2 = false;
        break;
      }
    }

    if (isPeriod2 && sorted.length >= 2) {
      final period = sorted[2].timestamp.difference(sorted[0].timestamp);
      final amplitude = (densities[0] - densities[1]).abs();

      return Cycle(
        type: 'density_cycle',
        period: period,
        amplitude: amplitude,
        confidence: 0.7,
      );
    }

    return null;
  }

  /// Analyze trends in worldsheet
  Map<String, Trend> _analyzeTrends(KnotWorldsheet worldsheet) {
    final trends = <String, Trend>{};

    if (worldsheet.snapshots.isEmpty) {
      return trends;
    }

    final sorted = List.from(worldsheet.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Analyze crossing number trend
    final crossingTrend = _analyzeCrossingNumberTrend(sorted);
    if (crossingTrend != null) {
      trends['crossing_number'] = crossingTrend;
    }

    return trends;
  }

  /// Analyze crossing number trend
  Trend? _analyzeCrossingNumberTrend(List sorted) {
    if (sorted.length < 2) return null;

    final crossings = sorted
        .map((s) => s.fabric.invariants.crossingNumber.toDouble())
        .toList();

    // Calculate linear regression slope
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumX2 = 0.0;

    for (int i = 0; i < crossings.length; i++) {
      final x = i.toDouble();
      final y = crossings[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final n = crossings.length.toDouble();
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    String direction;
    if (slope > 0.1) {
      direction = 'increasing';
    } else if (slope < -0.1) {
      direction = 'decreasing';
    } else {
      direction = 'stable';
    }

    return Trend(
      direction: direction,
      strength: slope.abs().clamp(0.0, 1.0),
      rate: slope,
    );
  }

  /// Calculate average evolution rate
  Future<double> _calculateAverageEvolutionRate(
    KnotWorldsheet worldsheet,
  ) async {
    if (worldsheet.snapshots.length < 2) {
      return 0.0;
    }

    // Performance optimization: Sample snapshots if too many
    final sorted = _sampleSnapshots(worldsheet.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalRate = 0.0;
    int count = 0;

    for (int i = 1; i < sorted.length; i++) {
      final rate = _evolutionDynamics.calculateEvolutionRate(
        sorted[i - 1],
        sorted[i],
      );
      totalRate += rate.magnitude;
      count++;
    }

    return count > 0 ? totalRate / count : 0.0;
  }

  /// Analyze stability trend
  Trend _analyzeStabilityTrend(KnotWorldsheet worldsheet) {
    if (worldsheet.snapshots.isEmpty) {
      return Trend(direction: 'stable', strength: 0.0, rate: 0.0);
    }

    final sorted = List.from(worldsheet.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final initial = worldsheet.initialFabric.stability;
    final final_ = sorted.last.fabric.stability;

    final change = final_ - initial;
    String direction;
    if (change > 0.05) {
      direction = 'increasing';
    } else if (change < -0.05) {
      direction = 'decreasing';
    } else {
      direction = 'stable';
    }

    return Trend(
      direction: direction,
      strength: change.abs().clamp(0.0, 1.0),
      rate: change,
    );
  }

  /// Analyze density trend
  Trend _analyzeDensityTrend(KnotWorldsheet worldsheet) {
    if (worldsheet.snapshots.isEmpty) {
      return Trend(direction: 'stable', strength: 0.0, rate: 0.0);
    }

    // Performance optimization: Sample snapshots if too many
    final sorted = _sampleSnapshots(worldsheet.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final initial = worldsheet.initialFabric.density;
    final final_ = sorted.last.fabric.density;

    final change = final_ - initial;
    String direction;
    if (change > 0.05) {
      direction = 'increasing';
    } else if (change < -0.05) {
      direction = 'decreasing';
    } else {
      direction = 'stable';
    }

    return Trend(
      direction: direction,
      strength: change.abs().clamp(0.0, 1.0),
      rate: change,
    );
  }

  // ===== Performance Optimization Methods =====

  /// Sample snapshots if dataset is too large
  ///
  /// **Strategy:**
  /// - If snapshots <= threshold: Return all snapshots
  /// - If snapshots > threshold: Sample uniformly to maxSampledSnapshots
  /// - Always include first and last snapshots
  List<FabricSnapshot> _sampleSnapshots(List<FabricSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return [];
    }

    if (snapshots.length <= _samplingThreshold) {
      return List.from(snapshots);
    }

    developer.log(
      'Sampling ${snapshots.length} snapshots down to $_maxSampledSnapshots for performance',
      name: _logName,
    );

    // Always include first and last
    final sampled = <FabricSnapshot>[];
    sampled.add(snapshots.first);

    // Sample uniformly from middle
    final step = (snapshots.length - 2) / (_maxSampledSnapshots - 2);
    for (int i = 1; i < _maxSampledSnapshots - 1; i++) {
      final index = (i * step).round();
      if (index > 0 && index < snapshots.length - 1) {
        sampled.add(snapshots[index]);
      }
    }

    sampled.add(snapshots.last);

    return sampled;
  }

  /// Add analytics result to cache
  /// Evicts oldest entries if cache exceeds max size
  void _addToCache(String groupId, WorldsheetAnalytics analytics) {
    // Evict oldest entries if cache is full
    if (_analyticsCache.length >= _maxCacheSize) {
      // Remove first entry (FIFO eviction)
      final firstKey = _analyticsCache.keys.first;
      _analyticsCache.remove(firstKey);
      developer.log(
        'Analytics cache full, evicted entry: $firstKey',
        name: _logName,
      );
    }

    _analyticsCache[groupId] = analytics;
  }

  /// Clear analytics cache
  /// Useful for memory management or when worldsheets are updated
  void clearCache() {
    final size = _analyticsCache.length;
    _analyticsCache.clear();
    developer.log('Cleared analytics cache ($size entries)', name: _logName);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _analyticsCache.length,
      'maxSize': _maxCacheSize,
      'usage':
          '${(_analyticsCache.length / _maxCacheSize * 100).toStringAsFixed(1)}%',
    };
  }
}

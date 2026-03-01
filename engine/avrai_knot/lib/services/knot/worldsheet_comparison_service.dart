// Worldsheet Comparison Service
//
// Service for comparing worldsheets and detecting common patterns
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/worldsheet_similarity.dart';
import 'package:avrai_knot/services/knot/worldsheet_evolution_dynamics.dart';

/// Service for comparing worldsheets
///
/// **Responsibilities:**
/// - Compare two worldsheets and calculate similarity metrics
/// - Detect common patterns across multiple worldsheets
/// - Analyze evolution patterns and trends
///
/// **Performance Optimizations (Phase 4):**
/// - Caching: Caches similarity calculations to avoid redundant computations
/// - Cache key: Combination of worldsheet IDs
class WorldsheetComparisonService {
  static const String _logName = 'WorldsheetComparisonService';

  final WorldsheetEvolutionDynamics _evolutionDynamics;

  // Performance optimization: Cache similarity results
  // Cache key: "${ws1.groupId}_${ws2.groupId}" (sorted to ensure bidirectional cache hits)
  final Map<String, WorldsheetSimilarity> _similarityCache = {};
  static const int _maxCacheSize =
      1000; // Limit cache size to prevent memory issues

  WorldsheetComparisonService({WorldsheetEvolutionDynamics? evolutionDynamics})
    : _evolutionDynamics = evolutionDynamics ?? WorldsheetEvolutionDynamics();

  /// Compare two worldsheets
  ///
  /// **Returns:**
  /// - WorldsheetSimilarity with all similarity metrics
  ///
  /// **Parameters:**
  /// - `ws1`: First worldsheet
  /// - `ws2`: Second worldsheet
  /// - `useCache`: Whether to use cached results (default: true)
  Future<WorldsheetSimilarity> compareWorldsheets({
    required KnotWorldsheet ws1,
    required KnotWorldsheet ws2,
    bool useCache = true,
  }) async {
    // Performance optimization: Check cache first
    if (useCache) {
      final cacheKey = _generateCacheKey(ws1.groupId, ws2.groupId);
      final cached = _similarityCache[cacheKey];
      if (cached != null) {
        developer.log(
          '✅ Using cached similarity for ${ws1.groupId} vs ${ws2.groupId}',
          name: _logName,
        );
        return cached;
      }
    }

    developer.log(
      'Comparing worldsheets: ${ws1.groupId} vs ${ws2.groupId}',
      name: _logName,
    );

    try {
      // Calculate individual similarity metrics
      final stabilitySim = _calculateStabilitySimilarity(ws1, ws2);
      final densitySim = _calculateDensitySimilarity(ws1, ws2);
      final evolutionSim = await _calculateEvolutionRateSimilarity(ws1, ws2);
      final invariantSim = _calculateInvariantSimilarity(ws1, ws2);
      final userOverlap = _calculateUserOverlap(ws1, ws2);
      final timeOverlap = _calculateTimeSpanOverlap(ws1, ws2);

      // Detect common patterns
      final commonPatterns = _detectCommonPatterns(ws1, ws2);

      // Calculate overall similarity (weighted average)
      final overallSimilarity =
          (stabilitySim * 0.2 +
                  densitySim * 0.2 +
                  evolutionSim * 0.2 +
                  invariantSim * 0.15 +
                  userOverlap * 0.15 +
                  timeOverlap * 0.1)
              .clamp(0.0, 1.0);

      final similarity = WorldsheetSimilarity(
        overallSimilarity: overallSimilarity,
        stabilitySimilarity: stabilitySim,
        densitySimilarity: densitySim,
        evolutionRateSimilarity: evolutionSim,
        invariantSimilarity: invariantSim,
        userOverlap: userOverlap,
        timeSpanOverlap: timeOverlap,
        commonPatterns: commonPatterns,
      );

      developer.log(
        '✅ Worldsheet comparison complete: similarity=$overallSimilarity',
        name: _logName,
      );

      // Performance optimization: Cache result
      if (useCache) {
        final cacheKey = _generateCacheKey(ws1.groupId, ws2.groupId);
        _addToCache(cacheKey, similarity);
      }

      return similarity;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to compare worldsheets: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate similarity metrics between two worldsheets
  ///
  /// **Returns:**
  /// - Map of metric names to similarity scores
  Future<Map<String, double>> calculateSimilarityMetrics({
    required KnotWorldsheet ws1,
    required KnotWorldsheet ws2,
  }) async {
    final similarity = await compareWorldsheets(ws1: ws1, ws2: ws2);

    return {
      'overall': similarity.overallSimilarity,
      'stability': similarity.stabilitySimilarity,
      'density': similarity.densitySimilarity,
      'evolutionRate': similarity.evolutionRateSimilarity,
      'invariant': similarity.invariantSimilarity,
      'userOverlap': similarity.userOverlap,
      'timeSpanOverlap': similarity.timeSpanOverlap,
    };
  }

  /// Detect common patterns across multiple worldsheets
  ///
  /// **Returns:**
  /// - List of common patterns detected
  ///
  /// **Parameters:**
  /// - `worldsheets`: List of worldsheets to analyze
  Future<List<CommonPattern>> detectCommonPatterns({
    required List<KnotWorldsheet> worldsheets,
  }) async {
    developer.log(
      'Detecting common patterns across ${worldsheets.length} worldsheets',
      name: _logName,
    );

    try {
      final patterns = <CommonPattern>[];

      if (worldsheets.length < 2) {
        return patterns;
      }

      // Pattern 1: Similar stability trends
      final stabilityPattern = _detectStabilityTrendPattern(worldsheets);
      if (stabilityPattern != null) {
        patterns.add(stabilityPattern);
      }

      // Pattern 2: Similar density evolution
      final densityPattern = _detectDensityEvolutionPattern(worldsheets);
      if (densityPattern != null) {
        patterns.add(densityPattern);
      }

      // Pattern 3: Similar user composition
      final userPattern = _detectUserCompositionPattern(worldsheets);
      if (userPattern != null) {
        patterns.add(userPattern);
      }

      // Pattern 4: Similar evolution rates
      final evolutionPattern = await _detectEvolutionRatePattern(worldsheets);
      if (evolutionPattern != null) {
        patterns.add(evolutionPattern);
      }

      developer.log(
        '✅ Detected ${patterns.length} common patterns',
        name: _logName,
      );

      return patterns;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to detect common patterns: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  // ===== Similarity Calculation Methods =====

  /// Calculate stability similarity
  double _calculateStabilitySimilarity(KnotWorldsheet ws1, KnotWorldsheet ws2) {
    final stability1 = ws1.initialFabric.stability;
    final stability2 = ws2.initialFabric.stability;

    // Calculate similarity: 1.0 - normalized difference
    final diff = (stability1 - stability2).abs();
    return (1.0 - diff).clamp(0.0, 1.0);
  }

  /// Calculate density similarity
  double _calculateDensitySimilarity(KnotWorldsheet ws1, KnotWorldsheet ws2) {
    final density1 = ws1.initialFabric.density;
    final density2 = ws2.initialFabric.density;

    // Calculate similarity: 1.0 - normalized difference
    final diff = (density1 - density2).abs();
    return (1.0 - diff).clamp(0.0, 1.0);
  }

  /// Calculate evolution rate similarity
  Future<double> _calculateEvolutionRateSimilarity(
    KnotWorldsheet ws1,
    KnotWorldsheet ws2,
  ) async {
    if (ws1.snapshots.length < 2 || ws2.snapshots.length < 2) {
      return 0.5; // Neutral if not enough data
    }

    // Calculate average evolution rates
    double totalRate1 = 0.0;
    int count1 = 0;

    for (int i = 1; i < ws1.snapshots.length; i++) {
      final rate = _evolutionDynamics.calculateEvolutionRate(
        ws1.snapshots[i - 1],
        ws1.snapshots[i],
      );
      totalRate1 += rate.magnitude;
      count1++;
    }

    double totalRate2 = 0.0;
    int count2 = 0;

    for (int i = 1; i < ws2.snapshots.length; i++) {
      final rate = _evolutionDynamics.calculateEvolutionRate(
        ws2.snapshots[i - 1],
        ws2.snapshots[i],
      );
      totalRate2 += rate.magnitude;
      count2++;
    }

    if (count1 == 0 || count2 == 0) {
      return 0.5;
    }

    final avgRate1 = totalRate1 / count1;
    final avgRate2 = totalRate2 / count2;

    // Calculate similarity
    final diff = (avgRate1 - avgRate2).abs();
    return (1.0 - diff).clamp(0.0, 1.0);
  }

  /// Calculate invariant similarity (Jones/Alexander polynomials)
  double _calculateInvariantSimilarity(KnotWorldsheet ws1, KnotWorldsheet ws2) {
    final inv1 = ws1.initialFabric.invariants;
    final inv2 = ws2.initialFabric.invariants;

    // Compare Jones polynomial coefficients
    final jones1 = inv1.jonesPolynomial.coefficients;
    final jones2 = inv2.jonesPolynomial.coefficients;

    double jonesSim = _comparePolynomials(jones1, jones2);

    // Compare Alexander polynomial coefficients
    final alex1 = inv1.alexanderPolynomial.coefficients;
    final alex2 = inv2.alexanderPolynomial.coefficients;

    double alexSim = _comparePolynomials(alex1, alex2);

    // Average of both
    return (jonesSim + alexSim) / 2.0;
  }

  /// Compare two polynomials
  double _comparePolynomials(List<double> p1, List<double> p2) {
    if (p1.isEmpty && p2.isEmpty) return 1.0;
    if (p1.isEmpty || p2.isEmpty) return 0.0;

    final maxLen = math.max(p1.length, p2.length);
    double totalDiff = 0.0;

    for (int i = 0; i < maxLen; i++) {
      final v1 = i < p1.length ? p1[i] : 0.0;
      final v2 = i < p2.length ? p2[i] : 0.0;
      totalDiff += (v1 - v2).abs();
    }

    // Normalize and convert to similarity
    final avgDiff = totalDiff / maxLen;
    return (1.0 - avgDiff).clamp(0.0, 1.0);
  }

  /// Calculate user overlap
  double _calculateUserOverlap(KnotWorldsheet ws1, KnotWorldsheet ws2) {
    final users1 = ws1.userIds.toSet();
    final users2 = ws2.userIds.toSet();

    if (users1.isEmpty && users2.isEmpty) return 1.0;
    if (users1.isEmpty || users2.isEmpty) return 0.0;

    final intersection = users1.intersection(users2);
    final union = users1.union(users2);

    return intersection.length / union.length;
  }

  /// Calculate time span overlap
  double _calculateTimeSpanOverlap(KnotWorldsheet ws1, KnotWorldsheet ws2) {
    if (ws1.snapshots.isEmpty || ws2.snapshots.isEmpty) {
      return 0.0;
    }

    final sorted1 = List.from(ws1.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sorted2 = List.from(ws2.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final start1 = sorted1.first.timestamp;
    final end1 = sorted1.last.timestamp;
    final start2 = sorted2.first.timestamp;
    final end2 = sorted2.last.timestamp;

    // Calculate overlap
    final overlapStart = start1.isAfter(start2) ? start1 : start2;
    final overlapEnd = end1.isBefore(end2) ? end1 : end2;

    if (overlapStart.isAfter(overlapEnd)) {
      return 0.0; // No overlap
    }

    final overlapDuration = overlapEnd.difference(overlapStart);
    final totalDuration1 = end1.difference(start1);
    final totalDuration2 = end2.difference(start2);

    if (totalDuration1.inMilliseconds == 0 ||
        totalDuration2.inMilliseconds == 0) {
      return 0.0;
    }

    // Average overlap percentage
    final overlap1 =
        overlapDuration.inMilliseconds / totalDuration1.inMilliseconds;
    final overlap2 =
        overlapDuration.inMilliseconds / totalDuration2.inMilliseconds;

    return (overlap1 + overlap2) / 2.0;
  }

  /// Detect common patterns between two worldsheets
  List<String> _detectCommonPatterns(KnotWorldsheet ws1, KnotWorldsheet ws2) {
    final patterns = <String>[];

    // Pattern: Similar stability
    if (_calculateStabilitySimilarity(ws1, ws2) > 0.8) {
      patterns.add('similar_stability');
    }

    // Pattern: Similar density
    if (_calculateDensitySimilarity(ws1, ws2) > 0.8) {
      patterns.add('similar_density');
    }

    // Pattern: High user overlap
    if (_calculateUserOverlap(ws1, ws2) > 0.5) {
      patterns.add('shared_users');
    }

    return patterns;
  }

  // ===== Pattern Detection Methods =====

  /// Detect stability trend pattern
  CommonPattern? _detectStabilityTrendPattern(
    List<KnotWorldsheet> worldsheets,
  ) {
    // Check if all worldsheets have similar stability trends
    final stabilities = worldsheets
        .map((ws) => ws.initialFabric.stability)
        .toList();

    final avg = stabilities.reduce((a, b) => a + b) / stabilities.length;
    final variance =
        stabilities.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) /
        stabilities.length;

    if (variance < 0.01) {
      // Low variance = similar stability
      return CommonPattern(
        patternType: 'similar_stability_trend',
        description: 'All worldsheets have similar stability values',
        confidence: 1.0 - variance,
        worldsheetIds: worldsheets.map((ws) => ws.groupId).toList(),
      );
    }

    return null;
  }

  /// Detect density evolution pattern
  CommonPattern? _detectDensityEvolutionPattern(
    List<KnotWorldsheet> worldsheets,
  ) {
    // Check if densities evolve similarly
    final densities = worldsheets
        .map((ws) => ws.initialFabric.density)
        .toList();

    final avg = densities.reduce((a, b) => a + b) / densities.length;
    final variance =
        densities.map((d) => (d - avg) * (d - avg)).reduce((a, b) => a + b) /
        densities.length;

    if (variance < 0.01) {
      return CommonPattern(
        patternType: 'similar_density_evolution',
        description: 'All worldsheets have similar density values',
        confidence: 1.0 - variance,
        worldsheetIds: worldsheets.map((ws) => ws.groupId).toList(),
      );
    }

    return null;
  }

  /// Detect user composition pattern
  CommonPattern? _detectUserCompositionPattern(
    List<KnotWorldsheet> worldsheets,
  ) {
    // Check if worldsheets share many users
    if (worldsheets.length < 2) return null;

    final allUsers = <String>{};
    final userCounts = <String, int>{};

    for (final ws in worldsheets) {
      for (final userId in ws.userIds) {
        allUsers.add(userId);
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      }
    }

    // Count users that appear in multiple worldsheets
    final sharedUsers = userCounts.entries.where((e) => e.value > 1).length;
    final sharedRatio = allUsers.isEmpty ? 0.0 : sharedUsers / allUsers.length;

    if (sharedRatio > 0.3) {
      return CommonPattern(
        patternType: 'shared_user_composition',
        description: 'Worldsheets share $sharedUsers common users',
        confidence: sharedRatio,
        worldsheetIds: worldsheets.map((ws) => ws.groupId).toList(),
      );
    }

    return null;
  }

  /// Detect evolution rate pattern
  Future<CommonPattern?> _detectEvolutionRatePattern(
    List<KnotWorldsheet> worldsheets,
  ) async {
    // This would require async calculation, so simplified for now
    // In full implementation, would calculate evolution rates and compare
    return null;
  }

  // ===== Performance Optimization Methods =====

  /// Generate cache key for two worldsheet IDs
  /// Sorts IDs to ensure bidirectional cache hits (ws1 vs ws2 = ws2 vs ws1)
  String _generateCacheKey(String id1, String id2) {
    // Sort IDs to ensure cache hits for both directions
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Add similarity result to cache
  /// Evicts oldest entries if cache exceeds max size
  void _addToCache(String key, WorldsheetSimilarity similarity) {
    // Evict oldest entries if cache is full
    if (_similarityCache.length >= _maxCacheSize) {
      // Remove first entry (FIFO eviction)
      final firstKey = _similarityCache.keys.first;
      _similarityCache.remove(firstKey);
      developer.log('Cache full, evicted entry: $firstKey', name: _logName);
    }

    _similarityCache[key] = similarity;
  }

  /// Clear similarity cache
  /// Useful for memory management or when worldsheets are updated
  void clearCache() {
    final size = _similarityCache.length;
    _similarityCache.clear();
    developer.log('Cleared similarity cache ($size entries)', name: _logName);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _similarityCache.length,
      'maxSize': _maxCacheSize,
      'usage':
          '${(_similarityCache.length / _maxCacheSize * 100).toStringAsFixed(1)}%',
    };
  }
}

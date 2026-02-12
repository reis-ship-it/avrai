// Knot Cache Service
//
// Caching service for knots and compatibility calculations
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Optional Enhancement: Performance Optimization

import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/compatibility_score.dart';

/// Cache entry with expiration
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry(this.value, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Service for caching knots and compatibility calculations
///
/// **Purpose:** Improve performance by caching frequently accessed data
/// **Cache Strategy:**
/// - Knots: 1 hour TTL
/// - Compatibility scores: 30 minutes TTL
/// - Max cache size: 1000 entries (LRU eviction)
class KnotCacheService {
  static const String _logName = 'KnotCacheService';

  // Cache TTLs
  static const Duration _knotCacheTTL = Duration(hours: 1);
  static const Duration _compatibilityCacheTTL = Duration(minutes: 30);

  // Max cache sizes
  static const int _maxKnotCacheSize = 500;
  static const int _maxCompatibilityCacheSize = 1000;

  // Caches
  final Map<String, _CacheEntry<PersonalityKnot>> _knotCache = {};
  final Map<String, _CacheEntry<CompatibilityScore>> _compatibilityCache = {};

  /// Get cached knot
  ///
  /// **Returns:** Cached knot if available and not expired, null otherwise
  PersonalityKnot? getCachedKnot(String agentId) {
    final entry = _knotCache[agentId];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _knotCache.remove(agentId);
      developer.log(
        'Cache expired for knot: ${agentId.substring(0, 10)}...',
        name: _logName,
      );
      return null;
    }

    developer.log(
      'Cache hit for knot: ${agentId.substring(0, 10)}...',
      name: _logName,
    );
    return entry.value;
  }

  /// Cache a knot
  ///
  /// **Parameters:**
  /// - `agentId`: Agent identifier
  /// - `knot`: Knot to cache
  void cacheKnot(String agentId, PersonalityKnot knot) {
    // Evict if cache is full (LRU - remove oldest)
    if (_knotCache.length >= _maxKnotCacheSize &&
        !_knotCache.containsKey(agentId)) {
      _evictOldestKnot();
    }

    _knotCache[agentId] = _CacheEntry(knot, _knotCacheTTL);
    developer.log(
      'Cached knot: ${agentId.substring(0, 10)}... (cache size: ${_knotCache.length})',
      name: _logName,
    );
  }

  /// Get cached compatibility score
  ///
  /// **Parameters:**
  /// - `agentIdA`: First agent identifier
  /// - `agentIdB`: Second agent identifier
  ///
  /// **Returns:** Cached compatibility score if available and not expired, null otherwise
  CompatibilityScore? getCachedCompatibility(String agentIdA, String agentIdB) {
    final key = _getCompatibilityKey(agentIdA, agentIdB);
    final entry = _compatibilityCache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _compatibilityCache.remove(key);
      return null;
    }

    developer.log(
      'Cache hit for compatibility: ${agentIdA.substring(0, 10)}... <-> ${agentIdB.substring(0, 10)}...',
      name: _logName,
    );
    return entry.value;
  }

  /// Cache a compatibility score
  ///
  /// **Parameters:**
  /// - `agentIdA`: First agent identifier
  /// - `agentIdB`: Second agent identifier
  /// - `score`: Compatibility score to cache
  void cacheCompatibility(
    String agentIdA,
    String agentIdB,
    CompatibilityScore score,
  ) {
    final key = _getCompatibilityKey(agentIdA, agentIdB);

    // Evict if cache is full (LRU - remove oldest)
    if (_compatibilityCache.length >= _maxCompatibilityCacheSize &&
        !_compatibilityCache.containsKey(key)) {
      _evictOldestCompatibility();
    }

    _compatibilityCache[key] = _CacheEntry(score, _compatibilityCacheTTL);
    developer.log(
      'Cached compatibility: ${agentIdA.substring(0, 10)}... <-> ${agentIdB.substring(0, 10)}... (cache size: ${_compatibilityCache.length})',
      name: _logName,
    );
  }

  /// Clear all caches
  void clearAll() {
    _knotCache.clear();
    _compatibilityCache.clear();
    developer.log('Cleared all caches', name: _logName);
  }

  /// Clear expired entries
  void clearExpired() {
    final knotKeysToRemove = _knotCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in knotKeysToRemove) {
      _knotCache.remove(key);
    }

    final compatibilityKeysToRemove = _compatibilityCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in compatibilityKeysToRemove) {
      _compatibilityCache.remove(key);
    }

    if (knotKeysToRemove.isNotEmpty || compatibilityKeysToRemove.isNotEmpty) {
      developer.log(
        'Cleared ${knotKeysToRemove.length} expired knots and ${compatibilityKeysToRemove.length} expired compatibility scores',
        name: _logName,
      );
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'knotCacheSize': _knotCache.length,
      'knotCacheMaxSize': _maxKnotCacheSize,
      'compatibilityCacheSize': _compatibilityCache.length,
      'compatibilityCacheMaxSize': _maxCompatibilityCacheSize,
      'knotCacheHitRate': 0.0, // Would need to track hits/misses
      'compatibilityCacheHitRate': 0.0, // Would need to track hits/misses
    };
  }

  /// Generate compatibility cache key (symmetric)
  String _getCompatibilityKey(String agentIdA, String agentIdB) {
    // Ensure consistent ordering (smaller ID first)
    if (agentIdA.compareTo(agentIdB) < 0) {
      return '$agentIdA:$agentIdB';
    } else {
      return '$agentIdB:$agentIdA';
    }
  }

  /// Evict oldest knot entry (LRU)
  void _evictOldestKnot() {
    if (_knotCache.isEmpty) return;

    // Find oldest entry (earliest expiration)
    String? oldestKey;
    DateTime? oldestExpiration;

    for (final entry in _knotCache.entries) {
      if (oldestExpiration == null ||
          entry.value.expiresAt.isBefore(oldestExpiration)) {
        oldestKey = entry.key;
        oldestExpiration = entry.value.expiresAt;
      }
    }

    if (oldestKey != null) {
      _knotCache.remove(oldestKey);
      developer.log(
        'Evicted oldest knot from cache: ${oldestKey.substring(0, 10)}...',
        name: _logName,
      );
    }
  }

  /// Evict oldest compatibility entry (LRU)
  void _evictOldestCompatibility() {
    if (_compatibilityCache.isEmpty) return;

    // Find oldest entry (earliest expiration)
    String? oldestKey;
    DateTime? oldestExpiration;

    for (final entry in _compatibilityCache.entries) {
      if (oldestExpiration == null ||
          entry.value.expiresAt.isBefore(oldestExpiration)) {
        oldestKey = entry.key;
        oldestExpiration = entry.value.expiresAt;
      }
    }

    if (oldestKey != null) {
      _compatibilityCache.remove(oldestKey);
      developer.log(
        'Evicted oldest compatibility from cache: ${oldestKey.substring(0, 10)}...',
        name: _logName,
      );
    }
  }
}

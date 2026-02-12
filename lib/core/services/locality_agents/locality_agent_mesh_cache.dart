import 'dart:developer' as developer;
import 'package:avrai/core/services/places/geohash_service.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

/// Cache for locality agent updates received through mesh network
///
/// Stores mesh updates temporarily so they can be used for neighbor smoothing.
/// Updates expire after TTL to prevent stale data.
class LocalityAgentMeshCache {
  static const String _logName = 'LocalityAgentMeshCache';
  static const String _box = 'spots_ai';
  static const Duration _defaultTtl = Duration(hours: 6);

  final StorageService _storage;

  // In-memory cache for quick access (keyed by stableKey)
  final Map<String, _CachedMeshUpdate> _memoryCache = {};

  LocalityAgentMeshCache({required StorageService storage})
      : _storage = storage;

  /// Store a mesh update in cache
  Future<void> storeMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required DateTime receivedAt,
    Duration? ttl,
  }) async {
    try {
      final expiresAt = receivedAt.add(ttl ?? _defaultTtl);
      final cached = _CachedMeshUpdate(
        key: key,
        delta12: delta12,
        receivedAt: receivedAt,
        expiresAt: expiresAt,
      );

      // Store in memory
      _memoryCache[key.stableKey] = cached;

      // Persist to storage (best-effort)
      try {
        await _storage.setObject(
          _cacheKey(key),
          cached.toJson(),
          box: _box,
        );
      } catch (e) {
        developer.log(
          'Failed to persist mesh update to storage: $e',
          name: _logName,
        );
        // Continue - memory cache is sufficient
      }

      developer.log(
        'Stored mesh update: ${key.stableKey} (expires at $expiresAt)',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed to store mesh update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get mesh updates for neighbors of a given key
  ///
  /// Returns delta vectors for geohash neighbors that are still valid (not expired).
  Future<List<List<double>>> getNeighborMeshUpdates(
    LocalityAgentKeyV1 key,
  ) async {
    try {
      // Get 8-neighborhood geohashes
      final neighborGeohashes = GeohashService.neighbors(
        geohash: key.geohashPrefix,
      );

      final updates = <_CachedMeshUpdate>[];
      final now = DateTime.now();

      for (final geohash in neighborGeohashes) {
        final neighborKey = LocalityAgentKeyV1(
          geohashPrefix: geohash,
          precision: key.precision,
          cityCode: key.cityCode,
        );

        // Check memory cache first
        final cached = _memoryCache[neighborKey.stableKey];
        if (cached != null && cached.expiresAt.isAfter(now)) {
          updates.add(cached);
          continue;
        }

        // Check storage cache
        try {
          final stored = _storage.getObject<Map<String, dynamic>>(
            _cacheKey(neighborKey),
            box: _box,
          );
          if (stored != null) {
            final storedUpdate = _CachedMeshUpdate.fromJson(stored);
            if (storedUpdate.expiresAt.isAfter(now)) {
              // Restore to memory cache
              _memoryCache[neighborKey.stableKey] = storedUpdate;
              updates.add(storedUpdate);
            }
          }
        } catch (e) {
          // Ignore storage errors
        }
      }

      // Clean up expired entries
      _cleanupExpired();

      // Return just the delta vectors
      return updates.map((update) => List<double>.from(update.delta)).toList();
    } catch (e, st) {
      developer.log(
        'Failed to get neighbor mesh updates: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Clean up expired entries from memory cache
  void _cleanupExpired() {
    final now = DateTime.now();
    _memoryCache.removeWhere((key, value) => value.expiresAt.isBefore(now));
  }

  String _cacheKey(LocalityAgentKeyV1 key) =>
      'locality_agent_mesh_cache:${key.stableKey}';
}

/// Cached mesh update with expiration
class _CachedMeshUpdate {
  final LocalityAgentKeyV1 key;
  final List<double> delta12;
  final DateTime receivedAt;
  final DateTime expiresAt;

  // Expose delta12 for external access
  List<double> get delta => List<double>.unmodifiable(delta12);

  _CachedMeshUpdate({
    required this.key,
    required this.delta12,
    required this.receivedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key.toJson(),
      'delta12': delta12,
      'received_at': receivedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  factory _CachedMeshUpdate.fromJson(Map<String, dynamic> json) {
    return _CachedMeshUpdate(
      key: LocalityAgentKeyV1.fromJson(json['key'] as Map<String, dynamic>),
      delta12: (json['delta12'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      receivedAt: DateTime.parse(json['received_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

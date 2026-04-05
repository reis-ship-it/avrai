import 'dart:developer' as developer;
import 'package:avrai_runtime_os/config/ai2ai_retention_config.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Cache for locality agent updates received through mesh network
///
/// Stores mesh updates temporarily so they can be used for neighbor smoothing.
/// Updates expire after TTL to prevent stale data.
class LocalityAgentMeshCache {
  static const String _logName = 'LocalityAgentMeshCache';
  static const String _box = 'spots_ai';
  static final Duration _defaultTtl =
      Ai2AiRetentionConfig.localityMeshHotCache.ttl ?? const Duration(hours: 6);
  static const String _cacheKeyPrefix = 'locality_agent_mesh_cache:';

  final StorageService _storage;

  // In-memory cache for quick access (keyed by stableKey)
  final Map<String, _CachedMeshUpdate> _memoryCache = {};

  LocalityAgentMeshCache({required StorageService storage})
      : _storage = storage;

  Ai2AiRetentionPolicy get retentionPolicy =>
      Ai2AiRetentionConfig.localityMeshHotCache;

  /// Store a mesh update in cache
  Future<LocalityAgentMeshStoreResult> storeMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required DateTime receivedAt,
    Duration? ttl,
  }) async {
    try {
      final effectiveTtl = ttl ?? _defaultTtl;
      final expiresAt = receivedAt.add(effectiveTtl);
      final prior = _memoryCache[key.stableKey] ?? _readStoredUpdate(key);
      final cached = _CachedMeshUpdate(
        key: key,
        delta12: delta12,
        receivedAt: receivedAt,
        expiresAt: expiresAt,
        supersededPriorRecord: prior != null,
        supersededReceivedAt: prior?.receivedAt,
        supersededExpiresAt: prior?.expiresAt,
        supersededAt: prior == null ? null : receivedAt,
      );

      // Store in memory
      _memoryCache[key.stableKey] = cached;

      // Persist to storage (best-effort)
      var persistedToStorage = false;
      try {
        await _storage.setObject(
          _cacheKey(key),
          cached.toJson(),
          box: _box,
        );
        persistedToStorage = true;
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
      return LocalityAgentMeshStoreResult(
        stableKey: key.stableKey,
        expiresAt: expiresAt,
        persistedToStorage: persistedToStorage,
        supersededPriorRecord: prior != null,
        supersededReceivedAt: prior?.receivedAt,
      );
    } catch (e, st) {
      developer.log(
        'Failed to store mesh update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return LocalityAgentMeshStoreResult(
        stableKey: key.stableKey,
        expiresAt: receivedAt.add(ttl ?? _defaultTtl),
        persistedToStorage: false,
        supersededPriorRecord: false,
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
        if (cached != null) {
          if (cached.expiresAt.isAfter(now)) {
            updates.add(cached);
            continue;
          }
          _memoryCache.remove(neighborKey.stableKey);
          await _removeStoredUpdate(neighborKey);
        }

        // Check storage cache
        try {
          final storedUpdate = _readStoredUpdate(neighborKey);
          if (storedUpdate != null) {
            if (storedUpdate.expiresAt.isAfter(now)) {
              // Restore to memory cache
              _memoryCache[neighborKey.stableKey] = storedUpdate;
              updates.add(storedUpdate);
            } else {
              await _removeStoredUpdate(neighborKey);
            }
          }
        } catch (e) {
          // Ignore storage errors
        }
      }

      // Clean up expired entries
      await cleanupExpiredEntries();

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

  /// Clean up expired entries from memory cache and persisted storage.
  Future<LocalityAgentMeshCleanupResult> cleanupExpiredEntries() async {
    final now = DateTime.now();
    final expiredMemoryKeys = <String>[];
    _memoryCache.removeWhere((key, value) {
      final isExpired = !value.expiresAt.isAfter(now);
      if (isExpired) {
        expiredMemoryKeys.add(key);
      }
      return isExpired;
    });

    final expiredPersistedKeys = <String>{};
    final failures = <String>[];
    for (final storageKey in _storage.getKeys(box: _box)) {
      if (!storageKey.startsWith(_cacheKeyPrefix)) {
        continue;
      }
      try {
        final stored =
            _storage.getObject<Map<String, dynamic>>(storageKey, box: _box);
        if (stored == null) {
          continue;
        }
        final record = _CachedMeshUpdate.fromJson(stored);
        if (!record.expiresAt.isAfter(now)) {
          await _storage.remove(storageKey, box: _box);
          expiredPersistedKeys.add(record.key.stableKey);
        }
      } catch (e) {
        failures.add('$storageKey:$e');
      }
    }

    return LocalityAgentMeshCleanupResult(
      expiredMemoryEntriesRemoved: expiredMemoryKeys.length,
      expiredPersistedEntriesRemoved: expiredPersistedKeys.length,
      expiredStableKeys: <String>{
        ...expiredMemoryKeys,
        ...expiredPersistedKeys,
      }.toList(growable: false),
      failures: failures,
    );
  }

  String _cacheKey(LocalityAgentKeyV1 key) =>
      '$_cacheKeyPrefix${key.stableKey}';

  _CachedMeshUpdate? _readStoredUpdate(LocalityAgentKeyV1 key) {
    final stored = _storage.getObject<Map<String, dynamic>>(
      _cacheKey(key),
      box: _box,
    );
    if (stored == null) {
      return null;
    }
    return _CachedMeshUpdate.fromJson(stored);
  }

  Future<void> _removeStoredUpdate(LocalityAgentKeyV1 key) async {
    try {
      if (_storage.containsKey(_cacheKey(key), box: _box)) {
        await _storage.remove(_cacheKey(key), box: _box);
      }
    } catch (_) {
      // Ignore storage cleanup errors for best-effort cache expiry.
    }
  }
}

class LocalityAgentMeshStoreResult {
  final String stableKey;
  final DateTime expiresAt;
  final bool persistedToStorage;
  final bool supersededPriorRecord;
  final DateTime? supersededReceivedAt;

  const LocalityAgentMeshStoreResult({
    required this.stableKey,
    required this.expiresAt,
    required this.persistedToStorage,
    required this.supersededPriorRecord,
    this.supersededReceivedAt,
  });
}

class LocalityAgentMeshCleanupResult {
  final int expiredMemoryEntriesRemoved;
  final int expiredPersistedEntriesRemoved;
  final List<String> expiredStableKeys;
  final List<String> failures;

  const LocalityAgentMeshCleanupResult({
    required this.expiredMemoryEntriesRemoved,
    required this.expiredPersistedEntriesRemoved,
    required this.expiredStableKeys,
    required this.failures,
  });
}

/// Cached mesh update with expiration
class _CachedMeshUpdate {
  final LocalityAgentKeyV1 key;
  final List<double> delta12;
  final DateTime receivedAt;
  final DateTime expiresAt;
  final bool supersededPriorRecord;
  final DateTime? supersededReceivedAt;
  final DateTime? supersededExpiresAt;
  final DateTime? supersededAt;

  // Expose delta12 for external access
  List<double> get delta => List<double>.unmodifiable(delta12);

  _CachedMeshUpdate({
    required this.key,
    required this.delta12,
    required this.receivedAt,
    required this.expiresAt,
    this.supersededPriorRecord = false,
    this.supersededReceivedAt,
    this.supersededExpiresAt,
    this.supersededAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key.toJson(),
      'delta12': delta12,
      'received_at': receivedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'superseded_prior_record': supersededPriorRecord,
      if (supersededReceivedAt != null)
        'superseded_received_at': supersededReceivedAt!.toIso8601String(),
      if (supersededExpiresAt != null)
        'superseded_expires_at': supersededExpiresAt!.toIso8601String(),
      if (supersededAt != null)
        'superseded_at': supersededAt!.toIso8601String(),
    };
  }

  factory _CachedMeshUpdate.fromJson(Map<String, dynamic> json) {
    return _CachedMeshUpdate(
      key: LocalityAgentKeyV1.fromJson(json['key'] as Map<String, dynamic>),
      delta12:
          (json['delta12'] as List).map((e) => (e as num).toDouble()).toList(),
      receivedAt: DateTime.parse(json['received_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      supersededPriorRecord: json['superseded_prior_record'] as bool? ?? false,
      supersededReceivedAt:
          DateTime.tryParse((json['superseded_received_at'] ?? '').toString()),
      supersededExpiresAt:
          DateTime.tryParse((json['superseded_expires_at'] ?? '').toString()),
      supersededAt: DateTime.tryParse((json['superseded_at'] ?? '').toString()),
    );
  }
}

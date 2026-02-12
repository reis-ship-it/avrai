import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:get_storage/get_storage.dart';

import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

/// Caches MapKit/Apple Places (Spot) for offline use on macOS.
///
/// Keyed by [Spot.id] (e.g. apple_...). Used by [MapKitPlacesDataSource]
/// and [HybridSearchRepository] offline branch on macOS.
///
/// Phase 26: Migrated from Sembast to GetStorage for simpler key-value caching.
class MapKitPlacesCacheService {
  static const String _logName = 'MapKitPlacesCacheService';
  static const String _boxName = 'apple_places_cache';
  static const Duration _placeExpiry = Duration(days: 7);

  final AppLogger _logger =
      const AppLogger(defaultTag: 'avrai', minimumLevel: LogLevel.debug);

  GetStorage? _storage;

  GetStorage get _box {
    _storage ??= GetStorage(_boxName);
    return _storage!;
  }

  /// Initialize the cache storage
  static Future<void> init() async {
    await GetStorage.init(_boxName);
  }

  Future<void> cachePlace(Spot spot) async {
    try {
      final placeData = {
        ...spot.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_placeExpiry).toIso8601String(),
      };
      await _box.write(spot.id, placeData);
      developer.log('Cached Apple place: ${spot.id}', name: _logName);
    } catch (e) {
      _logger.error('Error caching Apple place', error: e, tag: _logName);
    }
  }

  Future<void> cachePlaces(List<Spot> spots) async {
    try {
      if (spots.isEmpty) return;
      for (final spot in spots) {
        final placeData = {
          ...spot.toJson(),
          'cached_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(_placeExpiry).toIso8601String(),
        };
        await _box.write(spot.id, placeData);
      }
      developer.log('Cached ${spots.length} Apple places', name: _logName);
    } catch (e) {
      _logger.error('Error caching Apple places', error: e, tag: _logName);
    }
  }

  Future<List<Spot>> searchCachedPlaces(String query) async {
    try {
      final allKeys = _box.getKeys<Iterable<String>>();
      final results = <Spot>[];
      final queryLower = query.toLowerCase();

      for (final key in allKeys) {
        final data = _box.read<Map<String, dynamic>>(key);
        if (data == null) continue;

        // Check expiry
        final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '');
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          await _box.remove(key);
          continue;
        }

        // Check if matches query
        final name = (data['name'] as String? ?? '').toLowerCase();
        final address = (data['address'] as String? ?? '').toLowerCase();
        final category = (data['category'] as String? ?? '').toLowerCase();

        if (name.contains(queryLower) ||
            address.contains(queryLower) ||
            category.contains(queryLower)) {
          try {
            results.add(Spot.fromJson(data));
          } catch (e) {
            developer.log('Error parsing cached spot: $e', name: _logName);
          }
        }
      }

      developer.log(
        'Found ${results.length} cached Apple places matching "$query"',
        name: _logName,
      );
      return results;
    } catch (e) {
      _logger.error('Error searching cached Apple places', error: e, tag: _logName);
      return [];
    }
  }

  Future<List<Spot>> getCachedPlacesNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int? radius, // Backward compatibility - radius in meters
  }) async {
    // Use radius (meters) if provided, otherwise use radiusKm
    final effectiveRadiusKm = radius != null ? radius / 1000.0 : radiusKm;
    try {
      final allKeys = _box.getKeys<Iterable<String>>();
      final results = <Spot>[];

      for (final key in allKeys) {
        final data = _box.read<Map<String, dynamic>>(key);
        if (data == null) continue;

        // Check expiry
        final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '');
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          await _box.remove(key);
          continue;
        }

        // Check distance
        final spotLat = data['latitude'] as double?;
        final spotLon = data['longitude'] as double?;
        if (spotLat != null && spotLon != null) {
          final distance = _calculateDistance(latitude, longitude, spotLat, spotLon);
          if (distance <= effectiveRadiusKm) {
            try {
              results.add(Spot.fromJson(data));
            } catch (e) {
              developer.log('Error parsing cached spot: $e', name: _logName);
            }
          }
        }
      }

      developer.log(
        'Found ${results.length} cached Apple places within ${effectiveRadiusKm}km',
        name: _logName,
      );
      return results;
    } catch (e) {
      _logger.error('Error getting nearby cached Apple places', error: e, tag: _logName);
      return [];
    }
  }

  Future<Spot?> getCachedPlace(String placeId) async {
    try {
      final data = _box.read<Map<String, dynamic>>(placeId);
      if (data == null) return null;

      // Check expiry
      final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '');
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        await _box.remove(placeId);
        return null;
      }

      return Spot.fromJson(data);
    } catch (e) {
      _logger.error('Error getting cached Apple place', error: e, tag: _logName);
      return null;
    }
  }

  Future<void> clearExpiredCache() async {
    try {
      final allKeys = _box.getKeys<Iterable<String>>();
      int cleared = 0;

      for (final key in allKeys) {
        final data = _box.read<Map<String, dynamic>>(key);
        if (data == null) continue;

        final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '');
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          await _box.remove(key);
          cleared++;
        }
      }

      developer.log('Cleared $cleared expired Apple place entries', name: _logName);
    } catch (e) {
      _logger.error('Error clearing expired Apple cache', error: e, tag: _logName);
    }
  }

  Future<void> clearAllCache() async {
    try {
      await _box.erase();
      developer.log('Cleared all Apple places cache', name: _logName);
    } catch (e) {
      _logger.error('Error clearing all Apple cache', error: e, tag: _logName);
    }
  }

  /// Calculate distance in km using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}

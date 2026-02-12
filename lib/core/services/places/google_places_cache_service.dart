import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:get_storage/get_storage.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

/// Google Places Cache Service
/// Caches Google Places data locally for offline use
/// OUR_GUTS.md: "Effortless, Seamless Discovery" - Offline-capable search
class GooglePlacesCacheService {
  static const String _logName = 'GooglePlacesCacheService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  // Cache storage
  final GetStorage _box = GetStorage('google_places_cache');
  
  // Cache expiry durations
  static const Duration _placeExpiry = Duration(days: 7); // Cache places for 7 days
  static const Duration _detailsExpiry = Duration(days: 30); // Cache details for 30 days
  
  /// Cache a Google Place Spot
  Future<void> cachePlace(Spot spot) async {
    try {
      if (!spot.hasGooglePlaceId) {
        developer.log('Spot does not have Google Place ID, skipping cache', name: _logName);
        return;
      }
      
      final placeData = {
        ...spot.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_placeExpiry).toIso8601String(),
      };
      
      await _box.write('place_${spot.googlePlaceId!}', placeData);
      developer.log('Cached Google Place: ${spot.googlePlaceId}', name: _logName);
    } catch (e) {
      _logger.error('Error caching Google Place', error: e, tag: _logName);
    }
  }
  
  /// Cache multiple Google Place Spots
  Future<void> cachePlaces(List<Spot> spots) async {
    try {
      final placesToCache = spots.where((spot) => spot.hasGooglePlaceId).toList();
      if (placesToCache.isEmpty) return;
      
      for (final spot in placesToCache) {
        final placeData = {
          ...spot.toJson(),
          'cached_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(_placeExpiry).toIso8601String(),
        };
        await _box.write('place_${spot.googlePlaceId!}', placeData);
      }
      
      developer.log('Cached ${placesToCache.length} Google Places', name: _logName);
    } catch (e) {
      _logger.error('Error caching Google Places', error: e, tag: _logName);
    }
  }
  
  /// Get cached Google Place by Place ID
  Future<Spot?> getCachedPlace(String placeId) async {
    try {
      final cachedData = _box.read<Map<String, dynamic>>('place_$placeId');
      
      if (cachedData == null) {
        return null;
      }
      
      // Check if cache is expired
      final expiresAt = DateTime.parse(cachedData['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        developer.log('Cached place expired: $placeId', name: _logName);
        await _box.remove('place_$placeId');
        return null;
      }
      
      // Remove cache metadata before creating Spot
      final spotData = Map<String, dynamic>.from(cachedData);
      spotData.remove('cached_at');
      spotData.remove('expires_at');
      
      return Spot.fromJson(spotData);
    } catch (e) {
      _logger.error('Error getting cached place', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get cached Google Place details by Place ID
  Future<Map<String, dynamic>?> getCachedPlaceDetails(String placeId) async {
    try {
      final cachedData = _box.read<Map<String, dynamic>>('detail_$placeId');
      
      if (cachedData == null) {
        return null;
      }
      
      // Check if cache is expired
      final expiresAt = DateTime.parse(cachedData['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        developer.log('Cached place details expired: $placeId', name: _logName);
        await _box.remove('detail_$placeId');
        return null;
      }
      
      return cachedData;
    } catch (e) {
      _logger.error('Error getting cached place details', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Cache Google Place details
  Future<void> cachePlaceDetails(String placeId, Map<String, dynamic> details) async {
    try {
      final detailsData = {
        ...details,
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_detailsExpiry).toIso8601String(),
      };
      
      await _box.write('detail_$placeId', detailsData);
      developer.log('Cached Google Place details: $placeId', name: _logName);
    } catch (e) {
      _logger.error('Error caching place details', error: e, tag: _logName);
    }
  }
  
  /// Search cached places by query (for offline search)
  Future<List<Spot>> searchCachedPlaces(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final now = DateTime.now();
      
      final results = <Spot>[];
      
      for (final key in _box.getKeys()) {
        if (!key.toString().startsWith('place_')) continue;
        final data = _box.read<Map<String, dynamic>>(key.toString());
        if (data == null) continue;
        
        // Check if expired
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        if (now.isAfter(expiresAt)) {
          continue;
        }
        
        // Search in name, description, category
        final name = (data['name'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        
        if (name.contains(queryLower) || 
            description.contains(queryLower) || 
            category.contains(queryLower)) {
          // Remove cache metadata
          final spotData = Map<String, dynamic>.from(data);
          spotData.remove('cached_at');
          spotData.remove('expires_at');
          
          results.add(Spot.fromJson(spotData));
        }
      }
      
      developer.log('Found ${results.length} cached places for query: $query', name: _logName);
      return results;
    } catch (e) {
      _logger.error('Error searching cached places', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get cached places near a location (for offline nearby search)
  Future<List<Spot>> getCachedPlacesNearby({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      final now = DateTime.now();
      
      final results = <Spot>[];
      
      for (final key in _box.getKeys()) {
        if (!key.toString().startsWith('place_')) continue;
        final data = _box.read<Map<String, dynamic>>(key.toString());
        if (data == null) continue;
        
        // Check if expired
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        if (now.isAfter(expiresAt)) {
          continue;
        }
        
        // Calculate distance
        final spotLat = (data['latitude'] ?? 0.0).toDouble();
        final spotLng = (data['longitude'] ?? 0.0).toDouble();
        final distance = _calculateDistance(latitude, longitude, spotLat, spotLng);
        
        if (distance <= radius) {
          // Remove cache metadata
          final spotData = Map<String, dynamic>.from(data);
          spotData.remove('cached_at');
          spotData.remove('expires_at');
          
          results.add(Spot.fromJson(spotData));
        }
      }
      
      developer.log('Found ${results.length} cached places nearby', name: _logName);
      return results;
    } catch (e) {
      _logger.error('Error getting cached places nearby', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();
      
      // Clear expired places
      int expiredPlaces = 0;
      for (final key in _box.getKeys().toList()) {
        if (!key.toString().startsWith('place_')) continue;
        final data = _box.read<Map<String, dynamic>>(key.toString());
        if (data == null) continue;
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        if (now.isAfter(expiresAt)) {
          await _box.remove(key.toString());
          expiredPlaces++;
        }
      }
      
      // Clear expired place details
      int expiredDetails = 0;
      for (final key in _box.getKeys().toList()) {
        if (!key.toString().startsWith('detail_')) continue;
        final data = _box.read<Map<String, dynamic>>(key.toString());
        if (data == null) continue;
        final expiresAt = DateTime.parse(data['expires_at'] as String);
        if (now.isAfter(expiresAt)) {
          await _box.remove(key.toString());
          expiredDetails++;
        }
      }
      
      developer.log('Cleared $expiredPlaces expired places and $expiredDetails expired details', name: _logName);
    } catch (e) {
      _logger.error('Error clearing expired cache', error: e, tag: _logName);
    }
  }
  
  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) => degrees * (math.pi / 180);
}


import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

/// Google Place ID Finder Service (LEGACY - DEPRECATED)
/// 
/// ⚠️ DEPRECATED: This implementation uses the legacy Google Places API.
/// Use [GooglePlaceIdFinderServiceNew] instead, which uses the new Places API (New).
/// 
/// This file is kept for reference but is no longer used in production.
/// Migration completed: See [GOOGLE_PLACES_API_NEW_MIGRATION_COMPLETE.md]
/// 
/// Finds Google Place IDs for community spots by matching location and name
/// OUR_GUTS.md: "Community, Not Just Places" - Link community spots to Google Maps
@Deprecated('Use GooglePlaceIdFinderServiceNew instead. This uses the legacy Places API.')
class GooglePlaceIdFinderService {
  static const String _logName = 'GooglePlaceIdFinderService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final http.Client _httpClient;
  final String _apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // Matching thresholds
  static const double _maxDistanceMeters = 50.0; // Max 50 meters distance
  static const double _nameSimilarityThreshold = 0.7; // 70% name similarity
  
  GooglePlaceIdFinderService({
    required String apiKey,
    http.Client? httpClient,
  }) : _apiKey = apiKey,
       _httpClient = httpClient ?? http.Client();
  
  /// Find Google Place ID for a community spot
  /// Returns Place ID if found, null otherwise
  Future<String?> findPlaceId(Spot spot) async {
    try {
      developer.log('Finding Google Place ID for: ${spot.name}', name: _logName);
      
      // Try nearby search first (most accurate)
      final nearbyPlaceId = await _findPlaceIdByNearbySearch(spot);
      if (nearbyPlaceId != null) {
        developer.log('Found Place ID via nearby search: $nearbyPlaceId', name: _logName);
        return nearbyPlaceId;
      }
      
      // Try text search as fallback
      final textPlaceId = await _findPlaceIdByTextSearch(spot);
      if (textPlaceId != null) {
        developer.log('Found Place ID via text search: $textPlaceId', name: _logName);
        return textPlaceId;
      }
      
      developer.log('No Place ID found for: ${spot.name}', name: _logName);
      return null;
    } catch (e) {
      _logger.error('Error finding Place ID', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Find Place ID using nearby search (most accurate)
  Future<String?> _findPlaceIdByNearbySearch(Spot spot) async {
    try {
      // Search nearby places
      final url = '$_baseUrl/nearbysearch/json?'
          'location=${spot.latitude},${spot.longitude}'
          '&radius=50'
          '&key=$_apiKey';
      
      final response = await _httpClient.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        
        // Find best match
        for (final result in results) {
          final placeName = result['name'] as String? ?? '';
          final placeId = result['place_id'] as String? ?? '';
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          
          if (location == null || placeId.isEmpty) continue;
          
          final placeLat = (location['lat'] ?? 0.0).toDouble();
          final placeLng = (location['lng'] ?? 0.0).toDouble();
          
          // Check distance
          final distance = _calculateDistance(
            spot.latitude,
            spot.longitude,
            placeLat,
            placeLng,
          );
          
          if (distance > _maxDistanceMeters) continue;
          
          // Check name similarity
          final similarity = _calculateNameSimilarity(spot.name, placeName);
          if (similarity >= _nameSimilarityThreshold) {
            return placeId;
          }
        }
      }
      
      return null;
    } catch (e) {
      _logger.error('Error in nearby search', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Find Place ID using text search (fallback)
  Future<String?> _findPlaceIdByTextSearch(Spot spot) async {
    try {
      // Build search query with name and location
      final query = '${spot.name} ${spot.address ?? ''}';
      final url = '$_baseUrl/textsearch/json?'
          'query=${Uri.encodeComponent(query)}'
          '&location=${spot.latitude},${spot.longitude}'
          '&radius=100'
          '&key=$_apiKey';
      
      final response = await _httpClient.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        
        if (results.isEmpty) return null;
        
        // Get first result and verify it's a good match
        final firstResult = results[0];
        final placeName = firstResult['name'] as String? ?? '';
        final placeId = firstResult['place_id'] as String? ?? '';
        final geometry = firstResult['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;
        
        if (location == null || placeId.isEmpty) return null;
        
        final placeLat = (location['lat'] ?? 0.0).toDouble();
        final placeLng = (location['lng'] ?? 0.0).toDouble();
        
        // Check distance
        final distance = _calculateDistance(
          spot.latitude,
          spot.longitude,
          placeLat,
          placeLng,
        );
        
        if (distance > _maxDistanceMeters * 2) return null; // More lenient for text search
        
        // Check name similarity
        final similarity = _calculateNameSimilarity(spot.name, placeName);
        if (similarity >= _nameSimilarityThreshold) {
          return placeId;
        }
      }
      
      return null;
    } catch (e) {
      _logger.error('Error in text search', error: e, tag: _logName);
      return null;
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
  
  /// Calculate name similarity using Levenshtein distance
  double _calculateNameSimilarity(String name1, String name2) {
    final s1 = name1.toLowerCase().trim();
    final s2 = name2.toLowerCase().trim();
    
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    // Check if one contains the other
    if (s1.contains(s2) || s2.contains(s1)) {
      return 0.8;
    }
    
    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    
    return 1.0 - (distance / maxLength);
  }
  
  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
}


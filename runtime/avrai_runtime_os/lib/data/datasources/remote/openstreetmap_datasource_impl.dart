import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/data/datasources/remote/openstreetmap_datasource.dart';

/// OpenStreetMap Implementation
/// OUR_GUTS.md: "Community, Not Just Places" - Community-driven external data
class OpenStreetMapDataSourceImpl implements OpenStreetMapDataSource {
  static const String _logName = 'OpenStreetMapDataSource';
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _overpassBaseUrl =
      'https://overpass-api.de/api/interpreter';

  final http.Client _httpClient;

  // Caching and rate limiting for OSM APIs
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _lastRequest = {};
  static const Duration _cacheExpiry =
      Duration(hours: 2); // Longer cache for community data
  static const Duration _rateLimitDelay =
      Duration(seconds: 1); // Respectful rate limiting

  OpenStreetMapDataSourceImpl({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int limit = 20,
  }) async {
    try {
      developer.log('OSM: Searching places: $query', name: _logName);

      // Check cache first
      final cacheKey = 'search_${query}_${latitude}_${longitude}_$limit';
      if (_isCacheValid(cacheKey)) {
        developer.log('OSM: Returning cached results for: $query',
            name: _logName);
        return List<Spot>.from(_cache[cacheKey]);
      }

      // Rate limiting - be respectful to OSM
      await _enforceRateLimit();

      // Build Nominatim search URL
      final url = _buildNominatimSearchUrl(
        query: query,
        latitude: latitude,
        longitude: longitude,
        limit: limit,
      );

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SPOTS_App/1.0 (Community_Discovery)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final spots = _parseNominatimResults(data);

        // Cache results
        _cache[cacheKey] = spots;
        _lastRequest[cacheKey] = DateTime.now();

        developer.log('OSM: Found ${spots.length} places for: $query',
            name: _logName);
        return spots;
      } else {
        throw OpenStreetMapException(
            'Nominatim search failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('OSM: Error searching places: $e', name: _logName);
      // OUR_GUTS.md: "Effortless, Seamless Discovery" - Graceful fallback
      return [];
    }
  }

  @override
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? amenity,
  }) async {
    try {
      developer.log('OSM: Searching nearby places: $latitude,$longitude',
          name: _logName);

      // Check cache first
      final cacheKey = 'nearby_${latitude}_${longitude}_${radius}_$amenity';
      if (_isCacheValid(cacheKey)) {
        return List<Spot>.from(_cache[cacheKey]);
      }

      // Rate limiting
      await _enforceRateLimit();

      // Build Overpass query for nearby amenities
      final overpassQuery = _buildOverpassQuery(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        amenity: amenity,
      );

      final response = await _httpClient.post(
        Uri.parse(_overpassBaseUrl),
        headers: {
          'User-Agent': 'SPOTS_App/1.0 (Community_Discovery)',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'data=$overpassQuery',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final spots = _parseOverpassResults(data);

        // Cache results
        _cache[cacheKey] = spots;
        _lastRequest[cacheKey] = DateTime.now();

        developer.log('OSM: Found ${spots.length} nearby places',
            name: _logName);
        return spots;
      } else {
        throw OpenStreetMapException(
            'Overpass search failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('OSM: Error searching nearby places: $e', name: _logName);
      return [];
    }
  }

  @override
  Future<Spot?> getPlaceDetails(String osmId) async {
    try {
      developer.log('OSM: Getting place details: $osmId', name: _logName);

      // Check cache first
      final cacheKey = 'details_$osmId';
      if (_isCacheValid(cacheKey)) {
        return _cache[cacheKey] as Spot?;
      }

      // Rate limiting
      await _enforceRateLimit();

      final url =
          '$_nominatimBaseUrl/lookup?osm_ids=$osmId&format=json&addressdetails=1&extratags=1';

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SPOTS_App/1.0 (Community_Discovery)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final spot = _createSpotFromOSMPlace(data.first);

          // Cache result
          _cache[cacheKey] = spot;
          _lastRequest[cacheKey] = DateTime.now();

          return spot;
        }
      }

      return null;
    } catch (e) {
      developer.log('OSM: Error getting place details: $e', name: _logName);
      return null;
    }
  }

  @override
  Future<List<Spot>> searchAmenities({
    required double latitude,
    required double longitude,
    required String amenityType,
    int radius = 2000,
  }) async {
    try {
      developer.log('OSM: Searching amenities: $amenityType', name: _logName);

      // Check cache first
      final cacheKey =
          'amenities_${latitude}_${longitude}_${amenityType}_$radius';
      if (_isCacheValid(cacheKey)) {
        return List<Spot>.from(_cache[cacheKey]);
      }

      // Rate limiting
      await _enforceRateLimit();

      // Specific Overpass query for amenities
      final overpassQuery = '''
        [out:json][timeout:25];
        (
          node["amenity"="$amenityType"](around:$radius,$latitude,$longitude);
          way["amenity"="$amenityType"](around:$radius,$latitude,$longitude);
          relation["amenity"="$amenityType"](around:$radius,$latitude,$longitude);
        );
        out geom;
      ''';

      final response = await _httpClient.post(
        Uri.parse(_overpassBaseUrl),
        headers: {
          'User-Agent': 'SPOTS_App/1.0 (Community_Discovery)',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'data=$overpassQuery',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final spots = _parseOverpassResults(data);

        // Cache results
        _cache[cacheKey] = spots;
        _lastRequest[cacheKey] = DateTime.now();

        developer.log('OSM: Found ${spots.length} $amenityType amenities',
            name: _logName);
        return spots;
      } else {
        throw OpenStreetMapException(
            'Amenity search failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('OSM: Error searching amenities: $e', name: _logName);
      return [];
    }
  }

  // Helper methods

  String _buildNominatimSearchUrl({
    required String query,
    double? latitude,
    double? longitude,
    int limit = 20,
  }) {
    var url =
        '$_nominatimBaseUrl/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=$limit';

    if (latitude != null && longitude != null) {
      url += '&lat=$latitude&lon=$longitude';
    }

    return url;
  }

  String _buildOverpassQuery({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? amenity,
  }) {
    final amenityFilter =
        amenity != null ? '["amenity"="$amenity"]' : '["amenity"]';

    return '''
      [out:json][timeout:25];
      (
        node$amenityFilter(around:$radius,$latitude,$longitude);
        way$amenityFilter(around:$radius,$latitude,$longitude);
        relation$amenityFilter(around:$radius,$latitude,$longitude);
      );
      out geom;
    ''';
  }

  List<Spot> _parseNominatimResults(List<dynamic> results) {
    return results.map((result) => _createSpotFromOSMPlace(result)).toList();
  }

  List<Spot> _parseOverpassResults(Map<String, dynamic> data) {
    final elements = data['elements'] as List<dynamic>? ?? [];
    return elements
        .where((element) => element['lat'] != null && element['lon'] != null)
        .map((element) => _createSpotFromOverpassElement(element))
        .toList();
  }

  Spot _createSpotFromOSMPlace(Map<String, dynamic> place) {
    final address = place['address'] as Map<String, dynamic>? ?? {};
    final extratags = place['extratags'] as Map<String, dynamic>? ?? {};

    // OUR_GUTS.md: "Community, Not Just Places" - Community-contributed data
    final now = DateTime.now();
    return Spot(
      id: 'osm_${place['place_id'] ?? place['osm_id']}',
      name: place['display_name']?.split(',').first ?? 'Unknown Place',
      description: place['display_name'] ?? '',
      latitude: double.tryParse(place['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(place['lon']?.toString() ?? '0') ?? 0.0,
      category: _mapOSMTypeToCategory(place['type'], place['class']),
      rating: 0.0, // OSM doesn't have ratings
      createdBy: 'openstreetmap_community',
      createdAt: now,
      updatedAt: now,
      address: place['display_name'],
      tags: [
        'external_data',
        'openstreetmap',
        'community_contributed',
        if (place['type'] != null) place['type'].toString(),
        if (place['class'] != null) place['class'].toString(),
      ],
      metadata: {
        'source': 'openstreetmap',
        'osm_id': place['osm_id'],
        'osm_type': place['osm_type'],
        'place_id': place['place_id'],
        'is_external': true,
        'is_community_data': true,
        'importance': place['importance'],
        'address': address,
        'extratags': extratags,
      },
    );
  }

  Spot _createSpotFromOverpassElement(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final amenity = tags['amenity'] ?? 'unknown';

    final now = DateTime.now();
    return Spot(
      id: 'osm_${element['type']}_${element['id']}',
      name: tags['name'] ?? tags['brand'] ?? 'Unknown Place',
      description: tags['description'] ?? tags['addr:full'] ?? '',
      latitude: double.tryParse(element['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(element['lon']?.toString() ?? '0') ?? 0.0,
      category: _mapOSMAmenityToCategory(amenity),
      rating: 0.0,
      createdBy: 'openstreetmap_community',
      createdAt: now,
      updatedAt: now,
      address: _buildAddressFromTags(tags),
      tags: [
        'external_data',
        'openstreetmap',
        'community_contributed',
        amenity.toString(),
        ...tags.keys.map((key) => key.toString()),
      ],
      metadata: {
        'source': 'openstreetmap',
        'osm_id': '${element['type'][0]}${element['id']}',
        'osm_type': element['type'],
        'is_external': true,
        'is_community_data': true,
        'amenity': amenity,
        'all_tags': tags,
      },
    );
  }

  String _mapOSMTypeToCategory(String? type, String? osmClass) {
    // Map OSM types to SPOTS categories
    // OUR_GUTS.md: "Authenticity Over Algorithms" - Maintain consistent categorization
    if (type == 'amenity' || osmClass == 'amenity') {
      return 'Attractions';
    }

    switch (type ?? osmClass) {
      case 'tourism':
        return 'Attractions';
      case 'shop':
        return 'Shopping';
      case 'leisure':
        return 'Attractions';
      case 'historic':
        return 'Attractions';
      default:
        return 'Other';
    }
  }

  String _mapOSMAmenityToCategory(String amenity) {
    switch (amenity) {
      case 'restaurant':
      case 'cafe':
      case 'bar':
      case 'pub':
      case 'fast_food':
        return 'Food';
      case 'hotel':
      case 'hostel':
      case 'motel':
        return 'Stay';
      case 'attraction':
      case 'museum':
      case 'theatre':
      case 'cinema':
        return 'Attractions';
      case 'nightclub':
        return 'Nightlife';
      case 'shop':
      case 'marketplace':
        return 'Shopping';
      default:
        return 'Other';
    }
  }

  String _buildAddressFromTags(Map<String, dynamic> tags) {
    final addressParts = <String>[];

    if (tags['addr:housenumber'] != null) {
      addressParts.add(tags['addr:housenumber'].toString());
    }
    if (tags['addr:street'] != null) {
      addressParts.add(tags['addr:street'].toString());
    }
    if (tags['addr:city'] != null) {
      addressParts.add(tags['addr:city'].toString());
    }

    return addressParts.isNotEmpty
        ? addressParts.join(' ')
        : tags['name']?.toString() ?? '';
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_lastRequest.containsKey(key)) {
      return false;
    }

    final lastRequest = _lastRequest[key]!;
    return DateTime.now().difference(lastRequest) < _cacheExpiry;
  }

  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    final lastRequestTime = _lastRequest['rate_limit'];

    if (lastRequestTime != null) {
      final timeSinceLastRequest = now.difference(lastRequestTime);
      if (timeSinceLastRequest < _rateLimitDelay) {
        final delay = _rateLimitDelay - timeSinceLastRequest;
        await Future.delayed(delay);
      }
    }

    _lastRequest['rate_limit'] = DateTime.now();
  }
}

class OpenStreetMapException implements Exception {
  final String message;
  OpenStreetMapException(this.message);

  @override
  String toString() => 'OpenStreetMapException: $message';
}

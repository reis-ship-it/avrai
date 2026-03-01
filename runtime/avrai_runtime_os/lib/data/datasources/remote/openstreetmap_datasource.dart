import 'package:avrai_core/models/spots/spot.dart';

/// OpenStreetMap Data Source Interface
/// OUR_GUTS.md: "Community, Not Just Places" - Community-driven data that supplements local knowledge
abstract class OpenStreetMapDataSource {
  /// Search for places using OpenStreetMap Nominatim API
  /// Community-driven data that aligns with our authenticity principle
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int limit = 20,
  });

  /// Search nearby places around a location using Overpass API
  /// OUR_GUTS.md: "Authenticity Over Algorithms" - Real community-contributed data
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? amenity,
  });

  /// Get place details by OSM ID
  Future<Spot?> getPlaceDetails(String osmId);

  /// Search for specific amenities (restaurants, cafes, etc.)
  /// Supports community enhancement workflow
  Future<List<Spot>> searchAmenities({
    required double latitude,
    required double longitude,
    required String amenityType,
    int radius = 2000,
  });
}

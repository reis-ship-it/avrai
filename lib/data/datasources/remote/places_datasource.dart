import 'package:avrai/core/models/spots/spot.dart';

/// Abstraction for place/POI search used by HybridSearchRepository and
/// OnboardingPlaceListGenerator.
///
/// On macOS this is implemented by [MapKitPlacesDataSource] (MapKit
/// MKLocalSearch); on other platforms by [GooglePlacesDataSource].
/// [getPlaceDetails] is not included—MapKit uses different IDs; Google
/// sync remains on [GooglePlacesDataSource].
abstract class PlacesDataSource {
  /// Search for places by query (e.g. "coffee", "restaurant in Brooklyn").
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  });

  /// Search nearby places around a location.
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  });
}

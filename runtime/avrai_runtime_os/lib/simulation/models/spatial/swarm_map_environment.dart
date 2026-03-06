import 'geo_coordinate.dart';

enum POICategory {
  cafe,
  park,
  gym,
  restaurant,
  bar,
  retail,
  transit,
  office,
}

class PointOfInterest {
  final String id;
  final String name;
  final POICategory category;
  final GeoCoordinate location;
  final double cost; // 0.0 to 1.0
  final double baseQuality; // 0.0 to 1.0 (How highly rated is it?)

  const PointOfInterest({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.cost,
    required this.baseQuality,
  });
}

/// The spatial grid representing a city in the simulation.
/// Holds all Points of Interest and allows spatial querying (like a map API).
class SwarmMapEnvironment {
  final String cityId;
  final List<PointOfInterest> allPOIs;

  SwarmMapEnvironment({
    required this.cityId,
    required this.allPOIs,
  });

  /// Finds all POIs within a certain bounding box or radius of a point.
  /// Simulates querying Google Maps / Apple Maps for "coffee near me".
  List<PointOfInterest> findPOIsNear(GeoCoordinate center,
      {double radiusKm = 1.0, POICategory? category}) {
    // Note: distanceTo currently returns a squared pseudo-distance for speed,
    // but we can treat radiusKm^2 as the threshold for the simulation mock.
    final threshold = radiusKm * radiusKm;

    return allPOIs.where((poi) {
      if (category != null && poi.category != category) return false;
      return center.distanceTo(poi.location) <= threshold;
    }).toList();
  }

  /// Finds POIs that lie along a path between Point A and Point B.
  /// This is critical for the "Routine Enhancement" logic (finding interstitial gaps).
  List<PointOfInterest> findPOIsAlongRoute(
      List<GeoCoordinate> routePoints,
      {double maxDistanceKm = 1.0}) {
    // Optimization: create a bounding box of the route to pre-filter
    if (routePoints.isEmpty) return [];
    
    double minLat = double.maxFinite;
    double maxLat = -double.maxFinite;
    double minLng = double.maxFinite;
    double maxLng = -double.maxFinite;
    
    for (final p in routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    
    // Add padding to bounding box
    final latPadding = maxDistanceKm / 111.0;
    final lngPadding = maxDistanceKm / 85.0;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Filter first by bounding box, then by strict distance
    final threshold = maxDistanceKm * maxDistanceKm; // Using squared distance from GeoCoordinate

    return allPOIs.where((poi) {
      // 1. Fast bounding box check
      if (poi.location.latitude < minLat || 
          poi.location.latitude > maxLat ||
          poi.location.longitude < minLng || 
          poi.location.longitude > maxLng) {
        return false;
      }

      // 2. Slower precise distance check
      for (final point in routePoints) {
        if (point.distanceTo(poi.location) <= threshold) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}

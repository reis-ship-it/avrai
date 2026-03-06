import 'dart:math';
import 'geo_coordinate.dart';

/// Represents a geographic route comprising multiple coordinates.
class RoutePath {
  final GeoCoordinate start;
  final GeoCoordinate end;
  final List<GeoCoordinate> waypoints;
  final double totalDistanceKm;

  const RoutePath({
    required this.start,
    required this.end,
    required this.waypoints,
    required this.totalDistanceKm,
  });

  /// Get the full list of points including start and end
  List<GeoCoordinate> get allPoints => [start, ...waypoints, end];
}

/// Service to handle routing and pathfinding between coordinates.
/// In a real environment, this would call Google Maps Directions API.
/// Here, it approximates realistic routes along a grid or slight arc.
class PathfindingService {
  /// Generates a RoutePath between two coordinates, adding intermediate waypoints.
  /// 
  /// Uses a slight curvature to simulate non-linear travel (roads aren't straight lines).
  RoutePath calculateRoute(GeoCoordinate start, GeoCoordinate end) {
    final double distance = start.distanceTo(end);
    
    // If it's a very short trip, just a straight line is fine
    if (distance < 1.0) {
      return RoutePath(
        start: start,
        end: end,
        waypoints: [],
        totalDistanceKm: distance,
      );
    }

    // Generate waypoints (roughly one every 1-2 km)
    final int numWaypoints = max(1, (distance / 1.5).floor());
    final List<GeoCoordinate> waypoints = [];

    // Add a slight arc/deviation to the route to simulate road constraints
    // Deviation is perpendicular to the straight line
    final double dx = end.longitude - start.longitude;
    final double dy = end.latitude - start.latitude;
    
    // Perpendicular vector
    final double perpDx = -dy;
    final double perpDy = dx;
    
    // Randomize if the arc bows "left" or "right"
    final double arcDirection = (Random().nextBool() ? 1.0 : -1.0);
    // Max deviation is roughly 15% of the total distance
    final double maxDeviation = 0.15 * arcDirection;

    for (int i = 1; i <= numWaypoints; i++) {
      final double fraction = i / (numWaypoints + 1);
      
      // Base point on the straight line
      final double baseLat = start.latitude + (dy * fraction);
      final double baseLng = start.longitude + (dx * fraction);
      
      // Apply deviation (parabolic arc, highest in the middle)
      // fraction * (1 - fraction) creates a parabola peaking at 0.5
      final double deviationScale = 4.0 * fraction * (1.0 - fraction) * maxDeviation;
      
      waypoints.add(GeoCoordinate(
        baseLat + (perpDy * deviationScale),
        baseLng + (perpDx * deviationScale),
      ));
    }

    // The actual distance of the curved path will be slightly longer than the straight line
    double pathDistance = 0.0;
    GeoCoordinate current = start;
    for (final wp in waypoints) {
      pathDistance += current.distanceTo(wp);
      current = wp;
    }
    pathDistance += current.distanceTo(end);

    return RoutePath(
      start: start,
      end: end,
      waypoints: waypoints,
      totalDistanceKm: pathDistance,
    );
  }
}

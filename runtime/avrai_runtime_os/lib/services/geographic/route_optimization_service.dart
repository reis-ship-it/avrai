// Route Optimization Service
//
// Phase 5.2: Optimize list ordering for efficient visits
//
// Purpose: Order list items for minimal travel time

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_core/models/spots/spot.dart';

/// Route Optimization Service
///
/// Optimizes the order of places in a list for efficient visiting.
/// Uses nearest neighbor heuristic for quick optimization.
///
/// Part of Phase 5.2: Route Optimization

class RouteOptimizationService {
  static const String _logName = 'RouteOptimizationService';

  /// Earth radius in kilometers
  static const double _earthRadiusKm = 6371.0;

  RouteOptimizationService();

  /// Optimize the order of places for efficient visiting
  ///
  /// Uses nearest neighbor algorithm starting from user's current location.
  /// Returns places in optimized order.
  List<Spot> optimizeRoute({
    required List<Spot> places,
    required double startLatitude,
    required double startLongitude,
  }) {
    if (places.isEmpty) return [];
    if (places.length == 1) return places;

    developer.log(
      'Optimizing route for ${places.length} places',
      name: _logName,
    );

    final optimized = <Spot>[];
    final remaining = List<Spot>.from(places);

    // Start from user's location
    double currentLat = startLatitude;
    double currentLon = startLongitude;

    // Nearest neighbor algorithm
    while (remaining.isNotEmpty) {
      Spot? nearest;
      double nearestDistance = double.infinity;

      for (final place in remaining) {
        final distance = _calculateDistance(
          currentLat,
          currentLon,
          place.latitude,
          place.longitude,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = place;
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        remaining.remove(nearest);
        currentLat = nearest.latitude;
        currentLon = nearest.longitude;
      }
    }

    final totalDistance = _calculateTotalDistance(
      startLatitude,
      startLongitude,
      optimized,
    );

    developer.log(
      'Optimized route: ${totalDistance.toStringAsFixed(1)}km total',
      name: _logName,
    );

    return optimized;
  }

  /// Calculate total route distance
  double _calculateTotalDistance(
    double startLat,
    double startLon,
    List<Spot> route,
  ) {
    if (route.isEmpty) return 0.0;

    double total = _calculateDistance(
      startLat,
      startLon,
      route.first.latitude,
      route.first.longitude,
    );

    for (var i = 0; i < route.length - 1; i++) {
      total += _calculateDistance(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
    }

    return total;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Get route statistics
  RouteStatistics getRouteStatistics({
    required List<Spot> places,
    required double startLatitude,
    required double startLongitude,
  }) {
    final optimizedRoute = optimizeRoute(
      places: places,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
    );

    final totalDistance = _calculateTotalDistance(
      startLatitude,
      startLongitude,
      optimizedRoute,
    );

    // Estimate time (assuming 5 km/h walking, 30 km/h driving)
    final walkingTimeMinutes = (totalDistance / 5.0) * 60;
    final drivingTimeMinutes = (totalDistance / 30.0) * 60;

    return RouteStatistics(
      totalDistanceKm: totalDistance,
      estimatedWalkingMinutes: walkingTimeMinutes.round(),
      estimatedDrivingMinutes: drivingTimeMinutes.round(),
      stopCount: places.length,
    );
  }
}

/// Route statistics
class RouteStatistics {
  /// Total distance in kilometers
  final double totalDistanceKm;

  /// Estimated walking time in minutes
  final int estimatedWalkingMinutes;

  /// Estimated driving time in minutes
  final int estimatedDrivingMinutes;

  /// Number of stops
  final int stopCount;

  const RouteStatistics({
    required this.totalDistanceKm,
    required this.estimatedWalkingMinutes,
    required this.estimatedDrivingMinutes,
    required this.stopCount,
  });

  Map<String, dynamic> toJson() => {
        'totalDistanceKm': totalDistanceKm,
        'estimatedWalkingMinutes': estimatedWalkingMinutes,
        'estimatedDrivingMinutes': estimatedDrivingMinutes,
        'stopCount': stopCount,
      };
}

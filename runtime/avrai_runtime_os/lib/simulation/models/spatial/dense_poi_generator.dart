import 'dart:math';
import '../city_profile.dart';
import 'geo_coordinate.dart';
import 'swarm_map_environment.dart';
import '../../data/city_heatmaps.dart';
import 'package:uuid/uuid.dart';

class DensePOIGenerator {
  final Random _random;

  DensePOIGenerator({int? seed}) : _random = Random(seed);

  /// Generates a dense, highly populated map environment for a given city.
  SwarmMapEnvironment generateCityMap(CityProfile city,
      {int totalPOIs = 5000}) {
    final pois = <PointOfInterest>[];

    final heatmap = _getHeatmapForCity(city.name);

    for (int i = 0; i < totalPOIs; i++) {
      pois.add(_generateRandomPOI(city.id, heatmap));
    }

    return SwarmMapEnvironment(
      cityId: city.id,
      allPOIs: pois,
    );
  }

  SpatialHeatmap _getHeatmapForCity(String name) {
    if (name.contains('New York')) return CityHeatmaps.newYork;
    if (name.contains('Denver')) return CityHeatmaps.denver;
    if (name.contains('Birmingham')) return CityHeatmaps.birmingham;
    return CityHeatmaps.atlanta;
  }

  GeoCoordinate _generatePointInZones(List<HeatmapZone> zones,
      {String? cityId, bool isWork = false, HeatmapZone? homeZone}) {
    HeatmapZone selectedZone = zones.first;

    // Special NYC Commuting Logic
    if (isWork && cityId == 'nyc_sim_01' && homeZone != null) {
      if (_random.nextDouble() < 0.65) {
        if (homeZone.id == 'brooklyn_res') {
          selectedZone = _findZone(zones, 'downtown_bk_com') ??
              _findZone(zones, 'midtown_com') ??
              zones.first;
        } else if (homeZone.id == 'queens_res') {
          selectedZone = _findZone(zones, 'lic_queens_com') ??
              _findZone(zones, 'flushing_com') ??
              _findZone(zones, 'midtown_com') ??
              zones.first;
        } else if (homeZone.id == 'bronx_res') {
          selectedZone = _findZone(zones, 'bronx_hub_com') ??
              _findZone(zones, 'midtown_com') ??
              zones.first;
        } else if (homeZone.id == 'manhattan_res') {
          selectedZone = _findZone(zones, 'midtown_com') ??
              _findZone(zones, 'fidi_com') ??
              zones.first;
        }
      } else {
        selectedZone = _random.nextDouble() < 0.70
            ? (_findZone(zones, 'midtown_com') ?? zones.first)
            : (_findZone(zones, 'fidi_com') ?? zones.first);
      }
    } else {
      final totalWeight = zones.fold(0.0, (sum, zone) => sum + zone.weight);
      double roll = _random.nextDouble() * totalWeight;

      for (final zone in zones) {
        roll -= zone.weight;
        if (roll <= 0) {
          selectedZone = zone;
          break;
        }
      }
    }

    final radiusDegreesLat = selectedZone.radiusKm / 111.0;
    final radiusDegreesLng = selectedZone.radiusKm / 85.0;

    final angle = _random.nextDouble() * 2 * pi;
    final r = sqrt(_random.nextDouble());

    final dLat = r * radiusDegreesLat * cos(angle);
    final dLng = r * radiusDegreesLng * sin(angle);

    return GeoCoordinate(
      selectedZone.center.latitude + dLat,
      selectedZone.center.longitude + dLng,
    );
  }

  HeatmapZone? _findZone(List<HeatmapZone> zones, String id) {
    try {
      return zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  PointOfInterest _generateRandomPOI(String cityId, SpatialHeatmap heatmap) {
    // 1. Pick a random category based on urban distribution
    final category = _rollCategory();

    // 2. Generate Coordinate
    // Commercial POIs cluster in commercial zones. Parks/retail distribute across residential zones.
    GeoCoordinate location;
    if (category == POICategory.office || category == POICategory.transit) {
      location = _generatePointInZones(heatmap.commercialZones);
    } else if (category == POICategory.park) {
      location = _generatePointInZones(heatmap.residentialZones);
    } else {
      // 70% chance commercial, 30% chance residential for retail/food
      if (_random.nextDouble() < 0.70) {
        location = _generatePointInZones(heatmap.commercialZones);
      } else {
        location = _generatePointInZones(heatmap.residentialZones);
      }
    }

    // 3. Generate Attributes based on category
    double cost = 0.1;
    double baseQuality = _normalDistribution(0.6, 0.2).clamp(0.1, 1.0);
    String namePrefix = '';

    switch (category) {
      case POICategory.cafe:
        cost = _normalDistribution(0.1, 0.05).clamp(0.05, 0.3);
        namePrefix = 'Cafe';
        break;
      case POICategory.restaurant:
        cost = _normalDistribution(0.4, 0.2).clamp(0.2, 1.0);
        namePrefix = cost > 0.8 ? 'Fine Dining' : 'Bistro';
        break;
      case POICategory.park:
        cost = 0.0;
        namePrefix = 'Park';
        break;
      case POICategory.bar:
        cost = _normalDistribution(0.3, 0.15).clamp(0.1, 0.8);
        namePrefix = 'Bar/Pub';
        break;
      case POICategory.gym:
        cost = _normalDistribution(0.2, 0.1).clamp(0.1, 0.5);
        namePrefix = 'Fitness Studio';
        break;
      case POICategory.transit:
        cost = 0.05;
        namePrefix = 'Transit Stop';
        break;
      case POICategory.retail:
        cost = _normalDistribution(0.5, 0.3).clamp(0.1, 1.0);
        namePrefix = 'Store';
        break;
      case POICategory.office:
        cost = 0.0;
        namePrefix = 'Office Building';
        break;
    }

    return PointOfInterest(
      id: const Uuid().v4(),
      name: '$namePrefix ${_random.nextInt(1000)}',
      category: category,
      location: location,
      cost: cost,
      baseQuality: baseQuality,
    );
  }

  POICategory _rollCategory() {
    final roll = _random.nextDouble();
    if (roll < 0.25) return POICategory.restaurant; // 25% restaurants
    if (roll < 0.45) return POICategory.cafe; // 20% cafes
    if (roll < 0.60) return POICategory.retail; // 15% retail
    if (roll < 0.70) return POICategory.bar; // 10% bars
    if (roll < 0.80) return POICategory.office; // 10% offices
    if (roll < 0.90) return POICategory.transit; // 10% transit
    if (roll < 0.95) return POICategory.park; // 5% parks
    return POICategory.gym; // 5% gyms
  }

  double _normalDistribution(double mean, double stdDev) {
    double u1 = 1.0 - _random.nextDouble();
    double u2 = 1.0 - _random.nextDouble();
    double randStdNormal = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
    return mean + stdDev * randStdNormal;
  }
}

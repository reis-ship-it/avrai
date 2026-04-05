import 'dart:math';
import 'city_profile.dart';
import 'simulated_human.dart';
import 'spatial/geo_coordinate.dart';
import '../data/city_heatmaps.dart';

class SwarmPopulationGenerator {
  final Random _random;

  SwarmPopulationGenerator({int? seed}) : _random = Random(seed);

  List<SimulatedHuman> generatePopulation(CityProfile city, int size) {
    final population = <SimulatedHuman>[];
    for (int i = 0; i < size; i++) {
      population.add(_generateHuman(city));
    }
    return population;
  }

  SimulatedHuman _generateHuman(CityProfile city) {
    // 1. Friction Variance (Bell curve around city average)
    // Map city names to average friction manually
    final double cityBaseFriction = (city.name == 'New York City')
        ? 0.85
        : (city.name == 'Denver')
            ? 0.60
            : (city.name == 'Birmingham')
                ? 0.66
                : 0.70; // Atlanta and others

    double friction = _normalDistribution(cityBaseFriction, 0.15);
    friction = friction.clamp(0.1, 1.0);

    // 2. Routine Variance (Archetypes)
    // 60% Standard, 20% Early Bird, 15% Night Owl, 5% Shift Worker
    final double routineRoll = _random.nextDouble();
    DailyRoutine routine;

    if (routineRoll < 0.60) {
      // Standard: Wake 7, leave 8, arrive 9, leave 17, arrive 18, sleep 23
      routine = _generateRoutine(7, 8, 9, 17, 18, 23);
    } else if (routineRoll < 0.80) {
      // Early Bird: Wake 5, leave 6, arrive 7, leave 15, arrive 16, sleep 21
      routine = _generateRoutine(5, 6, 7, 15, 16, 21);
    } else if (routineRoll < 0.95) {
      // Night Owl: Wake 10, leave 11, arrive 12, leave 20, arrive 21, sleep 2
      routine = _generateRoutine(10, 11, 12, 20, 21, 2);
    } else {
      // Shift Worker: Wake 14, leave 15, arrive 16, leave 0, arrive 1, sleep 6
      routine = _generateRoutine(14, 15, 16, 0, 1, 6);
    }

    // 3. Financial Variance (Archetypes)
    // 30% Tight Budget, 50% Comfortable, 20% Affluent
    final double financialRoll = _random.nextDouble();
    FinancialProfile finances;

    if (financialRoll < 0.30) {
      // Tight: Low discretionary budget, high price sensitivity
      finances = FinancialProfile(
        discretionaryBudget: _normalDistribution(0.3, 0.1).clamp(0.1, 0.4),
        priceSensitivity: _normalDistribution(0.8, 0.1).clamp(0.6, 1.0),
      );
    } else if (financialRoll < 0.80) {
      // Comfortable: Medium budget, moderate sensitivity
      finances = FinancialProfile(
        discretionaryBudget: _normalDistribution(0.6, 0.1).clamp(0.4, 0.7),
        priceSensitivity: _normalDistribution(0.5, 0.1).clamp(0.3, 0.7),
      );
    } else {
      // Affluent: High budget, low sensitivity
      finances = FinancialProfile(
        discretionaryBudget: _normalDistribution(0.9, 0.1).clamp(0.7, 1.0),
        priceSensitivity: _normalDistribution(0.2, 0.1).clamp(0.1, 0.4),
      );
    }

    // 4. Spatial Coordinate Assignment via Heatmaps
    // Instead of random bounds, use the city's specific residential and commercial heatmaps
    final heatmap = _getHeatmapForCity(city.name);

    final homeZone =
        _selectZone(heatmap.residentialZones, cityId: city.id, isWork: false);
    final workZone = _selectZone(heatmap.commercialZones,
        cityId: city.id, isWork: true, homeZone: homeZone);

    final homeLocation = _generatePointInZone(homeZone);
    final workLocation = _generatePointInZone(workZone);

    return SimulatedHuman(
      city: city,
      routine: routine,
      finances: finances,
      transportDependence: _transportDependenceFor(city),
      weatherSensitivity: _normalDistribution(0.52, 0.18).clamp(0.1, 1.0),
      accessibilitySensitivity:
          _normalDistribution(0.25, 0.16).clamp(0.0, 1.0),
      socialFollowThrough: _normalDistribution(0.58, 0.18).clamp(0.1, 1.0),
      nightlifeAffinity: _normalDistribution(0.42, 0.24).clamp(0.0, 1.0),
      childcareFriction: _normalDistribution(0.20, 0.18).clamp(0.0, 1.0),
      homeLocation: homeLocation,
      workLocation: workLocation,
      baseInertia: friction,
    );
  }

  double _transportDependenceFor(CityProfile city) {
    switch (city.transportType) {
      case TransportationDominance.walkable:
        return _normalDistribution(0.25, 0.12).clamp(0.0, 1.0);
      case TransportationDominance.subway:
        return _normalDistribution(0.48, 0.14).clamp(0.0, 1.0);
      case TransportationDominance.carCentric:
        return _normalDistribution(0.72, 0.14).clamp(0.0, 1.0);
    }
  }

  SpatialHeatmap _getHeatmapForCity(String name) {
    if (name.contains('New York')) return CityHeatmaps.newYork;
    if (name.contains('Denver')) return CityHeatmaps.denver;
    if (name.contains('Birmingham')) return CityHeatmaps.birmingham;
    return CityHeatmaps.atlanta;
  }

  HeatmapZone _selectZone(List<HeatmapZone> zones,
      {String? cityId, bool isWork = false, HeatmapZone? homeZone}) {
    if (zones.isEmpty) {
      return HeatmapZone(
          id: 'fallback', center: GeoCoordinate(0, 0), radiusKm: 1, weight: 1);
    }

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
      if (totalWeight <= 0) return selectedZone;

      double roll = _random.nextDouble() * totalWeight;

      for (final zone in zones) {
        roll -= zone.weight;
        if (roll <= 0) {
          selectedZone = zone;
          break;
        }
      }
    }
    return selectedZone;
  }

  GeoCoordinate _generatePointInZone(HeatmapZone selectedZone) {
    final radiusDegreesLat = selectedZone.radiusKm / 111.0;
    final radiusDegreesLng =
        selectedZone.radiusKm / 85.0; // Rough approximation

    final angle = _random.nextDouble() * 2 * pi;
    final r = sqrt(_random.nextDouble()); // sqrt for uniform distribution

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

  DailyRoutine _generateRoutine(int w, int lw, int aw, int lhw, int ah, int s) {
    int variance() => _random.nextInt(3) - 1; // -1, 0, or 1

    int add(int base, int v) {
      int result = (base + v) % 24;
      return result < 0 ? result + 24 : result;
    }

    return DailyRoutine(
      wakeUpHour: add(w, variance()),
      leaveForWorkHour: add(lw, variance()),
      arriveAtWorkHour: add(aw, variance()),
      leaveWorkHour: add(lhw, variance()),
      arriveHomeHour: add(ah, variance()),
      sleepHour: add(s, variance()),
    );
  }

  // Box-Muller transform for normal distribution
  double _normalDistribution(double mean, double stdDev) {
    double u1 = 1.0 - _random.nextDouble(); // (0, 1]
    double u2 = 1.0 - _random.nextDouble(); // (0, 1]
    double randStdNormal = sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2);
    return mean + stdDev * randStdNormal;
  }
}

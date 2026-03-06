import 'spatial/geo_coordinate.dart';

enum TransportationDominance {
  walkable,
  subway,
  carCentric,
}

enum Season {
  spring,
  summer,
  autumn,
  winter,
}

/// Represents the weather state for a specific day in the simulation.
class WeatherState {
  final Season season;
  final double temperatureFahrenheit;
  final bool isPrecipitating;
  final double daylightHours;

  const WeatherState({
    required this.season,
    required this.temperatureFahrenheit,
    required this.isPrecipitating,
    required this.daylightHours,
  });

  @override
  String toString() =>
      'Weather[${season.name}, ${temperatureFahrenheit}F, precip: $isPrecipitating, daylight: ${daylightHours}h]';
}

/// Baseline simulation parameters for a city in the Swarm environment.
class CityProfile {
  final String id;
  final String name;
  final TransportationDominance transportType;
  final double populationDensity; // scale 0.0 to 1.0
  final double
      lifestylePacing; // scale 0.0 to 1.0 (1.0 = very fast paced, e.g. NYC)
  final CityBounds bounds;

  const CityProfile({
    required this.id,
    required this.name,
    required this.transportType,
    required this.populationDensity,
    required this.lifestylePacing,
    required this.bounds,
  });

  /// NYC: High walk/subway, high density, fast paced
  static CityProfile newYork() => const CityProfile(
        id: 'nyc_sim_01',
        name: 'New York City',
        transportType: TransportationDominance.subway,
        populationDensity: 0.95,
        lifestylePacing: 0.95,
        bounds: CityBounds(
          northWest: GeoCoordinate(40.87, -74.02),
          southEast: GeoCoordinate(40.57, -73.91),
        ),
      );

  /// Denver: Mixed/car/outdoors, medium density, moderate paced
  static CityProfile denver() => const CityProfile(
        id: 'denver_sim_01',
        name: 'Denver',
        transportType: TransportationDominance.carCentric,
        populationDensity: 0.50,
        lifestylePacing: 0.60,
        bounds: CityBounds(
          northWest: GeoCoordinate(39.88, -105.10),
          southEast: GeoCoordinate(39.60, -104.70),
        ),
      );

  /// Atlanta: Car-centric sprawl, medium density, moderate/fast paced
  static CityProfile atlanta() => const CityProfile(
        id: 'atlanta_sim_01',
        name: 'Atlanta',
        transportType: TransportationDominance.carCentric,
        populationDensity: 0.40,
        lifestylePacing: 0.70,
        bounds: CityBounds(
          northWest: GeoCoordinate(33.91, -84.51),
          southEast: GeoCoordinate(33.68, -84.28),
        ),
      );

  /// Generates a year-long (360 days) seasonal weather progression for the city.
  /// Each season is exactly 90 days.
  List<WeatherState> generateAnnualWeather() {
    final days = <WeatherState>[];
    for (int day = 0; day < 360; day++) {
      Season currentSeason;
      double baseTemp;
      double daylight;
      bool precip = (day % 7 == 0); // simplistic: rains every 7 days

      if (day < 90) {
        currentSeason = Season.spring;
        baseTemp = 60.0;
        daylight = 12.0;
      } else if (day < 180) {
        currentSeason = Season.summer;
        baseTemp = 85.0;
        daylight = 14.5;
      } else if (day < 270) {
        currentSeason = Season.autumn;
        baseTemp = 65.0;
        daylight = 11.0;
      } else {
        currentSeason = Season.winter;
        baseTemp = 35.0;
        daylight = 9.5;
      }

      // Add slight variance per city
      if (name == 'Denver') baseTemp -= 10.0; // Colder
      if (name == 'Atlanta') baseTemp += 10.0; // Warmer

      days.add(WeatherState(
        season: currentSeason,
        temperatureFahrenheit: baseTemp + (day % 5), // slight daily fluctuation
        isPrecipitating: precip,
        daylightHours: daylight,
      ));
    }
    return days;
  }
}

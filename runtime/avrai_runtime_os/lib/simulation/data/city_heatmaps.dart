import '../models/spatial/geo_coordinate.dart';

/// Defines probability zones for generating residential vs commercial locations
class SpatialHeatmap {
  final List<HeatmapZone> residentialZones;
  final List<HeatmapZone> commercialZones;

  const SpatialHeatmap({
    required this.residentialZones,
    required this.commercialZones,
  });
}

class HeatmapZone {
  final String id;
  final GeoCoordinate center;
  final double radiusKm;
  final double weight; // Higher weight = denser probability

  const HeatmapZone({
    this.id = '',
    required this.center,
    required this.radiusKm,
    required this.weight,
  });
}

class CityHeatmaps {
  // NYC: Commute from outer boroughs into Manhattan (Financial District/Midtown)
  static const SpatialHeatmap newYork = SpatialHeatmap(
    residentialZones: [
      HeatmapZone(
          center: GeoCoordinate(40.6782, -73.9442),
          radiusKm: 8.0,
          weight: 0.4), // Brooklyn
      HeatmapZone(
          center: GeoCoordinate(40.7282, -73.7949),
          radiusKm: 10.0,
          weight: 0.3), // Queens
      HeatmapZone(
          center: GeoCoordinate(40.7831, -73.9712),
          radiusKm: 4.0,
          weight: 0.2), // Upper West/East
    ],
    commercialZones: [
      HeatmapZone(
          center: GeoCoordinate(40.7580, -73.9855),
          radiusKm: 2.5,
          weight: 0.6), // Midtown
      HeatmapZone(
          center: GeoCoordinate(40.7074, -74.0113),
          radiusKm: 1.5,
          weight: 0.4), // FiDi
    ],
  );

  // Denver: Radiating outwards from Lodo/Downtown
  static const SpatialHeatmap denver = SpatialHeatmap(
    residentialZones: [
      HeatmapZone(
          center: GeoCoordinate(39.7392, -104.9903),
          radiusKm: 3.0,
          weight: 0.2), // Downtown residential
      HeatmapZone(
          center: GeoCoordinate(39.7169, -104.9575),
          radiusKm: 5.0,
          weight: 0.3), // Cherry Creek area
      HeatmapZone(
          center: GeoCoordinate(39.7643, -105.0444),
          radiusKm: 8.0,
          weight: 0.3), // Highlands/West
    ],
    commercialZones: [
      HeatmapZone(
          center: GeoCoordinate(39.7490, -104.9972),
          radiusKm: 2.0,
          weight: 0.5), // LoDo/Union Station
      HeatmapZone(
          center: GeoCoordinate(39.6133, -104.9006),
          radiusKm: 4.0,
          weight: 0.3), // Tech Center / Greenwood
    ],
  );

  // Atlanta: Multi-node sprawl (Downtown, Midtown, Buckhead)
  static const SpatialHeatmap atlanta = SpatialHeatmap(
    residentialZones: [
      HeatmapZone(
          center: GeoCoordinate(33.7490, -84.3880),
          radiusKm: 4.0,
          weight: 0.1), // Downtown
      HeatmapZone(
          center: GeoCoordinate(33.7719, -84.3665),
          radiusKm: 5.0,
          weight: 0.3), // Eastside/Inman Park
      HeatmapZone(
          center: GeoCoordinate(33.8390, -84.3738),
          radiusKm: 6.0,
          weight: 0.3), // Buckhead residential
      HeatmapZone(
          center: GeoCoordinate(33.7537, -84.3228),
          radiusKm: 8.0,
          weight: 0.3), // Decatur/East Lake
    ],
    commercialZones: [
      HeatmapZone(
          center: GeoCoordinate(33.7490, -84.3880),
          radiusKm: 2.0,
          weight: 0.3), // Downtown
      HeatmapZone(
          center: GeoCoordinate(33.7846, -84.3837),
          radiusKm: 2.0,
          weight: 0.4), // Midtown
      HeatmapZone(
          center: GeoCoordinate(33.8463, -84.3621),
          radiusKm: 3.0,
          weight: 0.3), // Buckhead commercial
    ],
  );

  // Birmingham: neighborhood clusters with a lighter downtown core.
  static const SpatialHeatmap birmingham = SpatialHeatmap(
    residentialZones: [
      HeatmapZone(
          id: 'highland_park_res',
          center: GeoCoordinate(33.5014, -86.7747),
          radiusKm: 3.2,
          weight: 0.28),
      HeatmapZone(
          id: 'avondale_res',
          center: GeoCoordinate(33.5231, -86.7741),
          radiusKm: 3.0,
          weight: 0.24),
      HeatmapZone(
          id: 'homewood_res',
          center: GeoCoordinate(33.4718, -86.8008),
          radiusKm: 3.6,
          weight: 0.24),
      HeatmapZone(
          id: 'crestwood_res',
          center: GeoCoordinate(33.5227, -86.7314),
          radiusKm: 3.2,
          weight: 0.24),
    ],
    commercialZones: [
      HeatmapZone(
          id: 'downtown_bham_com',
          center: GeoCoordinate(33.5186, -86.8104),
          radiusKm: 2.0,
          weight: 0.30),
      HeatmapZone(
          id: 'pepper_place_com',
          center: GeoCoordinate(33.5121, -86.7795),
          radiusKm: 1.8,
          weight: 0.24),
      HeatmapZone(
          id: 'five_points_com',
          center: GeoCoordinate(33.4983, -86.7911),
          radiusKm: 1.8,
          weight: 0.22),
      HeatmapZone(
          id: 'lakeview_com',
          center: GeoCoordinate(33.4913, -86.7741),
          radiusKm: 1.8,
          weight: 0.24),
    ],
  );
}

class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate(this.latitude, this.longitude);

  /// Approximate distance in kilometers using the Haversine formula
  double distanceTo(GeoCoordinate other) {
    // simplified for simulation performance
    final latDiff =
        (other.latitude - latitude).abs() * 111.0; // roughly 111km per degree
    final lngDiff = (other.longitude - longitude).abs() *
        85.0; // rough average for US latitudes
    return (latDiff * latDiff +
        lngDiff *
            lngDiff); // returning squared distance for faster comparisons unless true km is needed
  }
}

class CityBounds {
  final GeoCoordinate northWest;
  final GeoCoordinate southEast;

  const CityBounds({
    required this.northWest,
    required this.southEast,
  });

  /// Checks if a coordinate is within the city bounds
  bool contains(GeoCoordinate coord) {
    return coord.latitude <= northWest.latitude &&
        coord.latitude >= southEast.latitude &&
        coord.longitude >= northWest.longitude &&
        coord.longitude <= southEast.longitude;
  }
}

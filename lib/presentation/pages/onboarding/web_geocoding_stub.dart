// Flutter Web stub for geocoding to avoid timeouts during demos.
// Returns a synthetic Placemark quickly.

class Placemark {
  final String? name;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;
  final String? subAdministrativeArea;
  final String? thoroughfare;
  final String? subThoroughfare;
  String? get street => thoroughfare;
  final String? postalCode;
  final String? country;
  const Placemark({
    this.name,
    this.locality,
    this.subLocality,
    this.administrativeArea,
    this.subAdministrativeArea,
    this.thoroughfare,
    this.subThoroughfare,
    this.postalCode,
    this.country,
  });
}

Future<List<Placemark>> placemarkFromCoordinates(
  double latitude,
  double longitude, {
  Duration? timeLimit,
}) async {
  // Return a quick placeholder. Real web reverse geocoding can be added later via a web API.
  return [const Placemark(name: 'Approximate Location', locality: 'Web', subLocality: 'Demo')];
}



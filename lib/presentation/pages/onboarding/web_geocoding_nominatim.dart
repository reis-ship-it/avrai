import 'dart:convert';
import 'package:http/http.dart' as http;

class Placemark {
  final String? name;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;
  final String? subAdministrativeArea;
  final String? thoroughfare;
  final String? subThoroughfare;
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

  String? get street => thoroughfare;
}

Future<List<Placemark>> placemarkFromCoordinates(
  double latitude,
  double longitude, {
  Duration? timeLimit,
}) async {
  final uri = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&addressdetails=1',
  );
  final future = http.get(uri, headers: {
    'Accept': 'application/json',
    // Cannot set User-Agent from browser; Nominatim allows CORS for reverse endpoint.
  }).then((resp) {
    if (resp.statusCode != 200) {
      return <Placemark>[];
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final addr = (data['address'] as Map<String, dynamic>? ) ?? const {};
    return <Placemark>[
      Placemark(
        name: data['display_name'] as String?,
        locality: (addr['city'] ?? addr['town'] ?? addr['village']) as String?,
        subLocality: (addr['neighbourhood'] ?? addr['suburb']) as String?,
        administrativeArea: addr['state'] as String?,
        subAdministrativeArea: addr['county'] as String?,
        thoroughfare: (addr['road'] ?? addr['pedestrian']) as String?,
        subThoroughfare: addr['house_number'] as String?,
        postalCode: addr['postcode'] as String?,
        country: addr['country'] as String?,
      ),
    ];
  });

  return timeLimit != null ? await future.timeout(timeLimit, onTimeout: () => <Placemark>[]) : await future;
}



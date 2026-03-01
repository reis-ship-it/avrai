import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_runtime_os/services/geographic/geo_city_pack_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_locality_pack_service.dart';

void main() {
  test('GeoLocalityPackService: can load pack and resolve point->locality',
      () async {
    final root = await Directory.systemTemp.createTemp('geo_packs_test_');
    addTearDown(() async {
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    });

    const cityCode = 'us-nyc';
    const localityCode = 'us-nyc-brooklyn';

    final cityDir = Directory('${root.path}/$cityCode');
    await cityDir.create(recursive: true);
    await File('${cityDir.path}/current.txt').writeAsString('v1');

    final vDir = Directory('${cityDir.path}/v1');
    await vDir.create(recursive: true);

    // Simple square polygon around (lat=40, lon=-74).
    final localities = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'locality_code': localityCode,
            'display_name': 'Brooklyn',
            'is_neighborhood': false,
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-74.10, 39.90],
                [-73.90, 39.90],
                [-73.90, 40.10],
                [-74.10, 40.10],
                [-74.10, 39.90],
              ],
            ],
          },
        }
      ],
    };
    await File('${vDir.path}/localities.geojson')
        .writeAsString(jsonEncode(localities));

    // Empty index is fine for this test (service falls back to scanning all).
    await File('${vDir.path}/index.json').writeAsString(jsonEncode({}));

    final summaries = {
      localityCode: {
        'general_synco': {'one_liner': 'Test summary'}
      }
    };
    await File('${vDir.path}/summaries.json')
        .writeAsString(jsonEncode(summaries));

    final packs = GeoCityPackService(rootDir: root);
    final svc = GeoLocalityPackService(packs: packs);

    final found = await svc.lookupLocalityByPoint(lat: 40.0, lon: -74.0);
    expect(found, isNotNull);
    expect(found!.localityCode, localityCode);
    expect(found.cityCode, cityCode);

    final poly = await svc.getLocalityPolygon(localityCode: localityCode);
    expect(poly, isNotNull);
    expect(poly!.rings, isNotEmpty);

    final synco = await svc.getGeneralSyncoSummary(
      cityCode: cityCode,
      geoId: localityCode,
    );
    expect(synco, isNotNull);
    expect(synco!['one_liner'], 'Test summary');
  });

  test('GeoLocalityPackService: uses index.json geohash prefixes to shortlist',
      () async {
    final root = await Directory.systemTemp.createTemp('geo_packs_test_');
    addTearDown(() async {
      try {
        await root.delete(recursive: true);
      } catch (_) {}
    });

    const cityCode = 'us-nyc';
    const localityCode = 'us-nyc-brooklyn';

    final cityDir = Directory('${root.path}/$cityCode');
    await cityDir.create(recursive: true);
    await File('${cityDir.path}/current.txt').writeAsString('v1');

    final vDir = Directory('${cityDir.path}/v1');
    await vDir.create(recursive: true);

    // Same square polygon around (lat=40, lon=-74).
    final localities = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'locality_code': localityCode,
            'display_name': 'Brooklyn',
            'is_neighborhood': false,
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-74.10, 39.90],
                [-73.90, 39.90],
                [-73.90, 40.10],
                [-74.10, 40.10],
                [-74.10, 39.90],
              ],
            ],
          },
        }
      ],
    };
    await File('${vDir.path}/localities.geojson')
        .writeAsString(jsonEncode(localities));

    String encodeGeohash(double latitude, double longitude, int precision) {
      const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
      var latMin = -90.0, latMax = 90.0;
      var lonMin = -180.0, lonMax = 180.0;
      var hash = '';
      var bit = 0;
      var ch = 0;
      var even = true;
      while (hash.length < precision) {
        if (even) {
          final mid = (lonMin + lonMax) / 2;
          if (longitude >= mid) {
            ch |= 1 << (4 - bit);
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (latitude >= mid) {
            ch |= 1 << (4 - bit);
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        even = !even;
        if (bit < 4) {
          bit++;
        } else {
          hash += base32[ch];
          bit = 0;
          ch = 0;
        }
      }
      return hash;
    }

    final gh6 = encodeGeohash(40.0, -74.0, 6);
    await File('${vDir.path}/index.json').writeAsString(jsonEncode({
      gh6: [localityCode],
    }));

    await File('${vDir.path}/summaries.json').writeAsString(jsonEncode({}));

    final packs = GeoCityPackService(rootDir: root);
    final svc = GeoLocalityPackService(packs: packs);

    final found = await svc.lookupLocalityByPoint(
      lat: 40.0,
      lon: -74.0,
      geohashPrecision: 7,
    );
    expect(found, isNotNull);
    expect(found!.localityCode, localityCode);
    expect(found.cityCode, cityCode);
  });
}

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:avrai_runtime_os/services/geographic/geo_city_pack_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';

/// Reads locality polygons + summaries from installed city packs.
///
/// This is the **offline-first** lookup layer:
/// - point -> locality_code (best-effort)
/// - locality_code -> polygon
/// - geo_id -> synco summary
class GeoLocalityPackService {
  static const String _logName = 'GeoLocalityPackService';

  final GeoCityPackService _packs;

  GeoLocalityPackService({GeoCityPackService? packs})
      : _packs = packs ?? GeoCityPackService();

  final Map<String, _PackCache> _cacheByCityCode = {};

  Future<_PackCache?> _loadPack(String cityCode) async {
    if (_cacheByCityCode.containsKey(cityCode)) {
      return _cacheByCityCode[cityCode];
    }

    try {
      final dir = await _packs.getCurrentPackDir(cityCode);
      if (dir == null) {
        _cacheByCityCode[cityCode] = _PackCache.empty();
        return _cacheByCityCode[cityCode];
      }

      final localitiesFile = File(p.join(dir.path, 'localities.geojson'));
      final summariesFile = File(p.join(dir.path, 'summaries.json'));
      final indexFile = File(p.join(dir.path, 'index.json'));

      if (!await localitiesFile.exists()) {
        _cacheByCityCode[cityCode] = _PackCache.empty();
        return _cacheByCityCode[cityCode];
      }

      final geo = jsonDecode(await localitiesFile.readAsString());
      if (geo is! Map || geo['type'] != 'FeatureCollection') {
        _cacheByCityCode[cityCode] = _PackCache.empty();
        return _cacheByCityCode[cityCode];
      }

      final featuresRaw = geo['features'];
      if (featuresRaw is! List) {
        _cacheByCityCode[cityCode] = _PackCache.empty();
        return _cacheByCityCode[cityCode];
      }

      final features = <String, _PackLocalityFeature>{};
      for (final f in featuresRaw) {
        if (f is! Map) continue;
        final props = f['properties'];
        final geom = f['geometry'];
        if (props is! Map || geom is! Map) continue;
        final code = (props['locality_code'] ?? '').toString();
        if (code.isEmpty) continue;
        features[code] = _PackLocalityFeature(
          localityCode: code,
          cityCode: cityCode,
          displayName: (props['display_name'] ?? '').toString(),
          isNeighborhood: (props['is_neighborhood'] as bool?) ?? false,
          geometry: Map<String, dynamic>.from(geom),
        );
      }

      Map<String, dynamic> summaries = const {};
      if (await summariesFile.exists()) {
        final decoded = jsonDecode(await summariesFile.readAsString());
        if (decoded is Map) summaries = Map<String, dynamic>.from(decoded);
      }

      Map<String, List<String>> index = const {};
      if (await indexFile.exists()) {
        final decoded = jsonDecode(await indexFile.readAsString());
        if (decoded is Map) {
          final m = <String, List<String>>{};
          for (final entry in decoded.entries) {
            final k = entry.key.toString();
            final v = entry.value;
            if (v is List) {
              m[k] = v
                  .map((e) => e.toString())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          }
          index = m;
        }
      }

      final cache = _PackCache(
        cityCode: cityCode,
        localitiesByCode: features,
        indexByGeohashPrefix: index,
        summaries: summaries,
      );
      _cacheByCityCode[cityCode] = cache;
      return cache;
    } catch (e, st) {
      developer.log(
        'Failed to load pack for $cityCode',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _cacheByCityCode[cityCode] = _PackCache.empty();
      return _cacheByCityCode[cityCode];
    }
  }

  /// Attempt point -> locality across all installed city packs (best-effort).
  Future<({String localityCode, String cityCode, String displayName})?>
      lookupLocalityByPoint({
    required double lat,
    required double lon,
    int geohashPrecision = 7,
  }) async {
    final cities = await _packs.listInstalledCityCodes();
    for (final city in cities) {
      final res = await lookupLocalityByPointInCity(
        cityCode: city,
        lat: lat,
        lon: lon,
        geohashPrecision: geohashPrecision,
      );
      if (res != null) return res;
    }
    return null;
  }

  /// Attempt point -> locality using a known city pack.
  Future<({String localityCode, String cityCode, String displayName})?>
      lookupLocalityByPointInCity({
    required String cityCode,
    required double lat,
    required double lon,
    int geohashPrecision = 7,
  }) async {
    final pack = await _loadPack(cityCode);
    if (pack == null || pack.localitiesByCode.isEmpty) return null;

    final gh = _encodeGeohash(lat, lon, geohashPrecision);
    final candidateSet = <String>{};
    // Try progressively shorter prefixes (works with packs that store e.g. precision 6).
    for (var p = gh.length; p >= 5; p--) {
      final key = gh.substring(0, p);
      final list = pack.indexByGeohashPrefix[key];
      if (list != null && list.isNotEmpty) {
        candidateSet.addAll(list);
      }
    }
    final candidates =
        candidateSet.isEmpty ? const <String>[] : candidateSet.toList();

    _PackLocalityFeature? best;

    Future<void> scan(Iterable<String> codes) async {
      for (final code in codes) {
        final f = pack.localitiesByCode[code];
        if (f == null) continue;
        final poly = _parseGeoJsonToPolygonPreferLargest(f.geometry);
        if (_containsPoint(poly, lat: lat, lon: lon)) {
          if (best == null) {
            best = f;
          } else if (f.isNeighborhood && !best!.isNeighborhood) {
            best = f;
          }
        }
      }
    }

    if (candidates.isNotEmpty) {
      await scan(candidates);
      // If the index missed the correct locality, fall back to full scan.
      if (best == null) {
        await scan(pack.localitiesByCode.keys);
      }
    } else {
      await scan(pack.localitiesByCode.keys);
    }

    final chosen = best;
    if (chosen == null) return null;
    return (
      localityCode: chosen.localityCode,
      cityCode: chosen.cityCode,
      displayName: chosen.displayName
    );
  }

  /// Attempt locality_code -> polygon from any installed pack.
  Future<GeoPolygonV1?> getLocalityPolygon({
    required String localityCode,
    List<String> cityCodeHints = const [],
  }) async {
    // Try hinted cities first.
    for (final city in cityCodeHints) {
      final pack = await _loadPack(city);
      final f = pack?.localitiesByCode[localityCode];
      if (f != null) return _parseGeoJsonToPolygonPreferLargest(f.geometry);
    }
    // Fallback: scan loaded caches (cheap) - if not loaded, give up.
    for (final pack in _cacheByCityCode.values) {
      final f = pack.localitiesByCode[localityCode];
      if (f != null) return _parseGeoJsonToPolygonPreferLargest(f.geometry);
    }
    return null;
  }

  /// Read the offline “synco” summary for a geo_id if present in the city pack.
  ///
  /// Expected `summaries.json` shape:
  /// `{ "<geo_id>": { "general_synco": { ... } } }`
  Future<Map<String, dynamic>?> getGeneralSyncoSummary({
    required String cityCode,
    required String geoId,
  }) async {
    final pack = await _loadPack(cityCode);
    if (pack == null) return null;
    final raw = pack.summaries[geoId];
    if (raw is! Map) return null;
    final g = raw['general_synco'];
    return g is Map ? Map<String, dynamic>.from(g) : null;
  }

  // --------- helpers (geojson parsing + point-in-polygon + geohash) ---------

  GeoPolygonV1 _parseGeoJsonToPolygonPreferLargest(
      Map<String, dynamic> geojson) {
    final type = (geojson['type'] ?? '').toString();
    final coords = geojson['coordinates'];

    List<List<GeoPointV1>> parsePolygonRings(dynamic polygonCoords) {
      if (polygonCoords is! List) return const [];
      final rings = <List<GeoPointV1>>[];
      for (final ring in polygonCoords) {
        if (ring is! List) continue;
        final pts = <GeoPointV1>[];
        for (final pt in ring) {
          if (pt is! List || pt.length < 2) continue;
          final lon = (pt[0] as num).toDouble();
          final lat = (pt[1] as num).toDouble();
          pts.add(GeoPointV1(lat: lat, lon: lon));
        }
        if (pts.isNotEmpty) rings.add(pts);
      }
      return rings;
    }

    double ringArea(List<GeoPointV1> ring) {
      if (ring.length < 3) return 0;
      double sum = 0;
      for (var i = 0; i < ring.length; i++) {
        final a = ring[i];
        final b = ring[(i + 1) % ring.length];
        sum += (a.lon * b.lat) - (b.lon * a.lat);
      }
      return sum.abs() / 2.0;
    }

    if (type == 'Polygon') {
      return GeoPolygonV1(rings: parsePolygonRings(coords));
    }
    if (type == 'MultiPolygon') {
      if (coords is! List) return const GeoPolygonV1(rings: []);

      List<List<GeoPointV1>> bestRings = const [];
      double bestArea = -1;
      for (final poly in coords) {
        final rings = parsePolygonRings(poly);
        if (rings.isEmpty) continue;
        final area = ringArea(rings.first);
        if (area > bestArea) {
          bestArea = area;
          bestRings = rings;
        }
      }
      return GeoPolygonV1(rings: bestRings);
    }

    return const GeoPolygonV1(rings: []);
  }

  bool _containsPoint(
    GeoPolygonV1 polygon, {
    required double lat,
    required double lon,
  }) {
    if (polygon.rings.isEmpty) return false;

    bool inRing(List<GeoPointV1> ring) {
      var inside = false;
      for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        final xi = ring[i].lon;
        final yi = ring[i].lat;
        final xj = ring[j].lon;
        final yj = ring[j].lat;

        final denom = (yj - yi) == 0 ? 1e-12 : (yj - yi);
        final intersect = ((yi > lat) != (yj > lat)) &&
            (lon < (xj - xi) * (lat - yi) / denom + xi);
        if (intersect) inside = !inside;
      }
      return inside;
    }

    if (!inRing(polygon.rings.first)) return false;
    for (final hole in polygon.rings.skip(1)) {
      if (inRing(hole)) return false;
    }
    return true;
  }

  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  String _encodeGeohash(double latitude, double longitude, int precision) {
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
        hash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return hash;
  }
}

class _PackCache {
  final String cityCode;
  final Map<String, _PackLocalityFeature> localitiesByCode;
  final Map<String, List<String>> indexByGeohashPrefix;
  final Map<String, dynamic> summaries;

  const _PackCache({
    required this.cityCode,
    required this.localitiesByCode,
    required this.indexByGeohashPrefix,
    required this.summaries,
  });

  factory _PackCache.empty() => const _PackCache(
        cityCode: '',
        localitiesByCode: {},
        indexByGeohashPrefix: {},
        summaries: {},
      );
}

class _PackLocalityFeature {
  final String localityCode;
  final String cityCode;
  final String displayName;
  final bool isNeighborhood;
  final Map<String, dynamic> geometry;

  const _PackLocalityFeature({
    required this.localityCode,
    required this.cityCode,
    required this.displayName,
    required this.isNeighborhood,
    required this.geometry,
  });
}

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';

/// Offline-first locality geometry store backed by bundled GeoJSON assets.
///
/// This allows map/onboarding to render boundaries even when:
/// - Supabase is unavailable
/// - user is not authenticated
/// - network is offline
///
/// Current asset coverage:
/// - NYC boroughs (city_code = `us-nyc`)
class GeoLocalityAssetService {
  static const String _logName = 'GeoLocalityAssetService';

  static const String _nycBoroughsAssetPath =
      'assets/geo/localities/nyc_boroughs_simplified_v1.geojson';

  Map<String, _AssetLocalityFeature>? _featuresByLocalityCode;

  Future<void> _ensureLoaded() async {
    if (_featuresByLocalityCode != null) return;

    try {
      final raw = await rootBundle.loadString(_nycBoroughsAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _featuresByLocalityCode = const {};
        return;
      }

      final features = decoded['features'];
      if (features is! List) {
        _featuresByLocalityCode = const {};
        return;
      }

      final map = <String, _AssetLocalityFeature>{};
      for (final f in features) {
        if (f is! Map) continue;
        final props = f['properties'];
        final geom = f['geometry'];
        if (props is! Map || geom is! Map) continue;

        final localityCode = (props['locality_code'] ?? '').toString();
        if (localityCode.isEmpty) continue;

        map[localityCode] = _AssetLocalityFeature(
          localityCode: localityCode,
          cityCode: (props['city_code'] ?? '').toString(),
          displayName: (props['display_name'] ?? '').toString(),
          geometry: Map<String, dynamic>.from(geom),
        );
      }

      _featuresByLocalityCode = map;
    } catch (e, st) {
      developer.log(
        'Failed to load locality GeoJSON assets',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      _featuresByLocalityCode = const {};
    }
  }

  Future<GeoPolygonV1?> getLocalityPolygon({
    required String localityCode,
  }) async {
    await _ensureLoaded();
    final feature = _featuresByLocalityCode?[localityCode];
    if (feature == null) return null;

    try {
      return _parseGeoJsonToPolygonPreferLargest(feature.geometry);
    } catch (e, st) {
      developer.log(
        'Failed to parse locality GeoJSON asset for $localityCode',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<({String localityCode, String cityCode, String displayName})?>
      lookupLocalityByPoint({
    required double lat,
    required double lon,
  }) async {
    await _ensureLoaded();
    final features = _featuresByLocalityCode?.values.toList(growable: false) ??
        const <_AssetLocalityFeature>[];

    for (final f in features) {
      final poly = _parseGeoJsonToPolygonPreferLargest(f.geometry);
      if (_containsPoint(poly, lat: lat, lon: lon)) {
        return (
          localityCode: f.localityCode,
          cityCode: f.cityCode,
          displayName: f.displayName,
        );
      }
    }

    return null;
  }

  GeoPolygonV1 _parseGeoJsonToPolygonPreferLargest(
      Map<String, dynamic> geojson) {
    final type = (geojson['type'] ?? '').toString();
    final coords = geojson['coordinates'];

    List<List<GeoPointV1>> parsePolygonRings(dynamic polygonCoords) {
      // polygonCoords: [ [ [lon,lat], ... ] , [hole], ...]
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
      // Shoelace on lon/lat (good enough for relative comparisons).
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
      // MultiPolygon: [ polygon, polygon, ... ]
      if (coords is! List) return const GeoPolygonV1(rings: []);

      List<List<GeoPointV1>> bestRings = const [];
      double bestArea = -1;

      for (final poly in coords) {
        final rings = parsePolygonRings(poly);
        if (rings.isEmpty) continue;
        final outer = rings.first;
        final area = ringArea(outer);
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
      // Ray casting in lon/lat plane.
      var inside = false;
      for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        final xi = ring[i].lon;
        final yi = ring[i].lat;
        final xj = ring[j].lon;
        final yj = ring[j].lat;

        final intersect = ((yi > lat) != (yj > lat)) &&
            (lon <
                (xj - xi) * (lat - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                    xi);
        if (intersect) inside = !inside;
      }
      return inside;
    }

    // Must be in outer ring
    if (!inRing(polygon.rings.first)) return false;

    // Must NOT be in any hole ring
    for (final hole in polygon.rings.skip(1)) {
      if (inRing(hole)) return false;
    }
    return true;
  }
}

class _AssetLocalityFeature {
  final String localityCode;
  final String cityCode;
  final String displayName;
  final Map<String, dynamic> geometry;

  const _AssetLocalityFeature({
    required this.localityCode,
    required this.cityCode,
    required this.displayName,
    required this.geometry,
  });
}

import 'dart:developer' as developer;

import 'package:avrai/core/services/geographic/geo_locality_asset_service.dart';
import 'package:avrai/core/services/geographic/geo_locality_pack_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

class GeoCityV1 {
  final String cityCode;
  final String displayName;

  const GeoCityV1({required this.cityCode, required this.displayName});
}

class GeoLocalityV1 {
  final String localityCode;
  final String displayName;
  final String? parentLocalityCode;
  final bool isNeighborhood;

  const GeoLocalityV1({
    required this.localityCode,
    required this.displayName,
    required this.parentLocalityCode,
    required this.isNeighborhood,
  });
}

class GeoGeohash3BoundsV1 {
  final String geohash3Id;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;

  const GeoGeohash3BoundsV1({
    required this.geohash3Id,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
  });
}

class GeoPointV1 {
  final double lat;
  final double lon;

  const GeoPointV1({required this.lat, required this.lon});
}

class GeoPolygonV1 {
  /// Rings in GeoJSON order:
  /// - first ring is the outer boundary
  /// - subsequent rings (if any) are holes
  final List<List<GeoPointV1>> rings;

  const GeoPolygonV1({required this.rings});
}

/// Geo Hierarchy Service (v1)
///
/// Bridges the **expert system geographic hierarchy** (locality/city scope) with the
/// **outside-buyer geo buckets** (`city_code`) by reading the canonical hierarchy
/// from Supabase via controlled RPCs.
///
/// This is intentionally **best-effort**:
/// - If Supabase is unavailable, callers should fall back to local heuristics
///   (`GeographicScopeService`, `LargeCityDetectionService`, etc.).
///
/// Supabase RPCs used:
/// - `geo_list_cities_v1()`
/// - `geo_list_city_localities_v1(p_city_code text)`
class GeoHierarchyService {
  static const String _logName = 'GeoHierarchyService';

  final SupabaseService _supabaseService;
  final GeoLocalityAssetService _assetService = GeoLocalityAssetService();
  final GeoLocalityPackService _packService = GeoLocalityPackService();

  GeoHierarchyService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  Future<List<Map<String, dynamic>>> _listCitiesRaw() async {
    final c = _supabaseService.tryGetClient();
    if (c == null) return const [];
    final res = await c.rpc('geo_list_cities_v1');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> _listLocalitiesRaw(String cityCode) async {
    final c = _supabaseService.tryGetClient();
    if (c == null) return const [];
    final res = await c
        .rpc('geo_list_city_localities_v1', params: {'p_city_code': cityCode});
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> _listCityGeohash3BoundsRaw({
    required String cityCode,
    int limit = 5000,
  }) async {
    final c = _supabaseService.tryGetClient();
    if (c == null) return const [];
    final res = await c.rpc('geo_list_city_geohash3_bounds_v1', params: {
      'p_city_code': cityCode,
      'p_limit': limit,
    });
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>?> _getLocalityShapeGeoJsonRaw({
    required String localityCode,
    double simplifyTolerance = 0.002,
  }) async {
    final c = _supabaseService.tryGetClient();
    if (c == null) return null;
    final res = await c.rpc('geo_get_locality_shape_geojson_v1', params: {
      'p_locality_code': localityCode,
      'p_simplify_tolerance': simplifyTolerance,
    });
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<String?> lookupCityCodeByPoint({
    required double lat,
    required double lon,
  }) async {
    try {
      final c = _supabaseService.tryGetClient();
      if (c == null) {
        // Offline-first: try installed packs, then bundled assets.
        final locality = await _packService.lookupLocalityByPoint(lat: lat, lon: lon) ??
            await _assetService.lookupLocalityByPoint(lat: lat, lon: lon);
        return locality?.cityCode;
      }
      final res = await c.rpc('geo_lookup_city_code_by_point_v1', params: {
        'p_lat': lat,
        'p_lon': lon,
      });
      return res?.toString();
    } catch (e, st) {
      developer.log(
        'geo_lookup_city_code_by_point_v1 failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      // Offline fallback: try installed packs, then bundled assets.
      final locality = await _packService.lookupLocalityByPoint(lat: lat, lon: lon) ??
          await _assetService.lookupLocalityByPoint(lat: lat, lon: lon);
      return locality?.cityCode;
    }
  }

  Future<({String localityCode, String cityCode, String displayName})?>
      lookupLocalityByPoint({
    required double lat,
    required double lon,
  }) async {
    try {
      final c = _supabaseService.tryGetClient();
      if (c == null) {
        // Offline-first: try installed packs, then bundled assets.
        return await _packService.lookupLocalityByPoint(lat: lat, lon: lon) ??
            await _assetService.lookupLocalityByPoint(lat: lat, lon: lon);
      }
      final res = await c.rpc('geo_lookup_locality_by_point_v1', params: {
        'p_lat': lat,
        'p_lon': lon,
      });

      // table-returning RPCs come back as List<row>
      if (res is! List || res.isEmpty) return null;
      final row = Map<String, dynamic>.from(res.first as Map);

      final localityCode = (row['locality_code'] ?? '').toString();
      final cityCode = (row['city_code'] ?? '').toString();
      final displayName = (row['display_name'] ?? '').toString();
      if (localityCode.isEmpty) return null;

      return (
        localityCode: localityCode,
        cityCode: cityCode,
        displayName: displayName
      );
    } catch (e, st) {
      developer.log(
        'geo_lookup_locality_by_point_v1 failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return await _packService.lookupLocalityByPoint(lat: lat, lon: lon) ??
          await _assetService.lookupLocalityByPoint(lat: lat, lon: lon);
    }
  }

  Future<String?> lookupCityCode(String placeName) async {
    try {
      final c = _supabaseService.tryGetClient();
      if (c == null) return null;
      final res = await c
          .rpc('geo_lookup_city_code_v1', params: {'p_place_name': placeName});
      return res?.toString();
    } catch (e, st) {
      developer.log('geo_lookup_city_code_v1 failed',
          name: _logName, error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> lookupLocalityCode({
    required String cityCode,
    required String localityName,
  }) async {
    try {
      final c = _supabaseService.tryGetClient();
      if (c == null) return null;
      final res = await c.rpc('geo_lookup_locality_code_v1', params: {
        'p_city_code': cityCode,
        'p_locality_name': localityName,
      });
      return res?.toString();
    } catch (e, st) {
      developer.log(
        'geo_lookup_locality_code_v1 failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<List<GeoCityV1>> listCities() async {
    final raw = await _listCitiesRaw();
    return raw
        .map((r) => GeoCityV1(
              cityCode: (r['city_code'] ?? '').toString(),
              displayName: (r['display_name'] ?? '').toString(),
            ))
        .where((c) => c.cityCode.isNotEmpty)
        .toList();
  }

  Future<List<GeoLocalityV1>> listCityLocalities(String cityCode) async {
    final raw = await _listLocalitiesRaw(cityCode);
    return raw
        .map((r) => GeoLocalityV1(
              localityCode: (r['locality_code'] ?? '').toString(),
              displayName: (r['display_name'] ?? '').toString(),
              parentLocalityCode: r['parent_locality_code']?.toString(),
              isNeighborhood: (r['is_neighborhood'] as bool?) ?? false,
            ))
        .where((l) => l.localityCode.isNotEmpty)
        .toList();
  }

  Future<List<GeoGeohash3BoundsV1>> listCityGeohash3Bounds({
    required String cityCode,
    int limit = 5000,
  }) async {
    try {
      final raw =
          await _listCityGeohash3BoundsRaw(cityCode: cityCode, limit: limit);
      return raw
          .map((r) => GeoGeohash3BoundsV1(
                geohash3Id: (r['geohash3_id'] ?? '').toString(),
                minLat: (r['min_lat'] as num?)?.toDouble() ?? 0,
                minLon: (r['min_lon'] as num?)?.toDouble() ?? 0,
                maxLat: (r['max_lat'] as num?)?.toDouble() ?? 0,
                maxLon: (r['max_lon'] as num?)?.toDouble() ?? 0,
              ))
          .where((b) => b.geohash3Id.isNotEmpty)
          .toList();
    } catch (e, st) {
      developer.log(
        'geo_list_city_geohash3_bounds_v1 failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  /// Fetch a locality shape as a Google-Maps-friendly polygon.
  ///
  /// The Supabase RPC returns GeoJSON (Polygon or MultiPolygon). We parse the
  /// coordinates into rings of LatLng points.
  Future<GeoPolygonV1?> getLocalityPolygon({
    required String localityCode,
    double simplifyTolerance = 0.002,
  }) async {
    try {
      final geojson = await _getLocalityShapeGeoJsonRaw(
        localityCode: localityCode,
        simplifyTolerance: simplifyTolerance,
      );
      if (geojson == null) {
        final hint = _inferCityCodeHintFromLocalityCode(localityCode);
        return await _packService.getLocalityPolygon(
              localityCode: localityCode,
              cityCodeHints: hint == null ? const [] : [hint],
            ) ??
            await _assetService.getLocalityPolygon(localityCode: localityCode);
      }

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

      if (type == 'Polygon') {
        return GeoPolygonV1(rings: parsePolygonRings(coords));
      }
      if (type == 'MultiPolygon') {
        // MultiPolygon: [ polygon, polygon, ... ]
        // IMPORTANT: Google Maps `Polygon` supports holes, not multi-polygons.
        // We pick the largest polygon by outer-ring area (best-effort).
        if (coords is! List) {
          final hint = _inferCityCodeHintFromLocalityCode(localityCode);
          return await _packService.getLocalityPolygon(
                localityCode: localityCode,
                cityCodeHints: hint == null ? const [] : [hint],
              ) ??
              await _assetService.getLocalityPolygon(localityCode: localityCode);
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

        if (bestRings.isNotEmpty) {
          return GeoPolygonV1(rings: bestRings);
        }
        final hint = _inferCityCodeHintFromLocalityCode(localityCode);
        return await _packService.getLocalityPolygon(
              localityCode: localityCode,
              cityCodeHints: hint == null ? const [] : [hint],
            ) ??
            await _assetService.getLocalityPolygon(localityCode: localityCode);
      }

      return null;
    } catch (e, st) {
      developer.log(
        'geo_get_locality_shape_geojson_v1 parse failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      final hint = _inferCityCodeHintFromLocalityCode(localityCode);
      return await _packService.getLocalityPolygon(
            localityCode: localityCode,
            cityCodeHints: hint == null ? const [] : [hint],
          ) ??
          await _assetService.getLocalityPolygon(localityCode: localityCode);
    }
  }

  String? _inferCityCodeHintFromLocalityCode(String localityCode) {
    // Heuristic: locality codes often look like `us-nyc-brooklyn` where
    // city_code is the first two segments.
    final parts = localityCode.split('-');
    if (parts.length >= 2) {
      final candidate = '${parts[0]}-${parts[1]}';
      if (candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  /// Best-effort city_code inference from a user-entered location string.
  ///
  /// Current heuristic:
  /// - Fetch known `city_code` + `display_name` list
  /// - Match by normalized containment
  Future<String?> inferCityCodeFromLocation(String location) async {
    // Prefer DB lookup that also resolves via `geo_localities_v1`.
    final direct = await lookupCityCode(location);
    if (direct != null && direct.isNotEmpty) return direct;

    final normalized = location.toLowerCase();
    final cities = await _listCitiesRaw();
    for (final row in cities) {
      final code = (row['city_code'] ?? '').toString();
      final name = (row['display_name'] ?? '').toString();
      if (code.isEmpty || name.isEmpty) continue;
      final nameNorm = name.toLowerCase();
      if (normalized.contains(nameNorm) || nameNorm.contains(normalized)) {
        return code;
      }
    }
    return null;
  }

  /// Get locality display names for a given user location (best-effort).
  ///
  /// Intended usage:
  /// - City experts: populate locality dropdown with canonical geo hierarchy
  /// - Falls back to empty list if city_code can't be inferred
  Future<List<String>> listLocalityDisplayNamesForUserLocation(
      String userLocation) async {
    try {
      final cityCode = await inferCityCodeFromLocation(userLocation);
      if (cityCode == null) return const [];

      final localities = await _listLocalitiesRaw(cityCode);
      final names = <String>[];
      for (final row in localities) {
        final name = (row['display_name'] ?? '').toString().trim();
        if (name.isNotEmpty) names.add(name);
      }
      return names;
    } catch (e, st) {
      developer.log(
        'Geo hierarchy lookup failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  /// Resolve [localityCode] from city and locality display names.
  ///
  /// Uses [listCities] and [listCityLocalities] with case-insensitive matching.
  /// Returns null if no match (e.g. Supabase unavailable or names not in hierarchy).
  Future<String?> lookupLocalityCodeByDisplayName({
    required String cityDisplayName,
    required String localityDisplayName,
  }) async {
    try {
      final cities = await listCities();
      final cityNorm = cityDisplayName.trim().toLowerCase();
      if (cityNorm.isEmpty) return null;

      GeoCityV1? city;
      for (final c in cities) {
        if (c.displayName.trim().toLowerCase() == cityNorm) {
          city = c;
          break;
        }
      }
      if (city == null) return null;

      final localities = await listCityLocalities(city.cityCode);
      final locNorm = localityDisplayName.trim().toLowerCase();
      if (locNorm.isEmpty) return null;

      for (final loc in localities) {
        if (loc.displayName.trim().toLowerCase() == locNorm) {
          return loc.localityCode;
        }
      }
      return null;
    } catch (e, st) {
      developer.log(
        'lookupLocalityCodeByDisplayName failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

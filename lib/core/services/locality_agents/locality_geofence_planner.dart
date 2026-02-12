import 'dart:developer' as developer;

import 'package:avrai/core/services/places/geohash_service.dart';
import 'package:avrai/core/services/locality_agents/os_geofence_registrar.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

/// Locality geofence planner (v1)
///
/// Produces a bounded set of OS geofence registrations based on geohash cells.
/// The OS geofence system has strict limits (e.g. iOS ~20 regions), so we plan a small set.
class LocalityGeofencePlannerV1 {
  static const String _logName = 'LocalityGeofencePlannerV1';
  static const String _box = 'spots_ai';

  final StorageService _storage;
  final OsGeofenceRegistrarV1 _registrar;

  LocalityGeofencePlannerV1({
    required StorageService storage,
    required OsGeofenceRegistrarV1 registrar,
  })  : _storage = storage,
        _registrar = registrar;

  Future<List<PlannedOsGeofenceV1>> planAndRegister({
    required String agentId,
    required double latitude,
    required double longitude,
    int precision = 7,
    int maxGeofences = 12,
  }) async {
    final geohash = GeohashService.encode(
      latitude: latitude,
      longitude: longitude,
      precision: precision,
    );

    final candidates = <String>{geohash, ...GeohashService.neighbors(geohash: geohash)};

    // Add a coarser “parent” geohash to keep a broader anchor region.
    if (precision >= 6) {
      candidates.add(geohash.substring(0, 5));
    }

    final chosen = candidates.take(maxGeofences).toList(growable: false);
    final planned = chosen.map((gh) => _toOsGeofence(gh)).toList(growable: false);

    // Persist planned set (best-effort) for debugging/inspection.
    try {
      await _storage.setObject(
        'locality_os_geofences_v1:$agentId',
        planned
            .map((g) => {
                  'id': g.id,
                  'latitude': g.latitude,
                  'longitude': g.longitude,
                  'radiusMeters': g.radiusMeters,
                  'metadata': g.metadata,
                })
            .toList(),
        box: _box,
      );
    } catch (e, st) {
      developer.log('Failed persisting planned geofences: $e',
          name: _logName, error: e, stackTrace: st);
    }

    // Register with OS (no-op in v1)
    await _registrar.registerGeofences(planned);

    developer.log(
      'Planned OS geofences: ${planned.length} (precision=$precision)',
      name: _logName,
    );
    return planned;
  }

  PlannedOsGeofenceV1 _toOsGeofence(String geohash) {
    final bbox = GeohashService.decodeBoundingBox(geohash);
    final c = bbox.center;

    // Approximate radius: half of the max span converted to meters.
    // This is intentionally coarse; visit validation still happens via app logic.
    final radiusMeters = _approxRadiusMeters(bbox);

    return PlannedOsGeofenceV1(
      id: 'gh:${geohash.length}:$geohash',
      latitude: c.lat,
      longitude: c.lon,
      radiusMeters: radiusMeters,
      metadata: {
        'geohash': geohash,
        'precision': geohash.length,
      },
    );
  }

  double _approxRadiusMeters(GeohashBoundingBox bbox) {
    // 1 deg latitude ≈ 111_320m; longitude depends on latitude, but this approximation
    // is fine for bounded OS geofence triggers.
    final latMeters = bbox.latSpan * 111320.0;
    // treat lon as same scale for simplicity (overestimates at high latitudes)
    final lonMeters = bbox.lonSpan * 111320.0;
    final maxSpan = latMeters > lonMeters ? latMeters : lonMeters;
    final r = (maxSpan / 2).clamp(50.0, 500.0);
    return r.toDouble();
  }
}


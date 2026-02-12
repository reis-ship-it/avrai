import 'dart:async';
import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/models/spots/visit.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/places/geohash_service.dart';
import 'package:avrai/core/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_engine.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_update_emitter_v1.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/data/datasources/local/spots_local_datasource.dart';

/// Ingests visits/check-ins into LocalityAgents (v1).
///
/// Responsibilities:
/// - resolve stable agent key (geohash prefix)
/// - update per-user private delta (device)
/// - emit privacy-bounded update event to backend (Supabase)
class LocalityAgentIngestionServiceV1 {
  static const String _logName = 'LocalityAgentIngestionServiceV1';
  static const int _precision = 7;

  final AgentIdService _agentIdService;
  final GeoHierarchyService _geoHierarchyService;
  final SharedPreferencesCompat? _prefs;
  final SpotsLocalDataSource _spotsLocal;
  final LocalityAgentEngineV1 _engine;
  final LocalityAgentUpdateEmitterV1 _emitter;

  LocalityAgentIngestionServiceV1({
    required AgentIdService agentIdService,
    required GeoHierarchyService geoHierarchyService,
    required SharedPreferencesCompat? prefs,
    required SpotsLocalDataSource spotsLocalDataSource,
    required LocalityAgentEngineV1 engine,
    required LocalityAgentUpdateEmitterV1 emitter,
  })  : _agentIdService = agentIdService,
        _geoHierarchyService = geoHierarchyService,
        _prefs = prefs,
        _spotsLocal = spotsLocalDataSource,
        _engine = engine,
        _emitter = emitter;

  /// Seed the homebase LocalityAgent during onboarding.
  ///
  /// This primes caches and creates a minimal backend update record (best-effort).
  Future<void> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'onboarding_seed',
  }) async {
    final inferredCityCode = await _resolveInferredCityCodeBestEffort(
      lat: latitude,
      lon: longitude,
    );
    final geohash = GeohashService.encode(
      latitude: latitude,
      longitude: longitude,
      precision: _precision,
    );
    final key = LocalityAgentKeyV1(
      geohashPrefix: geohash,
      precision: _precision,
      cityCode: cityCode,
    );

    try {
      // Prime (download/cache) global priors and ensure local delta exists.
      await _engine.inferVector12(agentId: agentId, key: key);
      await _emitter.emit(
        userId: userId,
        event: LocalityAgentUpdateEventV1(
          key: key,
          occurredAtUtc: DateTime.now().toUtc(),
          source: source,
          reportedCityCode: cityCode,
          inferredCityCode: inferredCityCode,
        ),
      );
      developer.log('Seeded homebase locality agent: ${key.stableKey}',
          name: _logName);
    } catch (e, st) {
      developer.log('Failed seeding homebase locality agent: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  /// Ingest a completed visit into the locality agent system.
  ///
  /// Best-effort; failures should not block checkout flows.
  Future<void> ingestVisit({
    required String userId,
    required Visit visit,
    required String source,
  }) async {
    final agentId = await _agentIdService.getUserAgentId(userId);

    final coords = await _resolveVisitCoordinates(visit);
    if (coords == null) {
      developer.log(
        'No coordinates for visit; skipping locality ingestion',
        name: _logName,
      );
      return;
    }

    final cityCode = await _resolveCityCodeBestEffort(
      lat: coords.lat,
      lon: coords.lon,
    );
    final inferredCityCode = await _resolveInferredCityCodeBestEffort(
      lat: coords.lat,
      lon: coords.lon,
    );
    if (cityCode != null &&
        inferredCityCode != null &&
        cityCode != inferredCityCode) {
      developer.log(
        'City code mismatch (reported vs inferred): reported=$cityCode inferred=$inferredCityCode',
        name: _logName,
      );
    }

    final geohash = GeohashService.encode(
      latitude: coords.lat,
      longitude: coords.lon,
      precision: _precision,
    );
    final key = LocalityAgentKeyV1(
      geohashPrefix: geohash,
      precision: _precision,
      cityCode: cityCode,
    );

    final homebase = _readHomebaseCoords();

    LocalityAgentPersonalDeltaV1? updatedDelta;
    try {
      updatedDelta = await _engine.updateFromVisit(
        agentId: agentId,
        key: key,
        visit: visit,
        homebase: homebase,
      );
      
      // NEW: Propagate locality agent update through mesh (best-effort)
      unawaited(_propagateLocalityAgentUpdateThroughMesh(
        agentId: agentId,
        key: key,
        delta: updatedDelta,
      ));
    } catch (e, st) {
      developer.log('Local delta update failed: $e',
          name: _logName, error: e, stackTrace: st);
    }

    try {
      await _emitter.emit(
        userId: userId,
        event: LocalityAgentUpdateEventV1(
          key: key,
          occurredAtUtc: (visit.checkOutTime ?? visit.checkInTime).toUtc(),
          reportedCityCode: cityCode,
          inferredCityCode: inferredCityCode,
          dwellMinutes: visit.dwellTime?.inMinutes,
          qualityScore: visit.qualityScore,
          isRepeatVisit: visit.isRepeatVisit,
          source: source,
        ),
      );
    } catch (e, st) {
      developer.log('Update emit failed: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  Future<({double lat, double lon})?> _resolveVisitCoordinates(Visit visit) async {
    final gf = visit.geofencingData;
    if (gf != null) {
      return (lat: gf.latitude, lon: gf.longitude);
    }

    // Bluetooth-only visits might still have a known Spot with coordinates.
    try {
      final Spot? spot = await _spotsLocal.getSpotById(visit.locationId);
      final lat = spot?.latitude;
      final lon = spot?.longitude;
      if (lat != null && lon != null) return (lat: lat, lon: lon);
    } catch (_) {
      // ignore best-effort lookup failures
    }

    return null;
  }

  Future<String?> _resolveCityCodeBestEffort({
    required double lat,
    required double lon,
  }) async {
    try {
      final locality = await _geoHierarchyService.lookupLocalityByPoint(
        lat: lat,
        lon: lon,
      );
      return locality?.cityCode;
    } catch (_) {
      // ignore, offline fallback happens inside GeoHierarchyService
      return null;
    }
  }

  Future<String?> _resolveInferredCityCodeBestEffort({
    required double lat,
    required double lon,
  }) async {
    try {
      // This is intentionally "best-effort": it may return null when offline.
      return await _geoHierarchyService.lookupCityCodeByPoint(lat: lat, lon: lon);
    } catch (_) {
      return null;
    }
  }

  ({double lat, double lon})? _readHomebaseCoords() {
    final prefs = _prefs;
    if (prefs == null) return null;
    final lat = prefs.getDouble('cached_lat');
    final lon = prefs.getDouble('cached_lng');
    if (lat == null || lon == null) return null;
    return (lat: lat, lon: lon);
  }

  /// NEW: Propagate locality agent update through mesh network (best-effort)
  Future<void> _propagateLocalityAgentUpdateThroughMesh({
    required String agentId,
    required LocalityAgentKeyV1 key,
    required LocalityAgentPersonalDeltaV1 delta,
  }) async {
    try {
      // Get connection orchestrator from DI (best-effort)
      final sl = GetIt.instance;
      if (!sl.isRegistered<VibeConnectionOrchestrator>()) {
        return; // Mesh not available
      }
      
      final orchestrator = sl<VibeConnectionOrchestrator>();
      
      // Determine geographic scope from precision
      final scope = _getScopeFromPrecision(key.precision);
      
      // Create mesh message
      final message = {
        'type': 'locality_agent_update',
        'agent_id': agentId,
        'key': key.stableKey,
        'geohash_prefix': key.geohashPrefix,
        'precision': key.precision,
        'city_code': key.cityCode,
        'delta12': delta.delta12,
        'visit_count': delta.visitCount,
        'hop': 0,
        'origin_id': agentId,
        'scope': scope,
        'created_at': DateTime.now().toIso8601String(),
        'ttl_ms': 6 * 60 * 60 * 1000, // 6 hours
      };
      
      // Forward through mesh
      await orchestrator.forwardLocalityAgentUpdate(message);
      
      developer.log(
        'Propagated locality agent update through mesh: ${key.stableKey}',
        name: _logName,
      );
    } catch (e, st) {
      // Best-effort: mesh propagation failure should not block ingestion
      developer.log(
        'Failed to propagate locality agent update through mesh: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
  
  /// Get geographic scope from geohash precision
  String _getScopeFromPrecision(int precision) {
    // Precision 7 = locality, 6 = city-ish, 5 = region-ish, etc.
    if (precision >= 7) return 'locality';
    if (precision >= 6) return 'city';
    if (precision >= 5) return 'region';
    if (precision >= 4) return 'country';
    return 'global';
  }

  /// Convenience getter for use sites that don't have DI access.
  static LocalityAgentIngestionServiceV1? tryGetFromDI() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<LocalityAgentIngestionServiceV1>()) return null;
    return sl<LocalityAgentIngestionServiceV1>();
  }
}


import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:get_it/get_it.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_global_repository.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_local_store.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_mesh_cache.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

/// Locality Agent Engine (v1)
///
/// Produces a locality-context “vibe vector” by combining:
/// - Global priors (shared, downloaded from Supabase; smoothed across neighbors)
/// - Personal delta (private, stored on-device)
///
/// The 12 values correspond to `VibeConstants.coreDimensions` in order.
class LocalityAgentEngineV1 {
  static const String _logName = 'LocalityAgentEngineV1';

  final LocalityAgentGlobalRepositoryV1 _globalRepo;
  final LocalityAgentLocalStoreV1 _localStore;

  LocalityAgentEngineV1({
    required LocalityAgentGlobalRepositoryV1 globalRepo,
    required LocalityAgentLocalStoreV1 localStore,
  })  : _globalRepo = globalRepo,
        _localStore = localStore;

  static const List<String> dimensions = VibeConstants.coreDimensions;

  /// Infer the current locality vector for [key] for a specific [agentId].
  ///
  /// Includes neighbor smoothing (8-neighborhood + optional parent prefix).
  Future<List<double>> inferVector12({
    required String agentId,
    required LocalityAgentKeyV1 key,
  }) async {
    final self = await _globalRepo.getGlobalState(key);

    // Neighbor smoothing for “surrounding areas”
    final neighborKeys = GeohashService.neighbors(geohash: key.geohashPrefix)
        .map((gh) => LocalityAgentKeyV1(
              geohashPrefix: gh,
              precision: key.precision,
              cityCode: key.cityCode,
            ))
        .toList(growable: false);

    // Parent prefix (coarser prior) for city-ish smoothing.
    LocalityAgentKeyV1? parentKey;
    if (key.precision >= 6) {
      const parentPrecision = 5;
      parentKey = LocalityAgentKeyV1(
        geohashPrefix: key.geohashPrefix.substring(0, parentPrecision),
        precision: parentPrecision,
        cityCode: key.cityCode,
      );
    }

    final neighborStates = <LocalityAgentGlobalStateV1>[];
    for (final nk in neighborKeys) {
      neighborStates.add(await _globalRepo.getGlobalState(nk));
    }
    final parentState =
        parentKey != null ? await _globalRepo.getGlobalState(parentKey) : null;

    // NEW: Get mesh-smoothed neighbors (extended neighborhood from mesh network)
    final meshNeighborDeltas = await _getMeshSmoothedNeighbors(key);

    // Weighted blend (includes mesh neighbors)
    final combinedGlobal = _blendGlobal(
      self: self.vector12,
      neighbors: neighborStates.map((s) => s.vector12).toList(growable: false),
      parent: parentState?.vector12,
      meshNeighbors: meshNeighborDeltas, // NEW: Mesh-smoothed neighbors
    );

    final delta = await _localStore.getDelta(agentId: agentId, key: key);
    final withDelta = _applyDeltaAndClamp(combinedGlobal, delta.delta12);

    return withDelta;
  }

  /// Update the personal delta for [key] from a [visit].
  ///
  /// This is a **private** learning signal; it should not be uploaded verbatim.
  Future<LocalityAgentPersonalDeltaV1> updateFromVisit({
    required String agentId,
    required LocalityAgentKeyV1 key,
    required Visit visit,
    ({double lat, double lon})? homebase,
  }) async {
    final existing = await _localStore.getDelta(agentId: agentId, key: key);
    final signal = _visitToDeltaSignal(
      visit: visit,
      homebase: homebase,
    );

    final alpha = _computeAlpha(existing.visitCount);
    final nextDelta = List<double>.generate(
      12,
      (i) => existing.delta12[i] * (1 - alpha) + signal[i] * alpha,
      growable: false,
    );
    final updated = LocalityAgentPersonalDeltaV1(
      key: key,
      delta12: nextDelta,
      visitCount: existing.visitCount + 1,
      updatedAtUtc: DateTime.now().toUtc(),
    );
    await _localStore.saveDelta(agentId: agentId, delta: updated);

    developer.log(
      'Updated locality delta for ${key.stableKey} (visitCount=${updated.visitCount})',
      name: _logName,
    );

    return updated;
  }

  List<double> _blendGlobal({
    required List<double> self,
    required List<List<double>> neighbors,
    required List<double>? parent,
    List<List<double>> meshNeighbors = const [], // NEW: Mesh-smoothed neighbors
  }) {
    const selfW = 0.5; // Reduced from 0.6 to make room for mesh neighbors
    const neighborsW = 0.25; // Reduced from 0.3
    const parentW = 0.1;
    const meshW = 0.15; // NEW: Weight for mesh neighbors

    final n = neighbors.isEmpty ? 0 : neighbors.length;
    final perNeighbor = n == 0 ? 0.0 : neighborsW / n;
    final meshN = meshNeighbors.isEmpty ? 0 : meshNeighbors.length;
    final perMeshNeighbor = meshN == 0 ? 0.0 : meshW / meshN;

    final out = List<double>.filled(12, 0.0);
    for (var i = 0; i < 12; i++) {
      var v = self[i] * selfW;
      if (n > 0) {
        for (final nb in neighbors) {
          v += nb[i] * perNeighbor;
        }
      }
      // NEW: Add mesh neighbor contributions
      if (meshN > 0) {
        for (final meshNb in meshNeighbors) {
          v += meshNb[i] * perMeshNeighbor;
        }
      }
      if (parent != null) {
        v += parent[i] * parentW;
      } else {
        // redistribute parent weight to self if missing
        v += self[i] * parentW;
      }
      out[i] = v;
    }
    return out;
  }

  /// NEW: Get mesh-smoothed neighbors (extended neighborhood from mesh network)
  Future<List<List<double>>> _getMeshSmoothedNeighbors(
    LocalityAgentKeyV1 key,
  ) async {
    try {
      // Get mesh cache (if available)
      final sl = GetIt.instance;
      if (!sl.isRegistered<LocalityAgentMeshCache>()) {
        return []; // Mesh cache not available
      }

      final meshCache = sl<LocalityAgentMeshCache>();
      final meshDeltas = await meshCache.getNeighborMeshUpdates(key);

      // Return mesh-learned delta vectors directly
      return meshDeltas;
    } catch (e, st) {
      developer.log(
        'Failed to get mesh-smoothed neighbors: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  List<double> _applyDeltaAndClamp(List<double> base, List<double> delta) {
    return List<double>.generate(
      12,
      (i) => (base[i] + delta[i]).clamp(0.0, 1.0),
      growable: false,
    );
  }

  double _computeAlpha(int visitCount) {
    // Higher learning rate early, decays with evidence.
    // Bounded to prevent “stuck” behavior.
    final raw = 1.0 / math.max(4, visitCount + 1);
    return raw.clamp(0.03, 0.20);
  }

  List<double> _visitToDeltaSignal({
    required Visit visit,
    ({double lat, double lon})? homebase,
  }) {
    final out = List<double>.filled(12, 0.0);

    final dwellMin =
        visit.dwellTime?.inMinutes ?? visit.calculateDwellTime().inMinutes;
    final quality = visit.qualityScore.clamp(0.0, 1.5);
    final qualityNorm = (quality / 1.5).clamp(0.0, 1.0);
    final strength = (0.05 + 0.10 * qualityNorm).clamp(0.05, 0.15);

    // Index helpers
    int idx(String name) => dimensions.indexOf(name);

    // Novelty vs routine (repeat visits reduce novelty seeking).
    final novelty = visit.isRepeatVisit ? -1.0 : 1.0;
    out[idx('novelty_seeking')] += novelty * strength;
    out[idx('exploration_eagerness')] +=
        (visit.isRepeatVisit ? 0.02 : 0.05) * strength / 0.15;

    // Dwell time implies deeper engagement and often correlates with authenticity.
    if (dwellMin >= 30) {
      out[idx('authenticity_preference')] += 0.8 * strength;
    } else if (dwellMin >= 15) {
      out[idx('authenticity_preference')] += 0.4 * strength;
    }

    // Bluetooth AI2AI proximity suggests social discovery and trust-network behavior.
    final bt = visit.bluetoothData;
    if (bt != null && (bt.ai2aiConnected || bt.personalityExchanged)) {
      final mult = bt.personalityExchanged ? 1.0 : 0.6;
      out[idx('community_orientation')] += 0.7 * strength * mult;
      out[idx('social_discovery_style')] += 0.6 * strength * mult;
      out[idx('trust_network_reliance')] += 0.6 * strength * mult;
      out[idx('curation_tendency')] += 0.2 * strength * mult;
    }

    // Distance from homebase (if available) updates adventurousness in this area.
    final gf = visit.geofencingData;
    if (homebase != null && gf != null) {
      final km = _haversineKm(
        lat1: homebase.lat,
        lon1: homebase.lon,
        lat2: gf.latitude,
        lon2: gf.longitude,
      );
      final scaled = (km / 20.0).clamp(0.0, 1.0); // 0..20km
      out[idx('location_adventurousness')] += scaled * strength;
    }

    // Time of day affects energy + crowd tolerance heuristically.
    final hour = visit.checkInTime.toLocal().hour;
    if (hour >= 21 || hour <= 2) {
      out[idx('energy_preference')] += 0.4 * strength;
      out[idx('crowd_tolerance')] += 0.3 * strength;
      out[idx('temporal_flexibility')] += 0.3 * strength;
    } else if (hour >= 6 && hour <= 9) {
      out[idx('temporal_flexibility')] += 0.2 * strength;
    }

    // Rating can weakly nudge value orientation (premium experiences correlate with high ratings).
    final rating = visit.rating;
    if (rating != null) {
      final r = (rating / 5.0).clamp(0.0, 1.0);
      out[idx('value_orientation')] += (r - 0.5) * strength;
    }

    // Clamp extreme deltas (delta is additive on top of global; keep small)
    for (var i = 0; i < out.length; i++) {
      out[i] = out[i].clamp(-0.20, 0.20);
    }
    return out;
  }

  double _haversineKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const r = 6371.0; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double d) => d * (math.pi / 180.0);
}

import 'dart:math' as math;

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_sync_coordinator.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';

class LocalityVisitComputation {
  final LocalityState state;
  final LocalityAgentPersonalDeltaV1 delta;

  const LocalityVisitComputation({
    required this.state,
    required this.delta,
  });
}

class LocalityInferenceHead {
  static const List<String> dimensions = VibeConstants.coreDimensions;

  final LocalityMemory _memory;
  final LocalitySyncCoordinator _syncCoordinator;

  LocalityInferenceHead({
    required LocalityMemory memory,
    required LocalitySyncCoordinator syncCoordinator,
  })  : _memory = memory,
        _syncCoordinator = syncCoordinator;

  Future<LocalityState> resolve(LocalityPerceptionInput input) async {
    final key = input.localityKeyHint ??
        ((input.latitude != null && input.longitude != null)
            ? LocalityAgentKeyV1(
                geohashPrefix: GeohashService.encode(
                  latitude: input.latitude!,
                  longitude: input.longitude!,
                  precision: 7,
                ),
                precision: 7,
              )
            : null);
    if (key == null) {
      return LocalityState.zero(alias: input.topAlias);
    }
    return resolveFromKey(
      agentId: input.agentId,
      key: key,
      topAlias: input.topAlias,
    );
  }

  Future<LocalityState> resolveFromKey({
    required String agentId,
    required LocalityAgentKeyV1 key,
    String? topAlias,
    LocalityReliabilityTier? forcedTier,
    LocalitySourceMix? sourceMix,
  }) async {
    final self = await _syncCoordinator.getGlobalState(key);
    final neighborKeys = GeohashService.neighbors(geohash: key.geohashPrefix)
        .map((gh) => LocalityAgentKeyV1(
              geohashPrefix: gh,
              precision: key.precision,
              cityCode: key.cityCode,
            ))
        .toList(growable: false);

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
      neighborStates.add(await _syncCoordinator.getGlobalState(nk));
    }
    final parentState = parentKey != null
        ? await _syncCoordinator.getGlobalState(parentKey)
        : null;

    final meshNeighborDeltas = _syncCoordinator.getNeighborMeshUpdates(key);
    final combinedGlobal = _blendGlobal(
      self: self.vector12,
      neighbors:
          neighborStates.map((state) => state.vector12).toList(growable: false),
      parent: parentState?.vector12,
      meshNeighbors: meshNeighborDeltas,
    );
    final delta = _memory.getPersonalDelta(agentId: agentId, key: key);
    final embedding = _applyDeltaAndClamp(combinedGlobal, delta.delta12);

    final sampleCount = self.sampleCount;
    final averageConfidence =
        self.confidence12 == null || self.confidence12!.isEmpty
            ? 0.0
            : self.confidence12!.reduce((left, right) => left + right) /
                self.confidence12!.length;
    final confidence = averageConfidence.clamp(0.0, 1.0);
    final boundaryTension = _computeBoundaryTension(
      confidence: confidence,
      happinessTrendSlope: self.happinessTrendSlope,
      sampleCount: sampleCount,
    );
    final reliabilityTier = forcedTier ??
        _deriveTier(
          sampleCount: sampleCount,
          confidence: confidence,
          aggregateHappiness: self.aggregateHappiness,
        );
    final advisoryStatus = _deriveAdvisoryStatus(
      aggregateHappiness: self.aggregateHappiness,
      reliabilityTier: reliabilityTier,
    );

    LocalityToken? parentToken;
    if (key.precision >= 6 && key.geohashPrefix.length >= 5) {
      parentToken = LocalityToken.geohashCell(
        stableKey: 'gh5:${key.geohashPrefix.substring(0, 5)}',
        precision: 5,
      );
    }

    return LocalityState(
      activeToken: LocalityToken.geohashCell(
        stableKey: key.stableKey,
        precision: key.precision,
        alias: topAlias,
      ),
      embedding: embedding,
      confidence: confidence,
      boundaryTension: boundaryTension,
      reliabilityTier: reliabilityTier,
      freshness: self.updatedAtUtc,
      evidenceCount: sampleCount,
      evolutionRate: _computeEvolutionRate(
        sampleCount: sampleCount,
        happinessTrendSlope: self.happinessTrendSlope,
      ),
      advisoryStatus: advisoryStatus,
      sourceMix: sourceMix ??
          (sampleCount > 0
              ? const LocalitySourceMix(
                  local: 0.35,
                  federated: 0.45,
                  mesh: 0.2,
                )
              : const LocalitySourceMix.syntheticBootstrap()),
      parentToken: parentToken,
      topAlias: topAlias ?? key.cityCode,
    );
  }

  Future<LocalityVisitComputation> observeVisit({
    required String agentId,
    required LocalityAgentKeyV1 key,
    required Visit visit,
    ({double lat, double lon})? homebase,
    String? topAlias,
  }) async {
    final existing = _memory.getPersonalDelta(agentId: agentId, key: key);
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
    final delta = LocalityAgentPersonalDeltaV1(
      key: key,
      delta12: nextDelta,
      visitCount: existing.visitCount + 1,
      updatedAtUtc: DateTime.now().toUtc(),
    );
    await _memory.savePersonalDelta(agentId: agentId, delta: delta);

    final state = await resolveFromKey(
      agentId: agentId,
      key: key,
      topAlias: topAlias,
      forcedTier: delta.visitCount >= 8
          ? LocalityReliabilityTier.established
          : LocalityReliabilityTier.candidate,
      sourceMix: const LocalitySourceMix(
        local: 0.6,
        mesh: 0.2,
        federated: 0.2,
      ),
    );
    return LocalityVisitComputation(state: state, delta: delta);
  }

  List<double> _blendGlobal({
    required List<double> self,
    required List<List<double>> neighbors,
    required List<double>? parent,
    List<List<double>> meshNeighbors = const [],
  }) {
    const selfW = 0.5;
    const neighborsW = 0.25;
    const parentW = 0.1;
    const meshW = 0.15;

    final n = neighbors.isEmpty ? 0 : neighbors.length;
    final perNeighbor = n == 0 ? 0.0 : neighborsW / n;
    final meshN = meshNeighbors.isEmpty ? 0 : meshNeighbors.length;
    final perMeshNeighbor = meshN == 0 ? 0.0 : meshW / meshN;

    final out = List<double>.filled(12, 0.0);
    for (var i = 0; i < 12; i++) {
      var value = self[i] * selfW;
      if (n > 0) {
        for (final neighbor in neighbors) {
          value += neighbor[i] * perNeighbor;
        }
      }
      if (meshN > 0) {
        for (final meshNeighbor in meshNeighbors) {
          value += meshNeighbor[i] * perMeshNeighbor;
        }
      }
      if (parent != null) {
        value += parent[i] * parentW;
      } else {
        value += self[i] * parentW;
      }
      out[i] = value;
    }
    return out;
  }

  List<double> _applyDeltaAndClamp(List<double> base, List<double> delta) {
    return List<double>.generate(
      12,
      (i) => (base[i] + delta[i]).clamp(0.0, 1.0),
      growable: false,
    );
  }

  double _computeAlpha(int visitCount) {
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

    int idx(String name) => dimensions.indexOf(name);

    final novelty = visit.isRepeatVisit ? -1.0 : 1.0;
    out[idx('novelty_seeking')] += novelty * strength;
    out[idx('exploration_eagerness')] +=
        (visit.isRepeatVisit ? 0.02 : 0.05) * strength / 0.15;

    if (dwellMin >= 30) {
      out[idx('authenticity_preference')] += 0.8 * strength;
    } else if (dwellMin >= 15) {
      out[idx('authenticity_preference')] += 0.4 * strength;
    }

    final bt = visit.bluetoothData;
    if (bt != null && (bt.ai2aiConnected || bt.personalityExchanged)) {
      final mult = bt.personalityExchanged ? 1.0 : 0.6;
      out[idx('community_orientation')] += 0.7 * strength * mult;
      out[idx('social_discovery_style')] += 0.6 * strength * mult;
      out[idx('trust_network_reliance')] += 0.6 * strength * mult;
      out[idx('curation_tendency')] += 0.2 * strength * mult;
    }

    final gf = visit.geofencingData;
    if (homebase != null && gf != null) {
      final km = _haversineKm(
        lat1: homebase.lat,
        lon1: homebase.lon,
        lat2: gf.latitude,
        lon2: gf.longitude,
      );
      final scaled = (km / 20.0).clamp(0.0, 1.0);
      out[idx('location_adventurousness')] += scaled * strength;
    }

    final hour = visit.checkInTime.toLocal().hour;
    if (hour >= 21 || hour <= 2) {
      out[idx('energy_preference')] += 0.4 * strength;
      out[idx('crowd_tolerance')] += 0.3 * strength;
      out[idx('temporal_flexibility')] += 0.3 * strength;
    } else if (hour >= 6 && hour <= 9) {
      out[idx('temporal_flexibility')] += 0.2 * strength;
    }

    final rating = visit.rating;
    if (rating != null) {
      final normalizedRating = (rating / 5.0).clamp(0.0, 1.0);
      out[idx('value_orientation')] += (normalizedRating - 0.5) * strength;
    }

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
    const radiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusKm * c;
  }

  double _degToRad(double value) => value * (math.pi / 180.0);

  LocalityReliabilityTier _deriveTier({
    required int sampleCount,
    required double confidence,
    required double aggregateHappiness,
  }) {
    if (sampleCount <= 0) return LocalityReliabilityTier.bootstrap;
    if (aggregateHappiness < 0.6 && sampleCount >= 5) {
      return LocalityReliabilityTier.advisory;
    }
    if (sampleCount < 5 || confidence < 0.4) {
      return LocalityReliabilityTier.candidate;
    }
    return LocalityReliabilityTier.established;
  }

  LocalityAdvisoryStatus _deriveAdvisoryStatus({
    required double aggregateHappiness,
    required LocalityReliabilityTier reliabilityTier,
  }) {
    if (reliabilityTier == LocalityReliabilityTier.advisory) {
      return LocalityAdvisoryStatus.active;
    }
    if (aggregateHappiness < 0.65) {
      return LocalityAdvisoryStatus.eligible;
    }
    return LocalityAdvisoryStatus.inactive;
  }

  double _computeEvolutionRate({
    required int sampleCount,
    required double happinessTrendSlope,
  }) {
    final evidenceDecay = (1.0 / (sampleCount + 1)).clamp(0.0, 1.0);
    return (evidenceDecay + happinessTrendSlope.abs()).clamp(0.0, 1.0);
  }

  double _computeBoundaryTension({
    required double confidence,
    required double happinessTrendSlope,
    required int sampleCount,
  }) {
    final uncertainty = 1.0 - confidence;
    final sparseEvidenceBoost = sampleCount < 3 ? 0.2 : 0.0;
    final driftBoost = happinessTrendSlope.abs().clamp(0.0, 0.2);
    return (uncertainty + sparseEvidenceBoost + driftBoost).clamp(0.0, 1.0);
  }
}

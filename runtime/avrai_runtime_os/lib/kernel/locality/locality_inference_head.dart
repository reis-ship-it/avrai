import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_sync_coordinator.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_engine.dart';
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
  final LocalityAgentEngineV1 _engine;
  final LocalitySyncCoordinator _syncCoordinator;

  LocalityInferenceHead({
    required LocalityAgentEngineV1 engine,
    required LocalitySyncCoordinator syncCoordinator,
  })  : _engine = engine,
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
    final embedding = await _engine.inferVector12(agentId: agentId, key: key);
    final globalState = await _syncCoordinator.getGlobalState(key);
    final sampleCount = globalState.sampleCount;
    final averageConfidence =
        globalState.confidence12 == null || globalState.confidence12!.isEmpty
            ? 0.0
            : globalState.confidence12!.reduce((left, right) => left + right) /
                globalState.confidence12!.length;
    final confidence = averageConfidence.clamp(0.0, 1.0);
    final boundaryTension = _computeBoundaryTension(
      confidence: confidence,
      happinessTrendSlope: globalState.happinessTrendSlope,
      sampleCount: sampleCount,
    );
    final reliabilityTier = forcedTier ??
        _deriveTier(
          sampleCount: sampleCount,
          confidence: confidence,
          aggregateHappiness: globalState.aggregateHappiness,
        );
    final advisoryStatus = _deriveAdvisoryStatus(
      aggregateHappiness: globalState.aggregateHappiness,
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
      freshness: globalState.updatedAtUtc,
      evidenceCount: sampleCount,
      evolutionRate: _computeEvolutionRate(
        sampleCount: sampleCount,
        happinessTrendSlope: globalState.happinessTrendSlope,
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
    final delta = await _engine.updateFromVisit(
      agentId: agentId,
      key: key,
      visit: visit,
      homebase: homebase,
    );
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

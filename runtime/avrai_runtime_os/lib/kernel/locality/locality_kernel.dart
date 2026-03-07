import 'dart:developer' as developer;

import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_inference_head.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_projection_service.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_runtime_context.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_sync_coordinator.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

class LocalityKernel implements LocalityKernelContract {
  static const String _logName = 'LocalityKernel';
  static const int _precision = 7;
  static const String _systemAgentId = 'locality-kernel-system';
  static const Duration _candidateDecayWindow = Duration(days: 14);

  final AgentIdService _agentIdService;
  final GeoHierarchyService _geoHierarchyService;
  final SharedPreferencesCompat? _prefs;
  final SpotsLocalDataSource _spotsLocal;
  final LocalityMemory _memory;
  final LocalityInferenceHead _inferenceHead;
  final LocalitySyncCoordinator _syncCoordinator;
  final LocalityProjectionService _projectionService;
  final LocalityTrainingContract _trainingContract;

  LocalityKernel({
    required AgentIdService agentIdService,
    required GeoHierarchyService geoHierarchyService,
    required SharedPreferencesCompat? prefs,
    required SpotsLocalDataSource spotsLocalDataSource,
    required LocalityMemory memory,
    required LocalityInferenceHead inferenceHead,
    required LocalitySyncCoordinator syncCoordinator,
    required LocalityProjectionService projectionService,
    required LocalityTrainingContract trainingContract,
  })  : _agentIdService = agentIdService,
        _geoHierarchyService = geoHierarchyService,
        _prefs = prefs,
        _spotsLocal = spotsLocalDataSource,
        _memory = memory,
        _inferenceHead = inferenceHead,
        _syncCoordinator = syncCoordinator,
        _projectionService = projectionService,
        _trainingContract = trainingContract;

  LocalityKernel.fromRuntimeContext(LocalityKernelRuntimeContext context)
      : this(
          agentIdService: context.agentIdService,
          geoHierarchyService: context.geoHierarchyService,
          prefs: context.prefs,
          spotsLocalDataSource: context.spotsLocalDataSource,
          memory: context.memory,
          inferenceHead: context.inferenceHead,
          syncCoordinator: context.syncCoordinator,
          projectionService: context.projectionService,
          trainingContract: context.trainingContract,
        );

  @override
  Future<LocalityState> resolveWhere(LocalityPerceptionInput input) async {
    final state = await _inferenceHead.resolve(input);
    await _memory.saveSnapshot(agentId: input.agentId, state: state);
    return state;
  }

  @override
  Future<LocalityState> seedHomebase({
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
    final key = LocalityAgentKeyV1(
      geohashPrefix: GeohashService.encode(
        latitude: latitude,
        longitude: longitude,
        precision: _precision,
      ),
      precision: _precision,
      cityCode: cityCode,
    );

    final state = await _inferenceHead.resolveFromKey(
      agentId: agentId,
      key: key,
      topAlias: cityCode,
      forcedTier: LocalityReliabilityTier.bootstrap,
      sourceMix: const LocalitySourceMix(
        local: 0.1,
        federated: 0.5,
        geometry: 0.2,
        syntheticPrior: 0.2,
      ),
    );
    await _memory.saveSnapshot(agentId: agentId, state: state);
    await _syncCoordinator.emitObservation(
      LocalityObservation(
        userId: userId,
        agentId: agentId,
        type: LocalityObservationType.onboardingSeed,
        key: key,
        occurredAtUtc: DateTime.now().toUtc(),
        source: source,
        reportedCityCode: cityCode,
        inferredCityCode: inferredCityCode,
        topAlias: cityCode,
      ),
    );
    return state;
  }

  @override
  Future<LocalityUpdateReceipt?> observeVisit({
    required String userId,
    required Visit visit,
    required String source,
  }) async {
    final agentId = await _agentIdService.getUserAgentId(userId);
    final coords = await _resolveVisitCoordinates(visit);
    if (coords == null) {
      developer.log(
        'No coordinates for visit; skipping locality kernel observation',
        name: _logName,
      );
      return null;
    }

    final cityCode = await _resolveCityCodeBestEffort(
      lat: coords.lat,
      lon: coords.lon,
    );
    final inferredCityCode = await _resolveInferredCityCodeBestEffort(
      lat: coords.lat,
      lon: coords.lon,
    );
    final key = LocalityAgentKeyV1(
      geohashPrefix: GeohashService.encode(
        latitude: coords.lat,
        longitude: coords.lon,
        precision: _precision,
      ),
      precision: _precision,
      cityCode: cityCode,
    );

    final computation = await _inferenceHead.observeVisit(
      agentId: agentId,
      key: key,
      visit: visit,
      homebase: _readHomebaseCoords(),
      topAlias: cityCode,
    );
    final candidate = _nextCandidateRecord(
      agentId: agentId,
      token: computation.state.activeToken,
      occurredAtUtc: (visit.checkOutTime ?? visit.checkInTime).toUtc(),
    );
    await _memory.saveCandidate(agentId: agentId, record: candidate);
    final normalizedState = _normalizeCandidateState(
      state: computation.state,
      candidate: candidate,
    );
    await _memory.saveSnapshot(agentId: agentId, state: normalizedState);

    final observation = LocalityObservation(
      userId: userId,
      agentId: agentId,
      type: LocalityObservationType.visitComplete,
      key: key,
      occurredAtUtc: (visit.checkOutTime ?? visit.checkInTime).toUtc(),
      source: source,
      reportedCityCode: cityCode,
      inferredCityCode: inferredCityCode,
      dwellMinutes: visit.dwellTime?.inMinutes,
      qualityScore: visit.qualityScore,
      isRepeatVisit: visit.isRepeatVisit,
      topAlias: cityCode,
    );
    final cloudUpdated = await _syncCoordinator.emitObservation(observation);
    final meshForwarded = await _syncCoordinator.forwardMeshUpdate(
      agentId: agentId,
      key: key,
      delta: computation.delta,
    );

    return LocalityUpdateReceipt(
      state: normalizedState,
      cloudUpdated: cloudUpdated,
      meshForwarded: meshForwarded,
    );
  }

  @override
  Future<LocalityUpdateReceipt> observe(LocalityObservation observation) async {
    final resolvedState = await _inferenceHead.resolveFromKey(
      agentId: observation.agentId,
      key: observation.key,
      topAlias: observation.topAlias,
    );
    final state = await _applyObservationState(
      observation: observation,
      resolvedState: resolvedState,
    );
    await _memory.saveSnapshot(agentId: observation.agentId, state: state);
    final cloudUpdated = await _syncCoordinator.emitObservation(observation);
    return LocalityUpdateReceipt(state: state, cloudUpdated: cloudUpdated);
  }

  @override
  Future<LocalitySyncResult> sync(LocalitySyncRequest request) {
    return _syncWithSnapshot(request);
  }

  @override
  LocalityProjection project(LocalityProjectionRequest request) {
    return _projectionService.project(request);
  }

  @override
  Future<LocalityPointResolution> resolvePoint(
      LocalityPointQuery request) async {
    final spatial = await _resolveSpatialContextBestEffort(
      lat: request.latitude,
      lon: request.longitude,
    );
    final topAlias =
        request.topAlias ?? spatial.displayName ?? spatial.cityCode;
    final state = await _inferenceHead.resolve(
      LocalityPerceptionInput(
        agentId: request.agentId ?? _systemAgentId,
        latitude: request.latitude,
        longitude: request.longitude,
        occurredAtUtc: request.occurredAtUtc,
        topAlias: topAlias,
        geometryHint: spatial.localityCode,
      ),
    );
    final normalizedState =
        topAlias == null ? state : state.copyWith(topAlias: topAlias);
    final projection = _projectionService.project(
      LocalityProjectionRequest(
        audience: request.audience,
        state: normalizedState,
        includeGeometry: request.includeGeometry,
        includeAttribution: request.includeAttribution,
        includePrediction: request.includePrediction,
      ),
    );
    return LocalityPointResolution(
      state: normalizedState,
      projection: projection,
      cityCode: spatial.cityCode,
      localityCode: spatial.localityCode,
      displayName: spatial.displayName ?? projection.primaryLabel,
    );
  }

  @override
  LocalityKernelSnapshot? snapshot(String agentId) {
    final state = _memory.getSnapshot(agentId);
    if (state == null) return null;
    return LocalityKernelSnapshot(
      agentId: agentId,
      state: state,
      savedAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<LocalityRecoveryResult> recover(
      LocalityRecoveryRequest request) async {
    final snapshotState = _memory.getSnapshot(request.agentId);
    if (snapshotState != null) {
      return LocalityRecoveryResult(
        state: snapshotState,
        recoveredFromSnapshot: true,
      );
    }
    return LocalityRecoveryResult(
      state: LocalityState.zero(),
      recoveredFromSnapshot: false,
    );
  }

  @override
  Future<bool> observeMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) {
    return _syncCoordinator.ingestMeshUpdate(
      key: key,
      delta12: delta12,
      ttlMs: ttlMs,
      hop: hop,
    );
  }

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroLocalityReadiness({
    required String cityProfile,
    String modelFamily = 'reality_model',
    int localityCount = 12,
  }) async {
    final artifact = await _trainingContract.loadBaselineArtifact(
      cityProfile: cityProfile,
      modelFamily: modelFamily,
    );
    final batch = await _trainingContract.buildBootstrapBatch(
      cityProfile: cityProfile,
      localityCount: localityCount,
    );
    return _trainingContract.evaluateZeroLocality(
      artifact: artifact,
      batch: batch,
    );
  }

  Future<({double lat, double lon})?> _resolveVisitCoordinates(
      Visit visit) async {
    final gf = visit.geofencingData;
    if (gf != null) {
      return (lat: gf.latitude, lon: gf.longitude);
    }

    try {
      final Spot? spot = await _spotsLocal.getSpotById(visit.locationId);
      final lat = spot?.latitude;
      final lon = spot?.longitude;
      if (lat != null && lon != null) return (lat: lat, lon: lon);
    } catch (_) {}

    return null;
  }

  Future<String?> _resolveCityCodeBestEffort({
    required double lat,
    required double lon,
  }) async {
    final spatial = await _resolveSpatialContextBestEffort(lat: lat, lon: lon);
    return spatial.cityCode;
  }

  Future<String?> _resolveInferredCityCodeBestEffort({
    required double lat,
    required double lon,
  }) async {
    try {
      return await _geoHierarchyService.lookupCityCodeByPoint(
        lat: lat,
        lon: lon,
      );
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

  Future<({String? cityCode, String? localityCode, String? displayName})>
      _resolveSpatialContextBestEffort({
    required double lat,
    required double lon,
  }) async {
    try {
      final locality = await _geoHierarchyService.lookupLocalityByPoint(
        lat: lat,
        lon: lon,
      );
      if (locality != null) {
        return (
          cityCode: locality.cityCode,
          localityCode: locality.localityCode,
          displayName: locality.displayName,
        );
      }
    } catch (_) {}

    final cityCode = await _resolveInferredCityCodeBestEffort(
      lat: lat,
      lon: lon,
    );
    return (
      cityCode: cityCode,
      localityCode: null,
      displayName: cityCode,
    );
  }

  Future<LocalitySyncResult> _syncWithSnapshot(
      LocalitySyncRequest request) async {
    final snapshotState = _memory.getSnapshot(request.agentId);
    if (snapshotState == null) {
      return _syncCoordinator.sync(request);
    }

    final key = _keyFromToken(snapshotState.activeToken);
    if (key == null) {
      return _syncCoordinator.sync(request);
    }

    final refreshed = await _inferenceHead.resolveFromKey(
      agentId: request.agentId,
      key: key,
      topAlias: snapshotState.topAlias,
      forcedTier: snapshotState.reliabilityTier,
      sourceMix: const LocalitySourceMix(
        local: 0.3,
        federated: 0.5,
        mesh: 0.2,
      ),
    );
    await _memory.saveSnapshot(agentId: request.agentId, state: refreshed);
    return _syncCoordinator.sync(request);
  }

  LocalityAgentKeyV1? _keyFromToken(LocalityToken token) {
    if (token.kind != LocalityTokenKind.geohashCell) return null;
    final parts = token.id.split(':');
    if (parts.length != 2) return null;
    final precisionText =
        parts.first.startsWith('gh') ? parts.first.substring(2) : '';
    final precision = int.tryParse(precisionText);
    if (precision == null) return null;
    return LocalityAgentKeyV1(
      geohashPrefix: parts[1],
      precision: precision,
      cityCode: token.alias,
    );
  }

  LocalityCandidateRecord _nextCandidateRecord({
    required String agentId,
    required LocalityToken token,
    required DateTime occurredAtUtc,
  }) {
    final existing = _memory.getCandidate(agentId: agentId, tokenId: token.id);
    if (existing == null) {
      return LocalityCandidateRecord(
        token: token,
        coherenceCount: 1,
        firstSeenUtc: occurredAtUtc,
        lastSeenUtc: occurredAtUtc,
      );
    }
    final age = occurredAtUtc.difference(existing.lastSeenUtc);
    if (age > _candidateDecayWindow) {
      return LocalityCandidateRecord(
        token: token,
        coherenceCount: 1,
        firstSeenUtc: occurredAtUtc,
        lastSeenUtc: occurredAtUtc,
      );
    }
    return LocalityCandidateRecord(
      token: token,
      coherenceCount: existing.coherenceCount + 1,
      firstSeenUtc: existing.firstSeenUtc,
      lastSeenUtc: occurredAtUtc,
    );
  }

  LocalityState _normalizeCandidateState({
    required LocalityState state,
    required LocalityCandidateRecord candidate,
  }) {
    if (state.reliabilityTier == LocalityReliabilityTier.advisory) {
      return state.copyWith(
        evidenceCount: candidate.coherenceCount,
      );
    }
    if (candidate.coherenceCount >= 8) {
      return state.copyWith(
        reliabilityTier: LocalityReliabilityTier.established,
        confidence: state.confidence < 0.55 ? 0.55 : state.confidence,
        evidenceCount: candidate.coherenceCount,
      );
    }
    return state.copyWith(
      reliabilityTier: LocalityReliabilityTier.candidate,
      evidenceCount: candidate.coherenceCount,
    );
  }

  Future<LocalityState> _applyObservationState({
    required LocalityObservation observation,
    required LocalityState resolvedState,
  }) async {
    final freshness = observation.occurredAtUtc.isAfter(resolvedState.freshness)
        ? observation.occurredAtUtc
        : resolvedState.freshness;

    switch (observation.type) {
      case LocalityObservationType.visitComplete:
      case LocalityObservationType.organicDiscoverySignal:
        final candidate = _nextCandidateRecord(
          agentId: observation.agentId,
          token: resolvedState.activeToken,
          occurredAtUtc: observation.occurredAtUtc,
        );
        await _memory.saveCandidate(
          agentId: observation.agentId,
          record: candidate,
        );
        return _normalizeCandidateState(
          state: resolvedState.copyWith(
            freshness: freshness,
            sourceMix: _blendObservationSourceMix(
              current: resolvedState.sourceMix,
              overlay: const LocalitySourceMix(
                local: 0.65,
                mesh: 0.1,
                federated: 0.15,
                geometry: 0.05,
                syntheticPrior: 0.05,
              ),
            ),
          ),
          candidate: candidate,
        );
      case LocalityObservationType.meshLocalityUpdate:
        return resolvedState.copyWith(
          freshness: freshness,
          confidence:
              resolvedState.confidence < 0.42 ? 0.42 : resolvedState.confidence,
          reliabilityTier: resolvedState.reliabilityTier ==
                  LocalityReliabilityTier.zeroLocality
              ? LocalityReliabilityTier.candidate
              : resolvedState.reliabilityTier,
          sourceMix: _blendObservationSourceMix(
            current: resolvedState.sourceMix,
            overlay: const LocalitySourceMix(
              local: 0.1,
              mesh: 0.7,
              federated: 0.1,
              geometry: 0.05,
              syntheticPrior: 0.05,
            ),
          ),
        );
      case LocalityObservationType.federatedPriorUpdate:
        return resolvedState.copyWith(
          freshness: freshness,
          confidence:
              resolvedState.confidence < 0.5 ? 0.5 : resolvedState.confidence,
          reliabilityTier: resolvedState.reliabilityTier ==
                  LocalityReliabilityTier.zeroLocality
              ? LocalityReliabilityTier.bootstrap
              : resolvedState.reliabilityTier,
          sourceMix: _blendObservationSourceMix(
            current: resolvedState.sourceMix,
            overlay: const LocalitySourceMix(
              local: 0.1,
              mesh: 0.1,
              federated: 0.65,
              geometry: 0.1,
              syntheticPrior: 0.05,
            ),
          ),
        );
      case LocalityObservationType.happinessSignal:
      case LocalityObservationType.advisoryResult:
        return _applyAdvisoryObservationState(
          observation: observation,
          state: resolvedState.copyWith(freshness: freshness),
        );
      case LocalityObservationType.onboardingSeed:
        return resolvedState.copyWith(
          freshness: freshness,
          reliabilityTier: LocalityReliabilityTier.bootstrap,
          sourceMix: _blendObservationSourceMix(
            current: resolvedState.sourceMix,
            overlay: const LocalitySourceMix(
              local: 0.1,
              mesh: 0.0,
              federated: 0.45,
              geometry: 0.2,
              syntheticPrior: 0.25,
            ),
          ),
        );
    }
  }

  LocalityState _applyAdvisoryObservationState({
    required LocalityObservation observation,
    required LocalityState state,
  }) {
    final qualityScore = observation.qualityScore;
    if (qualityScore == null) {
      return state.copyWith(
        sourceMix: _blendObservationSourceMix(
          current: state.sourceMix,
          overlay: const LocalitySourceMix(
            local: 0.4,
            mesh: 0.1,
            federated: 0.4,
            geometry: 0.0,
            syntheticPrior: 0.1,
          ),
        ),
      );
    }

    if (qualityScore < 0.45) {
      return state.copyWith(
        reliabilityTier: LocalityReliabilityTier.advisory,
        advisoryStatus: LocalityAdvisoryStatus.active,
        confidence: state.confidence < 0.55 ? 0.55 : state.confidence,
        evolutionRate: (state.evolutionRate + 0.12).clamp(0.0, 1.0),
        sourceMix: _blendObservationSourceMix(
          current: state.sourceMix,
          overlay: const LocalitySourceMix(
            local: 0.2,
            mesh: 0.15,
            federated: 0.45,
            geometry: 0.05,
            syntheticPrior: 0.15,
          ),
        ),
      );
    }

    if (state.advisoryStatus == LocalityAdvisoryStatus.active &&
        qualityScore >= 0.7) {
      return state.copyWith(
        reliabilityTier: state.evidenceCount >= 8
            ? LocalityReliabilityTier.established
            : LocalityReliabilityTier.candidate,
        advisoryStatus: LocalityAdvisoryStatus.coolingDown,
        evolutionRate: (state.evolutionRate - 0.08).clamp(0.0, 1.0),
      );
    }

    return state.copyWith(
      advisoryStatus: qualityScore >= 0.6
          ? LocalityAdvisoryStatus.coolingDown
          : LocalityAdvisoryStatus.eligible,
      sourceMix: _blendObservationSourceMix(
        current: state.sourceMix,
        overlay: const LocalitySourceMix(
          local: 0.35,
          mesh: 0.1,
          federated: 0.35,
          geometry: 0.05,
          syntheticPrior: 0.15,
        ),
      ),
    );
  }

  LocalitySourceMix _blendObservationSourceMix({
    required LocalitySourceMix current,
    required LocalitySourceMix overlay,
  }) {
    final local = ((current.local + overlay.local) / 2).clamp(0.0, 1.0);
    final mesh = ((current.mesh + overlay.mesh) / 2).clamp(0.0, 1.0);
    final federated =
        ((current.federated + overlay.federated) / 2).clamp(0.0, 1.0);
    final geometry =
        ((current.geometry + overlay.geometry) / 2).clamp(0.0, 1.0);
    final syntheticPrior =
        ((current.syntheticPrior + overlay.syntheticPrior) / 2).clamp(0.0, 1.0);
    final total = local + mesh + federated + geometry + syntheticPrior;
    if (total <= 0) {
      return const LocalitySourceMix.syntheticBootstrap();
    }
    return LocalitySourceMix(
      local: local / total,
      mesh: mesh / total,
      federated: federated / total,
      geometry: geometry / total,
      syntheticPrior: syntheticPrior / total,
    );
  }
}

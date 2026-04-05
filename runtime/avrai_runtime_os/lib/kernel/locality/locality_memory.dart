import 'dart:developer' as developer;

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_runtime_policy.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_signal.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:reality_engine/reality_engine.dart';

class LocalityMemory {
  static const String _box = 'spots_ai';
  static const String _logName = 'LocalityMemory';

  final StorageService _storage;
  final Map<String, LocalityState> _snapshotCache = <String, LocalityState>{};
  final Map<String, LocalityCandidateRecord> _candidateCache =
      <String, LocalityCandidateRecord>{};
  final Map<String, LocalityAgentPersonalDeltaV1> _personalDeltaCache =
      <String, LocalityAgentPersonalDeltaV1>{};
  final Map<String, LocalityAgentGlobalStateV1> _globalStateCache =
      <String, LocalityAgentGlobalStateV1>{};
  final Map<String, _LocalityMeshUpdateRecord> _meshUpdateCache =
      <String, _LocalityMeshUpdateRecord>{};

  LocalityMemory({required StorageService storage}) : _storage = storage;

  String _snapshotKey(String agentId) => 'locality_kernel_snapshot_v1:$agentId';
  String _candidateKey(String agentId, String tokenId) =>
      'locality_kernel_candidate_v1:$agentId:$tokenId';
  String _personalDeltaKey(String agentId, LocalityAgentKeyV1 key) =>
      'locality_kernel_delta_v1:$agentId:${key.stableKey}';
  String _globalStateKey(LocalityAgentKeyV1 key) =>
      'locality_kernel_global_v1:${key.stableKey}';
  String _meshUpdateKey(LocalityAgentKeyV1 key) =>
      'locality_kernel_mesh_v1:${key.stableKey}';

  Future<void> saveSnapshot({
    required String agentId,
    required LocalityState state,
  }) async {
    _snapshotCache[_snapshotKey(agentId)] = state;
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storage.setObject(
      _snapshotKey(agentId),
      state.toJson(),
      box: _box,
    );
  }

  LocalityState? getSnapshot(String agentId) {
    final cached = _snapshotCache[_snapshotKey(agentId)];
    if (cached != null) {
      return cached;
    }
    final raw = _storage.getObject<Map<String, dynamic>>(
      _snapshotKey(agentId),
      box: _box,
    );
    if (raw == null) return null;
    return LocalityState.fromJson(raw);
  }

  Future<void> saveCandidate({
    required String agentId,
    required LocalityCandidateRecord record,
  }) async {
    _candidateCache[_candidateKey(agentId, record.token.id)] = record;
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storage.setObject(
      _candidateKey(agentId, record.token.id),
      record.toJson(),
      box: _box,
    );
  }

  LocalityCandidateRecord? getCandidate({
    required String agentId,
    required String tokenId,
  }) {
    final cached = _candidateCache[_candidateKey(agentId, tokenId)];
    if (cached != null) {
      return cached;
    }
    final raw = _storage.getObject<Map<String, dynamic>>(
      _candidateKey(agentId, tokenId),
      box: _box,
    );
    if (raw == null) return null;
    return LocalityCandidateRecord.fromJson(raw);
  }

  Future<void> savePersonalDelta({
    required String agentId,
    required LocalityAgentPersonalDeltaV1 delta,
  }) async {
    _personalDeltaCache[_personalDeltaKey(agentId, delta.key)] = delta;
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storage.setObject(
      _personalDeltaKey(agentId, delta.key),
      delta.toJson(),
      box: _box,
    );
  }

  LocalityAgentPersonalDeltaV1 getPersonalDelta({
    required String agentId,
    required LocalityAgentKeyV1 key,
  }) {
    final cacheKey = _personalDeltaKey(agentId, key);
    final cached = _personalDeltaCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final raw = _storage.getObject<Map<String, dynamic>>(
      cacheKey,
      box: _box,
    );
    if (raw == null) return LocalityAgentPersonalDeltaV1.empty(key);
    return LocalityAgentPersonalDeltaV1.fromJson(raw);
  }

  Future<void> saveGlobalState({
    required LocalityAgentGlobalStateV1 state,
  }) async {
    _globalStateCache[_globalStateKey(state.key)] = state;
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storage.setObject(
      _globalStateKey(state.key),
      state.toJson(),
      box: _box,
    );
  }

  LocalityAgentGlobalStateV1? getGlobalState(LocalityAgentKeyV1 key) {
    final cacheKey = _globalStateKey(key);
    final cached = _globalStateCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final raw = _storage.getObject<Map<String, dynamic>>(
      cacheKey,
      box: _box,
    );
    if (raw == null) return null;
    return LocalityAgentGlobalStateV1.fromJson(raw);
  }

  Future<void> saveMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required DateTime receivedAt,
    required Duration ttl,
    DateTime? originOccurredAtUtc,
    DateTime? localStateCapturedAtUtc,
    DateTime? exchangeCreatedAtUtc,
    String? kernelExchangePhase,
  }) async {
    final record = _LocalityMeshUpdateRecord(
      key: key,
      delta12: delta12,
      receivedAt: receivedAt,
      expiresAt: receivedAt.add(ttl),
      originOccurredAtUtc: originOccurredAtUtc,
      localStateCapturedAtUtc: localStateCapturedAtUtc,
      exchangeCreatedAtUtc: exchangeCreatedAtUtc,
      kernelExchangePhase: kernelExchangePhase,
    );
    _meshUpdateCache[_meshUpdateKey(key)] = record;
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storage.setObject(
      _meshUpdateKey(key),
      record.toJson(),
      box: _box,
    );
  }

  List<List<double>> getNeighborMeshUpdates(LocalityAgentKeyV1 key) {
    final updates = <List<double>>[];
    final now = DateTime.now();
    for (final geohash
        in GeohashService.neighbors(geohash: key.geohashPrefix)) {
      final neighborKey = LocalityAgentKeyV1(
        geohashPrefix: geohash,
        precision: key.precision,
        cityCode: key.cityCode,
      );
      try {
        final cachedRecord = _meshUpdateCache[_meshUpdateKey(neighborKey)];
        final raw = cachedRecord == null
            ? _storage.getObject<Map<String, dynamic>>(
                _meshUpdateKey(neighborKey),
                box: _box,
              )
            : null;
        if (cachedRecord == null && raw == null) continue;
        final record = cachedRecord ?? _LocalityMeshUpdateRecord.fromJson(raw!);
        if (record.expiresAt.isAfter(now)) {
          updates.add(record.delta12);
        }
      } catch (e, st) {
        developer.log(
          'Failed reading mesh update for ${neighborKey.stableKey}: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
    return updates;
  }

  LocalityAgentGlobalStateV1? getCanonicalGlobalState(LocalityAgentKeyV1 key) {
    final subjectRef = VibeSubjectRef.locality(key.stableKey);
    try {
      final snapshot = VibeKernel().getSnapshot(subjectRef);
      if (!hasCanonicalVibeSignal(snapshot)) {
        return null;
      }
      return LocalityAgentGlobalStateV1(
        key: key,
        vector12: _vectorFromSnapshot(snapshot),
        sampleCount: snapshot.behaviorPatterns.observationCount,
        confidence12: List<double>.filled(
          VibeConstants.coreDimensions.length,
          snapshot.confidence,
        ),
        aggregateHappiness: snapshot.affectiveState.valence,
        happinessSampleCount: snapshot.behaviorPatterns.observationCount,
        happinessTrendSlope: snapshot.stringEvolution.mutationVelocity,
        updatedAtUtc: snapshot.updatedAtUtc,
      );
    } catch (_) {
      return null;
    }
  }

  List<double> _vectorFromSnapshot(VibeStateSnapshot snapshot) {
    return VibeConstants.coreDimensions
        .map(
          (dimension) => (snapshot.coreDna.dimensions[dimension] ??
                  snapshot.pheromones.vectors[dimension] ??
                  0.5)
              .clamp(0.0, 1.0),
        )
        .toList(growable: false);
  }
}

class _LocalityMeshUpdateRecord {
  final LocalityAgentKeyV1 key;
  final List<double> delta12;
  final DateTime receivedAt;
  final DateTime expiresAt;
  final DateTime? originOccurredAtUtc;
  final DateTime? localStateCapturedAtUtc;
  final DateTime? exchangeCreatedAtUtc;
  final String? kernelExchangePhase;

  const _LocalityMeshUpdateRecord({
    required this.key,
    required this.delta12,
    required this.receivedAt,
    required this.expiresAt,
    this.originOccurredAtUtc,
    this.localStateCapturedAtUtc,
    this.exchangeCreatedAtUtc,
    this.kernelExchangePhase,
  });

  Map<String, dynamic> toJson() => {
        'key': key.toJson(),
        'delta12': delta12,
        'receivedAt': receivedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'originOccurredAtUtc': originOccurredAtUtc?.toIso8601String(),
        'localStateCapturedAtUtc': localStateCapturedAtUtc?.toIso8601String(),
        'exchangeCreatedAtUtc': exchangeCreatedAtUtc?.toIso8601String(),
        'kernelExchangePhase': kernelExchangePhase,
      };

  factory _LocalityMeshUpdateRecord.fromJson(Map<String, dynamic> json) {
    final delta = (json['delta12'] as List?)
            ?.map((entry) => (entry as num).toDouble())
            .toList() ??
        List<double>.filled(12, 0.0);
    return _LocalityMeshUpdateRecord(
      key: LocalityAgentKeyV1.fromJson(
        Map<String, dynamic>.from(json['key'] as Map? ?? const {}),
      ),
      delta12: delta.length == 12 ? delta : List<double>.filled(12, 0.0),
      receivedAt: DateTime.tryParse((json['receivedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      originOccurredAtUtc:
          DateTime.tryParse((json['originOccurredAtUtc'] ?? '').toString()),
      localStateCapturedAtUtc:
          DateTime.tryParse((json['localStateCapturedAtUtc'] ?? '').toString()),
      exchangeCreatedAtUtc:
          DateTime.tryParse((json['exchangeCreatedAtUtc'] ?? '').toString()),
      kernelExchangePhase: (json['kernelExchangePhase'] as String?)?.trim(),
    );
  }
}

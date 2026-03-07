import 'dart:developer' as developer;

import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class LocalityMemory {
  static const String _box = 'spots_ai';
  static const String _logName = 'LocalityMemory';

  final StorageService _storage;

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
    await _storage.setObject(
      _snapshotKey(agentId),
      state.toJson(),
      box: _box,
    );
  }

  LocalityState? getSnapshot(String agentId) {
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
    final raw = _storage.getObject<Map<String, dynamic>>(
      _personalDeltaKey(agentId, key),
      box: _box,
    );
    if (raw == null) return LocalityAgentPersonalDeltaV1.empty(key);
    return LocalityAgentPersonalDeltaV1.fromJson(raw);
  }

  Future<void> saveGlobalState({
    required LocalityAgentGlobalStateV1 state,
  }) async {
    await _storage.setObject(
      _globalStateKey(state.key),
      state.toJson(),
      box: _box,
    );
  }

  LocalityAgentGlobalStateV1? getGlobalState(LocalityAgentKeyV1 key) {
    final raw = _storage.getObject<Map<String, dynamic>>(
      _globalStateKey(key),
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
  }) async {
    final record = _LocalityMeshUpdateRecord(
      key: key,
      delta12: delta12,
      receivedAt: receivedAt,
      expiresAt: receivedAt.add(ttl),
    );
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
        final raw = _storage.getObject<Map<String, dynamic>>(
          _meshUpdateKey(neighborKey),
          box: _box,
        );
        if (raw == null) continue;
        final record = _LocalityMeshUpdateRecord.fromJson(raw);
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
}

class _LocalityMeshUpdateRecord {
  final LocalityAgentKeyV1 key;
  final List<double> delta12;
  final DateTime receivedAt;
  final DateTime expiresAt;

  const _LocalityMeshUpdateRecord({
    required this.key,
    required this.delta12,
    required this.receivedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
        'key': key.toJson(),
        'delta12': delta12,
        'receivedAt': receivedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
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
    );
  }
}

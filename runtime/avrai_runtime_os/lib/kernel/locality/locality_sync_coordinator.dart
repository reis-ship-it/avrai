import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_global_repository.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_update_emitter_v1.dart';

class LocalitySyncCoordinator {
  static const String _logName = 'LocalitySyncCoordinator';

  final LocalityAgentUpdateEmitterV1 _emitter;
  final LocalityAgentGlobalRepositoryV1 _globalRepository;
  final LocalityMemory _memory;

  LocalitySyncCoordinator({
    required LocalityAgentUpdateEmitterV1 emitter,
    required LocalityAgentGlobalRepositoryV1 globalRepository,
    required LocalityMemory memory,
  })  : _emitter = emitter,
        _globalRepository = globalRepository,
        _memory = memory;

  Future<LocalityAgentGlobalStateV1> getGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    final cached = _memory.getGlobalState(key);
    try {
      final remote = await _globalRepository.getGlobalState(key);
      final shouldUseCached =
          remote.sampleCount == 0 && cached != null && cached.sampleCount > 0;
      final resolved = shouldUseCached ? cached : remote;
      await _memory.saveGlobalState(state: resolved);
      return resolved;
    } catch (e, st) {
      developer.log(
        'Failed to refresh global locality state: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return cached ?? LocalityAgentGlobalStateV1.empty(key);
    }
  }

  List<List<double>> getNeighborMeshUpdates(LocalityAgentKeyV1 key) {
    return _memory.getNeighborMeshUpdates(key);
  }

  Future<bool> emitObservation(LocalityObservation observation) async {
    try {
      await _emitter.emit(
        userId: observation.userId,
        event: observation.toUpdateEvent(),
      );
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to emit locality observation: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> forwardMeshUpdate({
    required String agentId,
    required LocalityAgentKeyV1 key,
    required LocalityAgentPersonalDeltaV1 delta,
  }) async {
    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<VibeConnectionOrchestrator>()) {
        return false;
      }

      final orchestrator = sl<VibeConnectionOrchestrator>();
      final scope = _scopeFromPrecision(key.precision);
      await orchestrator.forwardLocalityAgentUpdate({
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
        'ttl_ms': 6 * 60 * 60 * 1000,
      });
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to forward locality mesh update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> ingestMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    try {
      await _memory.saveMeshUpdate(
        key: key,
        delta12: delta12,
        receivedAt: DateTime.now(),
        ttl: Duration(milliseconds: ttlMs),
      );
      developer.log(
        'Imported mesh locality update for ${key.stableKey} (hop=$hop)',
        name: _logName,
      );
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to import mesh locality update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<LocalitySyncResult> sync(LocalitySyncRequest request) async {
    return LocalitySyncResult(
      synced: request.allowCloud || request.allowMesh,
      message: 'Locality sync coordinator is active for ${request.agentId}',
    );
  }

  String _scopeFromPrecision(int precision) {
    if (precision >= 7) return 'locality';
    if (precision >= 6) return 'city';
    if (precision >= 5) return 'region';
    if (precision >= 4) return 'country';
    return 'global';
  }
}

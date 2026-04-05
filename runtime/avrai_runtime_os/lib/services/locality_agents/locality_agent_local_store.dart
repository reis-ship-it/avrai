import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Local (device) persistence for LocalityAgent per-user deltas (v1).
///
/// Stored on-device only, keyed by privacy-preserving `agentId` and stable geohash key.
class LocalityAgentLocalStoreV1 {
  static const String _logName = 'LocalityAgentLocalStoreV1';
  static const String _box = 'spots_ai';

  final StorageService _storage;

  LocalityAgentLocalStoreV1({required StorageService storage})
      : _storage = storage;

  String _deltaKey({
    required String agentId,
    required LocalityAgentKeyV1 key,
  }) =>
      'locality_agent_delta_v1:$agentId:${key.stableKey}';

  Future<LocalityAgentPersonalDeltaV1> getDelta({
    required String agentId,
    required LocalityAgentKeyV1 key,
  }) async {
    try {
      final raw = _storage.getObject<Map<String, dynamic>>(
        _deltaKey(agentId: agentId, key: key),
        box: _box,
      );
      if (raw == null) return LocalityAgentPersonalDeltaV1.empty(key);
      return LocalityAgentPersonalDeltaV1.fromJson(raw);
    } catch (e, st) {
      developer.log('Failed reading locality delta: $e',
          name: _logName, error: e, stackTrace: st);
      return LocalityAgentPersonalDeltaV1.empty(key);
    }
  }

  Future<void> saveDelta({
    required String agentId,
    required LocalityAgentPersonalDeltaV1 delta,
  }) async {
    try {
      await _storage.setObject(
        _deltaKey(agentId: agentId, key: delta.key),
        delta.toJson(),
        box: _box,
      );
    } catch (e, st) {
      developer.log('Failed saving locality delta: $e',
          name: _logName, error: e, stackTrace: st);
      rethrow;
    }
  }
}

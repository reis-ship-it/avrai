import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class LocalityMemory {
  static const String _box = 'spots_ai';

  final StorageService _storage;

  LocalityMemory({required StorageService storage}) : _storage = storage;

  String _snapshotKey(String agentId) => 'locality_kernel_snapshot_v1:$agentId';
  String _candidateKey(String agentId, String tokenId) =>
      'locality_kernel_candidate_v1:$agentId:$tokenId';

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
}

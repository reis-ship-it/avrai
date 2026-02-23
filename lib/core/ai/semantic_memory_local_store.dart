import 'package:avrai/core/ai/semantic_memory_schema.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/interfaces/storage_service_interface.dart';

/// Storage key prefix for semantic memory entries per agent.
const String _kSemanticMemoryPrefix = 'semantic_memory_entries:';

/// Key for pending semantic sync queue (list of agent IDs).
const String _kSemanticPendingSyncKey = 'semantic_memory_pending_sync';

/// AI box for semantic memory storage.
const String _kSemanticMemoryBox = 'spots_ai';

/// Local-first store for semantic memory entries.
///
/// Stores per-agent semantic entries and supports a pending sync queue.
class SemanticMemoryLocalStore {
  SemanticMemoryLocalStore({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final IStorageService _storage;

  String _key(String agentId) => '$_kSemanticMemoryPrefix$agentId';

  /// Reads all semantic entries for [agentId].
  Future<List<SemanticMemoryEntry>> getAll(String agentId) async {
    try {
      final raw =
          _storage.getObject<dynamic>(_key(agentId), box: _kSemanticMemoryBox);
      if (raw == null) return const [];
      final list = raw is List ? raw : const [];
      return list
          .whereType<Map>()
          .map(
              (m) => SemanticMemoryEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Upserts a semantic [entry] for [agentId] by entry id.
  Future<void> upsert(String agentId, SemanticMemoryEntry entry) async {
    final current = await getAll(agentId);
    final updated = <SemanticMemoryEntry>[];
    var replaced = false;
    for (final existing in current) {
      if (existing.id == entry.id) {
        updated.add(entry);
        replaced = true;
      } else {
        updated.add(existing);
      }
    }
    if (!replaced) {
      updated.add(entry);
    }
    await _storage.setObject(
      _key(agentId),
      updated.map((e) => e.toJson()).toList(growable: false),
      box: _kSemanticMemoryBox,
    );
  }

  /// Removes all semantic entries for [agentId].
  Future<void> remove(String agentId) async {
    await _storage.remove(_key(agentId), box: _kSemanticMemoryBox);
  }

  /// Adds [agentId] to pending semantic sync queue.
  Future<void> addPending(String agentId) async {
    final list = List<String>.from(
      _storage.getStringList(_kSemanticPendingSyncKey,
              box: _kSemanticMemoryBox) ??
          [],
    );
    if (list.contains(agentId)) return;
    list.add(agentId);
    await _storage.setStringList(
      _kSemanticPendingSyncKey,
      list,
      box: _kSemanticMemoryBox,
    );
  }

  /// Returns agent IDs in pending semantic sync queue.
  List<String> getPending() {
    return List<String>.from(
      _storage.getStringList(_kSemanticPendingSyncKey,
              box: _kSemanticMemoryBox) ??
          [],
    );
  }

  /// Removes [agentId] from pending semantic sync queue.
  Future<void> removePending(String agentId) async {
    final list = getPending();
    list.remove(agentId);
    await _storage.setStringList(
      _kSemanticPendingSyncKey,
      list,
      box: _kSemanticMemoryBox,
    );
  }
}

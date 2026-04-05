import 'package:avrai_runtime_os/ai/structured_facts.dart';
import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Storage key prefix for structured facts per agent.
const String _kFactsPrefix = 'structured_facts:';

/// Key for pending sync queue (list of agent IDs).
const String _kPendingSyncKey = 'structured_facts_pending_sync';

/// AI box for facts storage.
const String _kFactsBox = 'spots_ai';

/// Local-first store for [StructuredFacts].
///
/// Persists facts keyed by agentId. Supports a pending-sync queue for
/// offline-first sync to Supabase when online.
///
/// RAG AI2AI + Federated + Offline-First (Phase 1).
class FactsLocalStore {
  FactsLocalStore({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final IStorageService _storage;

  String _key(String agentId) => '$_kFactsPrefix$agentId';

  /// Reads facts for [agentId]. Returns null if not found.
  Future<StructuredFacts?> get(String agentId) async {
    try {
      final raw = _storage.getObject<dynamic>(_key(agentId), box: _kFactsBox);
      if (raw == null) return null;
      final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (map == null) return null;
      return _fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Upserts facts for [agentId]. Overwrites existing; caller handles merge.
  Future<void> upsert(String agentId, StructuredFacts facts) async {
    final map = _toMap(facts);
    await _storage.setObject(_key(agentId), map, box: _kFactsBox);
  }

  /// Removes facts for [agentId].
  Future<void> remove(String agentId) async {
    await _storage.remove(_key(agentId), box: _kFactsBox);
  }

  /// Adds [agentId] to the pending-sync queue.
  Future<void> addPending(String agentId) async {
    final list = List<String>.from(
      _storage.getStringList(_kPendingSyncKey, box: _kFactsBox) ?? [],
    );
    if (list.contains(agentId)) return;
    list.add(agentId);
    await _storage.setStringList(_kPendingSyncKey, list, box: _kFactsBox);
  }

  /// Returns agent IDs in the pending-sync queue.
  List<String> getPending() {
    return List<String>.from(
      _storage.getStringList(_kPendingSyncKey, box: _kFactsBox) ?? [],
    );
  }

  /// Removes [agentId] from the pending-sync queue.
  Future<void> removePending(String agentId) async {
    final list = getPending();
    list.remove(agentId);
    await _storage.setStringList(_kPendingSyncKey, list, box: _kFactsBox);
  }

  /// Removes all pending entries.
  Future<void> clearPending() async {
    await _storage.remove(_kPendingSyncKey, box: _kFactsBox);
  }

  static Map<String, dynamic> _toMap(StructuredFacts f) {
    return {
      'traits': f.traits,
      'places': f.places,
      'social_graph': f.socialGraph,
      'timestamp': f.timestamp.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static StructuredFacts _fromMap(Map<String, dynamic> map) {
    return StructuredFacts(
      traits: List<String>.from(map['traits'] ?? []),
      places: List<String>.from(map['places'] ?? []),
      socialGraph: List<String>.from(map['social_graph'] ?? []),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

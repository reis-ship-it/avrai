import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/interfaces/storage_service_interface.dart';

const String _kProceduralRulesPrefix = 'procedural_rules:';
const String _kProceduralPendingSyncKey = 'procedural_rules_pending_sync';
const String _kProceduralMemoryBox = 'spots_ai';

/// Local-first store for procedural rules.
class ProceduralRuleLocalStore {
  ProceduralRuleLocalStore({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final IStorageService _storage;

  String _key(String agentId) => '$_kProceduralRulesPrefix$agentId';

  Future<List<ProceduralRule>> getAll(String agentId) async {
    try {
      final raw = _storage.getObject<dynamic>(_key(agentId),
          box: _kProceduralMemoryBox);
      if (raw == null) return const [];
      final list = raw is List ? raw : const [];
      return list
          .whereType<Map>()
          .map((m) => ProceduralRule.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(String agentId, ProceduralRule rule) async {
    final current = await getAll(agentId);
    final updated = <ProceduralRule>[];
    var replaced = false;
    for (final existing in current) {
      if (existing.id == rule.id) {
        updated.add(rule);
        replaced = true;
      } else {
        updated.add(existing);
      }
    }
    if (!replaced) {
      updated.add(rule);
    }
    await _storage.setObject(
      _key(agentId),
      updated.map((e) => e.toJson()).toList(growable: false),
      box: _kProceduralMemoryBox,
    );
  }

  Future<void> remove(String agentId) async {
    await _storage.remove(_key(agentId), box: _kProceduralMemoryBox);
  }

  Future<void> addPending(String agentId) async {
    final list = List<String>.from(
      _storage.getStringList(_kProceduralPendingSyncKey,
              box: _kProceduralMemoryBox) ??
          [],
    );
    if (list.contains(agentId)) return;
    list.add(agentId);
    await _storage.setStringList(
      _kProceduralPendingSyncKey,
      list,
      box: _kProceduralMemoryBox,
    );
  }

  List<String> getPending() {
    return List<String>.from(
      _storage.getStringList(_kProceduralPendingSyncKey,
              box: _kProceduralMemoryBox) ??
          [],
    );
  }

  Future<void> removePending(String agentId) async {
    final list = getPending();
    list.remove(agentId);
    await _storage.setStringList(
      _kProceduralPendingSyncKey,
      list,
      box: _kProceduralMemoryBox,
    );
  }
}

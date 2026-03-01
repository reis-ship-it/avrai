import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Per-user conversation preferences (RAG vs bypass, verbosity) for larger learning models.
///
/// Plan: RAG wiring + RAG-as-answer — Conversation preferences (Phase 6).
class ConversationPreferences {
  final double bypassRate;
  final int totalRagTurns;
  final int totalBypassTurns;
  final DateTime lastUpdated;

  const ConversationPreferences({
    this.bypassRate = 0.0,
    this.totalRagTurns = 0,
    this.totalBypassTurns = 0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'bypassRate': bypassRate,
        'totalRagTurns': totalRagTurns,
        'totalBypassTurns': totalBypassTurns,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ConversationPreferences.fromJson(Map<String, dynamic> json) {
    final lu = json['lastUpdated'];
    final dt = lu is String ? DateTime.tryParse(lu) : null;
    return ConversationPreferences(
      bypassRate: (json['bypassRate'] as num?)?.toDouble() ?? 0.0,
      totalRagTurns: json['totalRagTurns'] as int? ?? 0,
      totalBypassTurns: json['totalBypassTurns'] as int? ?? 0,
      lastUpdated: dt ?? DateTime.now(),
    );
  }

  ConversationPreferences copyWith({
    double? bypassRate,
    int? totalRagTurns,
    int? totalBypassTurns,
    DateTime? lastUpdated,
  }) =>
      ConversationPreferences(
        bypassRate: bypassRate ?? this.bypassRate,
        totalRagTurns: totalRagTurns ?? this.totalRagTurns,
        totalBypassTurns: totalBypassTurns ?? this.totalBypassTurns,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

const String _kPrefix = 'conversation_prefs_';
const String _kBox = 'spots_ai';

/// Store for [ConversationPreferences] per user (agentId). Persisted in spots_ai.
class ConversationPreferenceStore {
  ConversationPreferenceStore({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  static const String _logName = 'ConversationPreferenceStore';
  final IStorageService _storage;

  String _key(String agentId) => '$_kPrefix$agentId';

  Future<ConversationPreferences?> get(String agentId) async {
    try {
      final raw = _storage.getObject<dynamic>(_key(agentId), box: _kBox);
      if (raw == null || raw is! Map) return null;
      return ConversationPreferences.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } catch (e) {
      developer.log('ConversationPreferenceStore.get failed: $e',
          name: _logName);
      return null;
    }
  }

  Future<void> save(String agentId, ConversationPreferences prefs) async {
    try {
      await _storage.setObject(
        _key(agentId),
        prefs.toJson(),
        box: _kBox,
      );
    } catch (e) {
      developer.log('ConversationPreferenceStore.save failed: $e',
          name: _logName);
    }
  }

  /// Updates prefs from a single RAG or bypass turn. Call after recording feedback.
  Future<void> updateFromTurn(String agentId,
      {required bool usedBypass}) async {
    try {
      final current = await get(agentId) ??
          ConversationPreferences(lastUpdated: DateTime.now());
      final newRag =
          usedBypass ? current.totalRagTurns : current.totalRagTurns + 1;
      final newBypass =
          usedBypass ? current.totalBypassTurns + 1 : current.totalBypassTurns;
      final total = newRag + newBypass;
      final rate = total > 0 ? newBypass / total : 0.0;
      await save(
        agentId,
        current.copyWith(
          bypassRate: rate,
          totalRagTurns: newRag,
          totalBypassTurns: newBypass,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      developer.log('ConversationPreferenceStore.updateFromTurn failed: $e',
          name: _logName);
    }
  }
}

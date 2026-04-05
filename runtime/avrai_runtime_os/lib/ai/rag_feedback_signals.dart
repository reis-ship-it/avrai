import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Privacy-safe RAG feedback signal for local learning and optional federated sync.
/// No raw user content.
///
/// RAG Phase 6: RAG→federation feedback.
/// Plan: RAG wiring + RAG-as-answer — usedBypass added for bypass-path recording.
class RAGFeedbackSignal {
  final String turnId;
  final String userId;
  final List<String> retrievedFactGroups;
  final bool networkCuesUsed;
  final bool searchUsed;
  final bool? engaged;
  final DateTime timestamp;
  final bool usedBypass;

  const RAGFeedbackSignal({
    required this.turnId,
    required this.userId,
    required this.retrievedFactGroups,
    required this.networkCuesUsed,
    required this.searchUsed,
    this.engaged,
    required this.timestamp,
    this.usedBypass = false,
  });

  Map<String, dynamic> toJson() => {
        'turnId': turnId,
        'userId': userId,
        'retrievedFactGroups': retrievedFactGroups,
        'networkCuesUsed': networkCuesUsed,
        'searchUsed': searchUsed,
        'engaged': engaged,
        'timestamp': timestamp.toIso8601String(),
        if (usedBypass) 'usedBypass': usedBypass,
      };

  /// Deserializes from stored JSON. [usedBypass] defaults to false if missing.
  factory RAGFeedbackSignal.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'];
    final dt = ts is String ? DateTime.tryParse(ts) : null;
    return RAGFeedbackSignal(
      turnId: json['turnId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      retrievedFactGroups: (json['retrievedFactGroups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      networkCuesUsed: json['networkCuesUsed'] as bool? ?? false,
      searchUsed: json['searchUsed'] as bool? ?? false,
      engaged: json['engaged'] as bool?,
      timestamp: dt ?? DateTime.now(),
      usedBypass: json['usedBypass'] as bool? ?? false,
    );
  }
}

/// Aggregated RAG feedback for local learning (RetrievalBiasService, conversation prefs).
class RAGFeedbackAggregate {
  final Map<String, int> retrievedGroupCounts;
  final int networkCuesUsedCount;
  final int searchUsedCount;
  final int bypassCount;

  const RAGFeedbackAggregate({
    required this.retrievedGroupCounts,
    required this.networkCuesUsedCount,
    required this.searchUsedCount,
    required this.bypassCount,
  });
}

const String _kSignalsKey = 'rag_feedback_signals_v1';
const String _kBox = 'spots_ai';
const int _kMaxSignals = 200;

/// Collects RAG feedback signals; stores locally. Optional federated upload when online.
///
/// RAG Phase 6: RAG→federation feedback.
class RAGSignalsCollector {
  RAGSignalsCollector({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  static const String _logName = 'RAGSignalsCollector';
  final IStorageService _storage;

  List<Map<String, dynamic>> _load() {
    final raw = _storage.getObject<dynamic>(_kSignalsKey, box: _kBox);
    if (raw == null || raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _save(List<Map<String, dynamic>> list) async {
    await _storage.setObject(_kSignalsKey, list, box: _kBox);
  }

  /// Records a RAG turn. [retrievedFactGroups] e.g. ['traits','places','social'].
  /// [usedBypass] true when user bypassed RAG-as-answer (e.g. "tell me more").
  Future<void> record({
    required String userId,
    required List<String> retrievedFactGroups,
    required bool networkCuesUsed,
    required bool searchUsed,
    bool? engaged,
    bool usedBypass = false,
  }) async {
    try {
      final signal = RAGFeedbackSignal(
        turnId: const Uuid().v4(),
        userId: userId,
        retrievedFactGroups: retrievedFactGroups,
        networkCuesUsed: networkCuesUsed,
        searchUsed: searchUsed,
        engaged: engaged,
        timestamp: DateTime.now(),
        usedBypass: usedBypass,
      );
      final list = _load();
      list.insert(0, signal.toJson());
      while (list.length > _kMaxSignals) {
        list.removeLast();
      }
      await _save(list);
    } catch (e) {
      developer.log('RAG signals record failed: $e', name: _logName);
    }
  }

  /// Loads recent signals, optionally filtered by [since]. [limit] caps count.
  List<RAGFeedbackSignal> getRecentSignals({
    int limit = 200,
    Duration? since,
  }) {
    final list = _load();
    final cutoff = since != null ? DateTime.now().subtract(since) : null;
    final signals = <RAGFeedbackSignal>[];
    for (final raw in list) {
      if (signals.length >= limit) break;
      final s = RAGFeedbackSignal.fromJson(Map<String, dynamic>.from(raw));
      if (cutoff != null && s.timestamp.isBefore(cutoff)) continue;
      signals.add(s);
    }
    return signals;
  }

  /// Aggregates recent signals for local learning (RetrievalBias, conversation prefs).
  RAGFeedbackAggregate aggregateForLocalLearning({
    int limit = 200,
    Duration? since,
  }) {
    final signals = getRecentSignals(limit: limit, since: since);
    final counts = <String, int>{};
    var networkCuesUsedCount = 0;
    var searchUsedCount = 0;
    var bypassCount = 0;
    for (final s in signals) {
      for (final g in s.retrievedFactGroups) {
        counts[g] = (counts[g] ?? 0) + 1;
      }
      if (s.networkCuesUsed) networkCuesUsedCount++;
      if (s.searchUsed) searchUsedCount++;
      if (s.usedBypass) bypassCount++;
    }
    return RAGFeedbackAggregate(
      retrievedGroupCounts: counts,
      networkCuesUsedCount: networkCuesUsedCount,
      searchUsedCount: searchUsedCount,
      bypassCount: bypassCount,
    );
  }

  /// Clears all stored signals. For testing only.
  Future<void> clear() async {
    await _save(<Map<String, dynamic>>[]);
  }
}

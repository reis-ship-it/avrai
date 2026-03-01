import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

const String _kKey = 'rag_ai2ai_insights_v1';
const String _kBox = 'spots_ai';
const int _kMaxInsights = 50;

/// Local store for last N AI2AI learning insights used by RAG context.
/// Device-only; ensures RAG has insights when mesh is inactive (offline).
///
/// RAG Phase 4: Consistent AI2AI context.
class RagAi2AiInsightsStore {
  RagAi2AiInsightsStore({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final IStorageService _storage;

  List<Map<String, dynamic>> _load() {
    final raw = _storage.getObject<dynamic>(_kKey, box: _kBox);
    if (raw == null || raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _save(List<Map<String, dynamic>> list) async {
    await _storage.setObject(_kKey, list, box: _kBox);
  }

  /// Appends a serialized insight and evicts oldest beyond [_kMaxInsights].
  Future<void> append(pl.AI2AILearningInsight insight) async {
    final map = {
      'type': insight.type.toString().split('.').last,
      'dimensionInsights': insight.dimensionInsights,
      'learningQuality': insight.learningQuality,
      'timestamp': insight.timestamp.toIso8601String(),
    };
    final list = _load();
    list.insert(0, map);
    while (list.length > _kMaxInsights) {
      list.removeLast();
    }
    await _save(list);
  }

  /// Returns stored insights as [pl.AI2AILearningInsight] (oldest first).
  List<pl.AI2AILearningInsight> getAll() {
    final list = _load();
    final out = <pl.AI2AILearningInsight>[];
    for (final m in list.reversed) {
      try {
        final type = pl.AI2AIInsightType.values.firstWhere(
          (e) => e.toString().split('.').last == (m['type'] as String? ?? ''),
          orElse: () => pl.AI2AIInsightType.dimensionDiscovery,
        );
        out.add(pl.AI2AILearningInsight(
          type: type,
          dimensionInsights:
              Map<String, double>.from(m['dimensionInsights'] as Map? ?? {}),
          learningQuality: (m['learningQuality'] as num?)?.toDouble() ?? 0.5,
          timestamp: m['timestamp'] != null
              ? DateTime.parse(m['timestamp'] as String)
              : DateTime.now(),
        ));
      } catch (_) {
        /* skip malformed */
      }
    }
    return out;
  }
}

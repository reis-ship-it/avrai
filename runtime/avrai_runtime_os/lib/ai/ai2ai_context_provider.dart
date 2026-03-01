import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/ai/rag_ai2ai_insights_store.dart';
import 'package:get_it/get_it.dart';

/// Provides AI2AI insights and connection metrics for RAG context.
/// Reads from local stores; connection metrics may be null when offline (v1).
///
/// RAG Phase 4: Consistent AI2AI context.
class AI2AIContextProvider {
  AI2AIContextProvider({RagAi2AiInsightsStore? insightsStore})
      : _insightsStore = insightsStore;

  final RagAi2AiInsightsStore? _insightsStore;

  /// Returns last N AI2AI learning insights from local store (offline-safe).
  List<pl.AI2AILearningInsight> getInsights(String userId) {
    final store = _insightsStore ?? _get<RagAi2AiInsightsStore>();
    if (store == null) return [];
    return store.getAll();
  }

  /// Returns connection metrics when available; null when offline (v1).
  Future<ConnectionMetrics?> getConnectionMetrics(String userId) async {
    return null;
  }

  T? _get<T extends Object>() {
    if (!GetIt.instance.isRegistered<T>()) return null;
    return GetIt.instance<T>();
  }
}

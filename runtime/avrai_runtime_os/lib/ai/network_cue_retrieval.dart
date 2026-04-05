import 'package:avrai_runtime_os/ai/network_retrieval_cue.dart';

/// Retrieves network cues for RAG context.
///
/// RAG Phase 2: Network-aware retrieval.
class NetworkCueRetrieval {
  NetworkCueRetrieval({NetworkCuesStore? store})
      : _store = store ?? NetworkCuesStore();

  final NetworkCuesStore _store;

  /// Returns top [limit] cues by strength (then recency). [userId] reserved for
  /// future query-aware filtering.
  List<NetworkRetrievalCue> retrieveCues({
    required String userId,
    int limit = 10,
    double minStrength = 0.0,
  }) {
    final all = _store.getAll();
    final filtered = minStrength > 0
        ? all.where((c) => c.strength >= minStrength).toList()
        : all;
    filtered.sort((a, b) {
      final str = b.strength.compareTo(a.strength);
      if (str != 0) return str;
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered.take(limit).toList();
  }
}

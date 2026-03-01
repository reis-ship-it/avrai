/// A single retrieved item for RAG-as-answer (fact, cue, or insight).
///
/// Plan: RAG wiring + RAG-as-answer — structured retrieval result.
class RetrievedItem {
  final String id;
  final String type;
  final String content;
  final double score;
  final String source;

  const RetrievedItem({
    required this.id,
    required this.type,
    required this.content,
    required this.score,
    required this.source,
  });
}

/// Result of retrieval for RAG-as-answer: items plus coverage and optional intent.
///
/// Plan: RAG wiring + RAG-as-answer — structured retrieval result.
class RetrievalResult {
  final List<RetrievedItem> items;
  final Map<String, int> coverage;
  final String? queryIntent;

  const RetrievalResult({
    required this.items,
    required this.coverage,
    this.queryIntent,
  });

  bool get isEmpty => items.isEmpty;
  bool get hasTraits => (coverage['traits'] ?? 0) > 0;
  bool get hasPlaces => (coverage['places'] ?? 0) > 0;
  bool get hasSocial => (coverage['social'] ?? 0) > 0;
  bool get hasCues => (coverage['cues'] ?? 0) > 0;
}

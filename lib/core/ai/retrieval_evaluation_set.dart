import 'dart:convert';

class RetrievalEvaluationEntry {
  final String id;
  final String queryText;
  final String locale;
  final String geoHint;
  final List<String> edgeCaseTags;
  final Map<String, List<String>> expectedRelevanceTiers;

  const RetrievalEvaluationEntry({
    required this.id,
    required this.queryText,
    required this.locale,
    required this.geoHint,
    required this.edgeCaseTags,
    required this.expectedRelevanceTiers,
  });

  factory RetrievalEvaluationEntry.fromJson(Map<String, dynamic> json) {
    final tiers = <String, List<String>>{};
    final rawTiers = json['expected_relevance_tiers'] as Map? ?? const {};
    rawTiers.forEach((key, value) {
      tiers['$key'] =
          (value as List? ?? const []).map((item) => '$item').toList();
    });

    return RetrievalEvaluationEntry(
      id: json['id'] as String? ?? '',
      queryText: json['query_text'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en-US',
      geoHint: json['geo_hint'] as String? ?? '',
      edgeCaseTags: (json['edge_case_tags'] as List? ?? const [])
          .map((e) => '$e')
          .toList(),
      expectedRelevanceTiers: tiers,
    );
  }
}

class RetrievalEvaluationSet {
  final String version;
  final String domain;
  final List<RetrievalEvaluationEntry> queries;

  const RetrievalEvaluationSet({
    required this.version,
    required this.domain,
    required this.queries,
  });

  factory RetrievalEvaluationSet.fromJson(Map<String, dynamic> json) {
    final rawQueries = json['queries'] as List? ?? const [];
    return RetrievalEvaluationSet(
      version: json['version'] as String? ?? 'unknown',
      domain: json['domain'] as String? ?? '',
      queries: rawQueries
          .whereType<Map>()
          .map((q) => RetrievalEvaluationEntry.fromJson(
                Map<String, dynamic>.from(q),
              ))
          .toList(growable: false),
    );
  }

  factory RetrievalEvaluationSet.fromJsonString(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return RetrievalEvaluationSet.fromJson(decoded);
  }

  List<RetrievalEvaluationEntry> withEdgeCase(String tag) {
    return queries
        .where((entry) => entry.edgeCaseTags.contains(tag))
        .toList(growable: false);
  }
}

import 'package:avrai/core/ai/memory/journal/facts_journal_schema.dart';

class FactsJournalRetrievalQuery {
  final String keyword;
  final Map<String, Object?> metadataFilters;
  final int topK;

  const FactsJournalRetrievalQuery({
    required this.keyword,
    this.metadataFilters = const {},
    this.topK = 20,
  });
}

class FactsJournalRetrievalResult {
  final FactsJournalEntry entry;
  final double score;

  const FactsJournalRetrievalResult({
    required this.entry,
    required this.score,
  });
}

class FactsJournalDeterministicRetrieval {
  const FactsJournalDeterministicRetrieval();

  List<FactsJournalRetrievalResult> retrieve({
    required List<FactsJournalEntry> entries,
    required FactsJournalRetrievalQuery query,
  }) {
    final normalizedKeyword = query.keyword.trim().toLowerCase();
    final scored = <FactsJournalRetrievalResult>[];

    for (final entry in entries) {
      if (!entry.isValid) continue;
      if (!_matchesMetadata(entry, query.metadataFilters)) continue;

      final score = _score(entry, normalizedKeyword);
      if (score <= 0) continue;

      scored.add(FactsJournalRetrievalResult(entry: entry, score: score));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.entry.timestamp.compareTo(a.entry.timestamp);
    });

    final boundedTopK = query.topK <= 0 ? 0 : query.topK;
    return scored.take(boundedTopK).toList(growable: false);
  }

  bool _matchesMetadata(
    FactsJournalEntry entry,
    Map<String, Object?> filters,
  ) {
    if (filters.isEmpty) return true;

    for (final candidate in filters.entries) {
      final value = entry.metadata[candidate.key];
      if (value != candidate.value) {
        return false;
      }
    }
    return true;
  }

  double _score(FactsJournalEntry entry, String keyword) {
    if (keyword.isEmpty) {
      return entry.confidence;
    }

    final key = entry.factKey.toLowerCase();
    final value = entry.factValue.toLowerCase();
    final source = entry.source.toLowerCase();

    var lexical = 0.0;
    if (key == keyword) {
      lexical += 1.0;
    } else if (key.contains(keyword)) {
      lexical += 0.75;
    }

    if (value.contains(keyword)) {
      lexical += 0.6;
    }

    if (source.contains(keyword)) {
      lexical += 0.2;
    }

    if (lexical <= 0) return 0;

    return lexical + entry.confidence;
  }
}

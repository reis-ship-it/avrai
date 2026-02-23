class FactsJournalWindowEntry {
  final String entryId;
  final String factKey;
  final String factValue;
  final String source;
  final double confidence;
  final DateTime timestamp;
  final String provenanceId;
  final Map<String, Object?> metadata;

  const FactsJournalWindowEntry({
    required this.entryId,
    required this.factKey,
    required this.factValue,
    required this.source,
    required this.confidence,
    required this.timestamp,
    required this.provenanceId,
    this.metadata = const {},
  });

  bool get isCritical {
    return metadata['critical_fact'] == true ||
        metadata['preserve_verbatim'] == true;
  }
}

class HistoryJournalWindowEntry {
  final String entryId;
  final String eventType;
  final String summary;
  final DateTime timestamp;
  final Map<String, Object?> metadata;

  const HistoryJournalWindowEntry({
    required this.entryId,
    required this.eventType,
    required this.summary,
    required this.timestamp,
    this.metadata = const {},
  });

  bool get isFailureSignature {
    if (metadata['failure_signature'] == true) return true;
    if ((metadata['failure_signature_id'] as String?)?.isNotEmpty == true) {
      return true;
    }
    return eventType.contains('failure') || eventType.contains('rollback');
  }
}

class FactSummaryBucket {
  final String factKey;
  final int count;
  final String latestValue;
  final double averageConfidence;
  final DateTime latestTimestamp;
  final List<String> sources;

  const FactSummaryBucket({
    required this.factKey,
    required this.count,
    required this.latestValue,
    required this.averageConfidence,
    required this.latestTimestamp,
    required this.sources,
  });
}

class HistorySummaryBucket {
  final String eventType;
  final int count;
  final String latestSummary;
  final DateTime latestTimestamp;

  const HistorySummaryBucket({
    required this.eventType,
    required this.count,
    required this.latestSummary,
    required this.latestTimestamp,
  });
}

class JournalWindowConsolidationResult {
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime recentCutoff;
  final List<FactSummaryBucket> factSummaries;
  final List<HistorySummaryBucket> historySummaries;
  final List<FactsJournalWindowEntry> preservedCriticalFacts;
  final List<HistoryJournalWindowEntry> preservedFailureSignatures;

  const JournalWindowConsolidationResult({
    required this.windowStart,
    required this.windowEnd,
    required this.recentCutoff,
    required this.factSummaries,
    required this.historySummaries,
    required this.preservedCriticalFacts,
    required this.preservedFailureSignatures,
  });
}

class JournalWindowConsolidationService {
  const JournalWindowConsolidationService({
    this.recentWindow = const Duration(days: 14),
  });

  final Duration recentWindow;

  JournalWindowConsolidationResult consolidate({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<FactsJournalWindowEntry> facts,
    required List<HistoryJournalWindowEntry> history,
  }) {
    final startUtc = windowStart.toUtc();
    final endUtc = windowEnd.toUtc();
    final recentCutoff = endUtc.subtract(recentWindow);

    final inWindowFacts = facts.where((entry) {
      final t = entry.timestamp.toUtc();
      return !t.isBefore(startUtc) && t.isBefore(endUtc);
    }).toList(growable: false);

    final inWindowHistory = history.where((entry) {
      final t = entry.timestamp.toUtc();
      return !t.isBefore(startUtc) && t.isBefore(endUtc);
    }).toList(growable: false);

    final preservedCriticalFacts = inWindowFacts
        .where((entry) => entry.isCritical)
        .toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final preservedFailureSignatures = inWindowHistory
        .where((entry) => entry.isFailureSignature)
        .toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final oldNonCriticalFacts = inWindowFacts
        .where((entry) =>
            !entry.isCritical && entry.timestamp.toUtc().isBefore(recentCutoff))
        .toList(growable: false);

    final oldNonFailureHistory = inWindowHistory
        .where((entry) =>
            !entry.isFailureSignature &&
            entry.timestamp.toUtc().isBefore(recentCutoff))
        .toList(growable: false);

    final factSummaries = _summarizeFacts(oldNonCriticalFacts);
    final historySummaries = _summarizeHistory(oldNonFailureHistory);

    return JournalWindowConsolidationResult(
      windowStart: startUtc,
      windowEnd: endUtc,
      recentCutoff: recentCutoff,
      factSummaries: factSummaries,
      historySummaries: historySummaries,
      preservedCriticalFacts: preservedCriticalFacts,
      preservedFailureSignatures: preservedFailureSignatures,
    );
  }

  List<FactSummaryBucket> _summarizeFacts(
      List<FactsJournalWindowEntry> entries) {
    final grouped = <String, List<FactsJournalWindowEntry>>{};
    for (final entry in entries) {
      grouped
          .putIfAbsent(entry.factKey, () => <FactsJournalWindowEntry>[])
          .add(entry);
    }

    final summaries = <FactSummaryBucket>[];
    final sortedKeys = grouped.keys.toList()..sort();

    for (final key in sortedKeys) {
      final rows = grouped[key]!;
      rows.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final latest = rows.last;
      final avgConfidence =
          rows.fold<double>(0.0, (sum, row) => sum + row.confidence) /
              rows.length;

      final sourceSet = rows.map((row) => row.source).toSet().toList()..sort();
      summaries.add(
        FactSummaryBucket(
          factKey: key,
          count: rows.length,
          latestValue: latest.factValue,
          averageConfidence: avgConfidence,
          latestTimestamp: latest.timestamp.toUtc(),
          sources: sourceSet,
        ),
      );
    }

    return summaries;
  }

  List<HistorySummaryBucket> _summarizeHistory(
    List<HistoryJournalWindowEntry> entries,
  ) {
    final grouped = <String, List<HistoryJournalWindowEntry>>{};
    for (final entry in entries) {
      grouped
          .putIfAbsent(entry.eventType, () => <HistoryJournalWindowEntry>[])
          .add(entry);
    }

    final summaries = <HistorySummaryBucket>[];
    final sortedTypes = grouped.keys.toList()..sort();

    for (final eventType in sortedTypes) {
      final rows = grouped[eventType]!;
      rows.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final latest = rows.last;

      summaries.add(
        HistorySummaryBucket(
          eventType: eventType,
          count: rows.length,
          latestSummary: latest.summary,
          latestTimestamp: latest.timestamp.toUtc(),
        ),
      );
    }

    return summaries;
  }
}

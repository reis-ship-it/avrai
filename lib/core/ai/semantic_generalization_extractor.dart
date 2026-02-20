import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/semantic_memory_local_store.dart';
import 'package:avrai/core/ai/semantic_memory_schema.dart';

/// Clusters episodic tuples into compressed semantic knowledge entries.
///
/// Phase 1.1A.3: extract recurring patterns and persist semantic summaries.
class SemanticGeneralizationExtractor {
  const SemanticGeneralizationExtractor({
    SemanticMemoryLocalStore? semanticLocalStore,
  }) : _semanticLocalStore = semanticLocalStore;

  final SemanticMemoryLocalStore? _semanticLocalStore;

  Future<List<SemanticMemoryEntry>> extractGeneralizations({
    required String agentId,
    required EpisodicMemoryStore episodicMemoryStore,
    DateTime? afterExclusive,
    int replayLimit = 2000,
    int minClusterSize = 2,
  }) async {
    final tuples = await episodicMemoryStore.replay(
      agentId: agentId,
      afterExclusive: afterExclusive,
      limit: replayLimit,
    );
    if (tuples.isEmpty) return const [];

    final clusters = <String, List<EpisodicTuple>>{};
    for (final tuple in tuples) {
      final key = _clusterKey(tuple);
      clusters.putIfAbsent(key, () => <EpisodicTuple>[]).add(tuple);
    }

    final entries = <SemanticMemoryEntry>[];
    final now = DateTime.now().toUtc();
    clusters.forEach((key, grouped) {
      if (grouped.length < minClusterSize) return;
      entries.add(
        _buildEntry(
          agentId: agentId,
          clusterKey: key,
          tuples: grouped,
          createdAt: now,
        ),
      );
    });

    entries.sort((a, b) => b.confidence.compareTo(a.confidence));

    final semanticStore = _semanticLocalStore;
    if (semanticStore != null) {
      final existingEntries = await semanticStore.getAll(agentId);
      final existingById = <String, SemanticMemoryEntry>{
        for (final existing in existingEntries) existing.id: existing,
      };
      final persisted = <SemanticMemoryEntry>[];
      for (final entry in entries) {
        final existing = existingById[entry.id];
        if (existing == null) {
          await semanticStore.upsert(agentId, entry);
          persisted.add(entry);
          continue;
        }

        final merged = existing
            .copyWith(
              embedding: entry.embedding,
              generalization: entry.generalization,
            )
            .mergeEvidence(
              additionalEvidence: entry.evidenceCount,
              observedConfidence: entry.confidence,
              mergedAt: entry.updatedAt,
            );
        await semanticStore.upsert(agentId, merged);
        persisted.add(merged);
      }
      if (entries.isNotEmpty) {
        await semanticStore.addPending(agentId);
      }
      return persisted;
    }

    return entries;
  }

  SemanticMemoryEntry _buildEntry({
    required String agentId,
    required String clusterKey,
    required List<EpisodicTuple> tuples,
    required DateTime createdAt,
  }) {
    var outcomeSum = 0.0;
    var positiveCount = 0;
    DateTime latest = tuples.first.recordedAt;
    for (final tuple in tuples) {
      outcomeSum += tuple.outcome.value;
      if (tuple.outcome.value >= 0.6) positiveCount++;
      if (tuple.recordedAt.isAfter(latest)) latest = tuple.recordedAt;
    }
    final evidenceCount = tuples.length;
    final avgOutcome = outcomeSum / evidenceCount;
    final positiveRate = positiveCount / evidenceCount;
    final confidence =
        ((positiveRate * 0.7) + ((_normalizeEvidence(evidenceCount) * 0.3)))
            .clamp(0.0, 1.0);

    final parts = clusterKey.split('|');
    final action = parts.isNotEmpty ? parts[0] : 'unknown_action';
    final category = parts.length > 1 ? parts[1] : 'general';
    final dayPart = parts.length > 2 ? parts[2] : 'anytime';

    final generalization = 'User tends to prefer `$action`'
        ' in `$category` contexts during `$dayPart` windows'
        ' (avg outcome ${(avgOutcome * 100).toStringAsFixed(0)}%).';

    return SemanticMemoryEntry(
      id: _entryId(agentId, clusterKey),
      agentId: agentId,
      embedding: _buildEmbedding(
        action: action,
        category: category,
        dayPart: dayPart,
        avgOutcome: avgOutcome,
        positiveRate: positiveRate,
        evidenceCount: evidenceCount,
      ),
      generalization: generalization,
      evidenceCount: evidenceCount,
      confidence: confidence,
      createdAt: createdAt,
      updatedAt: latest.toUtc(),
    );
  }

  String _clusterKey(EpisodicTuple tuple) {
    final action =
        tuple.actionType.trim().isEmpty ? 'unknown' : tuple.actionType;
    final category = _extractCategory(tuple);
    final dayPart = _dayPart(tuple.recordedAt.toLocal().hour);
    return '$action|$category|$dayPart';
  }

  String _extractCategory(EpisodicTuple tuple) {
    const categoryKeys = [
      'category',
      'entity_category',
      'spot_category',
      'event_category',
      'community_category',
      'business_category',
      'list_category',
    ];

    for (final key in categoryKeys) {
      final payloadValue = tuple.actionPayload[key];
      if (payloadValue is String && payloadValue.trim().isNotEmpty) {
        return payloadValue.trim().toLowerCase();
      }
      final stateValue = tuple.stateBefore[key];
      if (stateValue is String && stateValue.trim().isNotEmpty) {
        return stateValue.trim().toLowerCase();
      }
    }
    return 'general';
  }

  String _dayPart(int hour) {
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  double _normalizeEvidence(int evidenceCount) {
    if (evidenceCount <= 0) return 0.0;
    return (evidenceCount / 20.0).clamp(0.0, 1.0);
  }

  String _entryId(String agentId, String clusterKey) {
    final digest = sha256.convert(utf8.encode('$agentId::$clusterKey'));
    return 'semgen-${digest.toString().substring(0, 16)}';
  }

  List<double> _buildEmbedding({
    required String action,
    required String category,
    required String dayPart,
    required double avgOutcome,
    required double positiveRate,
    required int evidenceCount,
  }) {
    return <double>[
      _hashToUnit(action),
      _hashToUnit(category),
      _hashToUnit(dayPart),
      avgOutcome.clamp(0.0, 1.0),
      positiveRate.clamp(0.0, 1.0),
      _normalizeEvidence(evidenceCount),
    ];
  }

  double _hashToUnit(String value) {
    final digest = sha256.convert(utf8.encode(value));
    return digest.bytes.first / 255.0;
  }
}

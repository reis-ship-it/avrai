import 'dart:math' as math;

import 'package:avrai/core/ai/federated_priors_cache.dart';
import 'package:avrai/core/ai/network_retrieval_cue.dart';
import 'package:avrai/core/ai/rag_feedback_signals.dart';
import 'package:avrai/core/ai/structured_facts.dart';

/// Uses federated priors and local RAG feedback to bias retrieval.
/// Offline-capable; no network.
///
/// RAG Phase 3: Federated-shaped retrieval.
/// Plan: RAG wiring — merge local feedback boosts into weights.
class RetrievalBiasService {
  static const Duration _localFeedbackWindow = Duration(hours: 24);
  static const int _localFeedbackLimit = 100;
  static const double _maxLocalBoost = 0.15;

  RetrievalBiasService({
    FederatedPriorsCache? federatedPriorsCache,
    RAGSignalsCollector? signalsCollector,
  })  : _priorsCache = federatedPriorsCache ?? FederatedPriorsCache(),
        _signalsCollector = signalsCollector;

  final FederatedPriorsCache _priorsCache;
  final RAGSignalsCollector? _signalsCollector;

  /// Builds category -> weight from federated priors + local RAG feedback.
  /// Missing categories use 1.0. Final weights clamped to [1.0, 1.5].
  Map<String, double> _weights() {
    final w = <String, double>{};
    final cached = _priorsCache.get();
    if (cached != null && cached.priors.isNotEmpty) {
      for (final e in cached.priors.entries) {
        final mag = e.value.isEmpty
            ? 1.0
            : math.sqrt(e.value.map((x) => x * x).reduce((a, b) => a + b) /
                e.value.length);
        w[e.key] = (1.0 + 0.5 * mag.clamp(0.0, 1.0)).clamp(1.0, 1.5);
      }
    }
    if (_signalsCollector != null) {
      final agg = _signalsCollector.aggregateForLocalLearning(
        limit: _localFeedbackLimit,
        since: _localFeedbackWindow,
      );
      final local = _localBoosts(agg);
      for (final e in local.entries) {
        final current = w[e.key] ?? 1.0;
        w[e.key] = (current + e.value).clamp(1.0, 1.5);
      }
    }
    return w;
  }

  /// Derives category -> boost from RAG feedback aggregate. Small nudge.
  Map<String, double> _localBoosts(RAGFeedbackAggregate agg) {
    final boosts = <String, double>{};
    final counts = agg.retrievedGroupCounts;
    if (counts.isEmpty) return boosts;
    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);
    if (maxCount < 1) return boosts;
    for (final e in counts.entries) {
      final n = (e.value / maxCount).clamp(0.0, 1.0);
      boosts[e.key] = (_maxLocalBoost * n).clamp(0.0, _maxLocalBoost);
    }
    if (agg.networkCuesUsedCount > 0) {
      boosts['network'] = _maxLocalBoost * 0.5;
    }
    return boosts;
  }

  /// Re-ranks [cues] by prior-weighted score (category weight × recency).
  /// Returns new list (same items, different order).
  List<NetworkRetrievalCue> reRankCues(
    List<NetworkRetrievalCue> cues, {
    int limit = 50,
  }) {
    if (cues.isEmpty) return [];
    final weights = _weights();
    final now = DateTime.now();
    final scored = cues.map((c) {
      final w = weights[c.category] ?? 1.0;
      final ageSec = now.difference(c.createdAt).inSeconds.clamp(0, 86400 * 30);
      final recency = 1.0 / (1.0 + ageSec / 3600.0);
      final score = w * (c.strength * 0.5 + recency * 0.5);
      return (cue: c, score: score);
    }).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.cue).toList();
  }

  /// Returns [facts] unchanged and [cues] re-ranked. Use when building context.
  ({StructuredFacts facts, List<NetworkRetrievalCue> cues}) reRank(
    StructuredFacts facts,
    List<NetworkRetrievalCue> cues, {
    int cueLimit = 50,
  }) {
    return (
      facts: facts,
      cues: reRankCues(cues, limit: cueLimit),
    );
  }
}

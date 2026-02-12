import 'dart:developer' as developer;

import 'package:avrai/core/ai/ai2ai_context_provider.dart';
import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/core/ai/network_cue_retrieval.dart';
import 'package:avrai/core/ai/network_retrieval_cue.dart';
import 'package:avrai/core/ai/personality_learning.dart' as pl;
import 'package:avrai/core/ai/retrieval_bias_service.dart';
import 'package:avrai/core/ai/retrieval_result.dart';
import 'package:get_it/get_it.dart';

/// Cap per type for merge policy.
const int _kCapTraits = 5;
const int _kCapPlaces = 5;
const int _kCapSocial = 3;
const int _kCapCues = 5;
const int _kCapInsights = 5;

/// Retrieves facts, cues, and insights; applies merge policy; returns [RetrievalResult].
///
/// Plan: RAG wiring + RAG-as-answer — RetrievalService.
class RetrievalService {
  RetrievalService({
    FactsIndex? factsIndex,
    NetworkCueRetrieval? networkCueRetrieval,
    RetrievalBiasService? retrievalBiasService,
    AI2AIContextProvider? ai2aiContextProvider,
  })  : _factsIndex = factsIndex ?? GetIt.instance<FactsIndex>(),
        _networkCueRetrieval =
            networkCueRetrieval ?? _get<NetworkCueRetrieval>(),
        _retrievalBiasService =
            retrievalBiasService ?? _get<RetrievalBiasService>(),
        _ai2aiProvider = ai2aiContextProvider ?? _get<AI2AIContextProvider>();

  static const String _logName = 'RetrievalService';

  final FactsIndex _factsIndex;
  final NetworkCueRetrieval? _networkCueRetrieval;
  final RetrievalBiasService? _retrievalBiasService;
  final AI2AIContextProvider? _ai2aiProvider;

  static T? _get<T extends Object>() {
    if (!GetIt.instance.isRegistered<T>()) return null;
    return GetIt.instance<T>();
  }

  /// Retrieves and merges facts, cues, insights for [userId]. Returns [RetrievalResult].
  Future<RetrievalResult> retrieve({required String userId}) async {
    try {
      final facts = await _factsIndex.retrieveFacts(userId: userId);
      var cues = <NetworkRetrievalCue>[];
      if (_networkCueRetrieval != null) {
        cues = _networkCueRetrieval.retrieveCues(userId: userId, limit: 20);
      }
      if (_retrievalBiasService != null) {
        final r = _retrievalBiasService.reRank(facts, cues, cueLimit: 20);
        cues = r.cues;
      }
      final insights = _ai2aiProvider?.getInsights(userId) ?? [];

      final items = <RetrievedItem>[];
      final seen = <String>{};
      void add(RetrievedItem it) {
        if (seen.contains(it.content)) return;
        seen.add(it.content);
        items.add(it);
      }

      var tCount = 0;
      var pCount = 0;
      var sCount = 0;
      for (final x in facts.traits) {
        if (tCount >= _kCapTraits) break;
        add(RetrievedItem(
          id: 'trait-$x',
          type: 'traits',
          content: x,
          score: 1.0,
          source: 'facts',
        ));
        tCount++;
      }
      for (final x in facts.places) {
        if (pCount >= _kCapPlaces) break;
        add(RetrievedItem(
          id: 'place-$x',
          type: 'places',
          content: x,
          score: 1.0,
          source: 'facts',
        ));
        pCount++;
      }
      for (final x in facts.socialGraph) {
        if (sCount >= _kCapSocial) break;
        add(RetrievedItem(
          id: 'social-$x',
          type: 'social',
          content: x,
          score: 1.0,
          source: 'facts',
        ));
        sCount++;
      }

      var iCount = 0;
      for (final ins in insights) {
        if (iCount >= _kCapInsights) break;
        final summary = _insightSummary(ins);
        add(RetrievedItem(
          id: 'insight-${ins.type.name}-$iCount',
          type: 'insight',
          content: summary,
          score: ins.learningQuality.clamp(0.0, 1.0),
          source: 'ai2ai',
        ));
        iCount++;
      }

      var cCount = 0;
      for (final c in cues) {
        if (cCount >= _kCapCues) break;
        add(RetrievedItem(
          id: c.id,
          type: 'cues',
          content: c.summary,
          score: c.strength,
          source: c.source.name,
        ));
        cCount++;
      }

      final coverage = <String, int>{
        'traits': tCount,
        'places': pCount,
        'social': sCount,
        'cues': cCount,
        'insight': iCount,
      };
      return RetrievalResult(items: items, coverage: coverage);
    } catch (e, st) {
      developer.log('RetrievalService.retrieve failed: $e',
          name: _logName, error: e, stackTrace: st);
      return RetrievalResult(
        items: [],
        coverage: {
          'traits': 0,
          'places': 0,
          'social': 0,
          'cues': 0,
          'insight': 0
        },
      );
    }
  }

  String _insightSummary(pl.AI2AILearningInsight ins) {
    final parts = ins.dimensionInsights.entries
        .take(3)
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
        .toList();
    return '${ins.type.name}: ${parts.join(', ')}';
  }
}

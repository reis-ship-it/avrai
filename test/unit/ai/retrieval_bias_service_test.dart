/// Unit tests for RetrievalBiasService and FederatedPriorsCache (RAG Phase 3).
/// Plan: RAG wiring — local feedback merges into weights (Phase 2).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/federated_priors_cache.dart';
import 'package:avrai/core/ai/network_retrieval_cue.dart';
import 'package:avrai/core/ai/rag_feedback_signals.dart';
import 'package:avrai/core/ai/retrieval_bias_service.dart';
import 'package:avrai/core/ai/structured_facts.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('FederatedPriorsCache', () {
    late FederatedPriorsCache cache;

    setUp(() {
      cache = FederatedPriorsCache();
    });

    test('get returns null when empty', () {
      expect(cache.get(), isNull);
    });

    test('set and get round-trip', () async {
      final priors = <String, List<double>>{
        'exploration': [0.1, -0.2, 0.3],
        'social': [-0.1, 0.0, 0.2],
      };
      await cache.set(priors);
      final got = cache.get();
      expect(got, isNotNull);
      expect(got!.priors.keys, containsAll(['exploration', 'social']));
      expect(got.priors['exploration'], equals([0.1, -0.2, 0.3]));
    });
  });

  group('RetrievalBiasService', () {
    late FederatedPriorsCache cache;
    late RetrievalBiasService service;

    setUp(() {
      cache = FederatedPriorsCache();
      service = RetrievalBiasService(federatedPriorsCache: cache);
    });

    test('reRankCues returns empty when no cues', () {
      expect(service.reRankCues([]), isEmpty);
    });

    test(
        'reRankCues returns cues in strength-then-recency order when no priors',
        () async {
      final now = DateTime.now();
      final cues = [
        NetworkRetrievalCue(
          id: '1',
          category: 'a',
          summary: 's1',
          source: NetworkCueSource.ai2aiMesh,
          strength: 0.5,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        NetworkRetrievalCue(
          id: '2',
          category: 'b',
          summary: 's2',
          source: NetworkCueSource.federated,
          strength: 0.9,
          createdAt: now,
        ),
      ];
      final out = service.reRankCues(cues, limit: 10);
      expect(out.length, equals(2));
      expect(out.first.strength, equals(0.9));
    });

    test('reRank returns facts unchanged and cues re-ranked', () async {
      final facts = StructuredFacts(
        traits: ['t'],
        places: [],
        socialGraph: [],
        timestamp: DateTime.now(),
      );
      final cues = [
        NetworkRetrievalCue(
          id: '1',
          category: 'c',
          summary: 's',
          source: NetworkCueSource.ai2aiMesh,
          strength: 0.7,
          createdAt: DateTime.now(),
        ),
      ];
      final result = service.reRank(facts, cues, cueLimit: 5);
      expect(result.facts.traits, equals(['t']));
      expect(result.cues.length, equals(1));
      expect(result.cues.first.id, equals('1'));
    });
  });

  group('RetrievalBiasService with RAG feedback', () {
    late FederatedPriorsCache cache;
    late RAGSignalsCollector collector;
    late RetrievalBiasService service;

    setUp(() async {
      cache = FederatedPriorsCache();
      collector = RAGSignalsCollector();
      await collector.clear();
      service = RetrievalBiasService(
        federatedPriorsCache: cache,
        signalsCollector: collector,
      );
    });

    test('local feedback boosts category weight', () async {
      for (var i = 0; i < 5; i++) {
        await collector.record(
          userId: 'u',
          retrievedFactGroups: ['traits', 'places'],
          networkCuesUsed: true,
          searchUsed: false,
        );
      }
      final now = DateTime.now();
      final cues = [
        NetworkRetrievalCue(
          id: 'other',
          category: 'other',
          summary: 'o',
          source: NetworkCueSource.federated,
          strength: 0.6,
          createdAt: now,
        ),
        NetworkRetrievalCue(
          id: 'traits',
          category: 'traits',
          summary: 't',
          source: NetworkCueSource.ai2aiMesh,
          strength: 0.6,
          createdAt: now,
        ),
      ];
      final out = service.reRankCues(cues, limit: 10);
      expect(out.length, 2);
      expect(out.first.category, 'traits');
    });
  });
}

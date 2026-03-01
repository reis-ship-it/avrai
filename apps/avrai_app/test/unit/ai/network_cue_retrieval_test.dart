/// Unit tests for NetworkCuesStore and NetworkCueRetrieval (RAG Phase 2).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/network_cue_retrieval.dart';
import 'package:avrai_runtime_os/ai/network_retrieval_cue.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('NetworkCuesStore', () {
    late NetworkCuesStore store;

    setUp(() {
      store = NetworkCuesStore();
    });

    test('getAll returns empty initially', () {
      expect(store.getAll(), isEmpty);
    });

    test('add and getAll round-trip', () async {
      final cue = NetworkRetrievalCue(
        id: 'nc-1',
        category: 'exploration_eagerness',
        summary: 'elevated exploration_eagerness in network',
        source: NetworkCueSource.ai2aiMesh,
        strength: 0.8,
        createdAt: DateTime.now(),
      );
      await store.add(cue);
      final all = store.getAll();
      expect(all.length, equals(1));
      expect(all.first.id, equals('nc-1'));
      expect(all.first.category, equals('exploration_eagerness'));
      expect(all.first.strength, equals(0.8));
    });
  });

  group('NetworkCueRetrieval', () {
    late NetworkCuesStore store;
    late NetworkCueRetrieval retrieval;

    setUp(() {
      store = NetworkCuesStore();
      retrieval = NetworkCueRetrieval(store: store);
    });

    test('retrieveCues returns empty when no cues', () async {
      await store.clear();
      final cues = retrieval.retrieveCues(userId: 'u1', limit: 5);
      expect(cues, isEmpty);
    });

    test('retrieveCues returns cues sorted by strength then recency', () async {
      await store.clear();
      final now = DateTime.now();
      await store.add(NetworkRetrievalCue(
        id: 'a',
        category: 'c1',
        summary: 's1',
        source: NetworkCueSource.ai2aiMesh,
        strength: 0.5,
        createdAt: now,
      ));
      await store.add(NetworkRetrievalCue(
        id: 'b',
        category: 'c2',
        summary: 's2',
        source: NetworkCueSource.federated,
        strength: 0.9,
        createdAt: now,
      ));
      final cues = retrieval.retrieveCues(userId: 'u1', limit: 10);
      expect(cues.length, equals(2));
      expect(cues.first.strength, equals(0.9));
      expect(cues.last.strength, equals(0.5));
    });
  });
}

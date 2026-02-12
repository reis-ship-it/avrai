/// Unit tests for FactsLocalStore (RAG Phase 1: offline-first facts).
///
/// Verifies get, upsert, remove, and pending-sync queue behavior.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/facts_local_store.dart';
import 'package:avrai/core/ai/structured_facts.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('FactsLocalStore', () {
    late FactsLocalStore store;

    setUp(() {
      store = FactsLocalStore();
      store.clearPending();
    });

    test('get returns null when no facts stored', () async {
      expect(await store.get('agent-get-null'), isNull);
    });

    test('upsert and get round-trip', () async {
      const aid = 'agent-upsert-roundtrip';
      final facts = StructuredFacts(
        traits: ['prefers_coffee'],
        places: ['place-1'],
        socialGraph: ['event-1'],
        timestamp: DateTime.now(),
      );
      await store.upsert(aid, facts);
      final got = await store.get(aid);
      expect(got, isNotNull);
      expect(got!.traits, equals(['prefers_coffee']));
      expect(got.places, equals(['place-1']));
      expect(got.socialGraph, equals(['event-1']));
    });

    test('upsert overwrites existing', () async {
      const aid = 'agent-overwrite';
      await store.upsert(
          aid,
          StructuredFacts(
            traits: ['a'],
            places: [],
            socialGraph: [],
            timestamp: DateTime.now(),
          ));
      await store.upsert(
          aid,
          StructuredFacts(
            traits: ['b'],
            places: ['p1'],
            socialGraph: [],
            timestamp: DateTime.now(),
          ));
      final got = await store.get(aid);
      expect(got!.traits, equals(['b']));
      expect(got.places, equals(['p1']));
    });

    test('remove deletes facts', () async {
      const aid = 'agent-remove';
      await store.upsert(
          aid,
          StructuredFacts(
            traits: ['a'],
            places: [],
            socialGraph: [],
            timestamp: DateTime.now(),
          ));
      await store.remove(aid);
      expect(await store.get(aid), isNull);
    });

    test('addPending and getPending', () async {
      expect(store.getPending(), isEmpty);
      await store.addPending('agent-p1');
      expect(store.getPending(), contains('agent-p1'));
      await store.addPending('agent-p2');
      expect(store.getPending().length, equals(2));
    });

    test('addPending idempotent per agent', () async {
      await store.addPending('agent-idem');
      await store.addPending('agent-idem');
      expect(store.getPending(), equals(['agent-idem']));
    });

    test('removePending removes agent from queue', () async {
      await store.addPending('agent-r1');
      await store.addPending('agent-r2');
      await store.removePending('agent-r1');
      expect(store.getPending(), equals(['agent-r2']));
    });

    test('clearPending removes all', () async {
      await store.addPending('agent-1');
      await store.addPending('agent-2');
      await store.clearPending();
      expect(store.getPending(), isEmpty);
    });
  });
}

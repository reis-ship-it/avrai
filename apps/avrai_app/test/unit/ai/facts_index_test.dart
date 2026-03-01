/// Unit tests for FactsIndex (RAG Phase 1: local-first, offline).
///
/// Verifies index/retrieve/sync behavior with local store only; no Supabase.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/ai/facts_local_store.dart';
import 'package:avrai_runtime_os/ai/structured_facts.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([Connectivity, AgentIdService, SupabaseClient])
import 'facts_index_test.mocks.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('FactsIndex (local-first, offline)', () {
    late FactsIndex index;
    late FactsLocalStore localStore;
    late MockConnectivity mockConnectivity;
    late MockAgentIdService mockAgentId;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      localStore = FactsLocalStore();
      mockConnectivity = MockConnectivity();
      mockAgentId = MockAgentIdService();
      mockSupabase = MockSupabaseClient();
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(mockAgentId.getUserAgentId(any)).thenAnswer((i) async {
        final u = i.positionalArguments.first as String;
        return 'agent-$u';
      });
      index = FactsIndex(
        supabase: mockSupabase,
        agentIdService: mockAgentId,
        localStore: localStore,
        connectivity: mockConnectivity,
      );
    });

    test('indexFacts writes locally and does not call Supabase when offline',
        () async {
      const uid = 'user-index-retrieve';
      final facts = StructuredFacts(
        traits: ['prefers_coffee'],
        places: ['place-1'],
        socialGraph: [],
        timestamp: DateTime.now(),
      );
      await index.indexFacts(userId: uid, facts: facts);
      final got = await index.retrieveFacts(userId: uid);
      expect(got.traits, equals(['prefers_coffee']));
      expect(got.places, equals(['place-1']));
      verifyNever(mockSupabase.from(any));
    });

    test('retrieveFacts returns empty when no facts stored', () async {
      const uid = 'user-empty';
      final got = await index.retrieveFacts(userId: uid);
      expect(got.traits, isEmpty);
      expect(got.places, isEmpty);
      expect(got.socialGraph, isEmpty);
    });

    test('retrieveFacts returns merged facts after multiple indexFacts',
        () async {
      const uid = 'user-merge';
      await index.indexFacts(
        userId: uid,
        facts: StructuredFacts(
          traits: ['a'],
          places: [],
          socialGraph: [],
          timestamp: DateTime.now(),
        ),
      );
      await index.indexFacts(
        userId: uid,
        facts: StructuredFacts(
          traits: ['b'],
          places: ['p1'],
          socialGraph: ['e1'],
          timestamp: DateTime.now(),
        ),
      );
      final got = await index.retrieveFacts(userId: uid);
      expect(got.traits, containsAll(['a', 'b']));
      expect(got.places, equals(['p1']));
      expect(got.socialGraph, equals(['e1']));
    });

    test('syncToCloud is no-op when offline', () async {
      const uid = 'user-sync';
      await index.indexFacts(
        userId: uid,
        facts: StructuredFacts(
          traits: ['x'],
          places: [],
          socialGraph: [],
          timestamp: DateTime.now(),
        ),
      );
      await index.syncToCloud();
      expect(localStore.getPending(), isNotEmpty);
      verifyNever(mockSupabase.from(any));
    });

    test('clearFacts removes local facts and pending', () async {
      const uid = 'user-clear';
      await index.indexFacts(
        userId: uid,
        facts: StructuredFacts(
          traits: ['x'],
          places: [],
          socialGraph: [],
          timestamp: DateTime.now(),
        ),
      );
      expect(localStore.getPending(), contains('agent-$uid'));
      await index.clearFacts(userId: uid);
      final got = await index.retrieveFacts(userId: uid);
      expect(got.traits, isEmpty);
      expect(localStore.getPending(), isNot(contains('agent-$uid')));
    });
  });
}

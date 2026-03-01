/// Integration test: FactsIndex local-only path (Supabase unavailable).
///
/// Verifies that when offline / Supabase unavailable, index and retrieve
/// use local store only and still serve facts.
///
/// RAG Phase 1: offline-first facts.
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
import 'facts_index_local_only_integration_test.mocks.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('FactsIndex local-only integration', () {
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

    test('index and retrieve work from local only when offline', () async {
      const uid = 'user-local-only';
      final facts = StructuredFacts(
        traits: ['prefers_coffee', 'explorer'],
        places: ['place-1', 'place-2'],
        socialGraph: ['event-1'],
        timestamp: DateTime.now(),
      );
      await index.indexFacts(userId: uid, facts: facts);
      final got = await index.retrieveFacts(userId: uid);
      expect(got.traits, containsAll(['prefers_coffee', 'explorer']));
      expect(got.places, containsAll(['place-1', 'place-2']));
      expect(got.socialGraph, equals(['event-1']));
      verifyNever(mockSupabase.from(any));
    });
  });
}

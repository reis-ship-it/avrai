/// Unit tests for FactsIndex (RAG Phase 1: local-first, offline).
///
/// Verifies index/retrieve/sync behavior with local store only; no Supabase.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/core/ai/facts_local_store.dart';
import 'package:avrai/core/ai/semantic_memory_local_store.dart';
import 'package:avrai/core/ai/semantic_memory_schema.dart';
import 'package:avrai/core/ai/structured_facts.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
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
    late SemanticMemoryLocalStore semanticLocalStore;
    late MockConnectivity mockConnectivity;
    late MockAgentIdService mockAgentId;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      localStore = FactsLocalStore();
      semanticLocalStore = SemanticMemoryLocalStore();
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
        semanticLocalStore: semanticLocalStore,
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

    test('semantic nearest-neighbor retrieval ranks by embedding similarity',
        () async {
      const uid = 'user-semantic';
      final createdAt = DateTime.utc(2026, 2, 19, 12, 0, 0);

      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-1',
          agentId: '',
          embedding: const [1.0, 0.0],
          generalization: 'User prefers curated jazz spots.',
          evidenceCount: 2,
          confidence: 0.8,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-2',
          agentId: '',
          embedding: const [0.9, 0.1],
          generalization: 'Late-night social preference.',
          evidenceCount: 3,
          confidence: 0.7,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-3',
          agentId: '',
          embedding: const [0.0, 1.0],
          generalization: 'Morning quiet venues.',
          evidenceCount: 1,
          confidence: 0.5,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final nearest = await index.retrieveSemanticNearest(
        userId: uid,
        queryEmbedding: const [1.0, 0.0],
        topK: 2,
      );

      expect(nearest, hasLength(2));
      expect(nearest.first.entry.id, 'sem-1');
      expect(nearest[1].entry.id, 'sem-2');
      expect(nearest.first.similarity, greaterThan(nearest[1].similarity));
      verifyNever(mockSupabase.from(any));
    });

    test('semantic context query re-ranks by activity/time/location', () async {
      const uid = 'user-semantic-context';
      final createdAt = DateTime.utc(2026, 2, 19, 12, 0, 0);

      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-evening-food',
          agentId: '',
          embedding: const [0.95, 0.05],
          generalization:
              'User tends to prefer `dine` in `restaurant` contexts during `evening` windows on weekend.',
          evidenceCount: 6,
          confidence: 0.8,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-morning-food',
          agentId: '',
          embedding: const [0.99, 0.01],
          generalization:
              'User tends to prefer `dine` in `restaurant` contexts during `morning` windows.',
          evidenceCount: 8,
          confidence: 0.8,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-evening-downtown',
          agentId: '',
          embedding: const [0.9, 0.1],
          generalization:
              'User tends to prefer `browse` around downtown arts district during `evening` windows.',
          evidenceCount: 5,
          confidence: 0.7,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final matches = await index.querySemanticMemoryByContext(
        userId: uid,
        context: SemanticQueryContext(
          queryEmbedding: [1.0, 0.0],
          occursAt: DateTime.utc(2026, 2, 21, 20, 30), // Saturday evening
          location: 'downtown arts district',
          activityType: 'restaurant dining',
          topK: 2,
        ),
      );

      expect(matches, hasLength(2));
      expect(matches.first.entry.id, isNot('sem-morning-food'));
      expect(matches.first.contextRelevance, greaterThan(0.3));
      expect(matches.first.score, greaterThan(matches[1].score));
    });

    test('semantic context query honors minConfidence filter', () async {
      const uid = 'user-semantic-confidence';
      final createdAt = DateTime.utc(2026, 2, 19, 12, 0, 0);

      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-high-confidence',
          agentId: '',
          embedding: const [1.0, 0.0],
          generalization: 'High-confidence preference for evening dining.',
          evidenceCount: 10,
          confidence: 0.9,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await index.indexSemanticMemory(
        userId: uid,
        entry: SemanticMemoryEntry(
          id: 'sem-low-confidence',
          agentId: '',
          embedding: const [1.0, 0.0],
          generalization: 'Low-confidence preference for evening dining.',
          evidenceCount: 1,
          confidence: 0.2,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final matches = await index.querySemanticMemoryByContext(
        userId: uid,
        context: const SemanticQueryContext(
          queryEmbedding: [1.0, 0.0],
          activityType: 'dining',
          topK: 5,
          minConfidence: 0.5,
        ),
      );

      expect(matches.map((m) => m.entry.id), contains('sem-high-confidence'));
      expect(
        matches.map((m) => m.entry.id),
        isNot(contains('sem-low-confidence')),
      );
    });
  });
}

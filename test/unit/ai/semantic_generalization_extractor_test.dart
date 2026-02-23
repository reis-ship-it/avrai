import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/semantic_generalization_extractor.dart';
import 'package:avrai/core/ai/semantic_memory_local_store.dart';
import 'package:avrai/core/ai/semantic_memory_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('SemanticGeneralizationExtractor', () {
    late EpisodicMemoryStore episodicStore;
    late SemanticGeneralizationExtractor extractor;
    late SemanticMemoryLocalStore semanticStore;

    setUp(() async {
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      semanticStore = SemanticMemoryLocalStore();
      await semanticStore.remove('agent-1');
      await semanticStore.remove('agent-2');
      await semanticStore.removePending('agent-1');
      await semanticStore.removePending('agent-2');
      extractor = SemanticGeneralizationExtractor(
        semanticLocalStore: semanticStore,
      );
    });

    test('clusters recurring tuples into compressed semantic entries',
        () async {
      final now = DateTime.utc(2026, 2, 19, 19, 0, 0);
      Future<void> addTuple({
        required String action,
        required String category,
        required double outcome,
        required DateTime recordedAt,
      }) {
        return episodicStore.writeTuple(
          EpisodicTuple(
            agentId: 'agent-1',
            stateBefore: {'entity_category': category},
            actionType: action,
            actionPayload: {'category': category},
            nextState: const {},
            outcome: OutcomeSignal(
              type: '${action}_outcome',
              category: OutcomeCategory.binary,
              value: outcome,
            ),
            recordedAt: recordedAt,
          ),
        );
      }

      await addTuple(
        action: 'visit_spot',
        category: 'jazz',
        outcome: 0.9,
        recordedAt: now,
      );
      await addTuple(
        action: 'visit_spot',
        category: 'jazz',
        outcome: 0.8,
        recordedAt: now.add(const Duration(hours: 1)),
      );
      await addTuple(
        action: 'visit_spot',
        category: 'jazz',
        outcome: 0.7,
        recordedAt: now.add(const Duration(hours: 2)),
      );

      final entries = await extractor.extractGeneralizations(
        agentId: 'agent-1',
        episodicMemoryStore: episodicStore,
        minClusterSize: 2,
      );

      expect(entries, isNotEmpty);
      final jazzEntry = entries.firstWhere(
        (entry) => entry.generalization.contains('visit_spot'),
      );
      expect(jazzEntry.evidenceCount, 3);
      expect(jazzEntry.embedding, hasLength(6));
      expect(jazzEntry.confidence, greaterThan(0.0));
      expect(jazzEntry.generalization, contains('jazz'));
    });

    test('filters out clusters below minClusterSize', () async {
      await episodicStore.writeTuple(
        EpisodicTuple(
          agentId: 'agent-2',
          stateBefore: const {'entity_category': 'coffee'},
          actionType: 'visit_spot',
          actionPayload: const {'category': 'coffee'},
          nextState: const {},
          outcome: const OutcomeSignal(
            type: 'visit_spot_outcome',
            category: OutcomeCategory.binary,
            value: 1.0,
          ),
          recordedAt: DateTime.utc(2026, 2, 19, 8, 0, 0),
        ),
      );

      final entries = await extractor.extractGeneralizations(
        agentId: 'agent-2',
        episodicMemoryStore: episodicStore,
        minClusterSize: 2,
      );

      expect(entries, isEmpty);
    });

    test('merges with existing semantic entry evidence instead of replacing',
        () async {
      final now = DateTime.utc(2026, 2, 19, 20, 0, 0);
      final localHour = now.toLocal().hour;
      final dayPart = localHour < 6
          ? 'night'
          : localHour < 12
              ? 'morning'
              : localHour < 18
                  ? 'afternoon'
                  : 'evening';
      final digest = sha256.convert(
        utf8.encode('agent-1::visit_spot|jazz|$dayPart'),
      );
      final seedEntry = SemanticMemoryEntry(
        id: 'semgen-${digest.toString().substring(0, 16)}',
        agentId: 'agent-1',
        embedding: const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
        generalization: 'Seed generalization.',
        evidenceCount: 5,
        confidence: 0.5,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );
      await semanticStore.upsert('agent-1', seedEntry);

      Future<void> addTuple({
        required double outcome,
        required DateTime recordedAt,
      }) {
        return episodicStore.writeTuple(
          EpisodicTuple(
            agentId: 'agent-1',
            stateBefore: const {'entity_category': 'jazz'},
            actionType: 'visit_spot',
            actionPayload: const {'category': 'jazz'},
            nextState: const {},
            outcome: OutcomeSignal(
              type: 'visit_spot_outcome',
              category: OutcomeCategory.binary,
              value: outcome,
            ),
            recordedAt: recordedAt,
          ),
        );
      }

      await addTuple(outcome: 0.9, recordedAt: now);
      await addTuple(
          outcome: 0.8, recordedAt: now.add(const Duration(hours: 1)));
      await addTuple(
          outcome: 0.85, recordedAt: now.add(const Duration(hours: 2)));

      final entries = await extractor.extractGeneralizations(
        agentId: 'agent-1',
        episodicMemoryStore: episodicStore,
        minClusterSize: 2,
      );

      expect(entries, hasLength(1));
      expect(entries.first.evidenceCount, 8); // 5 existing + 3 new
      expect(entries.first.confidence, greaterThan(0.5));
      final stored = await semanticStore.getAll('agent-1');
      expect(stored, hasLength(1));
      expect(stored.first.evidenceCount, 8);
      expect(semanticStore.getPending(), contains('agent-1'));
    });
  });
}

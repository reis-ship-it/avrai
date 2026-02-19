import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/semantic_generalization_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticGeneralizationExtractor', () {
    late EpisodicMemoryStore episodicStore;
    late SemanticGeneralizationExtractor extractor;

    setUp(() async {
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      extractor = const SemanticGeneralizationExtractor();
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
  });
}

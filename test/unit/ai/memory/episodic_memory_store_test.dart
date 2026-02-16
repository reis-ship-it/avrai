import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpisodicMemoryStore', () {
    late EpisodicMemoryStore store;

    setUp(() async {
      store = EpisodicMemoryStore();
      await store.clearForTesting();
    });

    test('keeps schema consistent for new tuples', () async {
      final tuple = EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {'dim_a': 0.2},
        actionType: 'spot_visited',
        actionPayload: const {'spot_id': 's1'},
        nextState: const {'dim_a': 0.25},
        outcome: const OutcomeSignal(
          type: 'spot_visited',
          category: OutcomeCategory.binary,
          value: 1.0,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 10, 0, 0),
      );

      expect(tuple.schemaVersion, EpisodicTuple.currentSchemaVersion);
      final written = await store.writeTuple(tuple);
      expect(written.inserted, isTrue);
      expect(await store.count(agentId: 'agent-1'), 1);
    });

    test('deduplicates identical tuple hashes', () async {
      final tuple = EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {'state': 'before'},
        actionType: 'recommendation_rejected',
        actionPayload: const {'entity_id': 'e1'},
        nextState: const {'state': 'after'},
        outcome: const OutcomeSignal(
          type: 'recommendation_rejected',
          category: OutcomeCategory.binary,
          value: 0.0,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 10, 5, 0),
      );

      final first = await store.writeTuple(tuple);
      final second = await store.writeTuple(tuple);

      expect(first.inserted, isTrue);
      expect(second.inserted, isFalse);
      expect(await store.count(agentId: 'agent-1'), 1);
    });

    test('replay returns oldest to newest ordering', () async {
      final t1 = EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {'x': 1},
        actionType: 'a1',
        actionPayload: const {},
        nextState: const {'x': 2},
        outcome: const OutcomeSignal(
          type: 'a1',
          category: OutcomeCategory.behavioral,
          value: 0.1,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 9, 0, 0),
      );
      final t2 = EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {'x': 2},
        actionType: 'a2',
        actionPayload: const {},
        nextState: const {'x': 3},
        outcome: const OutcomeSignal(
          type: 'a2',
          category: OutcomeCategory.behavioral,
          value: 0.2,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 9, 5, 0),
      );
      final t3 = EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {'x': 3},
        actionType: 'a3',
        actionPayload: const {},
        nextState: const {'x': 4},
        outcome: const OutcomeSignal(
          type: 'a3',
          category: OutcomeCategory.behavioral,
          value: 0.3,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 9, 10, 0),
      );

      await store.writeTuple(t2);
      await store.writeTuple(t3);
      await store.writeTuple(t1);

      final replay = await store.replay(agentId: 'agent-1');
      expect(replay.map((t) => t.actionType).toList(), ['a1', 'a2', 'a3']);
    });

    test('replayWindow returns only tuples in range', () async {
      final start = DateTime.utc(2026, 2, 16, 9, 0, 0);
      final end = DateTime.utc(2026, 2, 16, 10, 0, 0);
      await store.writeTuple(EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {},
        actionType: 'in-window',
        actionPayload: const {},
        nextState: const {},
        outcome: const OutcomeSignal(
          type: 'in-window',
          category: OutcomeCategory.behavioral,
          value: 0.5,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 9, 30, 0),
      ));
      await store.writeTuple(EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {},
        actionType: 'out-of-window',
        actionPayload: const {},
        nextState: const {},
        outcome: const OutcomeSignal(
          type: 'out-of-window',
          category: OutcomeCategory.behavioral,
          value: 0.5,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 10, 30, 0),
      ));

      final replay = await store.replayWindow(
        agentId: 'agent-1',
        windowStartInclusive: start,
        windowEndExclusive: end,
      );
      expect(replay, hasLength(1));
      expect(replay.first.actionType, 'in-window');
    });

    test('queryRelevant filters by action and minimum outcome', () async {
      await store.writeTuple(EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {},
        actionType: 'spot_visited',
        actionPayload: const {},
        nextState: const {},
        outcome: const OutcomeSignal(
          type: 'spot_visited',
          category: OutcomeCategory.binary,
          value: 1.0,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 8, 0, 0),
      ));
      await store.writeTuple(EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {},
        actionType: 'spot_visited',
        actionPayload: const {},
        nextState: const {},
        outcome: const OutcomeSignal(
          type: 'spot_visited',
          category: OutcomeCategory.binary,
          value: 0.0,
        ),
        recordedAt: DateTime.utc(2026, 2, 16, 8, 5, 0),
      ));

      final rows = await store.queryRelevant(
        agentId: 'agent-1',
        actionType: 'spot_visited',
        minOutcomeValue: 0.5,
      );
      expect(rows, hasLength(1));
      expect(rows.first.outcome.value, 1.0);
    });
  });

  group('OutcomeTaxonomy', () {
    test('classifies quality outcomes', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'feedback_rating',
        parameters: const {'rating': 4},
      );
      expect(signal.category, OutcomeCategory.quality);
      expect(signal.value, 4.0);
    });

    test('classifies community_join as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'community_join',
        parameters: const {'community_id': 'community-1'},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies event_attend as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'event_attend',
        parameters: const {'event_id': 'event-1'},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies create_list as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'create_list',
        parameters: const {'item_count': 2},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies modify_list as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'modify_list',
        parameters: const {'delta_count': 1},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies share_list as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'share_list',
        parameters: const {'success_count': 0},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies actual_action_succeeded as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'actual_action_succeeded',
        parameters: const {'actual_action_type': 'create_spot'},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies actual_action_failed as binary negative outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'actual_action_failed',
        parameters: const {'actual_action_type': 'create_spot'},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 0.0);
    });

    test('classifies single_visit_only as neutral behavioral outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'single_visit_only',
        parameters: const {'spot_id': 'spot-1'},
      );
      expect(signal.category, OutcomeCategory.behavioral);
      expect(signal.value, 0.5);
    });

    test('classifies no_action as behavioral exploration outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'no_action',
        parameters: const {'entity_type': 'spot'},
      );
      expect(signal.category, OutcomeCategory.behavioral);
      expect(signal.value, 0.0);
    });

    test('classifies attend_expert_event_feedback as quality outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'attend_expert_event_feedback',
        parameters: const {'overall_rating': 4.6},
      );
      expect(signal.category, OutcomeCategory.quality);
      expect(signal.value, 4.6);
    });

    test('classifies sponsor_event as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'sponsor_event',
        parameters: const {'sponsorship_id': 'sp-1'},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies sponsorship_outcome_recorded as quality outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'sponsorship_outcome_recorded',
        parameters: const {'overall_rating': 4.1},
      );
      expect(signal.category, OutcomeCategory.quality);
      expect(signal.value, 4.1);
    });

    test('classifies form_partnership as binary positive outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'form_partnership',
        parameters: const {'partnership_id': 'pt-1'},
      );
      expect(signal.category, OutcomeCategory.binary);
      expect(signal.value, 1.0);
    });

    test('classifies partnership_outcome_recorded as quality outcome', () {
      final taxonomy = const OutcomeTaxonomy();
      final signal = taxonomy.classify(
        eventType: 'partnership_outcome_recorded',
        parameters: const {'overall_rating': 4.3},
      );
      expect(signal.category, OutcomeCategory.quality);
      expect(signal.value, 4.3);
    });
  });
}

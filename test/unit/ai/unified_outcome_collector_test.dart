import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/unified_outcome_collector.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnifiedOutcomeCollector', () {
    late EpisodicMemoryStore store;
    late UnifiedOutcomeCollector collector;

    setUp(() async {
      store = EpisodicMemoryStore();
      await store.clearForTesting();
      collector = UnifiedOutcomeCollector(
        episodicMemoryStore: store,
        agentIdService: AgentIdService(),
      );
    });

    test('writes binary outcome tuples for attended actions', () async {
      final tuple = await collector.collect(
        userId: 'user-1',
        eventType: 'attend_event',
        entityType: 'event',
        entityId: 'event-101',
        stateBefore: const {'session': 's-1'},
        actionPayload: const {'source': 'recommendation'},
        nextState: const {'status': 'checked_in'},
      );

      expect(tuple, isNotNull);
      final stored = (await store.replay(agentId: tuple!.agentId)).single;
      expect(stored.actionType, 'attend_event');
      expect(stored.actionPayload['entity_type'], 'event');
      expect(stored.actionPayload['entity_id'], 'event-101');
      expect(stored.metadata['pipeline'], 'unified_outcome_collector');
      expect(stored.outcome.category, OutcomeCategory.binary);
      expect(stored.outcome.value, 1.0);
    });

    test('writes behavioral no-action outcome for browse events', () async {
      final tuple = await collector.collect(
        userId: 'user-2',
        eventType: 'browse_entity',
        entityType: 'spot',
        entityId: 'spot-7',
        outcomeParameters: const {'no_action': true},
      );

      expect(tuple, isNotNull);
      final stored = (await store.replay(agentId: tuple!.agentId)).single;
      expect(stored.actionType, 'browse_entity');
      expect(stored.outcome.type, 'no_action');
      expect(stored.outcome.category, OutcomeCategory.behavioral);
      expect(stored.outcome.value, 0.0);
      expect(stored.outcome.metadata['entity_type'], 'spot');
      expect(stored.outcome.metadata['entity_id'], 'spot-7');
    });
  });
}

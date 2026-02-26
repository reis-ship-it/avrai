library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.16 discoverability feedback', () {
    late ContinuousLearningSystem learningSystem;
    late EpisodicMemoryStore episodicStore;

    setUp(() async {
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      learningSystem = ContinuousLearningSystem(
        agentIdService: AgentIdService(),
        episodicMemoryStore: episodicStore,
        supabase: null,
      );
    });

    test('records explicit show-everything category override', () async {
      await learningSystem.processUserInteraction(
        userId: 'discover-user-1',
        payload: {
          'event_type': 'discoverability_show_everything_category',
          'parameters': {
            'category': 'Nightlife',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 12);
      final overrideTuple = tuples.firstWhere(
        (row) => row.actionType == 'discoverability_override_enabled',
      );
      expect(overrideTuple.metadata['phase_ref'], equals('1.4.16'));
      expect(overrideTuple.actionPayload['scope'], equals('category'));

      final agentId = tuples.first.agentId;
      final state = learningSystem.getDiscoverabilityOverrideStateForAgent(
        agentId,
      );
      expect(
        (state['category_overrides'] as List<dynamic>).contains('nightlife'),
        isTrue,
      );
    });

    test(
        'logs guardrail violation when personalization suppresses overridden category',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'discover-user-2',
        payload: {
          'event_type': 'discoverability_show_everything_category',
          'parameters': {'category': 'food'},
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'discover-user-2',
        payload: {
          'event_type': 'discoverability_personalization_suppressed',
          'parameters': {
            'category': 'food',
            'suppression_reason': 'ranking',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 24);
      final hasViolation = tuples.any(
        (row) => row.actionType == 'discoverability_guardrail_violation',
      );
      expect(hasViolation, isTrue);
    });

    test('does not log violation for legal/safety/privacy suppression',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'discover-user-3',
        payload: {
          'event_type': 'discoverability_show_everything_area',
          'parameters': const {},
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'discover-user-3',
        payload: {
          'event_type': 'discoverability_personalization_suppressed',
          'parameters': {
            'suppression_reason': 'safety',
          },
          'context': const {},
        },
      );

      final tuples = await episodicStore.getRecent(limit: 24);
      final hasViolation = tuples.any(
        (row) => row.actionType == 'discoverability_guardrail_violation',
      );
      expect(hasViolation, isFalse);
    });
  });
}

library;

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem 1.4.12 bad-day dampening', () {
    late ContinuousLearningSystem learningSystem;
    late EpisodicMemoryStore episodicStore;

    setUp(() {
      episodicStore = EpisodicMemoryStore();
      learningSystem = ContinuousLearningSystem(
        agentIdService: AgentIdService(),
        episodicMemoryStore: episodicStore,
        supabase: null,
      );
    });

    test('detects bad-day candidate after 3 negative signals in one session',
        () async {
      for (var i = 0; i < 3; i++) {
        await learningSystem.processUserInteraction(
          userId: 'bad-day-user-1',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'entity_type': 'event',
              'category': 'nightlife',
              'session_id': 'session-a',
            },
            'context': const {},
          },
        );
      }

      final rows = await episodicStore.getRecent(limit: 40);
      final detectedTuple = rows.firstWhere(
        (row) => row.actionType == 'bad_day_session_detected',
      );
      final payload = detectedTuple.actionPayload;
      final state = detectedTuple.nextState;
      expect(payload['session_key'], equals('session-a'));
      expect(payload['negative_signal_count'], equals(3));
      expect(payload['candidate_dampening_factor'], equals(0.5));
      expect(state['bad_day_candidate'], isTrue);
      expect(state['awaiting_next_session_validation'], isTrue);
    });

    test('applies retroactive dampening when next session normalizes behavior',
        () async {
      for (var i = 0; i < 3; i++) {
        await learningSystem.processUserInteraction(
          userId: 'bad-day-user-2',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'entity_type': 'spot',
              'category': 'coffee',
              'session_id': 'session-a',
            },
            'context': const {},
          },
        );
      }

      await learningSystem.processUserInteraction(
        userId: 'bad-day-user-2',
        payload: {
          'event_type': 'save_spot',
          'parameters': {
            'entity_type': 'spot',
            'category': 'coffee',
            'session_id': 'session-b',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 80);
      final dampeningTuple = rows.firstWhere(
        (row) => row.actionType == 'bad_day_retroactive_dampening',
      );
      final payload = dampeningTuple.actionPayload;
      final state = dampeningTuple.nextState;
      expect(payload['source_session'], equals('session-a'));
      expect(payload['evaluation_session'], equals('session-b'));
      expect(payload['retroactive_dampening_factor'], equals(0.5));
      expect(state['retroactive_dampening_applied'], isTrue);
      expect(state['session_pattern_normalized'], isTrue);
    });

    test('withholds dampening when next session stays negative', () async {
      for (var i = 0; i < 3; i++) {
        await learningSystem.processUserInteraction(
          userId: 'bad-day-user-3',
          payload: {
            'event_type': 'recommendation_rejected',
            'parameters': {
              'entity_type': 'community',
              'category': 'clubs',
              'session_id': 'session-a',
            },
            'context': const {},
          },
        );
      }

      await learningSystem.processUserInteraction(
        userId: 'bad-day-user-3',
        payload: {
          'event_type': 'recommendation_rejected',
          'parameters': {
            'entity_type': 'community',
            'category': 'clubs',
            'session_id': 'session-b',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 80);
      final withheldTuple = rows.firstWhere(
        (row) => row.actionType == 'bad_day_dampening_withheld',
      );
      final payload = withheldTuple.actionPayload;
      final state = withheldTuple.nextState;
      expect(payload['source_session'], equals('session-a'));
      expect(payload['evaluation_session'], equals('session-b'));
      expect(
        payload['reason'],
        equals('negative_pattern_continued_across_sessions_treat_as_genuine'),
      );
      expect(state['retroactive_dampening_applied'], isFalse);
      expect(state['treat_as_genuine_taste_shift'], isTrue);
    });
  });
}

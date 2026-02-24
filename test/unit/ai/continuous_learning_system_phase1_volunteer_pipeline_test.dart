import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem phase 1 volunteer pipeline', () {
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

    test('captures signup and attendance with positive social weighting',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-volunteer-user',
        payload: {
          'event_type': 'volunteer_signup',
          'parameters': {
            'entity_type': 'community',
            'entity_id': 'community-1',
          },
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'phase1-volunteer-user',
        payload: {
          'event_type': 'volunteer_attend',
          'parameters': {
            'entity_type': 'event',
            'entity_id': 'event-1',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 8);
      final signup = rows.firstWhere((r) => r.actionType == 'volunteer_signup');
      final attend = rows.firstWhere((r) => r.actionType == 'volunteer_attend');

      expect(signup.actionPayload['positive_social_weight'], 1.25);
      expect(attend.actionPayload['positive_social_weight'], 1.35);
      expect(signup.outcome.value, 1.0);
      expect(attend.outcome.value, 1.0);
    });

    test('captures delayed 30/90-day retention and dropoff outcomes', () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-volunteer-user',
        payload: {
          'event_type': 'volunteer_retention',
          'parameters': {
            'entity_type': 'business',
            'entity_id': 'business-1',
            'impact_window_days': 90,
            'days': 90,
          },
          'context': const {},
        },
      );
      await learningSystem.processUserInteraction(
        userId: 'phase1-volunteer-user',
        payload: {
          'event_type': 'volunteer_dropoff',
          'parameters': {
            'entity_type': 'community',
            'entity_id': 'community-1',
            'impact_window_days': 30,
            'days': 30,
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 8);
      final retention =
          rows.firstWhere((r) => r.actionType == 'volunteer_retention');
      final dropoff =
          rows.firstWhere((r) => r.actionType == 'volunteer_dropoff');

      expect(retention.outcome.category.name, 'temporal');
      expect(retention.outcome.value, 90);
      expect(retention.actionPayload['impact_window_days'], 90);
      expect(dropoff.outcome.category.name, 'behavioral');
      expect(dropoff.outcome.value, -1.0);
      expect(dropoff.actionPayload['impact_window_days'], 30);
    });
  });
}

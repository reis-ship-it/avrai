import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem phase 1 physiology channel', () {
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

    test('zero-fills physiology features when consent is absent', () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'wearable_context_signal',
          'parameters': {
            'context_signal': 'resting_state_shift',
            'physiology_features': {
              'resting_heart_rate_trend': 0.8,
              'sleep_quality_rolling_avg': 0.6,
            },
            'wearable_consent_granted': false,
            'downstream_outcome': 'no_action',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 4);
      final tuple = rows.firstWhere(
        (r) => r.metadata['phase_ref'] == '1.2.27',
      );
      expect(tuple.actionType, 'context_signal');
      expect(
        tuple.actionPayload['physiology_features']['resting_heart_rate_trend'],
        0.0,
      );
      expect(tuple.nextState['consent_granted'], false);
    });

    test('keeps provided physiology features when consent is granted',
        () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'wearable_context_signal',
          'parameters': {
            'context_signal': 'fatigue_window',
            'physiology_features': {
              'resting_heart_rate_trend': 0.4,
              'sleep_quality_rolling_avg': 0.7,
              'activity_level_steps_per_day': 0.5,
            },
            'wearable_consent_granted': true,
            'downstream_outcome': 'event_attended',
          },
          'context': const {},
        },
      );

      final rows = await episodicStore.getRecent(limit: 4);
      final tuple = rows.firstWhere(
        (r) => r.metadata['phase_ref'] == '1.2.27',
      );
      expect(
        tuple.actionPayload['physiology_features']['sleep_quality_rolling_avg'],
        0.7,
      );
      expect(tuple.nextState['consent_granted'], true);
      expect(tuple.outcome.type, 'event_attended');
    });
  });
}

import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContinuousLearningSystem phase 1 nearby invite funnel', () {
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

    test('records privacy-minimal tuple when consent is absent', () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'invite_sent',
          'parameters': {
            'nearby_telemetry_consent_granted': false,
            'platform': 'ios',
            'transport': 'ble',
            'invitee_device_id': 'device-123',
            'install_link': 'https://example.com/install',
          },
          'context': const {'surface': 'nearby_share_sheet'},
        },
      );

      final rows = await episodicStore.getRecent(limit: 8);
      final tuple = rows.firstWhere((r) => r.metadata['phase_ref'] == '1.2.29');
      expect(tuple.actionType, 'nearby_invite_install_funnel');
      expect(tuple.actionPayload['event_type'], 'invite_sent');
      expect(tuple.actionPayload['consent_granted'], false);
      expect(tuple.actionPayload['privacy_mode'], 'minimal');
      expect(tuple.actionPayload.containsKey('invitee_device_id'), false);
      expect(tuple.actionPayload.containsKey('install_link'), false);
    });

    test('records activated stage with consent-safe outcome', () async {
      await learningSystem.processUserInteraction(
        userId: 'phase1-user',
        payload: {
          'event_type': 'first_action_after_install',
          'parameters': {
            'nearby_telemetry_consent_granted': true,
            'platform': 'android',
            'transport': 'wifi_direct',
            'first_action_type': 'create_list',
            'activation_latency_seconds': 12,
            'new_user_id': 'user-raw-identifier',
          },
          'context': const {'surface': 'nearby_invite_qr'},
        },
      );

      final rows = await episodicStore.getRecent(limit: 8);
      final tuple = rows.firstWhere((r) => r.metadata['phase_ref'] == '1.2.29');
      expect(tuple.actionPayload['funnel_stage'], 'activated');
      expect(tuple.nextState['funnel_completed'], true);
      expect(tuple.outcome.type, 'first_action_after_install');
      expect(tuple.outcome.value, 1.0);
      expect(tuple.actionPayload.containsKey('new_user_id'), false);
      expect(tuple.actionPayload['first_action_type'], 'create_list');
    });
  });
}

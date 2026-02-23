import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/business/business_expert_outreach_service.dart';
import 'package:avrai/core/models/business/business_expert_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessExpertOutreachService', () {
    test('writes initiate_outreach tuple with chat_started outcome', () async {
      final episodicStore = EpisodicMemoryStore();
      var wasSendCalled = false;

      final service = BusinessExpertOutreachService(
        episodicMemoryStore: episodicStore,
        sendMessageOverride: ({
          required String businessId,
          required String expertId,
          required String content,
          required MessageSenderType senderType,
          required MessageType messageType,
        }) async {
          wasSendCalled = true;
          expect(businessId, equals('business-123'));
          expect(expertId, equals('expert-456'));
          expect(content, equals('Interested in partnering on events.'));
          expect(senderType, equals(MessageSenderType.business));
          expect(messageType, equals(MessageType.text));
        },
      );

      final ok = await service.sendOutreach(
        businessId: 'business-123',
        expertId: 'expert-456',
        message: 'Interested in partnering on events.',
        subject: 'Coffee collab',
      );

      expect(ok, isTrue);
      expect(wasSendCalled, isTrue);

      final tuples = await episodicStore.getRecent(agentId: 'business-123');
      expect(tuples, hasLength(1));

      final tuple = tuples.first;
      expect(tuple.actionType, equals('initiate_outreach'));
      expect(tuple.outcome.type, equals('chat_started'));
      expect(tuple.stateBefore['phase_ref'], equals('1.2.23'));
      expect(tuple.actionPayload['expert_features']['expert_id'],
          equals('expert-456'));
      expect(
        tuple.nextState['chat_state']['chat_started'],
        isTrue,
      );
    });

    test('returns false when no chat transport is available', () async {
      final service = BusinessExpertOutreachService();
      final ok = await service.sendOutreach(
        businessId: 'business-123',
        expertId: 'expert-456',
        message: 'hello',
      );
      expect(ok, isFalse);
    });
  });
}

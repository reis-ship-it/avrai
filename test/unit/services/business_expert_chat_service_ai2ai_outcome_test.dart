library;

import 'dart:typed_data';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart' as ai2ai;
import 'package:avrai/core/models/business/business_expert_message.dart';
import 'package:avrai/core/services/business/business_expert_chat_service_ai2ai.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_storage_service.dart';

class _MockAgentIdService extends Mock implements AgentIdService {}

class _FakeEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.aes256gcm;

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(plaintext.codeUnits),
      encryptionType: EncryptionType.aes256gcm,
    );
  }

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return String.fromCharCodes(encrypted.encryptedContent);
  }
}

class _FakeProtocol extends ai2ai.AnonymousCommunicationProtocol {
  @override
  Future<ai2ai.AnonymousMessage> sendEncryptedMessage(
    String targetAgentId,
    ai2ai.MessageType messageType,
    Map<String, dynamic> anonymousPayload,
  ) async {
    return ai2ai.AnonymousMessage(
      messageId: 'msg-1',
      targetAgentId: targetAgentId,
      messageType: messageType,
      encryptedPayload: '{}',
      timestamp: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      routingHops: const [],
      privacyLevel: ai2ai.PrivacyLevel.maximum,
    );
  }
}

void main() {
  group('BusinessExpertChatServiceAI2AI outcome correlation', () {
    late _MockAgentIdService agentIdService;
    late EpisodicMemoryStore episodicStore;
    late BusinessExpertChatServiceAI2AI service;

    setUp(() {
      MockGetStorage.reset();
      agentIdService = _MockAgentIdService();
      episodicStore = EpisodicMemoryStore();

      when(() => agentIdService.getBusinessAgentId(any()))
          .thenAnswer((i) async => 'agent-biz-${i.positionalArguments.first}');
      when(() => agentIdService.getExpertAgentId(any()))
          .thenAnswer((i) async => 'agent-exp-${i.positionalArguments.first}');

      service = BusinessExpertChatServiceAI2AI(
        ai2aiProtocol: _FakeProtocol(),
        encryptionService: _FakeEncryptionService(),
        agentIdService: agentIdService,
        episodicMemoryStore: episodicStore,
        messageStorage:
            MockGetStorage.getInstance(boxName: 'business_expert_messages'),
        conversationStorage: MockGetStorage.getInstance(
            boxName: 'business_expert_conversations'),
      );
    });

    test('records partnership outcome correlation after chat', () async {
      await service.sendMessage(
        businessId: 'business-1',
        expertId: 'expert-1',
        content: 'Interested in a collab',
        senderType: MessageSenderType.business,
        messageType: MessageType.partnershipProposal,
        encrypt: false,
      );

      final recorded = await service.recordChatOutcomeCorrelation(
        businessId: 'business-1',
        expertId: 'expert-1',
        outcomeType: BusinessChatOutcomeType.partnership,
        outcomeContext: const {
          'partnership_id': 'partnership-1',
          'event_id': 'event-1',
        },
      );

      expect(recorded, isTrue);
      final tuples = await episodicStore.getRecent(agentId: 'business-1');
      final tuple = tuples.firstWhere(
        (t) => t.actionType == 'business_chat_outcome_correlation',
      );

      expect(tuple.outcome.type, equals('partnership_formed'));
      expect(tuple.actionPayload['outcome_type'], equals('partnership'));
      expect(tuple.nextState['journey_state'],
          equals('business_chat_to_partnership'));
      expect(tuple.nextState['chat_to_outcome_latency_ms'], isA<int>());
    });

    test('records event and reservation outcome mappings', () async {
      await service.sendMessage(
        businessId: 'business-2',
        expertId: 'expert-2',
        content: 'Let us plan details',
        senderType: MessageSenderType.business,
        encrypt: false,
      );

      final eventRecorded = await service.recordChatOutcomeCorrelation(
        businessId: 'business-2',
        expertId: 'expert-2',
        outcomeType: BusinessChatOutcomeType.event,
        outcomeContext: const {
          'event_id': 'event-2',
          'overall_rating': 4.3,
        },
      );
      final reservationRecorded = await service.recordChatOutcomeCorrelation(
        businessId: 'business-2',
        expertId: 'expert-2',
        outcomeType: BusinessChatOutcomeType.reservation,
        outcomeContext: const {
          'reservation_id': 'reservation-2',
        },
      );

      expect(eventRecorded, isTrue);
      expect(reservationRecorded, isTrue);

      final tuples = await episodicStore.getRecent(agentId: 'business-2');
      final eventTuple = tuples.firstWhere(
        (t) => t.nextState['journey_state'] == 'business_chat_to_event',
      );
      final reservationTuple = tuples.firstWhere(
        (t) => t.nextState['journey_state'] == 'business_chat_to_reservation',
      );

      expect(eventTuple.outcome.type, equals('event_outcome'));
      expect(reservationTuple.outcome.type, equals('create_reservation'));
    });

    test('returns false when no prior chat exists', () async {
      final recorded = await service.recordChatOutcomeCorrelation(
        businessId: 'business-missing',
        expertId: 'expert-missing',
        outcomeType: BusinessChatOutcomeType.partnership,
      );
      expect(recorded, isFalse);

      final tuples = await episodicStore.getRecent(agentId: 'business-missing');
      expect(tuples, isEmpty);
    });
  });
}

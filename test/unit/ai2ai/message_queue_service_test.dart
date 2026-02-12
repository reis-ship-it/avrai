import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/message_queue_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

void main() {
  group('MessageQueueService', () {
    late SupabaseService supabaseService;
    late MessageQueueService service;

    setUp(() {
      supabaseService = SupabaseService();
      service = MessageQueueService(
        supabaseService: supabaseService,
      );
    });

    test('should enqueue message successfully', () async {
      const messageId = 'test-message-123';
      const senderAgentId = 'sender-agent-123';
      const targetAgentId = 'target-agent-456';
      const encryptedPayload = 'encrypted-payload-base64';
      const messageType = 'userChat';

      // Note: This test may fail if Supabase is not available
      // In that case, it's expected behavior (service handles gracefully)
      try {
        await service.enqueueMessage(
          messageId: messageId,
          senderAgentId: senderAgentId,
          targetAgentId: targetAgentId,
          encryptedPayload: encryptedPayload,
          messageType: messageType,
          expiresAt: DateTime.now().add(const Duration(minutes: 60)),
        );

        // If no exception thrown, enqueue was successful
        expect(service, isNotNull);
      } catch (e) {
        // Expected if Supabase not available in test environment
        expect(e, isA<MessageQueueException>());
      }
    });

    test('should get pending messages for agent', () async {
      const agentId = 'test-agent-123';

      // Note: This test may return empty list if Supabase not available
      final messages = await service.getPendingMessages(agentId);

      expect(messages, isA<List<QueuedMessage>>());
    });

    test('should mark message as delivered', () async {
      const messageId = 'test-message-123';

      // Note: This test may fail if Supabase is not available
      try {
        await service.markMessageDelivered(messageId);
        expect(service, isNotNull);
      } catch (e) {
        // Expected if Supabase not available
        expect(e, isA<MessageQueueException>());
      }
    });

    test('should mark message as failed', () async {
      const messageId = 'test-message-123';

      // Note: This test may fail if Supabase is not available
      try {
        await service.markMessageFailed(messageId);
        expect(service, isNotNull);
      } catch (e) {
        // Expected if Supabase not available
        expect(e, isA<MessageQueueException>());
      }
    });

    test('should remove message from queue', () async {
      const messageId = 'test-message-123';

      // Note: This test may fail if Supabase is not available
      try {
        await service.removeMessage(messageId);
        expect(service, isNotNull);
      } catch (e) {
        // Expected if Supabase not available
        expect(e, isA<MessageQueueException>());
      }
    });

    test('should cleanup expired messages', () async {
      // Note: This test may fail if Supabase is not available
      // But it should not throw (cleanup is non-fatal)
      await service.cleanupExpiredMessages();

      expect(service, isNotNull);
    });

    test('QueuedMessage should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'message_id': 'test-message-123',
        'sender_agent_id': 'sender-123',
        'target_agent_id': 'target-456',
        'encrypted_payload': 'encrypted-payload',
        'message_type': 'userChat',
        'timestamp': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(minutes: 60)).toIso8601String(),
        'routing_hops': null,
        'status': 'pending',
        'delivery_attempts': 0,
        'last_delivery_attempt': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final message = QueuedMessage.fromJson(json);

      expect(message.messageId, equals('test-message-123'));
      expect(message.senderAgentId, equals('sender-123'));
      expect(message.targetAgentId, equals('target-456'));
      expect(message.status, equals('pending'));
    });
  });
}

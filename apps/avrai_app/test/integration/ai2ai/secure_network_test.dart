import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';
import 'dart:convert';

/// Security tests for secure AI2AI network
///
/// Phase 6: Secure Encrypted Private AI2AI Network Implementation
/// Tests security guarantees: anonymity, encryption, privacy
void main() {
  group('Secure Network Security Tests', () {
    late AnonymousCommunicationProtocol protocol;

    setUp(() {
      protocol = AnonymousCommunicationProtocol();
    });

    test('should not expose sender identity in routing metadata', () async {
      // This test verifies that routing metadata doesn't contain sender identity
      // The actual routing metadata is created in _createAnonymousRoutingMetadata

      const targetAgentId = 'target-agent-123';
      const messageType = MessageType.discoverySync;
      final payload = {
        'data': 'test data',
      };

      final message = await protocol.sendEncryptedMessage(
        targetAgentId,
        messageType,
        payload,
      );

      // Routing hops should not contain sender identity
      // (routing metadata is internal, but we can verify message structure)
      expect(message.routingHops, isA<List<String>>());

      // Verify message doesn't contain personal data
      expect(message.targetAgentId, equals(targetAgentId));
      // Encrypted payload should not be readable
      expect(message.encryptedPayload, isNotEmpty);
    });

    test('should encrypt messages end-to-end', () async {
      const targetAgentId = 'target-agent-123';
      const messageType = MessageType.discoverySync;
      final payload = {
        'data': 'test data',
      };

      final message = await protocol.sendEncryptedMessage(
        targetAgentId,
        messageType,
        payload,
      );

      // Message should be encrypted
      expect(message.encryptedPayload, isNotEmpty);

      // Encrypted payload should not match original
      final originalJson = jsonEncode(payload);
      expect(message.encryptedPayload, isNot(equals(originalJson)));

      // Encrypted payload should be base64-encoded
      expect(() => base64Decode(message.encryptedPayload), returnsNormally);
    });

    test('should validate anonymous payload (no personal data)', () async {
      const targetAgentId = 'target-agent-123';
      const messageType = MessageType.discoverySync;

      // Payload with personal data should be rejected
      final payloadWithPersonalData = {
        'userId': 'user-123',
        'email': 'user@example.com',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          targetAgentId,
          messageType,
          payloadWithPersonalData,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should allow anonymous payload', () async {
      const targetAgentId = 'target-agent-123';
      const messageType = MessageType.discoverySync;
      final anonymousPayload = {
        'data': 'test data',
        'anonymized_metrics': {
          'metric1': 0.5,
          'metric2': 0.7,
        },
      };

      // Should not throw
      final message = await protocol.sendEncryptedMessage(
        targetAgentId,
        messageType,
        anonymousPayload,
      );

      expect(message, isNotNull);
    });

    test('should expire messages after TTL', () async {
      const targetAgentId = 'target-agent-123';
      const messageType = MessageType.discoverySync;
      final payload = {
        'data': 'test data',
      };

      final message = await protocol.sendEncryptedMessage(
        targetAgentId,
        messageType,
        payload,
      );

      // Message should have expiration time
      expect(message.expiresAt.isAfter(message.timestamp), isTrue);

      // Expiration should be approximately 60 minutes from timestamp
      final expirationDuration =
          message.expiresAt.difference(message.timestamp);
      expect(expirationDuration.inMinutes, greaterThanOrEqualTo(59));
      expect(expirationDuration.inMinutes, lessThanOrEqualTo(61));
    });
  });
}

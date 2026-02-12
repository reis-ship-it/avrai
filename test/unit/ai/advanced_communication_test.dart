import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/advanced_communication.dart' show AdvancedAICommunication, AI2AIMessage, SecureCommunicationChannel;

/// Advanced AI Communication Tests
/// Tests secure, encrypted AI2AI communication system
/// OUR_GUTS.md: "Privacy-preserving AI2AI communication"
void main() {
  group('AdvancedAICommunication', () {
    late AdvancedAICommunication communication;

    setUp(() {
      communication = AdvancedAICommunication();
    });

    group('Message Sending', () {
      test('should send encrypted message without errors', () async {
        const targetAgentId = 'target-agent-123';
        const messageType = 'discovery_sync';
        final payload = {'data': 'test'};

        final message = await communication.sendEncryptedMessage(
          targetAgentId,
          messageType,
          payload,
        );

        expect(message, isA<AI2AIMessage>());
        expect(message.targetAgentId, equals(targetAgentId));
        expect(message.messageType, equals(messageType));
        expect(message.isAnonymous, isTrue);
        expect(message.containsUserData, isFalse);
        expect(message.payload, isA<String>());
      });

      test('should handle different message types', () async {
        const targetAgentId = 'target-agent-123';
        final messageTypes = [
          'discovery_sync',
          'recommendation_share',
          'trust_verification',
          'reputation_update',
        ];

        for (final messageType in messageTypes) {
          final message = await communication.sendEncryptedMessage(
            targetAgentId,
            messageType,
            {'data': 'test'},
          );

          expect(message.messageType, equals(messageType));
          expect(message.isAnonymous, isTrue);
        }
      });

      test('should handle empty payload', () async {
        const targetAgentId = 'target-agent-123';
        const messageType = 'discovery_sync';

        final message = await communication.sendEncryptedMessage(
          targetAgentId,
          messageType,
          {},
        );

        expect(message, isA<AI2AIMessage>());
      });
    });

    group('Message Receiving', () {
      test('should receive and decrypt messages without errors', () async {
        final messages = await communication.receiveEncryptedMessages();

        expect(messages, isA<List<AI2AIMessage>>());
        // All messages should be anonymous and contain no user data
        for (final message in messages) {
          expect(message.isAnonymous, isTrue);
          expect(message.containsUserData, isFalse);
        }
      });
    });

    group('Secure Channel Establishment', () {
      test('should establish secure channel without errors', () async {
        const partnerAgentId = 'partner-agent-123';
        const channelType = 'discovery_sync';

        final channel = await communication.establishSecureChannel(
          partnerAgentId,
          channelType,
        );

        expect(channel, isA<SecureCommunicationChannel>());
        expect(channel.partnerAgentId, equals(partnerAgentId));
        expect(channel.channelType, equals(channelType));
      });
    });

    group('Privacy Validation', () {
      test('should ensure messages contain no user data', () async {
        const targetAgentId = 'target-agent-123';
        const messageType = 'discovery_sync';
        final payload = {'data': 'test'};

        final message = await communication.sendEncryptedMessage(
          targetAgentId,
          messageType,
          payload,
        );

        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        expect(message.containsUserData, isFalse);
        expect(message.isAnonymous, isTrue);
      });
    });
  });
}


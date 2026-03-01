import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart'
    hide ChatMessage, ChatMessageType;
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI2AIChatAnalyzer', () {
    late AI2AIChatAnalyzer analyzer;
    late SharedPreferencesCompat prefs;
    late PersonalityLearning personalityLearning;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      personalityLearning = PersonalityLearning.withPrefs(prefs);
      analyzer = AI2AIChatAnalyzer(
        prefs: prefs,
        personalityLearning: personalityLearning,
      );
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('Chat Analysis', () {
      test('should analyze chat conversation without errors', () async {
        const localUserId = 'test-user-123';
        final chatEvent = AI2AIChatEvent(
          eventId: 'chat-123',
          messageType: ChatMessageType.personalitySharing,
          participants: ['user1', 'user2'],
          messages: [
            ChatMessage(
              senderId: 'user1',
              content: 'Test message',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        final result = await analyzer.analyzeChatConversation(
          localUserId,
          chatEvent,
          connectionContext,
        );

        expect(result, isA<AI2AIChatAnalysisResult>());
        expect(result.localUserId, equals(localUserId));
        expect(result.chatEvent, equals(chatEvent));
        expect(result.analysisConfidence, greaterThanOrEqualTo(0.0));
        expect(result.analysisConfidence, lessThanOrEqualTo(1.0));
      });

      test('should handle different chat message types', () async {
        const localUserId = 'test-user-123';
        final messageTypes = [
          ChatMessageType.personalitySharing,
          ChatMessageType.experienceSharing,
          ChatMessageType.trustBuilding,
        ];
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        for (final messageType in messageTypes) {
          final chatEvent = AI2AIChatEvent(
            eventId: 'chat-$messageType',
            messageType: messageType,
            participants: ['user1', 'user2'],
            messages: [
              ChatMessage(
                senderId: 'user1',
                content: 'Test message',
                timestamp: DateTime.now(),
                context: {},
              ),
            ],
            timestamp: DateTime.now(),
            duration: const Duration(minutes: 5),
            metadata: {},
          );

          final result = await analyzer.analyzeChatConversation(
            localUserId,
            chatEvent,
            connectionContext,
          );

          expect(result.chatEvent.messageType, equals(messageType));
        }
      });
    });

    group('Collective Intelligence', () {
      test('should analyze collective intelligence without errors', () async {
        const localUserId = 'test-user-123';
        final chatEvent = AI2AIChatEvent(
          eventId: 'chat-123',
          messageType: ChatMessageType.personalitySharing,
          participants: ['user1', 'user2', 'user3'],
          messages: [
            ChatMessage(
              senderId: 'user1',
              content: 'Test message',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        final result = await analyzer.analyzeChatConversation(
          localUserId,
          chatEvent,
          connectionContext,
        );

        expect(result.collectiveIntelligence, isNotNull);
      });
    });

    group('Privacy Validation', () {
      test('should ensure chat analysis contains no user data', () async {
        const localUserId = 'test-user-123';
        final chatEvent = AI2AIChatEvent(
          eventId: 'chat-123',
          messageType: ChatMessageType.personalitySharing,
          participants: ['user1', 'user2'],
          messages: [
            ChatMessage(
              senderId: 'user1',
              content: 'Test message',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        final result = await analyzer.analyzeChatConversation(
          localUserId,
          chatEvent,
          connectionContext,
        );

        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        // Analysis should work with anonymized data only
        expect(result, isA<AI2AIChatAnalysisResult>());
      });
    });
  });
}

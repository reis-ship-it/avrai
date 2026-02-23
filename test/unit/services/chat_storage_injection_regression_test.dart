library;

import 'dart:typed_data';

import 'package:avrai/core/ai/personality_learning.dart' as pl;
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai/core/services/ai_infrastructure/llm_service.dart';
import 'package:avrai/core/services/chat/friend_chat_service.dart';
import 'package:avrai/core/services/community/community_chat_service.dart';
import 'package:avrai/core/services/security/message_encryption_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/user/personality_agent_chat_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_storage_service.dart';

class _MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

class _MockAgentIdService extends Mock implements AgentIdService {}

class _MockLanguagePatternLearningService extends Mock
    implements LanguagePatternLearningService {}

class _MockLLMService extends Mock implements LLMService {}

class _MockPersonalityLearning extends Mock implements pl.PersonalityLearning {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      EncryptedMessage(
        encryptedContent: Uint8List(0),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
  });

  group('Chat storage injection regression', () {
    late _MockMessageEncryptionService encryptionService;

    setUp(() {
      MockGetStorage.reset();
      encryptionService = _MockMessageEncryptionService();
      when(() => encryptionService.encryptionType)
          .thenReturn(EncryptionType.aes256gcm);
      when(() => encryptionService.encrypt(any(), any())).thenAnswer((i) async {
        final text = i.positionalArguments[0] as String;
        return EncryptedMessage(
          encryptedContent: Uint8List.fromList(text.codeUnits),
          encryptionType: EncryptionType.aes256gcm,
        );
      });
      when(() => encryptionService.decrypt(any(), any())).thenAnswer((i) async {
        final encrypted = i.positionalArguments[0] as EncryptedMessage;
        return String.fromCharCodes(encrypted.encryptedContent);
      });
    });

    test('FriendChatService runs with injected storage (no platform channels)',
        () async {
      final service = FriendChatService(
        encryptionService: encryptionService,
        chatStorage:
            MockGetStorage.getInstance(boxName: 'friend_chat_messages'),
        outboxStorage:
            MockGetStorage.getInstance(boxName: 'friend_chat_outbox'),
      );

      await service.sendMessage('u1', 'u2', 'hello');
      final history = await service.getConversationHistory('u1', 'u2');
      expect(history, isNotEmpty);
    });

    test(
        'CommunityChatService runs with injected storage (no platform channels)',
        () async {
      final service = CommunityChatService(
        encryptionService: encryptionService,
        chatStorage:
            MockGetStorage.getInstance(boxName: 'community_chat_messages'),
      );
      final community = Community(
        id: 'community-1',
        name: 'Test',
        category: 'Social',
        memberIds: const ['u1'],
        memberCount: 1,
        originatingEventId: 'event-1',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: 'u1',
        originalLocality: 'SF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.sendGroupMessage(
        'u1',
        'community-1',
        'hello community',
        community: community,
      );
      final history = await service.getGroupChatHistory('community-1');
      expect(history, isNotEmpty);
    });

    test(
        'PersonalityAgentChatService runs with injected storage (no platform channels)',
        () async {
      final agentIdService = _MockAgentIdService();
      final languageService = _MockLanguagePatternLearningService();
      final llmService = _MockLLMService();
      final personalityLearning = _MockPersonalityLearning();

      when(() => agentIdService.getUserAgentId('u1'))
          .thenAnswer((_) async => 'agent-u1');
      when(() => languageService.analyzeMessage(any(), any(), any()))
          .thenAnswer((_) async => true);
      when(() => languageService.getLanguageStyleSummary(any()))
          .thenAnswer((_) async => '');
      when(() => personalityLearning.getCurrentPersonality(any())).thenAnswer(
        (_) async => PersonalityProfile.initial('agent-u1', userId: 'u1'),
      );
      when(() => llmService.generateWithContext(
            query: any(named: 'query'),
            userId: any(named: 'userId'),
            messages: any(named: 'messages'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((_) async => 'response');

      final service = PersonalityAgentChatService(
        agentIdService: agentIdService,
        encryptionService: encryptionService,
        languageLearningService: languageService,
        llmService: llmService,
        personalityLearning: personalityLearning,
        chatStorage:
            MockGetStorage.getInstance(boxName: 'personality_chat_messages'),
      );

      final response = await service.chat('u1', 'help me');
      expect(response, isNotEmpty);
    });
  });
}

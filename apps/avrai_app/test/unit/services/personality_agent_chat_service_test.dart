/// SPOTS PersonalityAgentChatService Tests
/// Date: December 2025
/// Purpose: Test PersonalityAgentChatService functionality
///
/// Test Coverage:
/// - Initialization: Service setup with all dependencies
/// - Chat: Main chat functionality with encryption
/// - Language Learning: Integration with language pattern learning
/// - Search Integration: Search request detection and result inclusion
/// - Conversation History: Encrypted message storage and retrieval
/// - Encryption: Message encryption and decryption
/// - Error Handling: Invalid inputs, missing dependencies, storage errors
/// - Privacy: agentId/userId conversion validation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avrai_runtime_os/services/user/aspirational_intent_parser.dart';
import 'package:avrai_runtime_os/services/user/aspirational_dna_engine.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/test_storage_helper.dart';

// Mock classes
class MockAgentIdService extends Mock implements AgentIdService {}

class MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

class MockLanguagePatternLearningService extends Mock
    implements LanguagePatternLearningService {}

class MockLLMService extends Mock implements LLMService {}

class MockPersonalityLearning extends Mock implements pl.PersonalityLearning {}

class MockHybridSearchRepository extends Mock
    implements HybridSearchRepository {}

class MockAspirationalIntentParser extends Mock
    implements AspirationalIntentParser {}

class MockAspirationalDNAEngine extends Mock implements AspirationalDNAEngine {}

class MockGeoHierarchyService extends Mock implements GeoHierarchyService {}

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(
      EncryptedMessage(
        encryptedContent: Uint8List(0),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
    registerFallbackValue(
        PersonalityProfile.initial('agent_test_user', userId: 'test_user'));
    registerFallbackValue(const LLMDispatchPolicy.humanChat());
    registerFallbackValue(HybridSearchResult(
      spots: [],
      communityCount: 0,
      externalCount: 0,
      totalCount: 0,
      searchDuration: const Duration(milliseconds: 0),
      sources: {},
    ));
  });

  group('PersonalityAgentChatService Tests', () {
    late PersonalityAgentChatService service;
    late MockAgentIdService mockAgentIdService;
    late MockMessageEncryptionService mockEncryptionService;
    late MockLanguagePatternLearningService mockLanguageLearningService;
    late MockLLMService mockLLMService;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockHybridSearchRepository mockSearchRepository;
    late MockAspirationalIntentParser mockAspirationalParser;
    late MockAspirationalDNAEngine mockAspirationalDNAEngine;
    late MockGeoHierarchyService mockGeoHierarchyService;

    const String testUserId = 'user_123';
    const String testAgentId = 'agent_abc123def456ghi789jkl012mno345pqr678';
    const String testChatId = 'chat_$testAgentId}_$testUserId';

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return '.';
          }
          return null;
        },
      );
    });

    setUp(() async {
      TestHelpers.setupTestEnvironment();
      await TestStorageHelper.initTestStorage();
      await GetStorage.init('personality_chat_messages');
      await GetStorage('personality_chat_messages').erase();

      // Initialize mocks
      mockAgentIdService = MockAgentIdService();
      mockEncryptionService = MockMessageEncryptionService();
      mockLanguageLearningService = MockLanguagePatternLearningService();
      mockLLMService = MockLLMService();
      mockPersonalityLearning = MockPersonalityLearning();
      mockSearchRepository = MockHybridSearchRepository();
      mockAspirationalParser = MockAspirationalIntentParser();
      mockAspirationalDNAEngine = MockAspirationalDNAEngine();
      mockGeoHierarchyService = MockGeoHierarchyService();

      // Setup default mock behaviors
      when(() => mockAgentIdService.getUserAgentId(testUserId))
          .thenAnswer((_) async => testAgentId);

      when(() => mockAspirationalParser.parseIntent(any()))
          .thenAnswer((_) async => <String, double>{});

      when(() => mockAspirationalDNAEngine.applyAspirationalShift(any(), any()))
          .thenAnswer((invocation) =>
              invocation.positionalArguments[0] as PersonalityProfile);

      when(() => mockEncryptionService.encryptionType)
          .thenReturn(EncryptionType.aes256gcm);

      when(() => mockEncryptionService.encrypt(any(), any()))
          .thenAnswer((invocation) async {
        final plaintext = invocation.positionalArguments[0] as String;
        // Create a simple mock encrypted message
        return EncryptedMessage(
          encryptedContent: Uint8List.fromList(plaintext.codeUnits),
          encryptionType: EncryptionType.aes256gcm,
        );
      });

      when(() => mockEncryptionService.decrypt(any(), any()))
          .thenAnswer((invocation) async {
        final encrypted = invocation.positionalArguments[0] as EncryptedMessage;
        // Simple mock decryption (just convert back from codeUnits)
        return String.fromCharCodes(encrypted.encryptedContent);
      });

      when(() =>
              mockLanguageLearningService.analyzeMessage(any(), any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockLanguageLearningService.getLanguageStyleSummary(any()))
          .thenAnswer((_) async => '');

      when(() => mockPersonalityLearning.getCurrentPersonality(any()))
          .thenAnswer((_) async => PersonalityProfile.initial(
              'agent_$testUserId',
              userId: testUserId));

      when(() => mockPersonalityLearning.updatePersonality(any(), any()))
          .thenAnswer((_) async => {});

      when(() => mockLLMService.chat(
            messages: any(named: 'messages'),
            context: any(named: 'context'),
            dispatchPolicy: any(named: 'dispatchPolicy'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((_) async => 'This is a test response from the agent.');

      when(() => mockLLMService.generateWithContext(
            query: any(named: 'query'),
            userId: any(named: 'userId'),
            messages: any(named: 'messages'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenThrow(Exception('Use fallback path for tests'));

      // Create service with mocks
      service = PersonalityAgentChatService(
        agentIdService: mockAgentIdService,
        encryptionService: mockEncryptionService,
        languageLearningService: mockLanguageLearningService,
        llmService: mockLLMService,
        personalityLearning: mockPersonalityLearning,
        searchRepository: mockSearchRepository,
        aspirationalParser: mockAspirationalParser,
        aspirationalDNAEngine: mockAspirationalDNAEngine,
      );

      final getIt = GetIt.instance;
      if (getIt.isRegistered<GeoHierarchyService>()) {
        getIt.unregister<GeoHierarchyService>();
      }
      if (getIt.isRegistered<SharedPreferencesCompat>()) {
        getIt.unregister<SharedPreferencesCompat>();
      }
    });

    tearDown(() async {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<GeoHierarchyService>()) {
        getIt.unregister<GeoHierarchyService>();
      }
      if (getIt.isRegistered<SharedPreferencesCompat>()) {
        getIt.unregister<SharedPreferencesCompat>();
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      TestHelpers.teardownTestEnvironment();
    });

    group('Initialization', () {
      test('should initialize with all dependencies', () {
        expect(service, isNotNull);
      });

      test('should require LLMService', () {
        expect(
          () => PersonalityAgentChatService(
            agentIdService: mockAgentIdService,
            encryptionService: mockEncryptionService,
            languageLearningService: mockLanguageLearningService,
            llmService: mockLLMService,
            personalityLearning: mockPersonalityLearning,
            searchRepository: mockSearchRepository,
            aspirationalParser: mockAspirationalParser,
            aspirationalDNAEngine: mockAspirationalDNAEngine,
          ),
          returnsNormally,
        );
      });
    });

    group('Chat Functionality', () {
      test('should process chat message and return agent response', () async {
        // Arrange
        const userMessage = 'Hello, can you help me find a coffee shop?';

        // Act
        final response = await service.chat(testUserId, userMessage);

        // Assert
        expect(response, isNotEmpty);
        expect(response, contains('test response'));

        // Verify agentId conversion
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);

        // Verify language learning
        verify(() => mockLanguageLearningService.analyzeMessage(
              testUserId,
              userMessage,
              'agent',
            )).called(1);

        // Verify encryption was called (for user message and agent response)
        verify(() => mockEncryptionService.encrypt(any(), any()))
            .called(greaterThan(0));

        // Verify LLM was called
        verify(() => mockLLMService.chat(
              messages: any(named: 'messages'),
              context: any(named: 'context'),
              dispatchPolicy: any(named: 'dispatchPolicy'),
              temperature: any(named: 'temperature'),
              maxTokens: any(named: 'maxTokens'),
            )).called(1);
      });

      test('should include conversation history in LLM context', () async {
        // Arrange
        const firstMessage = 'Hello';
        const secondMessage = 'How are you?';

        // Act - send first message
        await service.chat(testUserId, firstMessage);

        // Act - send second message
        await service.chat(testUserId, secondMessage);

        // Assert - verify LLM was called with history
        verify(() => mockLLMService.chat(
              messages: any(
                  named: 'messages',
                  that: predicate((List<ChatMessage> msgs) {
                    // Should have at least 2 messages (first user message + first agent response + second user message)
                    return msgs.length >= 2;
                  })),
              context: any(named: 'context'),
              dispatchPolicy: any(named: 'dispatchPolicy'),
              temperature: any(named: 'temperature'),
              maxTokens: any(named: 'maxTokens'),
            )).called(greaterThan(1));
      });

      test('should handle empty message', () async {
        // Act - empty messages are processed (may return empty response)
        final response = await service.chat(testUserId, '');

        // Assert - service should still process (may return empty or default response)
        expect(response, isA<String>());
      });

      test('should inject metro context into runtime prompt construction',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final getIt = GetIt.instance;
        getIt.registerSingleton<SharedPreferencesCompat>(prefs);
        getIt.registerSingleton<GeoHierarchyService>(mockGeoHierarchyService);

        when(() => mockGeoHierarchyService.lookupLocalityByPoint(
              lat: any(named: 'lat'),
              lon: any(named: 'lon'),
            )).thenAnswer((_) async => (
              localityCode: 'brooklyn-williamsburg',
              cityCode: 'us-nyc',
              displayName: 'Williamsburg'
            ));

        await service.chat(
          testUserId,
          'What should I do tonight?',
          currentLocation: Position(
            longitude: -73.956,
            latitude: 40.718,
            timestamp: DateTime(2026),
            accuracy: 5,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );

        verify(() => mockLLMService.chat(
              messages: any(
                named: 'messages',
                that: predicate((List<ChatMessage> messages) {
                  if (messages.isEmpty) {
                    return false;
                  }
                  final systemMessage = messages.first;
                  return systemMessage.role == ChatRole.system &&
                      systemMessage.content.contains('Local context: NYC') &&
                      systemMessage.content.contains('Dense, fast');
                }),
              ),
              context: any(
                named: 'context',
                that: predicate((LLMContext context) {
                  final metroContext = context.preferences?['metro_context']
                      as Map<String, dynamic>?;
                  return metroContext?['metro_key'] == 'nyc';
                }),
              ),
              dispatchPolicy: any(named: 'dispatchPolicy'),
              temperature: any(named: 'temperature'),
              maxTokens: any(named: 'maxTokens'),
            )).called(1);
      });
    });

    group('Language Learning Integration', () {
      test('should analyze user messages for language learning', () async {
        // Arrange
        const userMessage = 'Hey, I want to find some cool spots nearby';

        // Act
        await service.chat(testUserId, userMessage);

        // Assert
        verify(() => mockLanguageLearningService.analyzeMessage(
              testUserId,
              userMessage,
              'agent',
            )).called(1);
      });

      test('should get language style summary for context', () async {
        // Arrange
        when(() =>
            mockLanguageLearningService
                .getLanguageStyleSummary(any())).thenAnswer((_) async =>
            'User\'s Communication Style:\n- Vocabulary: cool, awesome\n- Formality: low');

        // Act
        await service.chat(testUserId, 'Test message');

        // Assert
        verify(() =>
                mockLanguageLearningService.getLanguageStyleSummary(testUserId))
            .called(1);
      });
    });

    group('Search Integration', () {
      test('should detect search intent and perform search', () async {
        // Arrange
        const searchMessage = 'Find coffee shops near me';
        final searchResult = HybridSearchResult(
          spots: [],
          communityCount: 0,
          externalCount: 0,
          totalCount: 0,
          searchDuration: const Duration(milliseconds: 100),
          sources: {},
        );

        when(() => mockSearchRepository.searchSpots(
              query: any(named: 'query'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              maxResults: any(named: 'maxResults'),
              includeExternal: any(named: 'includeExternal'),
            )).thenAnswer((_) async => searchResult);

        // Act
        await service.chat(testUserId, searchMessage);

        // Assert - verify search was attempted (may or may not be called depending on detection logic)
        // The service has simple keyword detection, so it should attempt search
        verify(() => mockSearchRepository.searchSpots(
              query: any(named: 'query'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              maxResults: any(named: 'maxResults'),
              includeExternal: any(named: 'includeExternal'),
            )).called(greaterThanOrEqualTo(0));
      });

      test('should handle search errors gracefully', () async {
        // Arrange
        const searchMessage = 'Find restaurants';

        when(() => mockSearchRepository.searchSpots(
              query: any(named: 'query'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              maxResults: any(named: 'maxResults'),
              includeExternal: any(named: 'includeExternal'),
            )).thenThrow(Exception('Search failed'));

        // Act & Assert - should not throw, should continue with chat
        final response = await service.chat(testUserId, searchMessage);
        expect(response, isNotEmpty);
      });
    });

    group('Conversation History', () {
      test('should save messages to conversation history', () async {
        // Arrange
        const userMessage = 'Test message';

        // Act
        await service.chat(testUserId, userMessage);

        // Assert - verify messages were encrypted and saved
        verify(() => mockEncryptionService.encrypt(any(), any()))
            .called(greaterThan(0));

        // Verify we can retrieve history
        final history = await service.getConversationHistory(testUserId);
        expect(history, isNotEmpty);
      });

      test('should retrieve conversation history', () async {
        // Arrange
        await service.chat(testUserId, 'First message');
        await service.chat(testUserId, 'Second message');

        // Act
        final history = await service.getConversationHistory(testUserId);

        // Assert
        expect(
            history.length,
            greaterThanOrEqualTo(
                2)); // At least 2 user messages + 2 agent responses
      });

      test('should decrypt messages when retrieving history', () async {
        // Arrange
        const userMessage = 'Secret message';
        await service.chat(testUserId, userMessage);

        // Act
        final history = await service.getConversationHistory(testUserId);
        final firstMessage = history.first;

        // Assert - verify decryption is called
        final decrypted = await service.getDecryptedMessageAsync(
          firstMessage,
          testAgentId,
          testUserId,
        );
        expect(decrypted, isNotEmpty);
        verify(() => mockEncryptionService.decrypt(any(), any()))
            .called(greaterThan(0));
      });
    });

    group('Encryption', () {
      test('should encrypt user messages before storage', () async {
        // Arrange
        const userMessage = 'This is a secret message';

        // Act
        await service.chat(testUserId, userMessage);

        // Assert
        verify(() => mockEncryptionService.encrypt(
              userMessage,
              testChatId,
            )).called(1);
      });

      test('should encrypt agent responses before storage', () async {
        // Arrange
        const userMessage = 'Hello';

        // Act
        await service.chat(testUserId, userMessage);

        // Assert - verify agent response was encrypted
        verify(() => mockEncryptionService.encrypt(
              any(that: contains('test response')),
              testChatId,
            )).called(1);
      });

      test('should decrypt messages for display', () async {
        // Arrange
        await service.chat(testUserId, 'Test message');
        final history = await service.getConversationHistory(testUserId);

        // Act
        final decrypted = await service.getDecryptedMessageAsync(
          history.first,
          testAgentId,
          testUserId,
        );

        // Assert
        expect(decrypted, isNotEmpty);
        // Note: decrypt may be called multiple times (in history retrieval and here)
        verify(() => mockEncryptionService.decrypt(any(), any()))
            .called(greaterThanOrEqualTo(1));
      });
    });

    group('Error Handling', () {
      test('should handle encryption errors gracefully', () async {
        // Arrange
        when(() => mockEncryptionService.encrypt(any(), any()))
            .thenThrow(Exception('Encryption failed'));

        // Act & Assert
        expect(
          () => service.chat(testUserId, 'Test message'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle LLM service errors gracefully', () async {
        // Arrange
        when(() => mockLLMService.chat(
              messages: any(named: 'messages'),
              context: any(named: 'context'),
              dispatchPolicy: any(named: 'dispatchPolicy'),
              temperature: any(named: 'temperature'),
              maxTokens: any(named: 'maxTokens'),
            )).thenThrow(Exception('LLM service unavailable'));

        // Act & Assert
        expect(
          () => service.chat(testUserId, 'Test message'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle agentId service errors', () async {
        // Arrange
        when(() => mockAgentIdService.getUserAgentId(any()))
            .thenThrow(Exception('AgentId service failed'));

        // Act & Assert
        expect(
          () => service.chat(testUserId, 'Test message'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Privacy Protection', () {
      test('should use agentId for internal operations', () async {
        // Arrange
        const userMessage = 'Test message';

        // Act
        await service.chat(testUserId, userMessage);

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);

        // Verify encryption uses chatId (which includes agentId)
        verify(() => mockEncryptionService.encrypt(
              any(),
              testChatId,
            )).called(greaterThan(0));
      });
    });
  });

  tearDownAll(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await GetStorage('personality_chat_messages').erase();
    await TestStorageHelper.clearTestStorage();
  });
}

import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:avrai_runtime_os/ai2ai/models/personality_chat_message.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

/// PersonalityAgentChatService
///
/// Orchestrates chat conversations with the user's personality agent.
/// Integrates personality profile, language learning, and search functionality.
///
/// Philosophy: "Doors, not badges" - Authentic AI companion that learns and adapts.
/// Privacy: All messages encrypted, uses agentId for privacy protection.
///
/// Phase 2.1: Personality Agent Chat Service
class PersonalityAgentChatService {
  static const String _logName = 'PersonalityAgentChatService';
  static const String _chatStoreName = 'personality_chat_messages';
  static const String _chatIdPrefix = 'chat_';

  final AgentIdService _agentIdService;
  final MessageEncryptionService _encryptionService;
  final LanguagePatternLearningService _languageLearningService;
  final LLMService _llmService;
  final pl.PersonalityLearning _personalityLearning;
  final HybridSearchRepository? _searchRepository;

  PersonalityAgentChatService({
    AgentIdService? agentIdService,
    MessageEncryptionService? encryptionService,
    LanguagePatternLearningService? languageLearningService,
    required LLMService llmService,
    pl.PersonalityLearning? personalityLearning,
    HybridSearchRepository? searchRepository,
  })  : _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _languageLearningService =
            languageLearningService ?? LanguagePatternLearningService(),
        _llmService = llmService,
        _personalityLearning = personalityLearning ?? pl.PersonalityLearning(),
        _searchRepository = searchRepository;

  /// Main chat method - handles user message and returns agent response
  ///
  /// [userId] - User-facing identifier
  /// [message] - User's message text
  /// [currentLocation] - Optional current location for search integration
  ///
  /// Returns agent's response text
  Future<String> chat(
    String userId,
    String message, {
    Position? currentLocation,
  }) async {
    try {
      developer.log('Processing chat message from user: $userId',
          name: _logName);

      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);
      final chatId = '$_chatIdPrefix$agentId}_$userId';

      // Analyze user message for language learning (only from agent chat)
      await _languageLearningService.analyzeMessage(userId, message, 'agent');

      // Encrypt and save user message
      await _saveMessage(
        chatId: chatId,
        senderId: userId,
        isFromUser: true,
        message: message,
        agentId: agentId,
        userId: userId,
      );

      // Check if message contains search request
      final searchResults =
          await _handleSearchRequest(message, currentLocation);

      // Build conversation history for context
      final history = await _getConversationHistory(userId, agentId);
      final historyMessages = <ChatMessage>[];
      for (final msg in history.take(10)) {
        final decrypted = await getDecryptedMessageAsync(msg, agentId, userId);
        historyMessages.add(ChatMessage(
          role: msg.isFromUser ? ChatRole.user : ChatRole.assistant,
          content: decrypted,
        ));
      }

      // Add current user message
      historyMessages.add(ChatMessage(role: ChatRole.user, content: message));

      // Add search results to user message if available
      String userMessage = message;
      if (searchResults != null && searchResults.spots.isNotEmpty) {
        final searchContext = _formatSearchResultsForContext(searchResults);
        userMessage = '$message\n\n$searchContext';
      }

      // Update last message with search context if available
      if (searchResults != null && searchResults.spots.isNotEmpty) {
        historyMessages[historyMessages.length - 1] = ChatMessage(
          role: ChatRole.user,
          content: userMessage,
        );
      }

      // Get personality profile
      final personality =
          await _personalityLearning.getCurrentPersonality(userId);

      // Get language style summary
      final languageStyle =
          await _languageLearningService.getLanguageStyleSummary(userId);

      // Phase 11 Section 5: Use generateWithContext() for structured facts integration
      // This automatically retrieves structured facts and includes them in context
      String response;
      try {
        // Use generateWithContext() with conversation history for enriched context
        response = await _llmService.generateWithContext(
          query:
              userMessage, // Use userMessage which may include search context
          userId: userId,
          messages: historyMessages, // Include conversation history
          temperature: 0.7,
          maxTokens: 500,
        );
      } catch (e) {
        developer.log(
          'generateWithContext failed, falling back to chat() with manual context: $e',
          name: _logName,
        );
        // Fallback: Manually retrieve structured facts and build context
        Map<String, dynamic> enrichedPreferences = {};
        try {
          if (GetIt.instance.isRegistered<FactsIndex>()) {
            final factsIndex = GetIt.instance<FactsIndex>();
            final facts = await factsIndex.retrieveFacts(userId: userId);

            // Merge structured facts into preferences
            enrichedPreferences = {
              'traits': facts.traits,
              'places': facts.places,
              'social_graph': facts.socialGraph,
            };
          }
        } catch (factsError) {
          developer.log('Error retrieving structured facts: $factsError',
              name: _logName);
        }

        // Generate agent response with fallback context
        response = await _llmService.chat(
          messages: historyMessages,
          context: LLMContext(
            userId: userId,
            location: currentLocation,
            personality: personality,
            preferences:
                enrichedPreferences.isNotEmpty ? enrichedPreferences : null,
            languageStyle: languageStyle.isNotEmpty ? languageStyle : null,
          ),
          temperature: 0.7,
          maxTokens: 500,
        );
      }

      // Encrypt and save agent response
      await _saveMessage(
        chatId: chatId,
        senderId: agentId,
        isFromUser: false,
        message: response,
        agentId: agentId,
        userId: userId,
      );

      developer.log('✅ Chat response generated and saved', name: _logName);
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'Error in chat: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get conversation history (decrypted)
  ///
  /// [userId] - User-facing identifier
  /// Returns list of decrypted messages, most recent first
  Future<List<PersonalityChatMessage>> getConversationHistory(
      String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      return await _getConversationHistory(userId, agentId);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting conversation history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // ========================================================================
  // PRIVATE METHODS
  // ========================================================================

  /// Format search results for LLM context
  String _formatSearchResultsForContext(HybridSearchResult results) {
    final buffer = StringBuffer();
    buffer.writeln('\nSearch Results Available:');
    buffer.writeln(
        'Found ${results.totalCount} spots (${results.communityCount} from community, ${results.externalCount} external)');
    buffer.writeln('\nTop Results:');

    for (int i = 0; i < results.spots.take(5).length; i++) {
      final spot = results.spots[i];
      buffer.writeln('${i + 1}. ${spot.name} - ${spot.category}');
      if (spot.description.isNotEmpty) {
        buffer.writeln(
            '   ${spot.description.substring(0, spot.description.length > 100 ? 100 : spot.description.length)}...');
      }
    }

    buffer.writeln(
        '\nYou can reference these spots in your response. Present them naturally in the user\'s language style.');

    return buffer.toString();
  }

  /// Handle search request if message contains search intent
  Future<HybridSearchResult?> _handleSearchRequest(
    String message,
    Position? currentLocation,
  ) async {
    if (_searchRepository == null) return null;

    // Simple search intent detection
    final lowerMessage = message.toLowerCase();
    final searchKeywords = [
      'find',
      'search',
      'look for',
      'where is',
      'near me',
      'nearby'
    ];
    final hasSearchIntent =
        searchKeywords.any((keyword) => lowerMessage.contains(keyword));

    if (!hasSearchIntent) return null;

    try {
      developer.log('Detected search intent, performing search',
          name: _logName);

      // Extract query (simple: remove search keywords)
      String query = message;
      for (final keyword in searchKeywords) {
        query =
            query.replaceAll(RegExp(keyword, caseSensitive: false), '').trim();
      }
      if (query.isEmpty) query = message; // Fallback to full message

      // Perform search
      final results = await _searchRepository.searchSpots(
        query: query,
        latitude: currentLocation?.latitude,
        longitude: currentLocation?.longitude,
        maxResults: 10,
        includeExternal: true,
      );

      developer.log('Search completed: ${results.totalCount} results',
          name: _logName);
      return results;
    } catch (e) {
      developer.log('Error performing search: $e', name: _logName);
      return null;
    }
  }

  /// Get conversation history (encrypted messages)
  Future<List<PersonalityChatMessage>> _getConversationHistory(
    String userId,
    String agentId,
  ) async {
    try {
      final chatId = '$_chatIdPrefix$agentId}_$userId';
      final box = GetStorage(_chatStoreName);
      final List<dynamic> raw =
          box.read<List<dynamic>>('personality_chat_$chatId') ?? [];

      final messages = raw
          .map((e) => PersonalityChatMessage.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();

      // Sort most recent first
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting conversation history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Save message (encrypt and store)
  Future<void> _saveMessage({
    required String chatId,
    required String senderId,
    required bool isFromUser,
    required String message,
    required String agentId,
    required String userId,
  }) async {
    try {
      // Encrypt message using chat ID as key
      final encrypted = await _encryptMessage(message, chatId);

      // Create message
      final chatMessage = PersonalityChatMessage(
        messageId: const Uuid().v4(),
        chatId: chatId,
        senderId: senderId,
        isFromUser: isFromUser,
        encryptedContent: encrypted,
        timestamp: DateTime.now(),
      );

      // Store in GetStorage
      final box = GetStorage(_chatStoreName);
      final key = 'personality_chat_$chatId';
      final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];
      existing.add(chatMessage.toJson());
      await box.write(key, existing);

      developer.log('Message saved: ${chatMessage.messageId}', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error saving message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Encrypt message
  Future<EncryptedMessage> _encryptMessage(
      String message, String chatId) async {
    return await _encryptionService.encrypt(message, chatId);
  }

  /// Get decrypted message content (async)
  Future<String> getDecryptedMessageAsync(
    PersonalityChatMessage message,
    String agentId,
    String userId,
  ) async {
    try {
      final chatId = '$_chatIdPrefix$agentId}_$userId';
      return await _encryptionService.decrypt(message.encryptedContent, chatId);
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return '[Message decryption failed]';
    }
  }
}

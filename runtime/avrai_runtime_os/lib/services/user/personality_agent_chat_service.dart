import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/ai2ai/models/personality_chat_message.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/human_chat_prompt_composer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import 'aspirational_intent_parser.dart';
import 'aspirational_dna_engine.dart';

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
  final AspirationalIntentParser _aspirationalParser;
  final AspirationalDNAEngine _aspirationalDNAEngine;
  final HumanChatPromptComposer _promptComposer;
  final EntitySignatureService? _entitySignatureService;

  PersonalityAgentChatService({
    AgentIdService? agentIdService,
    MessageEncryptionService? encryptionService,
    LanguagePatternLearningService? languageLearningService,
    required LLMService llmService,
    pl.PersonalityLearning? personalityLearning,
    HybridSearchRepository? searchRepository,
    AspirationalIntentParser? aspirationalParser,
    AspirationalDNAEngine? aspirationalDNAEngine,
    HumanChatPromptComposer? promptComposer,
    EntitySignatureService? entitySignatureService,
  })  : _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _languageLearningService =
            languageLearningService ?? LanguagePatternLearningService(),
        _llmService = llmService,
        _personalityLearning = personalityLearning ?? pl.PersonalityLearning(),
        _searchRepository = searchRepository,
        _aspirationalParser = aspirationalParser ??
            AspirationalIntentParser(llmService: llmService),
        _aspirationalDNAEngine =
            aspirationalDNAEngine ?? AspirationalDNAEngine(),
        _promptComposer = promptComposer ?? const HumanChatPromptComposer(),
        _entitySignatureService = entitySignatureService ??
            (GetIt.instance.isRegistered<EntitySignatureService>()
                ? GetIt.instance<EntitySignatureService>()
                : null);

  /// Intercepts chat to look for aspirational states ("I want to be more grungy")
  /// and saves them for the String Theory engine.
  Future<void> _extractAndSaveAspirationalState(
      String userId, String message) async {
    try {
      // Use the new mock parser instead of direct LLM calls for now
      final targetDimensions = await _aspirationalParser.parseIntent(message);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'aspirational_state_$userId', jsonEncode(targetDimensions));

      developer.log('Aspirational state saved: $targetDimensions',
          name: _logName);

      // Physically alter the underlying DNA
      final currentProfile =
          await _personalityLearning.getCurrentPersonality(userId);
      if (currentProfile != null) {
        final evolvedProfile = _aspirationalDNAEngine.applyAspirationalShift(
            currentProfile, targetDimensions);

        // Save the physically altered DNA back to storage
        await _personalityLearning.updatePersonality(
            userId, evolvedProfile.dimensions);

        developer.log('Aspirational state successfully merged into DNA!',
            name: _logName);
      } else {
        developer.log(
            'Failed to apply aspirational state: Could not fetch current profile for user $userId',
            name: _logName);
      }
    } catch (e) {
      developer.log('Failed to extract and apply aspirational state: $e',
          name: _logName);
    }
  }

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

      // --- Aspirational State Interception (String Theory Intentional Superposition) ---
      // We check if the user is expressing a desire to change their vibe.
      if (message.toLowerCase().contains('want to be') ||
          message.toLowerCase().contains('make me more') ||
          message.toLowerCase().contains('i wish i was')) {
        developer.log(
            'Aspirational intent detected. Analyzing target dimensions...',
            name: _logName);
        await _extractAndSaveAspirationalState(userId, message);
      }
      // --------------------------------------------------------------------------------

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
      final chronologicalHistory = [...history]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final recentHistory = chronologicalHistory.length <= 10
          ? chronologicalHistory
          : chronologicalHistory.sublist(chronologicalHistory.length - 10);
      final historyMessages = <ChatMessage>[];
      for (final msg in recentHistory) {
        final decrypted = await getDecryptedMessageAsync(msg, agentId, userId);
        historyMessages.add(ChatMessage(
          role: msg.isFromUser ? ChatRole.user : ChatRole.assistant,
          content: decrypted,
        ));
      }

      // Add search results to user message if available
      String userMessage = message;
      if (searchResults != null && searchResults.spots.isNotEmpty) {
        final searchContext = _formatSearchResultsForContext(searchResults);
        userMessage = '$message\n\n$searchContext';
      }

      // Update the most recent stored user message with the safe search summary.
      if (historyMessages.isNotEmpty &&
          searchResults != null &&
          searchResults.spots.isNotEmpty &&
          historyMessages.last.role == ChatRole.user) {
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
      final metroContext = await _resolveMetroContext(currentLocation);
      final structuredFacts = await _loadStructuredFacts(userId);
      final userSignatureSummary = await _loadUserSignatureSummary(
        userId: userId,
        personality: personality,
        metroContext: metroContext,
      );

      final prompt = _promptComposer.compose(
        historyMessages: historyMessages,
        userId: userId,
        personality: personality,
        languageStyle: languageStyle,
        userSignatureSummary: userSignatureSummary,
        structuredFacts: structuredFacts,
        metroContext: metroContext,
        currentLocation: currentLocation,
      );

      final response = await _llmService.chat(
        messages: prompt.messages,
        context: prompt.context,
        dispatchPolicy: const LLMDispatchPolicy.humanChat(),
        temperature: 0.7,
        maxTokens: 500,
      );

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

  Future<Map<String, dynamic>?> _loadStructuredFacts(String userId) async {
    try {
      if (!GetIt.instance.isRegistered<FactsIndex>()) {
        return null;
      }

      final factsIndex = GetIt.instance<FactsIndex>();
      final facts = await factsIndex.retrieveFacts(userId: userId);
      return <String, dynamic>{
        'traits': facts.traits,
        'places': facts.places,
        'social_graph': facts.socialGraph,
      };
    } catch (e, st) {
      developer.log(
        'Error retrieving structured facts for human chat',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<String?> _loadUserSignatureSummary({
    required String userId,
    required PersonalityProfile? personality,
    required MetroExperienceContext? metroContext,
  }) async {
    if (_entitySignatureService == null || personality == null) {
      return null;
    }

    try {
      final signature = await _entitySignatureService.buildUserSignature(
        user: UnifiedUser(
          id: userId,
          email: '$userId@local.avrai',
          location: metroContext?.displayName,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        personality: personality,
      );
      return signature.summary;
    } catch (e, st) {
      developer.log(
        'Failed to load user signature summary: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<String?> getUserSignatureSummary({
    required String userId,
    Position? currentLocation,
  }) async {
    final personality =
        await _personalityLearning.getCurrentPersonality(userId);
    final metroContext = await _resolveMetroContext(currentLocation);
    return _loadUserSignatureSummary(
      userId: userId,
      personality: personality,
      metroContext: metroContext,
    );
  }

  Future<MetroExperienceContext?> _resolveMetroContext(
    Position? currentLocation,
  ) async {
    try {
      final getIt = GetIt.instance;
      final prefs = getIt.isRegistered<SharedPreferencesCompat>()
          ? getIt<SharedPreferencesCompat>()
          : await SharedPreferencesCompat.getInstance();
      final geoHierarchyService = getIt.isRegistered<GeoHierarchyService>()
          ? getIt<GeoHierarchyService>()
          : GeoHierarchyService();
      final metroService = MetroExperienceService(
        geoHierarchyService: geoHierarchyService,
        prefs: prefs,
      );

      return await metroService.resolveBestEffort(
        latitude: currentLocation?.latitude,
        longitude: currentLocation?.longitude,
      );
    } catch (e, st) {
      developer.log(
        'Failed to resolve metro context',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
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
    buffer.writeln('Search results available:');
    buffer.writeln(
        'Found ${results.totalCount} spots (${results.communityCount} from community, ${results.externalCount} external)');
    buffer.writeln('Top results:');

    for (int i = 0; i < results.spots.take(5).length; i++) {
      final spot = results.spots[i];
      buffer.writeln('${i + 1}. ${spot.name} - ${spot.category}');
      if (spot.description.isNotEmpty) {
        final sanitizedDescription =
            spot.description.replaceAll(RegExp(r'\s+'), ' ').trim();
        final maxLength = sanitizedDescription.length > 100
            ? 100
            : sanitizedDescription.length;
        buffer.writeln('   ${sanitizedDescription.substring(0, maxLength)}...');
      }
    }

    buffer.writeln('Reference these naturally if relevant.');

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

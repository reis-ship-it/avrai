import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/ai2ai/models/personality_chat_message.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/human_chat_prompt_composer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reality_engine/reality_engine.dart';

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
  final LanguageKernelOrchestratorService _languageKernelOrchestrator;
  final pl.PersonalityLearning _personalityLearning;
  final HybridSearchRepository? _searchRepository;
  final AspirationalIntentParser _aspirationalParser;
  final AspirationalDNAEngine _aspirationalDNAEngine;
  final HumanChatPromptComposer _promptComposer;
  final EntitySignatureService? _entitySignatureService;
  final HeadlessAvraiOsHost? _headlessOsHost;
  final VibeKernel _vibeKernel;

  PersonalityAgentChatService({
    AgentIdService? agentIdService,
    MessageEncryptionService? encryptionService,
    LanguagePatternLearningService? languageLearningService,
    LanguageKernelOrchestratorService? languageKernelOrchestrator,
    required LanguageRuntimeService languageRuntimeService,
    pl.PersonalityLearning? personalityLearning,
    HybridSearchRepository? searchRepository,
    AspirationalIntentParser? aspirationalParser,
    AspirationalDNAEngine? aspirationalDNAEngine,
    HumanChatPromptComposer? promptComposer,
    EntitySignatureService? entitySignatureService,
    HeadlessAvraiOsHost? headlessOsHost,
    VibeKernel? vibeKernel,
  })  : _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
        _languageLearningService =
            languageLearningService ?? LanguagePatternLearningService(),
        _languageKernelOrchestrator = languageKernelOrchestrator ??
            LanguageKernelOrchestratorService(
              languageLearningService:
                  languageLearningService ?? LanguagePatternLearningService(),
            ),
        _personalityLearning = personalityLearning ?? pl.PersonalityLearning(),
        _searchRepository = searchRepository,
        _aspirationalParser = aspirationalParser ??
            AspirationalIntentParser(
              languageKernelOrchestrator: languageKernelOrchestrator,
              languageRuntimeService: languageRuntimeService,
            ),
        _aspirationalDNAEngine =
            aspirationalDNAEngine ?? AspirationalDNAEngine(),
        _promptComposer = promptComposer ?? const HumanChatPromptComposer(),
        _entitySignatureService = entitySignatureService ??
            (GetIt.instance.isRegistered<EntitySignatureService>()
                ? GetIt.instance<EntitySignatureService>()
                : null),
        _headlessOsHost = headlessOsHost ??
            (GetIt.instance.isRegistered<HeadlessAvraiOsHost>()
                ? GetIt.instance<HeadlessAvraiOsHost>()
                : null),
        _vibeKernel = vibeKernel ?? VibeKernel();

  /// Intercepts chat to look for aspirational states ("I want to be more grungy")
  /// and saves them for the String Theory engine.
  Future<void> _extractAndSaveAspirationalState(
      String userId, String message) async {
    try {
      final targetDimensions = await _aspirationalParser.parseIntent(
        message,
        actorAgentId: 'agt_user_$userId',
        consentScopes: const <String>{'user_runtime_learning'},
      );

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
    final result = await chatWithKernelContext(
      userId,
      message,
      currentLocation: currentLocation,
    );
    return result.response;
  }

  Future<PersonalityAgentChatResult> chatWithKernelContext(
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

      final humanLanguageTurn =
          await _languageKernelOrchestrator.processHumanText(
        actorAgentId: agentId,
        rawText: message,
        consentScopes: await _resolveLanguageConsentScopes(),
        privacyMode: BoundaryPrivacyMode.localSovereign,
        shareRequested: false,
        userId: userId,
        chatType: 'agent',
        surface: 'chat',
        channel: 'personality_agent',
      );
      if (!humanLanguageTurn.acceptedForTranscript) {
        throw HumanLanguageBoundaryViolationException(
          operation: 'personality_agent_human_message_store',
          decision: humanLanguageTurn.boundary,
        );
      }

      // Encrypt and save user message
      await _saveMessage(
        chatId: chatId,
        senderId: userId,
        isFromUser: true,
        message: message,
        agentId: agentId,
        userId: userId,
        metadata: <String, dynamic>{
          HumanLanguageBoundaryReview.metadataKey: <String, dynamic>{
            'intent': humanLanguageTurn.interpretation.intent.toWireValue(),
            'summary': humanLanguageTurn.interpretation.requestArtifact.summary,
            'privacy_sensitivity': humanLanguageTurn
                .interpretation.privacySensitivity
                .toWireValue(),
            'accepted': humanLanguageTurn.boundary.accepted,
            'disposition': humanLanguageTurn.boundary.disposition.toWireValue(),
            'transcript_storage_allowed':
                humanLanguageTurn.boundary.transcriptStorageAllowed,
            'storage_allowed': humanLanguageTurn.boundary.storageAllowed,
            'learning_allowed': humanLanguageTurn.boundary.learningAllowed,
            'reason_codes': humanLanguageTurn.boundary.reasonCodes,
            'egress_purpose':
                humanLanguageTurn.boundary.egressPurpose.toWireValue(),
          },
        },
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
      final historyMessages = <LanguageTurnMessage>[];
      for (final msg in recentHistory) {
        final decrypted = await getDecryptedMessageAsync(msg, agentId, userId);
        historyMessages.add(LanguageTurnMessage(
          role: msg.isFromUser
              ? LanguageTurnRole.user
              : LanguageTurnRole.assistant,
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
          historyMessages.last.role == LanguageTurnRole.user) {
        historyMessages[historyMessages.length - 1] = LanguageTurnMessage(
          role: LanguageTurnRole.user,
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

      final response = _renderGroundedAgentResponse(
        message: message,
        humanLanguageTurn: humanLanguageTurn,
        prompt: prompt,
        userSignatureSummary: userSignatureSummary,
        structuredFacts: structuredFacts,
        metroContext: metroContext,
        searchResults: searchResults,
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
      final kernelResult = await _emitHeadlessKernelChatLifecycle(
        userId: userId,
        agentId: agentId,
        message: message,
        response: response,
        currentLocation: currentLocation,
        metroContext: metroContext,
        searchResults: searchResults,
        historyLength: historyMessages.length,
        userSignatureSummary: userSignatureSummary,
        humanLanguageTurn: humanLanguageTurn,
      );
      return kernelResult ??
          PersonalityAgentChatResult(
            response: response,
            humanLanguageTurn: humanLanguageTurn,
          );
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

  Future<PersonalityAgentChatResult?> _emitHeadlessKernelChatLifecycle({
    required String userId,
    required String agentId,
    required String message,
    required String response,
    required Position? currentLocation,
    required MetroExperienceContext? metroContext,
    required HybridSearchResult? searchResults,
    required int historyLength,
    required String? userSignatureSummary,
    required HumanLanguageKernelTurn humanLanguageTurn,
  }) async {
    final host = _headlessOsHost;
    if (host == null) {
      return null;
    }

    try {
      await host.start();
      final now = DateTime.now().toUtc();
      final envelope = KernelEventEnvelope(
        eventId: 'human_chat:$userId:${now.microsecondsSinceEpoch}',
        agentId: agentId,
        userId: userId,
        occurredAtUtc: now,
        sourceSystem: 'personality_agent_chat_service',
        eventType: 'human_chat_turn_completed',
        actionType: 'chat_with_agent',
        entityId: agentId,
        entityType: 'personality_agent',
        context: <String, dynamic>{
          'message_length': message.length,
          'response_length': response.length,
          'history_length': historyLength,
          'has_search_results': (searchResults?.spots.isNotEmpty ?? false),
          if (searchResults != null)
            'search_result_count': searchResults.totalCount,
          if (metroContext != null)
            'metro_display_name': metroContext.displayName,
          if (metroContext != null)
            'metro_locality_code': metroContext.localityCode,
          if (currentLocation != null) 'latitude': currentLocation.latitude,
          if (currentLocation != null) 'longitude': currentLocation.longitude,
          'has_signature_summary':
              (userSignatureSummary ?? '').trim().isNotEmpty,
        },
        predictionContext: <String, dynamic>{
          'planner_mode': 'human_chat',
          'model_family': 'personality_agent_chat',
          'response_mode': 'reflective_guidance',
          'language_boundary_disposition':
              humanLanguageTurn.boundary.disposition.toWireValue(),
          'language_learning_allowed': humanLanguageTurn.acceptedForLearning,
        },
        policyContext: const <String, dynamic>{
          'trust_scope': 'private',
          'human_visible': true,
        },
        runtimeContext: const <String, dynamic>{
          'execution_path': 'personality_agent_chat_service.chat',
          'workflow_stage': 'human_chat_turn',
          'intervention_chain': <String>[
            'history',
            'signature',
            'prompt_compose',
            'grounded_expression',
            'persist',
            'headless_os_host',
          ],
        },
      );
      final runtimeBundle = await host.resolveRuntimeExecution(
        envelope: envelope,
      );
      final whyRequest = KernelWhyRequest(
        bundle: runtimeBundle.withoutWhy(),
        goal: 'answer_human_chat',
        predictedOutcome: 'response_delivered',
        predictedConfidence: 0.78,
        actualOutcome: 'responded',
        actualOutcomeScore: 1.0,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'message_length_signal',
            weight: (message.length / 120.0).clamp(0.0, 1.0),
            source: 'chat',
            durable: false,
          ),
          WhySignal(
            label: 'history_available',
            weight: historyLength > 0 ? 0.45 : 0.2,
            source: 'chat',
            durable: false,
          ),
        ],
        pheromoneSignals: <WhySignal>[
          WhySignal(
            label: 'search_context_present',
            weight: (searchResults?.spots.isNotEmpty ?? false) ? 0.32 : 0.0,
            source: 'chat',
            durable: false,
          ),
        ],
        policySignals: <WhySignal>[
          WhySignal(
            label: 'locality_in_where',
            weight: 0.4,
            source: 'policy',
            durable: true,
          ),
        ],
        memoryContext: <String, dynamic>{
          'history_length': historyLength,
          if (metroContext != null) 'metro': metroContext.displayName,
        },
        severity: 'normal',
      );
      final modelTruth = await host.buildModelTruth(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      final governance = await host.inspectGovernance(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      return PersonalityAgentChatResult(
        response: response,
        realityKernelFusionInput: modelTruth,
        governanceReport: governance,
        humanLanguageTurn: humanLanguageTurn,
      );
    } catch (e, st) {
      developer.log(
        'Headless chat lifecycle failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
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

  Future<Set<String>> _resolveLanguageConsentScopes() async {
    try {
      final getIt = GetIt.instance;
      final prefs = getIt.isRegistered<SharedPreferencesCompat>()
          ? getIt<SharedPreferencesCompat>()
          : await SharedPreferencesCompat.getInstance();
      final scopes = <String>{};
      if (prefs.getBool('user_runtime_learning_enabled') ?? true) {
        scopes.add('user_runtime_learning');
      }
      if (prefs.getBool('ai2ai_learning_enabled') ?? true) {
        scopes.add('ai2ai_learning');
      }
      return scopes;
    } catch (_) {
      return const <String>{'user_runtime_learning', 'ai2ai_learning'};
    }
  }

  String _renderGroundedAgentResponse({
    required String message,
    required HumanLanguageKernelTurn humanLanguageTurn,
    required HumanChatPrompt prompt,
    required String? userSignatureSummary,
    required Map<String, dynamic>? structuredFacts,
    required MetroExperienceContext? metroContext,
    required HybridSearchResult? searchResults,
  }) {
    final allowedClaims = _buildGroundedAllowedClaims(
      humanLanguageTurn: humanLanguageTurn,
      prompt: prompt,
      userSignatureSummary: userSignatureSummary,
      structuredFacts: structuredFacts,
      metroContext: metroContext,
      searchResults: searchResults,
    );
    final speechAct = _selectGroundedSpeechAct(
      humanLanguageTurn: humanLanguageTurn,
      searchResults: searchResults,
    );
    final subjectLabel = _selectGroundedSubjectLabel(
      humanLanguageTurn: humanLanguageTurn,
      searchResults: searchResults,
    );
    final rendered = _languageKernelOrchestrator.renderGroundedOutput(
      speechAct: speechAct,
      audience: ExpressionAudience.userSafe,
      surfaceShape: ExpressionSurfaceShape.chatTurn,
      subjectLabel: subjectLabel,
      allowedClaims: allowedClaims,
      evidenceRefs: _buildGroundedEvidenceRefs(
        humanLanguageTurn: humanLanguageTurn,
        prompt: prompt,
        metroContext: metroContext,
        searchResults: searchResults,
      ),
      confidenceBand: humanLanguageTurn.interpretation.confidence >= 0.75
          ? 'high'
          : 'medium',
      toneProfile: _selectToneProfile(prompt.context.languageStyle),
      vibeContext: _safeExpressionContext(prompt.context.userId),
      uncertaintyNotice: humanLanguageTurn.interpretation.needsClarification
          ? 'I can stay more grounded if you narrow the vibe, place type, timing, or distance.'
          : null,
      cta: _buildGroundedCta(
        message: message,
        humanLanguageTurn: humanLanguageTurn,
        searchResults: searchResults,
      ),
      adaptationProfileRef: prompt.context.userId,
    );
    return rendered.text;
  }

  VibeExpressionContext? _safeExpressionContext(String? subjectId) {
    if (subjectId == null || subjectId.trim().isEmpty) {
      return null;
    }
    try {
      return _vibeKernel.getExpressionContext(subjectId);
    } catch (_) {
      return null;
    }
  }

  List<String> _buildGroundedAllowedClaims({
    required HumanLanguageKernelTurn humanLanguageTurn,
    required HumanChatPrompt prompt,
    required String? userSignatureSummary,
    required Map<String, dynamic>? structuredFacts,
    required MetroExperienceContext? metroContext,
    required HybridSearchResult? searchResults,
  }) {
    final claims = <String>[];
    final sanitized = humanLanguageTurn.boundary.sanitizedArtifact;

    if (searchResults != null && searchResults.spots.isNotEmpty) {
      for (final spot in searchResults.spots.take(3)) {
        claims.add(
          '${spot.name} is a grounded option in this result set for ${spot.category}.',
        );
        if (spot.description.trim().isNotEmpty) {
          claims
              .add(_truncateSentence(spot.description.trim(), maxLength: 120));
        }
      }
    }

    if (sanitized.safeClaims.isNotEmpty) {
      claims.addAll(sanitized.safeClaims.take(2));
    }

    if (sanitized.safePreferenceSignals.isNotEmpty) {
      final signal = sanitized.safePreferenceSignals.first;
      claims.add(
        'I can use your local preference signal around ${signal.value} in future suggestions.',
      );
    }

    if (userSignatureSummary != null &&
        userSignatureSummary.trim().isNotEmpty) {
      claims
          .add(_truncateSentence(userSignatureSummary.trim(), maxLength: 140));
    }

    final traitFacts = structuredFacts?['traits'];
    if (traitFacts is List && traitFacts.isNotEmpty) {
      final traits =
          traitFacts.take(3).map((entry) => entry.toString()).join(', ');
      claims.add('Grounded preference signals I already have include $traits.');
    } else {
      final promptTraits = prompt.context.preferences?['traits'];
      if (promptTraits is List && promptTraits.isNotEmpty) {
        final traits =
            promptTraits.take(3).map((entry) => entry.toString()).join(', ');
        claims
            .add('Grounded preference signals I already have include $traits.');
      }
    }

    final conversationPreferences = prompt.context.conversationPreferences;
    final summary = conversationPreferences?['summary'] as String?;
    final displayName = conversationPreferences?['display_name'] as String?;
    if ((displayName ?? '').isNotEmpty && (summary ?? '').isNotEmpty) {
      claims.add(
        'Your current local context is $displayName. ${_truncateSentence(summary!, maxLength: 110)}',
      );
    } else if (metroContext != null) {
      claims.add(
        'Your current local context is ${metroContext.displayName}. ${_truncateSentence(metroContext.summary, maxLength: 110)}',
      );
    }

    if (humanLanguageTurn.interpretation.needsClarification) {
      claims.add(
        'Your last message is still broad enough that I should ask a narrower follow-up instead of pretending certainty.',
      );
    }

    if (claims.isEmpty) {
      claims.add(
        'I can only answer from grounded signals already inside AVRAI, and I do not have enough grounded context yet.',
      );
    }

    return claims.take(4).toList(growable: false);
  }

  List<String> _buildGroundedEvidenceRefs({
    required HumanLanguageKernelTurn humanLanguageTurn,
    required HumanChatPrompt prompt,
    required MetroExperienceContext? metroContext,
    required HybridSearchResult? searchResults,
  }) {
    return <String>[
      'interpretation:${humanLanguageTurn.interpretation.intent.toWireValue()}',
      'boundary:${humanLanguageTurn.boundary.disposition.toWireValue()}',
      if ((prompt.context.preferences?['traits'] as List?)?.isNotEmpty ?? false)
        'facts:traits',
      if (metroContext != null ||
          (prompt.context.conversationPreferences?['display_name'] as String?)
                  ?.isNotEmpty ==
              true)
        'facts:locality',
      if (searchResults != null && searchResults.spots.isNotEmpty)
        'facts:search',
    ];
  }

  ExpressionSpeechAct _selectGroundedSpeechAct({
    required HumanLanguageKernelTurn humanLanguageTurn,
    required HybridSearchResult? searchResults,
  }) {
    if (searchResults != null && searchResults.spots.isNotEmpty) {
      return ExpressionSpeechAct.recommend;
    }
    if (humanLanguageTurn.interpretation.needsClarification) {
      return ExpressionSpeechAct.clarify;
    }
    return switch (humanLanguageTurn.interpretation.intent) {
      InterpretationIntent.prefer => ExpressionSpeechAct.confirm,
      InterpretationIntent.correct => ExpressionSpeechAct.confirm,
      InterpretationIntent.confirm => ExpressionSpeechAct.confirm,
      InterpretationIntent.reject => ExpressionSpeechAct.confirm,
      InterpretationIntent.ask => ExpressionSpeechAct.explain,
      InterpretationIntent.plan => ExpressionSpeechAct.explain,
      InterpretationIntent.share => ExpressionSpeechAct.warn,
      InterpretationIntent.reflect => ExpressionSpeechAct.reassure,
      _ => ExpressionSpeechAct.reassure,
    };
  }

  String _selectGroundedSubjectLabel({
    required HumanLanguageKernelTurn humanLanguageTurn,
    required HybridSearchResult? searchResults,
  }) {
    if (searchResults != null && searchResults.spots.isNotEmpty) {
      return searchResults.spots.first.name;
    }
    return switch (humanLanguageTurn.interpretation.intent) {
      InterpretationIntent.prefer => 'your preference signal',
      InterpretationIntent.correct => 'your correction',
      InterpretationIntent.plan => 'your next step',
      InterpretationIntent.ask => 'your question',
      InterpretationIntent.share => 'your sharing request',
      _ => 'what AVRAI can say right now',
    };
  }

  String? _buildGroundedCta({
    required String message,
    required HumanLanguageKernelTurn humanLanguageTurn,
    required HybridSearchResult? searchResults,
  }) {
    if (searchResults != null && searchResults.spots.isNotEmpty) {
      return 'Tell me if you want quieter, livelier, closer, or cheaper options.';
    }
    if (humanLanguageTurn.interpretation.needsClarification) {
      return 'Tell me the vibe, distance, timing, or place type you want.';
    }
    if (humanLanguageTurn.boundary.learningAllowed) {
      return 'Keep telling me what fits and what does not, and I will keep that local signal grounded.';
    }
    if (message.trim().isNotEmpty) {
      return 'Ask about a place, a plan, or a preference and I will stay inside grounded context.';
    }
    return null;
  }

  String _selectToneProfile(String? languageStyle) {
    final style = (languageStyle ?? '').toLowerCase();
    if (style.contains('direct')) {
      return 'grounded_direct';
    }
    if (style.contains('formal')) {
      return 'grounded_formal';
    }
    return 'grounded_calm';
  }

  String _truncateSentence(String text, {int maxLength = 120}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength).trimRight()}...';
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
    Map<String, dynamic>? metadata,
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
        metadata: metadata,
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

class PersonalityAgentChatResult {
  const PersonalityAgentChatResult({
    required this.response,
    this.realityKernelFusionInput,
    this.governanceReport,
    this.humanLanguageTurn,
  });

  final String response;
  final RealityKernelFusionInput? realityKernelFusionInput;
  final KernelGovernanceReport? governanceReport;
  final HumanLanguageKernelTurn? humanLanguageTurn;

  String? get kernelEventId =>
      realityKernelFusionInput?.envelope.eventId ??
      governanceReport?.envelope.eventId;

  bool get modelTruthReady => realityKernelFusionInput != null;

  bool get localityContainedInWhere =>
      realityKernelFusionInput?.localityContainedInWhere ?? false;

  bool get languageLearningAccepted =>
      humanLanguageTurn?.acceptedForLearning ?? false;

  bool get languageEgressRequiresAirGap =>
      humanLanguageTurn?.egressRequiresAirGap ?? false;

  String? get governanceSummary => governanceReport?.projections.isEmpty ?? true
      ? null
      : governanceReport!.projections.first.summary;

  List<String> get governanceDomains => governanceReport == null
      ? const <String>[]
      : governanceReport!.projections
          .map((projection) => projection.domain.name)
          .toList(growable: false);
}

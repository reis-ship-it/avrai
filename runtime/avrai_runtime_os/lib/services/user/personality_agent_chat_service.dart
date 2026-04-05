import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/reality/user_visible_governed_learning.dart';
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
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/business/business_operator_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/community/community_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/human_chat_prompt_composer.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_response_composer_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
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
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final UserGovernedLearningProjectionService?
      _userGovernedLearningProjectionService;
  final UserGovernedLearningControlService? _userGovernedLearningControlService;
  final UserGovernedLearningChatObservationService?
      _userGovernedLearningChatObservationService;
  final UserGovernedLearningResponseComposerService
      _userGovernedLearningResponseComposerService;
  final RecommendationFeedbackAssistantFollowUpService?
      _assistantFollowUpService;
  final PostEventFeedbackAssistantFollowUpService?
      _eventAssistantFollowUpService;
  final SavedDiscoveryAssistantFollowUpService?
      _savedDiscoveryAssistantFollowUpService;
  final UserGovernedLearningCorrectionAssistantFollowUpService?
      _correctionAssistantFollowUpService;
  final VisitLocalityAssistantFollowUpService?
      _visitLocalityAssistantFollowUpService;
  final CommunityAssistantFollowUpService? _communityAssistantFollowUpService;
  final OnboardingAssistantFollowUpService? _onboardingAssistantFollowUpService;
  final BusinessOperatorAssistantFollowUpService?
      _businessAssistantFollowUpService;
  final ReservationOperationalAssistantFollowUpService?
      _reservationOperationalAssistantFollowUpService;

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
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    UserGovernedLearningProjectionService?
        userGovernedLearningProjectionService,
    UserGovernedLearningControlService? userGovernedLearningControlService,
    UserGovernedLearningChatObservationService?
        userGovernedLearningChatObservationService,
    UserGovernedLearningResponseComposerService?
        userGovernedLearningResponseComposerService,
    RecommendationFeedbackAssistantFollowUpService? assistantFollowUpService,
    PostEventFeedbackAssistantFollowUpService? eventAssistantFollowUpService,
    SavedDiscoveryAssistantFollowUpService?
        savedDiscoveryAssistantFollowUpService,
    UserGovernedLearningCorrectionAssistantFollowUpService?
        correctionAssistantFollowUpService,
    VisitLocalityAssistantFollowUpService?
        visitLocalityAssistantFollowUpService,
    CommunityAssistantFollowUpService? communityAssistantFollowUpService,
    OnboardingAssistantFollowUpService? onboardingAssistantFollowUpService,
    BusinessOperatorAssistantFollowUpService? businessAssistantFollowUpService,
    ReservationOperationalAssistantFollowUpService?
        reservationOperationalAssistantFollowUpService,
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
        _vibeKernel = vibeKernel ?? VibeKernel(),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.instance
                        .isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.instance<GovernedUpwardLearningIntakeService>()
                    : null),
        _userGovernedLearningProjectionService =
            userGovernedLearningProjectionService ??
                (GetIt.instance
                        .isRegistered<UserGovernedLearningProjectionService>()
                    ? GetIt.instance<UserGovernedLearningProjectionService>()
                    : GetIt.instance.isRegistered<UniversalIntakeRepository>()
                        ? UserGovernedLearningProjectionService(
                            intakeRepository:
                                GetIt.instance<UniversalIntakeRepository>(),
                            signalPolicyService: GetIt.instance.isRegistered<
                                    UserGovernedLearningSignalPolicyService>()
                                ? GetIt.instance<
                                    UserGovernedLearningSignalPolicyService>()
                                : null,
                            adoptionService: GetIt.instance.isRegistered<
                                    UserGovernedLearningAdoptionService>()
                                ? GetIt.instance<
                                    UserGovernedLearningAdoptionService>()
                                : null,
                            observationService: GetIt.instance.isRegistered<
                                    UserGovernedLearningChatObservationService>()
                                ? GetIt.instance<
                                    UserGovernedLearningChatObservationService>()
                                : null,
                            usageService: GetIt.instance.isRegistered<
                                    UserGovernedLearningUsageService>()
                                ? GetIt.instance<
                                    UserGovernedLearningUsageService>()
                                : null,
                          )
                        : null),
        _userGovernedLearningControlService =
            userGovernedLearningControlService ??
                (GetIt.instance
                        .isRegistered<UserGovernedLearningControlService>()
                    ? GetIt.instance<UserGovernedLearningControlService>()
                    : null),
        _userGovernedLearningChatObservationService =
            userGovernedLearningChatObservationService ??
                (GetIt.instance.isRegistered<
                        UserGovernedLearningChatObservationService>()
                    ? GetIt.instance<
                        UserGovernedLearningChatObservationService>()
                    : null),
        _userGovernedLearningResponseComposerService =
            userGovernedLearningResponseComposerService ??
                (GetIt.instance.isRegistered<
                        UserGovernedLearningResponseComposerService>()
                    ? GetIt.instance<
                        UserGovernedLearningResponseComposerService>()
                    : const UserGovernedLearningResponseComposerService()),
        _assistantFollowUpService = assistantFollowUpService ??
            (GetIt.instance.isRegistered<
                    RecommendationFeedbackAssistantFollowUpService>()
                ? GetIt.instance<
                    RecommendationFeedbackAssistantFollowUpService>()
                : null),
        _eventAssistantFollowUpService = eventAssistantFollowUpService ??
            (GetIt.instance
                    .isRegistered<PostEventFeedbackAssistantFollowUpService>()
                ? GetIt.instance<PostEventFeedbackAssistantFollowUpService>()
                : null),
        _savedDiscoveryAssistantFollowUpService =
            savedDiscoveryAssistantFollowUpService ??
                (GetIt.instance
                        .isRegistered<SavedDiscoveryAssistantFollowUpService>()
                    ? GetIt.instance<SavedDiscoveryAssistantFollowUpService>()
                    : null),
        _correctionAssistantFollowUpService =
            correctionAssistantFollowUpService ??
                (GetIt.instance.isRegistered<
                        UserGovernedLearningCorrectionAssistantFollowUpService>()
                    ? GetIt.instance<
                        UserGovernedLearningCorrectionAssistantFollowUpService>()
                    : null),
        _visitLocalityAssistantFollowUpService =
            visitLocalityAssistantFollowUpService ??
                (GetIt.instance
                        .isRegistered<VisitLocalityAssistantFollowUpService>()
                    ? GetIt.instance<VisitLocalityAssistantFollowUpService>()
                    : null),
        _communityAssistantFollowUpService =
            communityAssistantFollowUpService ??
                (GetIt.instance
                        .isRegistered<CommunityAssistantFollowUpService>()
                    ? GetIt.instance<CommunityAssistantFollowUpService>()
                    : null),
        _onboardingAssistantFollowUpService =
            onboardingAssistantFollowUpService ??
                (GetIt.instance
                        .isRegistered<OnboardingAssistantFollowUpService>()
                    ? GetIt.instance<OnboardingAssistantFollowUpService>()
                    : null),
        _businessAssistantFollowUpService = businessAssistantFollowUpService ??
            (GetIt.instance
                    .isRegistered<BusinessOperatorAssistantFollowUpService>()
                ? GetIt.instance<BusinessOperatorAssistantFollowUpService>()
                : null),
        _reservationOperationalAssistantFollowUpService =
            reservationOperationalAssistantFollowUpService ??
                (GetIt.instance.isRegistered<
                        ReservationOperationalAssistantFollowUpService>()
                    ? GetIt.instance<
                        ReservationOperationalAssistantFollowUpService>()
                    : null);

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

      final capturedAssistantFollowUpResponse = await _assistantFollowUpService
          ?.captureActiveAssistantFollowUpResponse(
        ownerUserId: userId,
        responseText: message,
      );
      final capturedEventAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null
              ? await _eventAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedCorrectionAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null
              ? await _correctionAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedVisitLocalityAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null &&
                  capturedCorrectionAssistantFollowUpResponse == null
              ? await _visitLocalityAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedCommunityAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null &&
                  capturedCorrectionAssistantFollowUpResponse == null &&
                  capturedVisitLocalityAssistantFollowUpResponse == null
              ? await _communityAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedOnboardingAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null &&
                  capturedCorrectionAssistantFollowUpResponse == null &&
                  capturedVisitLocalityAssistantFollowUpResponse == null &&
                  capturedCommunityAssistantFollowUpResponse == null
              ? await _onboardingAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedBusinessAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null &&
                  capturedCorrectionAssistantFollowUpResponse == null &&
                  capturedVisitLocalityAssistantFollowUpResponse == null &&
                  capturedCommunityAssistantFollowUpResponse == null &&
                  capturedOnboardingAssistantFollowUpResponse == null
              ? await _businessAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedReservationAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null &&
                  capturedCorrectionAssistantFollowUpResponse == null &&
                  capturedVisitLocalityAssistantFollowUpResponse == null &&
                  capturedCommunityAssistantFollowUpResponse == null &&
                  capturedOnboardingAssistantFollowUpResponse == null &&
                  capturedBusinessAssistantFollowUpResponse == null
              ? await _reservationOperationalAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;
      final capturedSavedDiscoveryAssistantFollowUpResponse =
          capturedAssistantFollowUpResponse == null &&
                  capturedEventAssistantFollowUpResponse == null &&
                  capturedCorrectionAssistantFollowUpResponse == null &&
                  capturedVisitLocalityAssistantFollowUpResponse == null &&
                  capturedCommunityAssistantFollowUpResponse == null &&
                  capturedReservationAssistantFollowUpResponse == null
              ? await _savedDiscoveryAssistantFollowUpService
                  ?.captureActiveAssistantFollowUpResponse(
                  ownerUserId: userId,
                  responseText: message,
                )
              : null;

      // Encrypt and save user message
      final requestArtifact = humanLanguageTurn.interpretation.requestArtifact;
      final sanitizedArtifact = humanLanguageTurn.boundary.sanitizedArtifact;
      final boundaryMetadata = <String, dynamic>{
        'intent': humanLanguageTurn.interpretation.intent.toWireValue(),
        'summary': requestArtifact.summary,
        'privacy_sensitivity':
            humanLanguageTurn.interpretation.privacySensitivity.toWireValue(),
        'asks_for_response': requestArtifact.asksForResponse,
        'asks_for_recommendation': requestArtifact.asksForRecommendation,
        'asks_for_action': requestArtifact.asksForAction,
        'asks_for_explanation': requestArtifact.asksForExplanation,
        'referenced_entities': requestArtifact.referencedEntities,
        'questions': requestArtifact.questions,
        'preference_signals': requestArtifact.preferenceSignals
            .map((entry) => entry.toJson())
            .toList(),
        'share_intent': requestArtifact.shareIntent,
        'accepted': humanLanguageTurn.boundary.accepted,
        'disposition': humanLanguageTurn.boundary.disposition.toWireValue(),
        'transcript_storage_allowed':
            humanLanguageTurn.boundary.transcriptStorageAllowed,
        'storage_allowed': humanLanguageTurn.boundary.storageAllowed,
        'learning_allowed': humanLanguageTurn.boundary.learningAllowed,
        'reason_codes': humanLanguageTurn.boundary.reasonCodes,
        'egress_purpose':
            humanLanguageTurn.boundary.egressPurpose.toWireValue(),
        'sanitized_summary': sanitizedArtifact.summary,
        'sanitized_artifact': sanitizedArtifact.toJson(),
        'safe_questions': sanitizedArtifact.safeQuestions,
        'safe_preference_signals': sanitizedArtifact.safePreferenceSignals
            .map((entry) => entry.toJson())
            .toList(),
        'pseudonymous_actor_ref': sanitizedArtifact.pseudonymousActorRef,
      };
      final governedLearningChatAction = _resolveGovernedLearningChatAction(
        message: message,
        requestArtifact: requestArtifact,
      );

      final storedUserMessage = await _saveMessage(
        chatId: chatId,
        senderId: userId,
        isFromUser: true,
        message: message,
        agentId: agentId,
        userId: userId,
        metadata: <String, dynamic>{
          HumanLanguageBoundaryReview.metadataKey: boundaryMetadata,
        },
      );
      if (governedLearningChatAction == null) {
        await _maybeAcknowledgeRecentGovernedLearningExplanation(
          ownerUserId: userId,
          message: message,
        );
      }
      if (governedLearningChatAction == null) {
        await _stageUpwardLearningBestEffort(
          userId: userId,
          agentId: agentId,
          chatId: chatId,
          storedUserMessage: storedUserMessage,
          boundaryMetadata: boundaryMetadata,
          learningAllowed: humanLanguageTurn.acceptedForLearning,
        );
      }

      // Check if message contains search request
      final searchResults = governedLearningChatAction != null
          ? null
          : await _handleSearchRequest(message, currentLocation);

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

      final governedLearningActionResult = governedLearningChatAction != null
          ? await _handleGovernedLearningChatAction(
              userId: userId,
              action: governedLearningChatAction,
            )
          : null;
      var response = governedLearningActionResult?.response ??
          _renderGroundedAgentResponse(
            message: message,
            humanLanguageTurn: humanLanguageTurn,
            prompt: _promptComposer.compose(
              historyMessages: historyMessages,
              userId: userId,
              personality: personality,
              languageStyle: languageStyle,
              userSignatureSummary: userSignatureSummary,
              structuredFacts: structuredFacts,
              metroContext: metroContext,
              currentLocation: currentLocation,
            ),
            userSignatureSummary: userSignatureSummary,
            structuredFacts: structuredFacts,
            metroContext: metroContext,
            searchResults: searchResults,
          );

      String? assistantFollowUpQuestion;
      String? assistantFollowUpPlanId;
      if (capturedAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier recommendation reaction about "${capturedAssistantFollowUpResponse.entity.title}".';
      } else if (capturedEventAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier event feedback about "${capturedEventAssistantFollowUpResponse.eventTitle}".';
      } else if (capturedCorrectionAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier correction about "${capturedCorrectionAssistantFollowUpResponse.targetSummary}".';
      } else if (capturedVisitLocalityAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier ${capturedVisitLocalityAssistantFollowUpResponse.observationKind} signal about "${capturedVisitLocalityAssistantFollowUpResponse.targetLabel}".';
      } else if (capturedCommunityAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier ${capturedCommunityAssistantFollowUpResponse.followUpKind} signal about "${capturedCommunityAssistantFollowUpResponse.targetLabel}".';
      } else if (capturedOnboardingAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your original onboarding signal${capturedOnboardingAssistantFollowUpResponse.homebase?.trim().isNotEmpty == true ? ' about "${capturedOnboardingAssistantFollowUpResponse.homebase!.trim()}"' : ''}.';
      } else if (capturedBusinessAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier business ${capturedBusinessAssistantFollowUpResponse.action} signal about "${capturedBusinessAssistantFollowUpResponse.businessName}".';
      } else if (capturedReservationAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier reservation ${capturedReservationAssistantFollowUpResponse.operationKind} signal about "${capturedReservationAssistantFollowUpResponse.targetLabel}".';
      } else if (capturedSavedDiscoveryAssistantFollowUpResponse != null) {
        response =
            '$response\n\nThanks. I will keep that answer bounded to your earlier saved discovery action about "${capturedSavedDiscoveryAssistantFollowUpResponse.entity.title}".';
      } else if (governedLearningChatAction == null &&
          !humanLanguageTurn.interpretation.needsClarification) {
        final followUpOffer =
            await _assistantFollowUpService?.maybeOfferFollowUp(
          ownerUserId: userId,
        );
        if (followUpOffer != null) {
          assistantFollowUpQuestion = followUpOffer.plan.promptQuestion;
          assistantFollowUpPlanId = followUpOffer.plan.planId;
          response = '$response\n\n${followUpOffer.assistantPrompt}';
        } else {
          final eventFollowUpOffer =
              await _eventAssistantFollowUpService?.maybeOfferFollowUp(
            ownerUserId: userId,
          );
          if (eventFollowUpOffer != null) {
            assistantFollowUpQuestion = eventFollowUpOffer.plan.promptQuestion;
            assistantFollowUpPlanId = eventFollowUpOffer.plan.planId;
            response = '$response\n\n${eventFollowUpOffer.assistantPrompt}';
          } else {
            final correctionFollowUpOffer =
                await _correctionAssistantFollowUpService?.maybeOfferFollowUp(
              ownerUserId: userId,
            );
            if (correctionFollowUpOffer != null) {
              assistantFollowUpQuestion =
                  correctionFollowUpOffer.plan.promptQuestion;
              assistantFollowUpPlanId = correctionFollowUpOffer.plan.planId;
              response =
                  '$response\n\n${correctionFollowUpOffer.assistantPrompt}';
            } else {
              final visitLocalityFollowUpOffer =
                  await _visitLocalityAssistantFollowUpService
                      ?.maybeOfferFollowUp(
                ownerUserId: userId,
              );
              if (visitLocalityFollowUpOffer != null) {
                assistantFollowUpQuestion =
                    visitLocalityFollowUpOffer.plan.promptQuestion;
                assistantFollowUpPlanId =
                    visitLocalityFollowUpOffer.plan.planId;
                response =
                    '$response\n\n${visitLocalityFollowUpOffer.assistantPrompt}';
              } else {
                final communityFollowUpOffer =
                    await _communityAssistantFollowUpService
                        ?.maybeOfferFollowUp(
                  ownerUserId: userId,
                );
                if (communityFollowUpOffer != null) {
                  assistantFollowUpQuestion =
                      communityFollowUpOffer.plan.promptQuestion;
                  assistantFollowUpPlanId = communityFollowUpOffer.plan.planId;
                  response =
                      '$response\n\n${communityFollowUpOffer.assistantPrompt}';
                } else {
                  final onboardingFollowUpOffer =
                      await _onboardingAssistantFollowUpService
                          ?.maybeOfferFollowUp(
                    ownerUserId: userId,
                  );
                  if (onboardingFollowUpOffer != null) {
                    assistantFollowUpQuestion =
                        onboardingFollowUpOffer.plan.promptQuestion;
                    assistantFollowUpPlanId =
                        onboardingFollowUpOffer.plan.planId;
                    response =
                        '$response\n\n${onboardingFollowUpOffer.assistantPrompt}';
                  } else {
                    final businessFollowUpOffer =
                        await _businessAssistantFollowUpService
                            ?.maybeOfferFollowUp(
                      ownerUserId: userId,
                    );
                    if (businessFollowUpOffer != null) {
                      assistantFollowUpQuestion =
                          businessFollowUpOffer.plan.promptQuestion;
                      assistantFollowUpPlanId =
                          businessFollowUpOffer.plan.planId;
                      response =
                          '$response\n\n${businessFollowUpOffer.assistantPrompt}';
                    } else {
                      final reservationFollowUpOffer =
                          await _reservationOperationalAssistantFollowUpService
                              ?.maybeOfferFollowUp(
                        ownerUserId: userId,
                      );
                      if (reservationFollowUpOffer != null) {
                        assistantFollowUpQuestion =
                            reservationFollowUpOffer.plan.promptQuestion;
                        assistantFollowUpPlanId =
                            reservationFollowUpOffer.plan.planId;
                        response =
                            '$response\n\n${reservationFollowUpOffer.assistantPrompt}';
                      } else {
                        final savedDiscoveryFollowUpOffer =
                            await _savedDiscoveryAssistantFollowUpService
                                ?.maybeOfferFollowUp(
                          ownerUserId: userId,
                        );
                        if (savedDiscoveryFollowUpOffer != null) {
                          assistantFollowUpQuestion =
                              savedDiscoveryFollowUpOffer.plan.promptQuestion;
                          assistantFollowUpPlanId =
                              savedDiscoveryFollowUpOffer.plan.planId;
                          response =
                              '$response\n\n${savedDiscoveryFollowUpOffer.assistantPrompt}';
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Encrypt and save agent response
      final storedAssistantMessage = await _saveMessage(
        chatId: chatId,
        senderId: agentId,
        isFromUser: false,
        message: response,
        agentId: agentId,
        userId: userId,
        metadata: governedLearningActionResult?.assistantMetadata,
      );
      await _recordGovernedLearningChatObservationIfNeeded(
        ownerUserId: userId,
        chatId: chatId,
        storedUserMessage: storedUserMessage,
        storedAssistantMessage: storedAssistantMessage,
        userQuestion: message,
        actionResult: governedLearningActionResult,
        renderedResponse: response,
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
      if (kernelResult != null) {
        return PersonalityAgentChatResult(
          response: response,
          realityKernelFusionInput: kernelResult.realityKernelFusionInput,
          governanceReport: kernelResult.governanceReport,
          humanLanguageTurn: kernelResult.humanLanguageTurn,
          assistantFollowUpPlanId: assistantFollowUpPlanId,
          assistantFollowUpQuestion: assistantFollowUpQuestion,
          assistantFollowUpResponseCaptured:
              capturedAssistantFollowUpResponse != null ||
                  capturedEventAssistantFollowUpResponse != null ||
                  capturedCorrectionAssistantFollowUpResponse != null ||
                  capturedVisitLocalityAssistantFollowUpResponse != null ||
                  capturedCommunityAssistantFollowUpResponse != null ||
                  capturedOnboardingAssistantFollowUpResponse != null ||
                  capturedBusinessAssistantFollowUpResponse != null ||
                  capturedReservationAssistantFollowUpResponse != null ||
                  capturedSavedDiscoveryAssistantFollowUpResponse != null,
        );
      }
      return PersonalityAgentChatResult(
        response: response,
        humanLanguageTurn: humanLanguageTurn,
        assistantFollowUpPlanId: assistantFollowUpPlanId,
        assistantFollowUpQuestion: assistantFollowUpQuestion,
        assistantFollowUpResponseCaptured:
            capturedAssistantFollowUpResponse != null ||
                capturedEventAssistantFollowUpResponse != null ||
                capturedCorrectionAssistantFollowUpResponse != null ||
                capturedVisitLocalityAssistantFollowUpResponse != null ||
                capturedCommunityAssistantFollowUpResponse != null ||
                capturedOnboardingAssistantFollowUpResponse != null ||
                capturedBusinessAssistantFollowUpResponse != null ||
                capturedReservationAssistantFollowUpResponse != null ||
                capturedSavedDiscoveryAssistantFollowUpResponse != null,
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
          if (metroContext?.effectiveGovernedKnowledgeAtUtc != null)
            'metro_effective_knowledge_at': metroContext!
                .effectiveGovernedKnowledgeAtUtc!
                .toUtc()
                .toIso8601String(),
          if (metroContext?.governedKnowledgeSyncedAtUtc != null)
            'metro_governed_knowledge_synced_at': metroContext!
                .governedKnowledgeSyncedAtUtc!
                .toUtc()
                .toIso8601String(),
          if (metroContext?.governedKnowledgePhase?.trim().isNotEmpty ?? false)
            'metro_governed_knowledge_phase':
                metroContext!.governedKnowledgePhase,
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
          if (metroContext?.effectiveGovernedKnowledgeAtUtc != null)
            'metro_effective_knowledge_at': metroContext!
                .effectiveGovernedKnowledgeAtUtc!
                .toUtc()
                .toIso8601String(),
          if (metroContext?.governedKnowledgePhase?.trim().isNotEmpty ?? false)
            'metro_governed_knowledge_phase':
                metroContext!.governedKnowledgePhase,
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

  bool _isGovernedLearningInquiry({
    required String message,
    required InterpretationRequestArtifact requestArtifact,
  }) {
    final normalized = message.toLowerCase();
    const phrases = <String>[
      'what did you learn from me',
      'what have you learned from me',
      'what did you learn about me',
      'what have you learned about me',
      'what do you know about me',
      'what did you store about me',
      'what have you stored about me',
      'what did you infer about me',
      'how did you change because of me',
      'why did you change because of me',
      'did you change because of me',
      'did you update because of me',
      'what changed because of me',
      'show me what this came from',
      'show me where this came from',
      'what recommendation did this affect',
      'which recommendation did this affect',
    ];
    if (phrases.any(normalized.contains)) {
      return true;
    }
    if (!requestArtifact.asksForExplanation) {
      return false;
    }
    const learningKeywords = <String>[
      'learn',
      'know',
      'store',
      'infer',
      'change',
      'update',
    ];
    return learningKeywords.any(normalized.contains);
  }

  _GovernedLearningChatAction? _resolveGovernedLearningChatAction({
    required String message,
    required InterpretationRequestArtifact requestArtifact,
  }) {
    final normalized = message.trim().toLowerCase();
    final correctionCommand = _parseGovernedLearningCorrectionCommand(message);
    if (correctionCommand != null) {
      return _GovernedLearningChatAction.correct(
        correctionCommand.correctionText,
        recordQuery: correctionCommand.recordQuery,
      );
    }
    const forgetPhrases = <String>[
      'forget that',
      'forget it',
      'forget this',
      'forget what you learned',
      'delete that learning',
      'remove that learning',
    ];
    if (forgetPhrases.any(normalized.contains)) {
      return const _GovernedLearningChatAction.forget();
    }
    const stopPhrases = <String>[
      'stop using that signal',
      'stop using this signal',
      'stop learning from that',
      'stop learning from this',
      'do not use that signal',
      'don\'t use that signal',
      'do not use this signal',
      'don\'t use this signal',
    ];
    if (stopPhrases.any(normalized.contains)) {
      return const _GovernedLearningChatAction.stopUsing();
    }
    if (_isGovernedLearningInquiry(
      message: message,
      requestArtifact: requestArtifact,
    )) {
      return _GovernedLearningChatAction.explain(recordQuery: message);
    }
    final forgetTarget = _extractGovernedLearningRecordQuery(
      message,
      prefixes: const <String>[
        'forget ',
        'delete ',
        'remove ',
      ],
    );
    if (forgetTarget != null) {
      return _GovernedLearningChatAction.forget(recordQuery: forgetTarget);
    }
    final stopTarget = _extractGovernedLearningRecordQuery(
      message,
      prefixes: const <String>[
        'stop using ',
        'do not use ',
        'don\'t use ',
        'stop learning from ',
      ],
      suffixes: const <String>[
        ' signal',
        ' for learning',
      ],
    );
    if (stopTarget != null) {
      return _GovernedLearningChatAction.stopUsing(recordQuery: stopTarget);
    }
    return null;
  }

  _GovernedLearningCorrectionCommand? _parseGovernedLearningCorrectionCommand(
    String message,
  ) {
    final trimmed = message.trim();
    final normalized = trimmed.toLowerCase();
    final colonMatch = RegExp(
      r'^(?:please\s+)?(?:correct|change|update)\s+(.+?)\s*:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (colonMatch != null) {
      final recordQuery = _normalizeRecordQuery(colonMatch.group(1));
      final correctionText = colonMatch.group(2)?.trim() ?? '';
      if (correctionText.isNotEmpty) {
        return _GovernedLearningCorrectionCommand(
          correctionText: correctionText,
          recordQuery: recordQuery,
        );
      }
    }
    final toMatch = RegExp(
      r'^(?:please\s+)?(?:correct|change|update)\s+(.+?)\s+to\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (toMatch != null) {
      final recordQuery = _normalizeRecordQuery(toMatch.group(1));
      final correctionText = toMatch.group(2)?.trim() ?? '';
      if (correctionText.isNotEmpty) {
        return _GovernedLearningCorrectionCommand(
          correctionText: correctionText,
          recordQuery: recordQuery,
        );
      }
    }
    const pronounCues = <String>[
      'correct that:',
      'correct this:',
      'correct it:',
      'correct that to ',
      'correct this to ',
      'correct it to ',
      'change that to ',
      'change this to ',
      'change it to ',
      'update that to ',
      'update this to ',
      'update it to ',
      'correction: ',
      'correction:',
    ];
    for (final cue in pronounCues) {
      final index = normalized.indexOf(cue);
      if (index == -1) {
        continue;
      }
      final correctionText = trimmed.substring(index + cue.length).trim();
      if (correctionText.isNotEmpty) {
        return _GovernedLearningCorrectionCommand(
          correctionText: correctionText,
        );
      }
    }
    return null;
  }

  String? _extractGovernedLearningRecordQuery(
    String message, {
    required List<String> prefixes,
    List<String> suffixes = const <String>[],
  }) {
    final normalized = message.trim().toLowerCase();
    for (final prefix in prefixes) {
      if (!normalized.startsWith(prefix)) {
        continue;
      }
      var candidate = message.trim().substring(prefix.length).trim();
      for (final suffix in suffixes) {
        if (candidate.toLowerCase().endsWith(suffix)) {
          candidate = candidate.substring(0, candidate.length - suffix.length);
          break;
        }
      }
      return _normalizeRecordQuery(candidate);
    }
    return null;
  }

  String? _normalizeRecordQuery(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw
        .trim()
        .replaceAll(RegExp(r'^(the|that|this|it)\s+', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'\s+(one|record|signal)$', caseSensitive: false), '')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (const <String>{'that', 'this', 'it'}
        .contains(normalized.toLowerCase())) {
      return null;
    }
    return normalized;
  }

  Future<_GovernedLearningChatActionResult> _handleGovernedLearningChatAction({
    required String userId,
    required _GovernedLearningChatAction action,
  }) async {
    switch (action.kind) {
      case _GovernedLearningChatActionKind.explain:
        return _renderGovernedLearningChatResponse(
          userId: userId,
          query: action.recordQuery,
        );
      case _GovernedLearningChatActionKind.forget:
        return _forgetGovernedLearningRecord(
          userId: userId,
          query: action.recordQuery,
        );
      case _GovernedLearningChatActionKind.stopUsing:
        return _stopUsingGovernedLearningSignal(
          userId: userId,
          query: action.recordQuery,
        );
      case _GovernedLearningChatActionKind.correct:
        return _correctGovernedLearningRecord(
          userId: userId,
          correctionText: action.correctionText ?? '',
          query: action.recordQuery,
        );
    }
  }

  Future<_GovernedLearningChatActionResult>
      _renderGovernedLearningChatResponse({
    required String userId,
    String? query,
  }) async {
    final service = _userGovernedLearningProjectionService;
    if (service == null) {
      return const _GovernedLearningChatActionResult(
        response:
            'I can explain what I have learned once your governed learning ledger is available.',
        kind: _GovernedLearningChatActionKind.explain,
      );
    }
    final explanation = await service.buildChatExplanation(
      ownerUserId: userId,
      query: query,
    );
    var selectedRecord = explanation.selectedRecord;
    if (selectedRecord == null) {
      final segments = <String>[explanation.summary];
      segments.addAll(explanation.details.take(3));
      return _GovernedLearningChatActionResult(
        response: segments.join(' '),
        kind: _GovernedLearningChatActionKind.explain,
      );
    }
    var visibleRecords = explanation.records;
    final observationService = _userGovernedLearningChatObservationService;
    if (observationService != null) {
      final followUpMarked = await observationService.markLatestPendingOutcome(
        ownerUserId: userId,
        envelopeId: selectedRecord.envelopeId,
        outcome: GovernedLearningChatObservationOutcome.requestedFollowUp,
      );
      if (followUpMarked != null) {
        final refreshedExplanation = await service.buildChatExplanation(
          ownerUserId: userId,
          query: query,
        );
        selectedRecord = refreshedExplanation.selectedRecord ?? selectedRecord;
        visibleRecords = refreshedExplanation.records;
      }
    }
    final composed = _userGovernedLearningResponseComposerService.compose(
      selectedRecord: selectedRecord,
      visibleRecords: visibleRecords,
      userQuestion: query,
    );
    return _GovernedLearningChatActionResult(
      response: composed.render(),
      kind: _GovernedLearningChatActionKind.explain,
      selectedRecord: selectedRecord,
      focus: composed.focus,
      assistantMetadata: <String, dynamic>{
        'governedLearningEnvelopeId': selectedRecord.envelopeId,
        'governedLearningSourceId': selectedRecord.sourceId,
        'governedLearningFocus': composed.focus.name,
      },
    );
  }

  Future<_GovernedLearningChatActionResult> _forgetGovernedLearningRecord({
    required String userId,
    String? query,
  }) async {
    final controlService = _userGovernedLearningControlService;
    final selectedRecord = await _loadTargetGovernedLearningRecord(
      userId: userId,
      query: query,
    );
    if (controlService == null || selectedRecord == null) {
      return const _GovernedLearningChatActionResult(
        response:
            'I can explain your governed learning records, but I cannot forget one from chat on this device yet.',
        kind: _GovernedLearningChatActionKind.forget,
      );
    }
    final forgotten = await controlService.forgetRecord(
      ownerUserId: userId,
      envelopeId: selectedRecord.envelopeId,
    );
    if (!forgotten) {
      return const _GovernedLearningChatActionResult(
        response:
            'I could not find the governed learning record you wanted to forget.',
        kind: _GovernedLearningChatActionKind.forget,
      );
    }
    return _GovernedLearningChatActionResult(
      response:
          'I forgot the governed learning record about "${selectedRecord.safeSummary}". It will no longer appear in chat explanations or your Data Center ledger.',
      kind: _GovernedLearningChatActionKind.forget,
      selectedRecord: selectedRecord,
    );
  }

  Future<_GovernedLearningChatActionResult> _stopUsingGovernedLearningSignal({
    required String userId,
    String? query,
  }) async {
    final controlService = _userGovernedLearningControlService;
    final selectedRecord = await _loadTargetGovernedLearningRecord(
      userId: userId,
      query: query,
    );
    if (controlService == null || selectedRecord == null) {
      return const _GovernedLearningChatActionResult(
        response:
            'I can explain your governed learning records, but I cannot change signal-use policy from chat on this device yet.',
        kind: _GovernedLearningChatActionKind.stopUsing,
      );
    }
    final stopped = await controlService.stopUsingSignal(
      ownerUserId: userId,
      envelopeId: selectedRecord.envelopeId,
    );
    if (!stopped) {
      return const _GovernedLearningChatActionResult(
        response: 'I could not update that governed learning signal policy.',
        kind: _GovernedLearningChatActionKind.stopUsing,
      );
    }
    return _GovernedLearningChatActionResult(
      response:
          'I will stop using future ${_humanizeGovernedLearningConvictionTier(selectedRecord.convictionTier)} signals from ${selectedRecord.sourceProvider} for governed learning. The current record stays visible so you can still inspect it.',
      kind: _GovernedLearningChatActionKind.stopUsing,
      selectedRecord: selectedRecord,
    );
  }

  Future<_GovernedLearningChatActionResult> _correctGovernedLearningRecord({
    required String userId,
    required String correctionText,
    String? query,
  }) async {
    final controlService = _userGovernedLearningControlService;
    final selectedRecord = await _loadTargetGovernedLearningRecord(
      userId: userId,
      query: query,
    );
    if (controlService == null || selectedRecord == null) {
      return const _GovernedLearningChatActionResult(
        response:
            'I can explain your governed learning records, but I cannot stage a correction from chat on this device yet.',
        kind: _GovernedLearningChatActionKind.correct,
      );
    }
    if (correctionText.trim().isEmpty) {
      return const _GovernedLearningChatActionResult(
        response:
            'Tell me the correction text directly, for example: "Correct that: I wanted a louder place."',
        kind: _GovernedLearningChatActionKind.correct,
      );
    }
    final result = await controlService.submitCorrection(
      ownerUserId: userId,
      envelopeId: selectedRecord.envelopeId,
      correctionText: correctionText,
    );
    if (result == null) {
      return const _GovernedLearningChatActionResult(
        response:
            'I could not stage a correction for that governed learning record.',
        kind: _GovernedLearningChatActionKind.correct,
      );
    }
    return _GovernedLearningChatActionResult(
      response:
          'I staged a governed correction against the learning record about "${selectedRecord.safeSummary}". Your correction says: "$correctionText". It will go through governed review before broader use, and once it starts shaping relevant suggestions you should notice the change. If you do not, let me know.',
      kind: _GovernedLearningChatActionKind.correct,
      selectedRecord: selectedRecord,
    );
  }

  Future<UserVisibleGovernedLearningRecord?> _loadTargetGovernedLearningRecord({
    required String userId,
    String? query,
  }) async {
    final service = _userGovernedLearningProjectionService;
    if (service == null) {
      return null;
    }
    return service.resolveRelevantRecord(
      ownerUserId: userId,
      query: query,
      limit: 20,
    );
  }

  Future<void> _maybeAcknowledgeRecentGovernedLearningExplanation({
    required String ownerUserId,
    required String message,
  }) async {
    final observationService = _userGovernedLearningChatObservationService;
    if (observationService == null ||
        !_looksLikeGovernedLearningAcknowledgement(message)) {
      return;
    }
    await observationService.markLatestPendingOutcome(
      ownerUserId: ownerUserId,
      outcome: GovernedLearningChatObservationOutcome.acknowledged,
    );
  }

  Future<void> _recordGovernedLearningChatObservationIfNeeded({
    required String ownerUserId,
    required String chatId,
    required PersonalityChatMessage storedUserMessage,
    required PersonalityChatMessage storedAssistantMessage,
    required String userQuestion,
    required String renderedResponse,
    required _GovernedLearningChatActionResult? actionResult,
  }) async {
    final observationService = _userGovernedLearningChatObservationService;
    final selectedRecord = actionResult?.selectedRecord;
    final kind = actionResult?.kind;
    if (observationService == null || selectedRecord == null || kind == null) {
      return;
    }
    switch (kind) {
      case _GovernedLearningChatActionKind.explain:
        await observationService.recordReceipts([
          GovernedLearningChatObservationReceipt(
            id: '${selectedRecord.envelopeId}:${storedAssistantMessage.messageId}:explanation',
            ownerUserId: ownerUserId,
            envelopeId: selectedRecord.envelopeId,
            sourceId: selectedRecord.sourceId,
            kind: GovernedLearningChatObservationKind.explanation,
            outcome: GovernedLearningChatObservationOutcome.pending,
            recordedAtUtc: storedAssistantMessage.timestamp.toUtc(),
            chatId: chatId,
            userMessageId: storedUserMessage.messageId,
            assistantMessageId: storedAssistantMessage.messageId,
            focus: actionResult?.focus?.name,
            userQuestion: userQuestion,
            renderedResponse: renderedResponse,
          ),
        ]);
        break;
      case _GovernedLearningChatActionKind.correct:
        await observationService.markLatestPendingOutcome(
          ownerUserId: ownerUserId,
          envelopeId: selectedRecord.envelopeId,
          outcome: GovernedLearningChatObservationOutcome.correctedRecord,
        );
        break;
      case _GovernedLearningChatActionKind.forget:
        await observationService.markLatestPendingOutcome(
          ownerUserId: ownerUserId,
          envelopeId: selectedRecord.envelopeId,
          outcome: GovernedLearningChatObservationOutcome.forgotRecord,
        );
        break;
      case _GovernedLearningChatActionKind.stopUsing:
        await observationService.markLatestPendingOutcome(
          ownerUserId: ownerUserId,
          envelopeId: selectedRecord.envelopeId,
          outcome: GovernedLearningChatObservationOutcome.stoppedUsingSignal,
        );
        break;
    }
  }

  bool _looksLikeGovernedLearningAcknowledgement(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    const phrases = <String>[
      'thanks',
      'thank you',
      'that helps',
      'helpful',
      'makes sense',
      'got it',
      'understood',
      'okay that makes sense',
      'ok that makes sense',
    ];
    return phrases.any(normalized.contains);
  }

  String _humanizeGovernedLearningConvictionTier(String convictionTier) {
    switch (convictionTier) {
      case 'personal_agent_human_observation':
        return 'personal human observation';
      case 'explicit_correction_signal':
        return 'explicit correction';
      case 'ai2ai_explicit_correction_signal':
        return 'AI2AI explicit correction';
      case 'recommendation_feedback_correction_signal':
        return 'recommendation feedback correction';
      default:
        return convictionTier.replaceAll('_', ' ').trim();
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
  Future<PersonalityChatMessage> _saveMessage({
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
      return chatMessage;
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

  Future<void> _stageUpwardLearningBestEffort({
    required String userId,
    required String agentId,
    required String chatId,
    required PersonalityChatMessage storedUserMessage,
    required Map<String, dynamic> boundaryMetadata,
    required bool learningAllowed,
  }) async {
    if (!learningAllowed) {
      return;
    }
    final service = _governedUpwardLearningIntakeService;
    if (service == null) {
      return;
    }
    try {
      final sourceKind = boundaryMetadata['intent']?.toString() == 'correct'
          ? 'explicit_correction_intake'
          : 'personal_agent_human_intake';
      final airGapArtifact = const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: sourceKind,
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'actorAgentId': agentId,
          'chatId': chatId,
          'messageId': storedUserMessage.messageId,
          'boundaryMetadata': boundaryMetadata,
        },
        pseudonymousActorRef:
            boundaryMetadata['pseudonymous_actor_ref']?.toString(),
      );
      await service.stagePersonalAgentHumanIntake(
        ownerUserId: userId,
        actorAgentId: agentId,
        chatId: chatId,
        messageId: storedUserMessage.messageId,
        occurredAtUtc: storedUserMessage.timestamp.toUtc(),
        boundaryMetadata: boundaryMetadata,
        airGapArtifact: airGapArtifact,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to stage governed upward learning intake for personality-agent chat',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
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

enum _GovernedLearningChatActionKind {
  explain,
  forget,
  stopUsing,
  correct,
}

class _GovernedLearningChatAction {
  const _GovernedLearningChatAction._(
    this.kind, {
    this.correctionText,
    this.recordQuery,
  });

  const _GovernedLearningChatAction.explain({String? recordQuery})
      : this._(
          _GovernedLearningChatActionKind.explain,
          recordQuery: recordQuery,
        );

  const _GovernedLearningChatAction.forget({String? recordQuery})
      : this._(
          _GovernedLearningChatActionKind.forget,
          recordQuery: recordQuery,
        );

  const _GovernedLearningChatAction.stopUsing({String? recordQuery})
      : this._(
          _GovernedLearningChatActionKind.stopUsing,
          recordQuery: recordQuery,
        );

  const _GovernedLearningChatAction.correct(
    String correctionText, {
    String? recordQuery,
  }) : this._(
          _GovernedLearningChatActionKind.correct,
          correctionText: correctionText,
          recordQuery: recordQuery,
        );

  final _GovernedLearningChatActionKind kind;
  final String? correctionText;
  final String? recordQuery;
}

class _GovernedLearningCorrectionCommand {
  const _GovernedLearningCorrectionCommand({
    required this.correctionText,
    this.recordQuery,
  });

  final String correctionText;
  final String? recordQuery;
}

class _GovernedLearningChatActionResult {
  const _GovernedLearningChatActionResult({
    required this.response,
    required this.kind,
    this.selectedRecord,
    this.focus,
    this.assistantMetadata,
  });

  final String response;
  final _GovernedLearningChatActionKind kind;
  final UserVisibleGovernedLearningRecord? selectedRecord;
  final UserGovernedLearningResponseFocus? focus;
  final Map<String, dynamic>? assistantMetadata;
}

class PersonalityAgentChatResult {
  const PersonalityAgentChatResult({
    required this.response,
    this.realityKernelFusionInput,
    this.governanceReport,
    this.humanLanguageTurn,
    this.assistantFollowUpPlanId,
    this.assistantFollowUpQuestion,
    this.assistantFollowUpResponseCaptured = false,
  });

  final String response;
  final RealityKernelFusionInput? realityKernelFusionInput;
  final KernelGovernanceReport? governanceReport;
  final HumanLanguageKernelTurn? humanLanguageTurn;
  final String? assistantFollowUpPlanId;
  final String? assistantFollowUpQuestion;
  final bool assistantFollowUpResponseCaptured;

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

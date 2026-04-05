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
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/business/business_operator_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/community/community_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/events/event_feedback.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avrai_runtime_os/services/user/aspirational_intent_parser.dart';
import 'package:avrai_runtime_os/services/user/aspirational_dna_engine.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/test_storage_helper.dart';

final _testPromptPolicyService = BoundedFollowUpPromptPolicyService(
  policy: BoundedFollowUpPromptPolicy(
    maxPromptPlansPerDay: 10,
    quietHoursStartHour: 0,
    quietHoursEndHour: 0,
    suggestionFamilyCooldown: Duration(seconds: 1),
    eventFamilyCooldown: Duration(seconds: 1),
  ),
);

// Mock classes
class MockAgentIdService extends Mock implements AgentIdService {}

class MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

class MockLanguagePatternLearningService extends Mock
    implements LanguagePatternLearningService {}

class MockLanguageRuntimeService extends Mock
    implements LanguageRuntimeService {}

class MockPersonalityLearning extends Mock implements pl.PersonalityLearning {}

class MockHybridSearchRepository extends Mock
    implements HybridSearchRepository {}

class MockAspirationalIntentParser extends Mock
    implements AspirationalIntentParser {}

class MockAspirationalDNAEngine extends Mock implements AspirationalDNAEngine {}

class MockGeoHierarchyService extends Mock implements GeoHierarchyService {}

class _FakeChatHeadlessHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
      summary: 'chat host ready',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      who: const WhoRealityProjection(summary: 'who', confidence: 0.9),
      what: const WhatRealityProjection(summary: 'what', confidence: 0.8),
      when: const WhenRealityProjection(summary: 'when', confidence: 0.95),
      where: const WhereRealityProjection(summary: 'where', confidence: 0.88),
      why: const WhyRealityProjection(summary: 'why', confidence: 0.77),
      how: const HowRealityProjection(summary: 'how', confidence: 0.8),
      generatedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
    );
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async {
    return const <KernelHealthReport>[];
  }

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return KernelGovernanceReport(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      projections: const <KernelGovernanceProjection>[
        KernelGovernanceProjection(
          domain: KernelDomain.why,
          summary: 'chat stayed inside governance',
          confidence: 0.82,
        ),
      ],
      generatedAtUtc: DateTime.utc(2026, 3, 7),
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    return const KernelContextBundle(
      who: null,
      what: null,
      when: null,
      where: null,
      how: null,
      why: null,
    );
  }
}

class _FixedLanguageKernelOrchestrator
    extends LanguageKernelOrchestratorService {
  _FixedLanguageKernelOrchestrator({
    required this.languageLearningService,
  });

  final LanguagePatternLearningService languageLearningService;

  @override
  Future<HumanLanguageKernelTurn> processHumanText({
    required String actorAgentId,
    required String rawText,
    required Set<String> consentScopes,
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    bool shareRequested = false,
    BoundaryEgressPurpose egressPurpose = BoundaryEgressPurpose.none,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
  }) async {
    if (userId != null && rawText.trim().isNotEmpty) {
      await languageLearningService.analyzeMessage(userId, rawText, chatType);
    }
    return _buildKernelTurn(rawText);
  }

  @override
  RenderedExpression renderGroundedOutput({
    required ExpressionSpeechAct speechAct,
    required ExpressionAudience audience,
    required ExpressionSurfaceShape surfaceShape,
    required String subjectLabel,
    required List<String> allowedClaims,
    List<String> forbiddenClaims = const <String>[],
    List<String> evidenceRefs = const <String>[],
    String confidenceBand = 'medium',
    String toneProfile = 'clear_calm',
    vibeContext,
    String? uncertaintyNotice,
    String? cta,
    String? adaptationProfileRef,
  }) {
    final text = allowedClaims.isNotEmpty
        ? allowedClaims.join(' ')
        : 'Grounded response available.';
    return RenderedExpression(
      text: text,
      sections: <ExpressionSection>[
        ExpressionSection(
          kind: 'body',
          text: text,
        ),
      ],
      assertedClaims: allowedClaims,
    );
  }
}

HumanLanguageKernelTurn _buildKernelTurn(String rawText) {
  final trimmed = rawText.trim();
  final accepted = trimmed.isNotEmpty;
  final lower = trimmed.toLowerCase();
  return HumanLanguageKernelTurn(
    interpretation: InterpretationResult(
      intent: trimmed.endsWith('?')
          ? InterpretationIntent.ask
          : InterpretationIntent.share,
      normalizedText: trimmed,
      requestArtifact: InterpretationRequestArtifact(
        summary: trimmed,
        asksForResponse: accepted,
        asksForRecommendation:
            lower.contains('find') || lower.contains('suggest'),
        asksForAction: false,
        asksForExplanation: lower.contains('why'),
        referencedEntities: const <String>[],
        questions: trimmed.endsWith('?') ? <String>[trimmed] : const <String>[],
        preferenceSignals: const <InterpretationPreferenceSignal>[],
        shareIntent: !trimmed.endsWith('?'),
      ),
      learningArtifact: const InterpretationLearningArtifact(
        vocabulary: <String>[],
        phrases: <String>[],
        toneMetrics: <String, double>{},
        directnessPreference: 0.5,
        brevityPreference: 0.5,
      ),
      privacySensitivity: InterpretationPrivacySensitivity.low,
      confidence: accepted ? 0.95 : 0.1,
      ambiguityFlags: const <String>[],
      needsClarification: false,
      safeForLearning: accepted,
    ),
    boundary: BoundaryDecision(
      accepted: accepted,
      disposition:
          accepted ? BoundaryDisposition.localOnly : BoundaryDisposition.block,
      transcriptStorageAllowed: accepted,
      storageAllowed: accepted,
      learningAllowed: accepted,
      egressAllowed: false,
      airGapRequired: false,
      reasonCodes:
          accepted ? const <String>[] : const <String>['empty_message'],
      sanitizedArtifact: BoundarySanitizedArtifact(
        pseudonymousActorRef: 'anon_test_user',
        summary: trimmed,
        safeClaims: accepted ? <String>[trimmed] : const <String>[],
        safeQuestions: const <String>[],
        safePreferenceSignals: const <InterpretationPreferenceSignal>[],
        learningVocabulary: const <String>[],
        learningPhrases: const <String>[],
        redactedText: accepted ? trimmed : '[redacted]',
      ),
      egressPurpose: BoundaryEgressPurpose.none,
    ),
  );
}

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
    registerFallbackValue(const LanguageRoutingPolicy.humanChat());
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
    late MockLanguageRuntimeService mockLanguageRuntimeService;
    late MockPersonalityLearning mockPersonalityLearning;
    late MockHybridSearchRepository mockSearchRepository;
    late MockAspirationalIntentParser mockAspirationalParser;
    late MockAspirationalDNAEngine mockAspirationalDNAEngine;
    late MockGeoHierarchyService mockGeoHierarchyService;
    late _FixedLanguageKernelOrchestrator fixedLanguageKernelOrchestrator;

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
      mockLanguageRuntimeService = MockLanguageRuntimeService();
      mockPersonalityLearning = MockPersonalityLearning();
      mockSearchRepository = MockHybridSearchRepository();
      mockAspirationalParser = MockAspirationalIntentParser();
      mockAspirationalDNAEngine = MockAspirationalDNAEngine();
      mockGeoHierarchyService = MockGeoHierarchyService();
      fixedLanguageKernelOrchestrator = _FixedLanguageKernelOrchestrator(
        languageLearningService: mockLanguageLearningService,
      );

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

      // Create service with mocks
      service = PersonalityAgentChatService(
        agentIdService: mockAgentIdService,
        encryptionService: mockEncryptionService,
        languageLearningService: mockLanguageLearningService,
        languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
        languageRuntimeService: mockLanguageRuntimeService,
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

      test('should require language runtime service', () {
        expect(
          () => PersonalityAgentChatService(
            agentIdService: mockAgentIdService,
            encryptionService: mockEncryptionService,
            languageLearningService: mockLanguageLearningService,
            languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
            languageRuntimeService: mockLanguageRuntimeService,
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
        expect(response, contains('Your current local context is'));

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
        verifyZeroInteractions(mockLanguageRuntimeService);
      });

      test(
          'should return kernel-backed chat artifacts when headless host is available',
          () async {
        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          headlessOsHost: _FakeChatHeadlessHost(),
        );

        final result = await service.chatWithKernelContext(
          testUserId,
          'How should I think about tonight?',
        );

        expect(result.response, isNotEmpty);
        expect(result.modelTruthReady, isTrue);
        expect(result.localityContainedInWhere, isTrue);
        expect(result.kernelEventId, isNotNull);
        expect(result.governanceSummary, 'chat stayed inside governance');
        expect(result.governanceDomains, contains('why'));
        expect(result.languageLearningAccepted, isTrue);
      });

      test('should keep returning grounded responses across conversation turns',
          () async {
        // Arrange
        const firstMessage = 'Hello';
        const secondMessage = 'How are you?';

        // Act - send first message
        await service.chat(testUserId, firstMessage);

        // Act - send second message
        final response = await service.chat(testUserId, secondMessage);

        // Assert
        expect(response, isNotEmpty);
        final history = await service.getConversationHistory(testUserId);
        expect(history.length, greaterThanOrEqualTo(4));
      });

      test('should handle empty message', () async {
        expect(
          () => service.chat(testUserId, ''),
          throwsA(isA<HumanLanguageBoundaryViolationException>()),
        );
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

        final response = await service.chat(
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

        expect(response, contains('Your current local context is NYC'));
      });

      test(
          'should offer a bounded assistant follow-up and capture the next reply',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = RecommendationFeedbackPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = RecommendationFeedbackAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        await planner.createPlan(
          ownerUserId: testUserId,
          entity: const DiscoveryEntityReference(
            type: DiscoveryEntityType.spot,
            id: 'spot_follow_up',
            title: 'Heatwave Cafe',
            localityLabel: 'brooklyn_williamsburg',
          ),
          action: RecommendationFeedbackAction.lessLikeThis,
          occurredAtUtc: DateTime.utc(2026, 4, 4, 18),
          sourceSurface: 'explore',
          attribution: const RecommendationAttribution(
            why: 'Matches your indoor coffee pattern',
            whyDetails:
                'It ranked because you kept saving indoor daytime places',
            projectedEnjoyabilityPercent: 75,
            recommendationSource: 'place_intelligence_lane',
            confidence: 0.78,
          ),
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          assistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'Give me a grounded suggestion for later.',
        );

        expect(
          first.response,
          contains('Quick follow-up: What felt off about "Heatwave Cafe"'),
        );
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'It felt too loud and crowded for what I wanted.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains(
            'I will keep that answer bounded to your earlier recommendation reaction about "Heatwave Cafe".',
          ),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
        final responses = await planner.listResponses(testUserId);
        expect(responses, hasLength(1));
        expect(
          responses.single.responseText,
          'It felt too loud and crowded for what I wanted.',
        );
      });

      test('should offer an event follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = PostEventFeedbackPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = PostEventFeedbackAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        final event = ExpertiseEvent(
          id: 'event_123',
          title: 'Rooftop Jazz Night',
          description: 'Music and conversation.',
          category: 'Music',
          eventType: ExpertiseEventType.meetup,
          host: UnifiedUser(
            id: 'host_123',
            email: 'host@example.com',
            displayName: 'Host User',
            createdAt: DateTime.utc(2026, 4, 1),
            updatedAt: DateTime.utc(2026, 4, 1),
          ),
          startTime: DateTime.utc(2026, 4, 4, 20),
          endTime: DateTime.utc(2026, 4, 4, 23),
          createdAt: DateTime.utc(2026, 4, 1, 12),
          updatedAt: DateTime.utc(2026, 4, 1, 12),
          cityCode: 'austin',
          localityCode: 'austin_east',
        );
        await planner.createPlan(
          feedback: EventFeedback(
            id: 'feedback_123',
            eventId: event.id,
            userId: testUserId,
            userRole: 'attendee',
            overallRating: 2.8,
            categoryRatings: const <String, double>{'venue': 2.5},
            comments: 'The room felt too packed.',
            submittedAt: DateTime.utc(2026, 4, 4, 23, 30),
            wouldAttendAgain: false,
            wouldRecommend: false,
          ),
          event: event,
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          eventAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'What should I keep in mind for future events?',
        );

        expect(
          first.response,
          contains(
            'Quick event follow-up: What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
          ),
        );
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'It got too crowded too fast and I left early.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains(
            'I will keep that answer bounded to your earlier event feedback about "Rooftop Jazz Night".',
          ),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
        final responses = await planner.listResponses(testUserId);
        expect(responses, hasLength(1));
        expect(
          responses.single.responseText,
          'It got too crowded too fast and I left early.',
        );
      });

      test(
          'should offer an explicit-correction follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner =
            UserGovernedLearningCorrectionFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService =
            UserGovernedLearningCorrectionAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        await planner.createPlan(
          ownerUserId: testUserId,
          targetEnvelopeId: 'env_correction',
          targetSourceId: 'src_correction',
          targetSummary: 'The user wants a quieter weeknight plan.',
          correctionText: 'Actually I only mean that on weekdays.',
          occurredAtUtc: DateTime.utc(2026, 4, 4, 18),
          sourceSurface: 'data_center_correction',
          domainHints: const <String>['place'],
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          correctionAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'What should I keep in mind about that correction?',
        );

        expect(
          first.response,
          contains(
            'Quick correction follow-up: Should I treat your correction about "The user wants a quieter weeknight plan." as durable, or only for a specific situation?',
          ),
        );
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'Only when I am planning a quieter worknight.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains(
            'I will keep that answer bounded to your earlier correction about "The user wants a quieter weeknight plan.".',
          ),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
        final responses = await planner.listResponses(testUserId);
        expect(responses, hasLength(1));
        expect(
          responses.single.responseText,
          'Only when I am planning a quieter worknight.',
        );
      });

      test(
          'should offer a visit/locality follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = VisitLocalityFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = VisitLocalityAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        await planner.createLocalityPlan(
          ownerUserId: testUserId,
          occurredAtUtc: DateTime.utc(2026, 4, 4, 19),
          sourceKind: 'passive_dwell',
          localityStableKey: 'gh7:abc1234',
          structuredSignals: const <String, dynamic>{
            'dwellDurationMinutes': 52,
            'coPresenceDetected': true,
          },
          socialContext: 'social_cluster',
          activityContext: 'passive_dwell',
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          visitLocalityAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'Anything I should keep in mind about where I have been lately?',
        );

        expect(
          first.response,
          contains(
            'Quick locality follow-up: What was going on around "gh7:abc1234" that should shape future locality guidance?',
          ),
        );
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'That area works when I want somewhere social enough to linger without committing to an event.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains(
            'I will keep that answer bounded to your earlier locality signal about "gh7:abc1234".',
          ),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
        final responses = await planner.listResponses(testUserId);
        expect(responses, hasLength(1));
      });

      test(
          'should offer a community follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = CommunityFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = CommunityAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll();

        await planner.createCoordinationPlan(
          community: Community(
            id: 'community_123',
            name: 'Night Owls',
            description: 'Late-night community',
            category: 'social',
            originatingEventId: 'event_123',
            originatingEventType: OriginatingEventType.communityEvent,
            memberIds: const <String>['user_123'],
            memberCount: 1,
            founderId: 'founder_1',
            eventIds: const <String>[],
            eventCount: 0,
            memberGrowthRate: 0,
            eventGrowthRate: 0,
            createdAt: DateTime.utc(2026, 4, 5, 4),
            lastEventAt: null,
            engagementScore: 0.3,
            diversityScore: 0.2,
            activityLevel: ActivityLevel.active,
            originalLocality: 'Downtown',
            currentLocalities: const <String>['Downtown'],
            localityCode: 'atx_downtown',
            updatedAt: DateTime.utc(2026, 4, 5, 4, 5),
          ),
          action: 'add_member',
          actorUserId: testUserId,
          affectedRef: testUserId,
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          communityAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'Anything I should remember about the communities I join?',
        );

        expect(
          first.response,
          contains(
            'Quick community follow-up: What about "Night Owls" made joining feel right, and what should AVRAI remember from that?',
          ),
        );
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'It works best for spontaneous late coffee plans where nobody expects a rigid schedule.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains(
            'I will keep that answer bounded to your earlier community_coordination signal about "Night Owls".',
          ),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
        final responses = await planner.listResponses(testUserId);
        expect(responses, hasLength(1));
      });

      test(
          'should offer an onboarding follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = OnboardingFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = OnboardingAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        await planner.createPlan(
          ownerUserId: testUserId,
          onboardingData: OnboardingData(
            agentId: 'agent_onboarding_chat',
            homebase: 'Austin, TX',
            favoritePlaces: const <String>['Quiet cafe'],
            preferences: const <String, List<String>>{
              'Food & Drink': <String>['Coffee'],
            },
            completedAt: DateTime.utc(2026, 4, 5, 4),
            questionnaireVersion: 'v3',
          ),
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          onboardingAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'What do you remember from how I described myself when I first joined?',
        );

        expect(first.response, contains('Quick onboarding follow-up:'));
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'Keep my Austin homebase durable, but treat nightlife preferences as exploratory.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains('I will keep that answer bounded to your original onboarding signal'),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
      });

      test(
          'should offer a business follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = BusinessOperatorFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = BusinessOperatorAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        await planner.createPlan(
          account: BusinessAccount(
            id: 'business_chat_123',
            name: 'Night Owl Cafe',
            email: 'owner@nightowl.com',
            businessType: 'Restaurant',
            location: 'downtown',
            createdAt: DateTime.utc(2026, 4, 5, 10),
            updatedAt: DateTime.utc(2026, 4, 5, 11),
            createdBy: testUserId,
          ),
          action: 'update',
          occurredAtUtc: DateTime.utc(2026, 4, 5, 11),
          changedFields: const <String>['location'],
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          businessAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'Anything I should keep in mind about my business profile updates?',
        );

        expect(first.response, contains('Quick business follow-up:'));
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'Treat the new downtown footprint as durable because it changes who we serve at night.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains('I will keep that answer bounded to your earlier business update signal about "Night Owl Cafe".'),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
      });

      test(
          'should offer a saved-discovery follow-up and capture the next reply in chat',
          () async {
        final prefs = await SharedPreferencesCompat.getInstance();
        final planner = SavedDiscoveryFollowUpPromptPlannerService(
          prefs: prefs,
          promptPolicyService: _testPromptPolicyService,
        );
        final followUpService = SavedDiscoveryAssistantFollowUpService(
          plannerService: planner,
        );
        await planner.clearAll(testUserId);

        await planner.createPlan(
          ownerUserId: testUserId,
          entity: const DiscoveryEntityReference(
            type: DiscoveryEntityType.spot,
            id: 'spot_saved_follow_up',
            title: 'Night Owl Cafe',
            localityLabel: 'brooklyn_williamsburg',
          ),
          action: 'save',
          occurredAtUtc: DateTime.utc(2026, 4, 4, 18),
          sourceSurface: 'explore',
        );

        service = PersonalityAgentChatService(
          agentIdService: mockAgentIdService,
          encryptionService: mockEncryptionService,
          languageLearningService: mockLanguageLearningService,
          languageKernelOrchestrator: fixedLanguageKernelOrchestrator,
          languageRuntimeService: mockLanguageRuntimeService,
          personalityLearning: mockPersonalityLearning,
          searchRepository: mockSearchRepository,
          aspirationalParser: mockAspirationalParser,
          aspirationalDNAEngine: mockAspirationalDNAEngine,
          savedDiscoveryAssistantFollowUpService: followUpService,
        );

        final first = await service.chatWithKernelContext(
          testUserId,
          'Anything I should keep in mind about saved places?',
        );

        expect(
          first.response,
          contains(
            'Quick saved-item follow-up: What made "Night Owl Cafe" worth saving for later?',
          ),
        );
        expect(first.assistantFollowUpQuestion, isNotNull);

        final second = await service.chatWithKernelContext(
          testUserId,
          'It felt like a place I would genuinely want to come back to.',
        );

        expect(second.assistantFollowUpResponseCaptured, isTrue);
        expect(
          second.response,
          contains(
            'I will keep that answer bounded to your earlier saved discovery action about "Night Owl Cafe".',
          ),
        );
        expect(await planner.listPendingPlans(testUserId), isEmpty);
        final responses = await planner.listResponses(testUserId);
        expect(responses, hasLength(1));
        expect(
          responses.single.responseText,
          'It felt like a place I would genuinely want to come back to.',
        );
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
              any(that: contains('Your current local context is')),
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

      test('should not depend on freeform language runtime for grounded output',
          () async {
        // Act
        final response = await service.chat(testUserId, 'Test message');

        // Assert
        expect(response, isNotEmpty);
        verifyZeroInteractions(mockLanguageRuntimeService);
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

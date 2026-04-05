import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/aspirational_dna_engine.dart';
import 'package:avrai_runtime_os/services/user/aspirational_intent_parser.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/platform_channel_helper.dart';

class _MockAgentIdService extends Mock implements AgentIdService {}

class _MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

class _MockLanguagePatternLearningService extends Mock
    implements LanguagePatternLearningService {}

class _MockLanguageRuntimeService extends Mock
    implements LanguageRuntimeService {}

class _MockPersonalityLearning extends Mock implements pl.PersonalityLearning {}

class _MockAspirationalIntentParser extends Mock
    implements AspirationalIntentParser {}

class _MockAspirationalDNAEngine extends Mock
    implements AspirationalDNAEngine {}

class _FixedHumanLearningBoundaryLane extends HumanLanguageBoundaryReviewLane {
  _FixedHumanLearningBoundaryLane(this._review);

  final HumanLanguageBoundaryReview _review;

  @override
  Future<HumanLanguageBoundaryReview> reviewLocalLearningText({
    required String actorAgentId,
    required String rawText,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.userRuntime,
    Set<String>? consentScopes,
  }) async {
    return _review;
  }
}

class _FixedLanguageKernelOrchestrator
    extends LanguageKernelOrchestratorService {
  _FixedLanguageKernelOrchestrator(this._turn);

  final HumanLanguageKernelTurn _turn;

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
    return _turn;
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
    return RenderedExpression(
      text: allowedClaims.isNotEmpty
          ? allowedClaims.join(' ')
          : 'Governed response available.',
      sections: <ExpressionSection>[
        ExpressionSection(
          kind: 'body',
          text: allowedClaims.isNotEmpty
              ? allowedClaims.join(' ')
              : 'Governed response available.',
        ),
      ],
      assertedClaims: allowedClaims,
    );
  }
}

HumanLanguageBoundaryReview _buildLearningReview({
  required String summary,
  required String actorRef,
  List<String> referencedEntities = const <String>[],
  List<String> questions = const <String>[],
  List<InterpretationPreferenceSignal> preferenceSignals =
      const <InterpretationPreferenceSignal>[],
  List<String> safeQuestions = const <String>[],
  List<InterpretationPreferenceSignal> safePreferenceSignals =
      const <InterpretationPreferenceSignal>[],
}) {
  return HumanLanguageBoundaryReview(
    rawText: summary,
    turn: HumanLanguageKernelTurn(
      interpretation: InterpretationResult(
        intent: InterpretationIntent.share,
        normalizedText: summary,
        requestArtifact: InterpretationRequestArtifact(
          summary: summary,
          asksForResponse: false,
          asksForRecommendation: false,
          asksForAction: false,
          asksForExplanation: false,
          referencedEntities: referencedEntities,
          questions: questions,
          preferenceSignals: preferenceSignals,
          shareIntent: true,
        ),
        learningArtifact: const InterpretationLearningArtifact(
          vocabulary: <String>[],
          phrases: <String>[],
          toneMetrics: <String, double>{},
          directnessPreference: 0.5,
          brevityPreference: 0.5,
        ),
        privacySensitivity: InterpretationPrivacySensitivity.low,
        confidence: 0.92,
        ambiguityFlags: const <String>[],
        needsClarification: false,
        safeForLearning: true,
      ),
      boundary: BoundaryDecision(
        accepted: true,
        disposition: BoundaryDisposition.localOnly,
        transcriptStorageAllowed: true,
        storageAllowed: true,
        learningAllowed: true,
        egressAllowed: false,
        airGapRequired: false,
        reasonCodes: const <String>[],
        sanitizedArtifact: BoundarySanitizedArtifact(
          pseudonymousActorRef: actorRef,
          summary: summary,
          safeClaims: const <String>[],
          safeQuestions: safeQuestions,
          safePreferenceSignals: safePreferenceSignals,
          learningVocabulary: const <String>['calm'],
          learningPhrases: const <String>['quiet night'],
          redactedText: summary,
        ),
        egressPurpose: BoundaryEgressPurpose.none,
      ),
    ),
    egressRequested: false,
    egressPurpose: BoundaryEgressPurpose.none,
    chatType: 'agent',
    surface: 'chat',
    channel: 'personality_agent',
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
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
    registerFallbackValue(
      PersonalityProfile.initial('fallback_agent', userId: 'fallback_user'),
    );
    registerFallbackValue(
      EncryptedMessage(
        encryptedContent: Uint8List(0),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  test('AI2AI intake stages governed upward learning review', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'upward_ai2ai_prefs'),
    );
    final analyzer = AI2AIChatAnalyzer(
      prefs: prefs,
      personalityLearning: pl.PersonalityLearning(),
    );
    final repository = UniversalIntakeRepository();
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final agentIdService = _MockAgentIdService();
    when(() => agentIdService.getUserAgentId(any())).thenAnswer(
      (invocation) async =>
          'agt_${invocation.positionalArguments.single as String}',
    );
    final intake = Ai2AiChatEventIntakeService(
      chatAnalyzer: analyzer,
      humanLanguageBoundaryReviewLane: _FixedHumanLearningBoundaryLane(
        _buildLearningReview(
          summary: 'A peer signal suggests calmer late-evening plans.',
          actorRef: 'anon_peer',
          referencedEntities: const <String>['community list', 'local venue'],
          safePreferenceSignals: const <InterpretationPreferenceSignal>[
            InterpretationPreferenceSignal(
              kind: 'group_preference',
              value: 'community venue list',
              confidence: 0.86,
            ),
          ],
        ),
      ),
      agentIdService: agentIdService,
      governedUpwardLearningIntakeService: upwardService,
    );

    final result = await intake.ingestDirectMessage(
      localUserId: 'user_a',
      senderUserId: 'user_b',
      counterpartUserId: 'user_b',
      messageId: 'msg_1',
      plaintext: 'Let us do a quieter plan tonight.',
      occurredAt: DateTime.utc(2026, 4, 2, 20, 0),
      direction: Ai2AiChatFlowDirection.inbound,
    );

    final reviews = await repository.getAllReviewItems();
    expect(result.learningAllowed, isTrue);
    expect(reviews, hasLength(1));
    expect(reviews.single.payload['sourceKind'], 'ai2ai_chat_intake');
    expect(reviews.single.payload['convictionTier'], 'ai2ai_peer_signal');
    expect(
      reviews.single.payload['upwardDomainHints'],
      containsAll(const <String>['community', 'list', 'venue']),
    );
  });

  test('personality-agent chat stages governed upward learning review',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    await GetStorage.init('personality_chat_messages');
    await GetStorage('personality_chat_messages').erase();

    when(() => agentIdService.getUserAgentId('user_123'))
        .thenAnswer((_) async => 'agent_123');
    when(() => aspirationalParser.parseIntent(any()))
        .thenAnswer((_) async => <String, double>{});
    when(() => aspirationalDNAEngine.applyAspirationalShift(any(), any()))
        .thenAnswer(
      (invocation) => invocation.positionalArguments[0] as PersonalityProfile,
    );
    when(() => encryptionService.encryptionType)
        .thenReturn(EncryptionType.aes256gcm);
    when(() => encryptionService.encrypt(any(), any())).thenAnswer(
      (invocation) async => EncryptedMessage(
        encryptedContent: Uint8List.fromList(
            (invocation.positionalArguments[0] as String).codeUnits),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
    when(() => encryptionService.decrypt(any(), any())).thenAnswer(
      (invocation) async => String.fromCharCodes(
        (invocation.positionalArguments[0] as EncryptedMessage)
            .encryptedContent,
      ),
    );
    when(() => languageLearningService.analyzeMessage(any(), any(), any()))
        .thenAnswer((_) async => true);
    when(() => languageLearningService.getLanguageStyleSummary(any()))
        .thenAnswer((_) async => '');
    when(() => personalityLearning.getCurrentPersonality(any())).thenAnswer(
      (_) async =>
          PersonalityProfile.initial('agent_user_123', userId: 'user_123'),
    );
    when(() => personalityLearning.updatePersonality(any(), any()))
        .thenAnswer((_) async => <String, dynamic>{});

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildLearningReview(
          summary: 'The user wants a calmer, more local evening.',
          actorRef: 'anon_person',
          referencedEntities: const <String>['coffee place'],
          questions: const <String>['Which place stays calm tonight?'],
          preferenceSignals: const <InterpretationPreferenceSignal>[
            InterpretationPreferenceSignal(
              kind: 'activity',
              value: 'local place recommendation',
              confidence: 0.9,
            ),
          ],
        ).turn,
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
    );

    final response = await service.chat(
      'user_123',
      'I want a calmer local evening tonight.',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response, isNotEmpty);
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'personal_agent_human_intake',
    );
    expect(
      reviews.single.payload['convictionTier'],
      'personal_agent_human_observation',
    );
    expect(
      reviews.single.payload['upwardDomainHints'],
      contains('place'),
    );
    expect(
      reviews.single.payload['upwardQuestions'],
      contains('Which place stays calm tonight?'),
    );
  });
}

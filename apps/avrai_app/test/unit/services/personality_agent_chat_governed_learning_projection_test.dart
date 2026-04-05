import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/reality/governed_learning_adoption_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_core/models/reality/governed_learning_usage_receipt.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/aspirational_dna_engine.dart';
import 'package:avrai_runtime_os/services/user/aspirational_intent_parser.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_control_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_adoption_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_projection_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_signal_policy_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_usage_service.dart';
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

HumanLanguageKernelTurn _buildKernelTurn({
  required String summary,
  bool asksForExplanation = false,
}) {
  return HumanLanguageKernelTurn(
    interpretation: InterpretationResult(
      intent: asksForExplanation
          ? InterpretationIntent.ask
          : InterpretationIntent.share,
      normalizedText: summary,
      requestArtifact: InterpretationRequestArtifact(
        summary: summary,
        asksForResponse: false,
        asksForRecommendation: false,
        asksForAction: false,
        asksForExplanation: asksForExplanation,
        referencedEntities: const <String>[],
        questions: const <String>[],
        preferenceSignals: const <InterpretationPreferenceSignal>[],
        shareIntent: !asksForExplanation,
      ),
      learningArtifact: const InterpretationLearningArtifact(
        vocabulary: <String>[],
        phrases: <String>[],
        toneMetrics: <String, double>{},
        directnessPreference: 0.5,
        brevityPreference: 0.5,
      ),
      privacySensitivity: InterpretationPrivacySensitivity.low,
      confidence: 0.94,
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
        pseudonymousActorRef: 'anon_user',
        summary: summary,
        safeClaims: const <String>[],
        safeQuestions: const <String>[],
        safePreferenceSignals: const <InterpretationPreferenceSignal>[],
        learningVocabulary: const <String>['quiet'],
        learningPhrases: const <String>['quiet weeknight'],
        redactedText: summary,
      ),
      egressPurpose: BoundaryEgressPurpose.none,
    ),
  );
}

void _stubCommonChatDependencies({
  required _MockAgentIdService agentIdService,
  required _MockMessageEncryptionService encryptionService,
  required _MockLanguagePatternLearningService languageLearningService,
  required _MockPersonalityLearning personalityLearning,
  required _MockAspirationalIntentParser aspirationalParser,
  required _MockAspirationalDNAEngine aspirationalDNAEngine,
}) {
  when(() => agentIdService.getUserAgentId('user_123'))
      .thenAnswer((_) async => 'agent_123');
  when(() => encryptionService.encryptionType)
      .thenReturn(EncryptionType.aes256gcm);
  when(() => encryptionService.encrypt(any(), any())).thenAnswer(
    (invocation) async => EncryptedMessage(
      encryptedContent: Uint8List.fromList(
        (invocation.positionalArguments[0] as String).codeUnits,
      ),
      encryptionType: EncryptionType.aes256gcm,
    ),
  );
  when(() => encryptionService.decrypt(any(), any())).thenAnswer(
    (invocation) async => String.fromCharCodes(
      (invocation.positionalArguments[0] as EncryptedMessage).encryptedContent,
    ),
  );
  when(() => languageLearningService.getLanguageStyleSummary(any()))
      .thenAnswer((_) async => '');
  when(() => personalityLearning.getCurrentPersonality(any())).thenAnswer(
    (_) async => PersonalityProfile.initial('agent_123', userId: 'user_123'),
  );
  when(() => aspirationalParser.parseIntent(any()))
      .thenAnswer((_) async => <String, double>{});
  when(() => aspirationalDNAEngine.applyAspirationalShift(any(), any()))
      .thenAnswer(
    (invocation) => invocation.positionalArguments[0] as PersonalityProfile,
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

  setUp(() async {
    await StorageService.instance.clear();
    await StorageService.instance.clear(box: 'spots_user');
    await StorageService.instance.clear(box: 'spots_ai');
    await StorageService.instance.clear(box: 'spots_analytics');
    await GetStorage.init('personality_chat_messages');
    await GetStorage('personality_chat_messages').erase();
  });

  test(
      'governed learning transparency question returns projection without staging new intake',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants a quieter weeknight plan.',
        'sanitized_summary': 'The user wants a quieter weeknight plan.',
        'referenced_entities': <String>['coffee shop list', 'downtown place'],
        'questions': <String>['Which place works best tonight?'],
        'preference_signals': <Map<String, dynamic>>[
          <String, dynamic>{
            'kind': 'pace',
            'value': 'calm local list',
            'confidence': 0.91,
          },
        ],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    final sourceCountBefore =
        (await repository.getSourcesForOwner('user_123')).length;
    final reviewCountBefore = (await repository.getAllReviewItems()).length;

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what was learned from prior behavior.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from me?',
    );

    final sourceCountAfter =
        (await repository.getSourcesForOwner('user_123')).length;
    final reviewCountAfter = (await repository.getAllReviewItems()).length;

    expect(
      response,
      contains('I learned that'),
    );
    expect(
      response,
      contains('quieter weeknight plan'),
    );
    expect(response, contains('human review'));
    expect(sourceCountAfter, sourceCountBefore);
    expect(reviewCountAfter, reviewCountBefore);
  });

  test(
      'governed learning transparency response does not promise soon for accepted-only corrections',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );
    when(() => agentIdService.getUserAgentId('user_123'))
        .thenAnswer((_) async => 'agent_123');

    final original = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_correction_seed_1',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user prefers quieter weekday coffee spots.',
        'sanitized_summary': 'The user prefers quieter weekday coffee spots.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_correction_seed_1',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );
    await controlService.submitCorrection(
      ownerUserId: 'user_123',
      envelopeId: original.envelope.id,
      correctionText: 'Actually I mean weekday coffee shops with calm seating.',
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked whether the correction is active yet.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from my correction about coffee seating?',
    );

    expect(
      response,
      contains(
        'do not have a surfaced recommendation lane queued for it yet',
      ),
    );
    expect(
        response, isNot(contains('personalized event recommendations soon')));
  });

  test(
      'governed learning transparency response promises soon only for queued event corrections',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );
    when(() => agentIdService.getUserAgentId('user_123'))
        .thenAnswer((_) async => 'agent_123');

    final original = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_correction_seed_2',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 2),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user reacts to social plans.',
        'sanitized_summary': 'The user reacts to social plans.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_correction_seed_2',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );
    await controlService.submitCorrection(
      ownerUserId: 'user_123',
      envelopeId: original.envelope.id,
      correctionText:
          'Actually I wanted louder nightlife events with more social energy.',
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked when the nightlife correction will show up.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from my nightlife correction?',
    );

    expect(response, contains('personalized event recommendations soon'));
  });

  test(
      'governed learning transparency response cites a concrete surfaced recommendation when usage receipts exist',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final usageService = UserGovernedLearningUsageService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
      usageService: usageService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_nightlife_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants louder nightlife scenes.',
        'sanitized_summary': 'The user wants louder nightlife scenes.',
        'referenced_entities': <String>['Austin After Dark'],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_nightlife_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await usageService.recordReceipts([
      GovernedLearningUsageReceipt(
        id: 'usage_receipt_nightlife_1',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        decisionFamily: 'event_recommendation',
        decisionId: 'decision_nightlife_1',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event-nightlife-1',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
        usedAtUtc: DateTime.utc(2026, 4, 4, 4),
        influenceKind: GovernedLearningUsageInfluenceKind.boost,
        influenceScoreDelta: 0.08,
        influenceReason: 'Nightlife preference boosted this recommendation.',
        surface: 'events_personalized',
      ),
    ]);
    await adoptionService.recordReceipts([
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:events_personalized:first_surfaced_on_surface',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 4, 4),
        surface: 'events_personalized',
        decisionFamily: 'event_recommendation',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event-nightlife-1',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
        reason: 'surfaced',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what was learned about nightlife.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from me about nightlife?',
    );

    expect(response, contains('Austin After Dark'));
    expect(response, contains('nightlife recommendations'));
    expect(response, contains('helped me recommend'));
  });

  test(
      'governed learning transparency response names explore spot propagation when a record first surfaced there',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final usageService = UserGovernedLearningUsageService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
      usageService: usageService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_coffee_321',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary':
            'The user likes coffee shops with espresso and natural light.',
        'sanitized_summary':
            'The user likes coffee shops with espresso and natural light.',
        'referenced_entities': <String>['Quiet Coffee House', 'coffee'],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_coffee_321',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await usageService.recordReceipts([
      GovernedLearningUsageReceipt(
        id: 'usage_receipt_coffee_1',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        decisionFamily: 'spot_recommendation',
        decisionId: 'decision_coffee_1',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        targetEntityId: 'spot-coffee-1',
        targetEntityType: 'spot',
        targetEntityTitle: 'Quiet Coffee House',
        usedAtUtc: DateTime.utc(2026, 4, 4, 4),
        influenceKind: GovernedLearningUsageInfluenceKind.boost,
        influenceScoreDelta: 0.07,
        influenceReason: 'Coffee preference boosted this recommendation.',
        surface: 'explore_spots',
      ),
    ]);
    await adoptionService.recordReceipts([
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:explore_spots:first_surfaced_on_surface',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 4, 4),
        surface: 'explore_spots',
        decisionFamily: 'spot_recommendation',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        targetEntityId: 'spot-coffee-1',
        targetEntityType: 'spot',
        targetEntityTitle: 'Quiet Coffee House',
        reason: 'surfaced',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what changed for coffee recommendations.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from me about coffee recommendations?',
    );

    expect(response, contains('coffee recommendations'));
    expect(response, contains('Quiet Coffee House'));
    expect(response, contains('explore spot recommendations'));
  });

  test(
      'governed learning transparency response enumerates active and queued surfaced lanes',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final usageService = UserGovernedLearningUsageService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
      usageService: usageService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_surface_map',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user likes quieter coffee spots with natural light.',
        'sanitized_summary':
            'The user likes quieter coffee spots with natural light.',
        'referenced_entities': <String>['Quiet Coffee House', 'coffee'],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_surface_map',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await usageService.recordReceipts([
      GovernedLearningUsageReceipt(
        id: 'usage_receipt_surface_map_1',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        decisionFamily: 'spot_recommendation',
        decisionId: 'decision_surface_map_1',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        targetEntityId: 'spot-coffee-1',
        targetEntityType: 'spot',
        targetEntityTitle: 'Quiet Coffee House',
        usedAtUtc: DateTime.utc(2026, 4, 4, 4),
        influenceKind: GovernedLearningUsageInfluenceKind.boost,
        influenceScoreDelta: 0.07,
        influenceReason: 'Coffee preference boosted this recommendation.',
        surface: 'explore_spots',
      ),
    ]);
    await adoptionService.recordReceipts([
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:explore_spots:first',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 4, 4),
        surface: 'explore_spots',
        decisionFamily: 'spot_recommendation',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        targetEntityId: 'spot-coffee-1',
        targetEntityType: 'spot',
        targetEntityTitle: 'Quiet Coffee House',
        reason: 'surfaced',
      ),
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:events_personalized:queued',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.queuedForSurfaceRefresh,
        recordedAtUtc: DateTime.utc(2026, 4, 4, 4, 5),
        surface: 'events_personalized',
        decisionFamily: 'event_recommendation',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        reason: 'queued',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked where this has propagated.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'Has this changed explore spots or personalized events yet?',
    );

    expect(response, contains('explore spot recommendations'));
    expect(response, contains('queued for personalized event recommendations'));
    expect(response, contains('Quiet Coffee House'));
  });

  test(
      'governed learning transparency response can point back to the record and latest recommendation trail',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final usageService = UserGovernedLearningUsageService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
      usageService: usageService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_nightlife_124',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants louder nightlife scenes.',
        'sanitized_summary': 'The user wants louder nightlife scenes.',
        'referenced_entities': <String>['Austin After Dark'],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_nightlife_124',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await usageService.recordReceipts([
      GovernedLearningUsageReceipt(
        id: 'usage_receipt_nightlife_3',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        decisionFamily: 'event_recommendation',
        decisionId: 'decision_nightlife_3',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event-nightlife-3',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
        usedAtUtc: DateTime.utc(2026, 4, 4, 7),
        influenceKind: GovernedLearningUsageInfluenceKind.boost,
        influenceScoreDelta: 0.08,
        influenceReason: 'Nightlife preference boosted this recommendation.',
        surface: 'events_personalized',
      ),
    ]);
    await adoptionService.recordReceipts([
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:events_personalized:first_surfaced_on_surface',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 4, 7),
        surface: 'events_personalized',
        decisionFamily: 'event_recommendation',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event-nightlife-3',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
        reason: 'surfaced',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked to see what this came from.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'Show me what this came from.',
    );

    expect(response, contains('open your Data Center ledger'));
    expect(response, contains('Austin After Dark'));
    expect(response, contains('latest visible event recommendation'));
  });

  test(
      'governed learning transparency response can distinguish affected and unaffected domains from the question',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final usageService = UserGovernedLearningUsageService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
      usageService: usageService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_nightlife_456',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 5),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants louder nightlife scenes.',
        'sanitized_summary': 'The user wants louder nightlife scenes.',
        'referenced_entities': <String>['Austin After Dark'],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_nightlife_456',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await usageService.recordReceipts([
      GovernedLearningUsageReceipt(
        id: 'usage_receipt_nightlife_2',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        decisionFamily: 'event_recommendation',
        decisionId: 'decision_nightlife_2',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event-nightlife-2',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
        usedAtUtc: DateTime.utc(2026, 4, 4, 6),
        influenceKind: GovernedLearningUsageInfluenceKind.boost,
        influenceScoreDelta: 0.08,
        influenceReason: 'Nightlife preference boosted this recommendation.',
        surface: 'events_personalized',
      ),
    ]);
    await adoptionService.recordReceipts([
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:events_personalized:first_surfaced_on_surface',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 4, 6),
        surface: 'events_personalized',
        decisionFamily: 'event_recommendation',
        domainId: 'nightlife',
        domainLabel: 'Nightlife',
        targetEntityId: 'event-nightlife-2',
        targetEntityType: 'event',
        targetEntityTitle: 'Austin After Dark',
        reason: 'surfaced',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary:
              'The user asked whether nightlife changed but coffee stayed unaffected.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'Did this change nightlife recommendations, but not my coffee recs?',
    );

    expect(response, contains('nightlife recommendations'));
    expect(response, contains('not coffee recommendations'));
    expect(response, contains('Austin After Dark'));
  });

  test('chat explanation targets a specific matching record, not just latest',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stageRecommendationFeedbackIntake(
      ownerUserId: 'user_123',
      action: RecommendationFeedbackAction.lessLikeThis,
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_123',
        title: 'Late Night Venue',
        localityLabel: 'downtown',
      ),
      occurredAtUtc: DateTime.utc(2026, 4, 4, 1),
      sourceSurface: 'explore',
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'recommendation_feedback_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{'entityId': 'spot_123'},
      ),
    );
    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_latest_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants a quieter weeknight plan.',
        'sanitized_summary': 'The user wants a quieter weeknight plan.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_latest_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what was learned about Late Night Venue.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn about Late Night Venue?',
    );

    expect(
      response,
      contains('best matched your question'),
    );
    expect(response, contains('Late Night Venue'));
    expect(
      response,
      isNot(contains('The user wants a quieter weeknight plan.')),
    );
  });

  test('chat can forget the latest visible governed learning record', () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants a quieter weeknight plan.',
        'sanitized_summary': 'The user wants a quieter weeknight plan.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(summary: 'The user asked to forget that record.'),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat('user_123', 'Forget that.');
    final records = await projectionService.listVisibleRecords(
      ownerUserId: 'user_123',
    );
    final reviews = await repository.getAllReviewItems();

    expect(response, contains('I forgot the governed learning record'));
    expect(records, isEmpty);
    expect(reviews, isEmpty);
  });

  test('chat can stage a correction against the latest visible record',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants a quieter weeknight plan.',
        'sanitized_summary': 'The user wants a quieter weeknight plan.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(summary: 'The user asked to correct that record.'),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'Correct that: I wanted a louder place with more activity.',
    );
    final reviews = await repository.getAllReviewItems();

    expect(response, contains('I staged a governed correction'));
    expect(response, contains('I wanted a louder place with more activity.'));
    expect(reviews.first.payload['sourceKind'], 'explicit_correction_intake');
  });

  test('chat can stop using the latest governed learning signal', () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants a quieter weeknight plan.',
        'sanitized_summary': 'The user wants a quieter weeknight plan.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(summary: 'The user asked to stop using that signal.'),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat('user_123', 'Stop using that signal.');
    final records = await projectionService.listVisibleRecords(
      ownerUserId: 'user_123',
    );
    final reviews = await repository.getAllReviewItems();

    expect(response, contains('I will stop using future'));
    expect(records.single.futureSignalUseBlocked, isTrue);
    expect(reviews, isEmpty);
  });

  test('chat can forget a specifically matched older record', () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stageRecommendationFeedbackIntake(
      ownerUserId: 'user_123',
      action: RecommendationFeedbackAction.lessLikeThis,
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_123',
        title: 'Late Night Venue',
        localityLabel: 'downtown',
      ),
      occurredAtUtc: DateTime.utc(2026, 4, 4, 1),
      sourceSurface: 'explore',
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'recommendation_feedback_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{'entityId': 'spot_123'},
      ),
    );
    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_latest_123',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants a quieter weeknight plan.',
        'sanitized_summary': 'The user wants a quieter weeknight plan.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_latest_123',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(summary: 'The user asked to forget the venue record.'),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
    );

    final response = await service.chat(
      'user_123',
      'Forget the Late Night Venue one.',
    );
    final records = await projectionService.listVisibleRecords(
      ownerUserId: 'user_123',
    );

    expect(response, contains('Late Night Venue'));
    expect(records, hasLength(1));
    expect(
        records.single.safeSummary, 'The user wants a quieter weeknight plan.');
  });

  test(
      'governed learning explanation records a pending chat observation receipt',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final observationService = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      observationService: observationService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_obs_seed',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 1),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user likes quieter coffee spots.',
        'sanitized_summary': 'The user likes quieter coffee spots.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_obs_seed',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what was learned about coffee.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningChatObservationService: observationService,
    );

    await service.chat('user_123', 'What did you learn from me about coffee?');

    final receipts = await observationService.listReceiptsForUser(
      ownerUserId: 'user_123',
    );
    expect(receipts, hasLength(1));
    expect(
      receipts.single.outcome,
      GovernedLearningChatObservationOutcome.pending,
    );
    expect(receipts.single.focus, 'overview');
  });

  test(
      'governed learning repeated explanation marks the prior receipt as follow-up',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final observationService = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      observationService: observationService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_obs_followup',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 1),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user likes louder nightlife scenes.',
        'sanitized_summary': 'The user likes louder nightlife scenes.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_obs_followup',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what changed from nightlife learning.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningChatObservationService: observationService,
    );

    await service.chat(
        'user_123', 'What did you learn from me about nightlife?');
    final followUpResponse =
        await service.chat('user_123', 'Show me where this came from.');

    final receipts = await observationService.listReceiptsForUser(
      ownerUserId: 'user_123',
    );
    expect(receipts, hasLength(2));
    expect(
      receipts.last.outcome,
      GovernedLearningChatObservationOutcome.requestedFollowUp,
    );
    expect(
      receipts.first.outcome,
      GovernedLearningChatObservationOutcome.pending,
    );
    expect(
      followUpResponse,
      contains('keep walking the record and recommendation trail step by step'),
    );
  });

  test(
      'governed learning correction resolves the latest pending explanation receipt',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final observationService = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      observationService: observationService,
    );
    final controlService = UserGovernedLearningControlService(
      intakeRepository: repository,
      governedUpwardLearningIntakeService: upwardService,
      agentIdService: agentIdService,
      signalPolicyService: signalPolicyService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_obs_correct',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 1),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants calmer weeknight coffee plans.',
        'sanitized_summary': 'The user wants calmer weeknight coffee plans.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_obs_correct',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked about the calm coffee record.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningControlService: controlService,
      userGovernedLearningChatObservationService: observationService,
    );

    await service.chat('user_123', 'What did you learn from me about coffee?');
    await service.chat(
      'user_123',
      'Correct that: I wanted calmer coffee spots with quiet seating.',
    );

    final receipts = await observationService.listReceiptsForUser(
      ownerUserId: 'user_123',
    );
    expect(receipts, isNotEmpty);
    expect(
      receipts.first.outcome,
      GovernedLearningChatObservationOutcome.correctedRecord,
    );
  });

  test(
      'governed learning acknowledgement resolves the latest pending explanation receipt',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final observationService = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      observationService: observationService,
    );

    await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_obs_ack',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 1),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user likes brighter coffee shops.',
        'sanitized_summary': 'The user likes brighter coffee shops.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_obs_ack',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what was learned about bright coffee shops.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningChatObservationService: observationService,
    );

    await service.chat('user_123', 'What did you learn from me about coffee?');
    await service.chat('user_123', 'Thanks, that helps.');

    final receipts = await observationService.listReceiptsForUser(
      ownerUserId: 'user_123',
    );
    expect(receipts, isNotEmpty);
    expect(
      receipts.first.outcome,
      GovernedLearningChatObservationOutcome.acknowledged,
    );
  });

  test(
      'governed learning explanation mentions when a prior explanation was later borne out by surfaced adoption',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final adoptionService = UserGovernedLearningAdoptionService(
      storageService: StorageService.instance,
    );
    final usageService = UserGovernedLearningUsageService(
      storageService: StorageService.instance,
    );
    final observationService = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      adoptionService: adoptionService,
      observationService: observationService,
      usageService: usageService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_validation_1',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 3),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user likes coffee shops with natural light.',
        'sanitized_summary': 'The user likes coffee shops with natural light.',
        'referenced_entities': <String>['Quiet Coffee House', 'coffee'],
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_validation_1',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await usageService.recordReceipts([
      GovernedLearningUsageReceipt(
        id: 'usage_validation_1',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        decisionFamily: 'spot_recommendation',
        decisionId: 'decision_validation_1',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        targetEntityId: 'spot-coffee-1',
        targetEntityType: 'spot',
        targetEntityTitle: 'Quiet Coffee House',
        usedAtUtc: DateTime.utc(2026, 4, 5, 4),
        influenceKind: GovernedLearningUsageInfluenceKind.boost,
        influenceScoreDelta: 0.07,
        influenceReason: 'Coffee preference boosted this recommendation.',
        surface: 'explore_spots',
      ),
    ]);
    await adoptionService.recordReceipts([
      GovernedLearningAdoptionReceipt(
        id: '${intakeResult.envelope.id}:explore_spots:surfaced',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        status: GovernedLearningAdoptionStatus.firstSurfacedOnSurface,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 4),
        surface: 'explore_spots',
        decisionFamily: 'spot_recommendation',
        domainId: 'coffee',
        domainLabel: 'Coffee',
        targetEntityId: 'spot-coffee-1',
        targetEntityType: 'spot',
        targetEntityTitle: 'Quiet Coffee House',
        reason: 'surfaced',
      ),
    ]);
    await observationService.recordReceipts([
      GovernedLearningChatObservationReceipt(
        id: 'obs_validation_1',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.acknowledged,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 3, 30),
        chatId: 'chat_123',
        userMessageId: 'user_msg_validation_1',
        validationStatus: GovernedLearningChatObservationValidationStatus
            .validatedBySurfacedAdoption,
        validatedAtUtc: DateTime.utc(2026, 4, 5, 4),
        validatedSurface: 'explore_spots',
        validatedTargetEntityTitle: 'Quiet Coffee House',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what was learned about coffee.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningChatObservationService: observationService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from me about coffee?',
    );

    expect(
      response,
      contains(
          'later borne out when it surfaced in explore spot recommendations'),
    );
    expect(response, contains('Quiet Coffee House'));
  });

  test(
      'governed learning explanation mentions when governance later constrains the explanation',
      () async {
    final agentIdService = _MockAgentIdService();
    final encryptionService = _MockMessageEncryptionService();
    final languageLearningService = _MockLanguagePatternLearningService();
    final languageRuntimeService = _MockLanguageRuntimeService();
    final personalityLearning = _MockPersonalityLearning();
    final aspirationalParser = _MockAspirationalIntentParser();
    final aspirationalDNAEngine = _MockAspirationalDNAEngine();
    final repository = UniversalIntakeRepository();
    final signalPolicyService = UserGovernedLearningSignalPolicyService(
      storageService: StorageService.instance,
    );
    final observationService = UserGovernedLearningChatObservationService(
      storageService: StorageService.instance,
    );
    final upwardService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
      signalPolicyService: signalPolicyService,
    );
    final projectionService = UserGovernedLearningProjectionService(
      intakeRepository: repository,
      signalPolicyService: signalPolicyService,
      observationService: observationService,
    );

    final intakeResult = await upwardService.stagePersonalAgentHumanIntake(
      ownerUserId: 'user_123',
      actorAgentId: 'agent_123',
      chatId: 'chat_123',
      messageId: 'message_governance_1',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 5),
      boundaryMetadata: const <String, dynamic>{
        'summary': 'The user wants louder nightlife scenes.',
        'sanitized_summary': 'The user wants louder nightlife scenes.',
        'accepted': true,
        'learning_allowed': true,
      },
      airGapArtifact: const UpwardAirGapService().issueArtifact(
        originPlane: 'personal_device',
        sourceKind: 'personal_agent_human_intake',
        sourceScope: 'human',
        destinationCeiling: 'reality_model_agent',
        issuedAtUtc: DateTime.now().toUtc(),
        sanitizedPayload: <String, dynamic>{
          'chatId': 'chat_123',
          'messageId': 'message_governance_1',
        },
        pseudonymousActorRef: 'anon_user',
      ),
    );

    await observationService.recordReceipts([
      GovernedLearningChatObservationReceipt(
        id: 'obs_governance_1',
        ownerUserId: 'user_123',
        envelopeId: intakeResult.envelope.id,
        sourceId: intakeResult.sourceId,
        kind: GovernedLearningChatObservationKind.explanation,
        outcome: GovernedLearningChatObservationOutcome.acknowledged,
        recordedAtUtc: DateTime.utc(2026, 4, 5, 5, 5),
        chatId: 'chat_123',
        userMessageId: 'msg_1',
        governanceStatus: GovernedLearningChatObservationGovernanceStatus
            .constrainedByGovernance,
        governanceUpdatedAtUtc: DateTime.utc(2026, 4, 5, 5, 10),
        governanceStage: 'reality_model_truth_review',
        governanceReason: 'Held for more evidence.',
      ),
    ]);

    _stubCommonChatDependencies(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
    );

    final service = PersonalityAgentChatService(
      agentIdService: agentIdService,
      encryptionService: encryptionService,
      languageLearningService: languageLearningService,
      languageKernelOrchestrator: _FixedLanguageKernelOrchestrator(
        _buildKernelTurn(
          summary: 'The user asked what happened to the nightlife explanation.',
          asksForExplanation: true,
        ),
      ),
      languageRuntimeService: languageRuntimeService,
      personalityLearning: personalityLearning,
      aspirationalParser: aspirationalParser,
      aspirationalDNAEngine: aspirationalDNAEngine,
      governedUpwardLearningIntakeService: upwardService,
      userGovernedLearningProjectionService: projectionService,
      userGovernedLearningChatObservationService: observationService,
    );

    final response = await service.chat(
      'user_123',
      'What did you learn from me about nightlife?',
    );

    expect(
      response,
      contains(
        'governance review constrained this explanation during reality-model truth review',
      ),
    );
  });
}

library;

import 'dart:io';

import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/business/business_expert_message.dart';
import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_network/network/message_encryption_service.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/business/business_business_chat_service_ai2ai.dart';
import 'package:avrai_runtime_os/services/business/business_expert_chat_service_ai2ai.dart';
import 'package:avrai_runtime_os/services/chat/conversation_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageEncryptionService extends Mock
    implements MessageEncryptionService {}

class MockConversationOrchestrationLane extends Mock
    implements ConversationOrchestrationLane {}

class MockAgentIdService extends Mock implements AgentIdService {}

class _FixedHumanLanguageBoundaryReviewLane
    extends HumanLanguageBoundaryReviewLane {
  _FixedHumanLanguageBoundaryReviewLane(this._review);

  final HumanLanguageBoundaryReview _review;

  @override
  Future<HumanLanguageBoundaryReview> reviewOutboundText({
    required String actorAgentId,
    required String rawText,
    required BoundaryEgressPurpose egressPurpose,
    required bool egressRequested,
    String? userId,
    String chatType = 'agent',
    String surface = 'chat',
    String channel = 'in_app',
    BoundaryPrivacyMode privacyMode = BoundaryPrivacyMode.localSovereign,
    Set<String>? consentScopes,
  }) async {
    return _review;
  }

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

HumanLanguageBoundaryReview _buildBoundaryReview({
  required String reviewedText,
  required BoundaryDecision decision,
}) {
  return HumanLanguageBoundaryReview(
    rawText: reviewedText,
    turn: HumanLanguageKernelTurn(
      interpretation: InterpretationResult(
        intent: InterpretationIntent.share,
        normalizedText: reviewedText,
        requestArtifact: InterpretationRequestArtifact(
          summary: reviewedText,
          asksForResponse: false,
          asksForRecommendation: false,
          asksForAction: false,
          asksForExplanation: false,
          referencedEntities: const <String>[],
          questions: const <String>[],
          preferenceSignals: const <InterpretationPreferenceSignal>[],
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
        confidence: 0.95,
        ambiguityFlags: const <String>[],
        needsClarification: false,
        safeForLearning: true,
      ),
      boundary: decision,
    ),
    egressRequested: true,
    egressPurpose: BoundaryEgressPurpose.directMessage,
    chatType: 'business_direct',
    surface: 'business_chat',
    channel: 'business_test',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;

  setUpAll(() async {
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
      EncryptedMessage(
        encryptedContent: Uint8List(0),
        encryptionType: EncryptionType.aes256gcm,
      ),
    );
    registerFallbackValue(<String, dynamic>{});

    storageRoot =
        await Directory.systemTemp.createTemp('business_ai2ai_chat_test_');
    await GetStorage(
      'business_expert_messages',
      storageRoot.path,
    ).initStorage;
    await GetStorage(
      'business_expert_conversations',
      storageRoot.path,
    ).initStorage;
    await GetStorage(
      'business_business_messages',
      storageRoot.path,
    ).initStorage;
    await GetStorage(
      'business_business_conversations',
      storageRoot.path,
    ).initStorage;
    await GetStorage(
      'ai2ai_business_chat_event_intake',
      storageRoot.path,
    ).initStorage;
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await storageRoot.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup for GetStorage temp files.
    }
  });

  group('Business AI2AI chat services', () {
    late MockMessageEncryptionService encryptionService;
    late MockConversationOrchestrationLane conversationOrchestrationLane;
    late MockAgentIdService agentIdService;
    late SharedPreferencesCompat prefs;
    late AI2AIChatAnalyzer analyzer;

    setUp(() async {
      await GetStorage('business_expert_messages').erase();
      await GetStorage('business_expert_conversations').erase();
      await GetStorage('business_business_messages').erase();
      await GetStorage('business_business_conversations').erase();

      final intakeStorage = GetStorage('ai2ai_business_chat_event_intake');
      await intakeStorage.erase();
      prefs = await SharedPreferencesCompat.getInstance(storage: intakeStorage);
      await prefs.setBool('user_runtime_learning_enabled', true);
      await prefs.setBool('ai2ai_learning_enabled', true);

      analyzer = AI2AIChatAnalyzer(
        prefs: prefs,
        personalityLearning: PersonalityLearning.withPrefs(prefs),
      );

      encryptionService = MockMessageEncryptionService();
      conversationOrchestrationLane = MockConversationOrchestrationLane();
      agentIdService = MockAgentIdService();

      when(() => encryptionService.encryptionType)
          .thenReturn(EncryptionType.aes256gcm);
      when(() => encryptionService.encrypt(any(), any()))
          .thenAnswer((invocation) async {
        final plaintext = invocation.positionalArguments[0] as String;
        return EncryptedMessage(
          encryptedContent: Uint8List.fromList(plaintext.codeUnits),
          encryptionType: EncryptionType.aes256gcm,
        );
      });
      when(
        () => conversationOrchestrationLane.sendDirectMessagePayload(
          recipientAgentId: any(named: 'recipientAgentId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer(
        (_) async => ConversationTransportDispatchResult(
          messageId: 'dispatch-msg',
          timestamp: DateTime.utc(2026, 3, 12, 12),
          messageCategory: 'user_chat',
        ),
      );
    });

    test(
        'business-expert send stores boundary metadata, feeds governed learning, and routes reviewed text',
        () async {
      when(
        () => agentIdService.getBusinessAgentId('business_1'),
      ).thenAnswer((_) async => 'agt_business_1');
      when(
        () => agentIdService.getExpertAgentId('expert_1'),
      ).thenAnswer((_) async => 'agt_expert_1');

      final lane = _FixedHumanLanguageBoundaryReviewLane(
        _buildBoundaryReview(
          reviewedText: 'boundary-reviewed business expert message',
          decision: BoundaryDecision(
            accepted: true,
            disposition: BoundaryDisposition.userAuthorizedEgress,
            transcriptStorageAllowed: true,
            storageAllowed: true,
            learningAllowed: true,
            egressAllowed: true,
            airGapRequired: false,
            reasonCodes: const <String>[],
            sanitizedArtifact: const BoundarySanitizedArtifact(
              pseudonymousActorRef: 'anon_business_expert',
              summary: 'boundary-reviewed business expert message',
              safeClaims: <String>[],
              safeQuestions: <String>[],
              safePreferenceSignals: <InterpretationPreferenceSignal>[],
              learningVocabulary: <String>['boundary', 'reviewed'],
              learningPhrases: <String>['boundary reviewed'],
              redactedText: 'boundary-reviewed business expert message',
            ),
            egressPurpose: BoundaryEgressPurpose.directMessage,
          ),
        ),
      );
      final intake = Ai2AiChatEventIntakeService(
        chatAnalyzer: analyzer,
        humanLanguageBoundaryReviewLane: lane,
        agentIdService: agentIdService,
      );
      final service = BusinessExpertChatServiceAI2AI(
        conversationOrchestrationLane: conversationOrchestrationLane,
        encryptionService: encryptionService,
        agentIdService: agentIdService,
        humanLanguageBoundaryReviewLane: lane,
        ai2aiChatEventIntakeService: intake,
      );

      final message = await service.sendMessage(
        businessId: 'business_1',
        expertId: 'expert_1',
        content: 'raw original message',
        senderType: MessageSenderType.business,
      );

      expect(message.content, 'boundary-reviewed business expert message');
      expect(
        message.metadata?[HumanLanguageBoundaryReview.metadataKey],
        isA<Map<String, dynamic>>(),
      );
      expect(
        message.metadata?[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map<String, dynamic>>(),
      );

      verify(
        () => encryptionService.encrypt(
          'boundary-reviewed business expert message',
          'agt_expert_1',
        ),
      ).called(1);
      verify(
        () => conversationOrchestrationLane.sendDirectMessagePayload(
          recipientAgentId: 'agt_expert_1',
          payload: any(
            named: 'payload',
            that: predicate<Map<String, dynamic>>(
              (payload) =>
                  payload['content'] ==
                      'boundary-reviewed business expert message' &&
                  payload['message_category'] == 'user_chat',
            ),
          ),
        ),
      ).called(1);

      final history = await service.getMessageHistory(message.conversationId);
      expect(history, hasLength(1));
      expect(
        history.single.metadata?[HumanLanguageBoundaryReview.metadataKey],
        isA<Map<String, dynamic>>(),
      );

      final analyzerHistory =
          await analyzer.getChatHistoryForAdmin('business_1');
      expect(analyzerHistory, hasLength(1));
      expect(
        analyzerHistory.single.messages.single.content,
        'boundary-reviewed business expert message',
      );
      expect(
        analyzerHistory.single.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );
    });

    test('business-expert send fails closed when boundary blocks egress',
        () async {
      when(
        () => agentIdService.getBusinessAgentId('business_1'),
      ).thenAnswer((_) async => 'agt_business_1');
      when(
        () => agentIdService.getExpertAgentId('expert_1'),
      ).thenAnswer((_) async => 'agt_expert_1');

      final lane = _FixedHumanLanguageBoundaryReviewLane(
        _buildBoundaryReview(
          reviewedText: 'blocked',
          decision: BoundaryDecision(
            accepted: false,
            disposition: BoundaryDisposition.block,
            transcriptStorageAllowed: false,
            storageAllowed: false,
            learningAllowed: false,
            egressAllowed: false,
            airGapRequired: false,
            reasonCodes: const <String>['policy_blocked'],
            sanitizedArtifact: const BoundarySanitizedArtifact(
              pseudonymousActorRef: 'anon_blocked',
              summary: 'blocked',
              safeClaims: <String>[],
              safeQuestions: <String>[],
              safePreferenceSignals: <InterpretationPreferenceSignal>[],
              learningVocabulary: <String>[],
              learningPhrases: <String>[],
              redactedText: 'blocked',
            ),
            egressPurpose: BoundaryEgressPurpose.directMessage,
          ),
        ),
      );
      final service = BusinessExpertChatServiceAI2AI(
        conversationOrchestrationLane: conversationOrchestrationLane,
        encryptionService: encryptionService,
        agentIdService: agentIdService,
        humanLanguageBoundaryReviewLane: lane,
      );

      expect(
        () => service.sendMessage(
          businessId: 'business_1',
          expertId: 'expert_1',
          content: 'raw original message',
          senderType: MessageSenderType.business,
        ),
        throwsA(isA<HumanLanguageBoundaryViolationException>()),
      );
      verifyNever(
        () => conversationOrchestrationLane.sendDirectMessagePayload(
          recipientAgentId: any(named: 'recipientAgentId'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test(
        'business-business send stores boundary metadata, feeds governed learning, and routes reviewed text',
        () async {
      when(
        () => agentIdService.getBusinessAgentId('business_1'),
      ).thenAnswer((_) async => 'agt_business_1');
      when(
        () => agentIdService.getBusinessAgentId('business_2'),
      ).thenAnswer((_) async => 'agt_business_2');

      final lane = _FixedHumanLanguageBoundaryReviewLane(
        _buildBoundaryReview(
          reviewedText: 'boundary-reviewed business business message',
          decision: BoundaryDecision(
            accepted: true,
            disposition: BoundaryDisposition.userAuthorizedEgress,
            transcriptStorageAllowed: true,
            storageAllowed: true,
            learningAllowed: true,
            egressAllowed: true,
            airGapRequired: false,
            reasonCodes: const <String>[],
            sanitizedArtifact: const BoundarySanitizedArtifact(
              pseudonymousActorRef: 'anon_business_business',
              summary: 'boundary-reviewed business business message',
              safeClaims: <String>[],
              safeQuestions: <String>[],
              safePreferenceSignals: <InterpretationPreferenceSignal>[],
              learningVocabulary: <String>['boundary', 'business'],
              learningPhrases: <String>['business boundary'],
              redactedText: 'boundary-reviewed business business message',
            ),
            egressPurpose: BoundaryEgressPurpose.directMessage,
          ),
        ),
      );
      final intake = Ai2AiChatEventIntakeService(
        chatAnalyzer: analyzer,
        humanLanguageBoundaryReviewLane: lane,
        agentIdService: agentIdService,
      );
      final service = BusinessBusinessChatServiceAI2AI(
        conversationOrchestrationLane: conversationOrchestrationLane,
        encryptionService: encryptionService,
        agentIdService: agentIdService,
        humanLanguageBoundaryReviewLane: lane,
        ai2aiChatEventIntakeService: intake,
      );

      final message = await service.sendMessage(
        senderBusinessId: 'business_1',
        recipientBusinessId: 'business_2',
        content: 'raw original message',
      );

      expect(message.content, 'boundary-reviewed business business message');
      expect(
        message.metadata?[HumanLanguageBoundaryReview.metadataKey],
        isA<Map<String, dynamic>>(),
      );
      expect(
        message.metadata?[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map<String, dynamic>>(),
      );

      verify(
        () => encryptionService.encrypt(
          'boundary-reviewed business business message',
          'agt_business_2',
        ),
      ).called(1);
      verify(
        () => conversationOrchestrationLane.sendDirectMessagePayload(
          recipientAgentId: 'agt_business_2',
          payload: any(
            named: 'payload',
            that: predicate<Map<String, dynamic>>(
              (payload) =>
                  payload['content'] ==
                      'boundary-reviewed business business message' &&
                  payload['message_category'] == 'user_chat',
            ),
          ),
        ),
      ).called(1);

      final history = await service.getMessageHistory(message.conversationId);
      expect(history, hasLength(1));
      expect(
        history.single.metadata?[HumanLanguageBoundaryReview.metadataKey],
        isA<Map<String, dynamic>>(),
      );

      final analyzerHistory =
          await analyzer.getChatHistoryForAdmin('business_1');
      expect(analyzerHistory, hasLength(1));
      expect(
        analyzerHistory.single.messages.single.content,
        'boundary-reviewed business business message',
      );
      expect(
        analyzerHistory.single.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );
    });

    test('business-business send fails closed when boundary blocks egress',
        () async {
      when(
        () => agentIdService.getBusinessAgentId('business_1'),
      ).thenAnswer((_) async => 'agt_business_1');
      when(
        () => agentIdService.getBusinessAgentId('business_2'),
      ).thenAnswer((_) async => 'agt_business_2');

      final lane = _FixedHumanLanguageBoundaryReviewLane(
        _buildBoundaryReview(
          reviewedText: 'blocked',
          decision: BoundaryDecision(
            accepted: false,
            disposition: BoundaryDisposition.block,
            transcriptStorageAllowed: false,
            storageAllowed: false,
            learningAllowed: false,
            egressAllowed: false,
            airGapRequired: false,
            reasonCodes: const <String>['policy_blocked'],
            sanitizedArtifact: const BoundarySanitizedArtifact(
              pseudonymousActorRef: 'anon_blocked',
              summary: 'blocked',
              safeClaims: <String>[],
              safeQuestions: <String>[],
              safePreferenceSignals: <InterpretationPreferenceSignal>[],
              learningVocabulary: <String>[],
              learningPhrases: <String>[],
              redactedText: 'blocked',
            ),
            egressPurpose: BoundaryEgressPurpose.directMessage,
          ),
        ),
      );
      final service = BusinessBusinessChatServiceAI2AI(
        conversationOrchestrationLane: conversationOrchestrationLane,
        encryptionService: encryptionService,
        agentIdService: agentIdService,
        humanLanguageBoundaryReviewLane: lane,
      );

      expect(
        () => service.sendMessage(
          senderBusinessId: 'business_1',
          recipientBusinessId: 'business_2',
          content: 'raw original message',
        ),
        throwsA(isA<HumanLanguageBoundaryViolationException>()),
      );
      verifyNever(
        () => conversationOrchestrationLane.sendDirectMessagePayload(
          recipientAgentId: any(named: 'recipientAgentId'),
          payload: any(named: 'payload'),
        ),
      );
    });
  });
}

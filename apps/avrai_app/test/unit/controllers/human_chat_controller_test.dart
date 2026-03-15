import 'package:avrai/presentation/controllers/human_chat_controller.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPersonalityAgentChatService extends Mock
    implements PersonalityAgentChatService {}

class _MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  setUpAll(() {
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
  });

  group('HumanChatController', () {
    late _MockPersonalityAgentChatService chatService;
    late _MockAgentIdService agentIdService;
    late SharedPreferencesCompat prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferencesCompat.getInstance();
      chatService = _MockPersonalityAgentChatService();
      agentIdService = _MockAgentIdService();

      when(() => agentIdService.getUserAgentId('user-1'))
          .thenAnswer((_) async => 'agent-1');
      when(() => chatService.getConversationHistory('user-1'))
          .thenAnswer((_) async => const []);
      when(
        () => chatService.getUserSignatureSummary(
          userId: 'user-1',
          currentLocation: any(named: 'currentLocation'),
        ),
      ).thenAnswer((_) async => 'Your local signature is active.');
      when(
        () => chatService.chatWithKernelContext(
          'user-1',
          'Hello OS',
          currentLocation: any(named: 'currentLocation'),
        ),
      ).thenAnswer(
        (_) async => PersonalityAgentChatResult(
          response: 'Hello back.',
          realityKernelFusionInput: _buildModelTruth(),
          governanceReport: _buildGovernanceReport(),
        ),
      );
    });

    test('surfaces headless OS chat artifacts after sending a message',
        () async {
      final controller = HumanChatController(
        chatService: chatService,
        agentIdService: agentIdService,
        prefsProvider: () async => prefs,
        locationProvider: () async => null,
      );

      await controller.initialize(userId: 'user-1');
      await controller.sendMessage('Hello OS');

      expect(controller.messages, hasLength(2));
      expect(controller.messages.last.content, 'Hello back.');
      expect(controller.modelTruthReady, isTrue);
      expect(controller.localityContainedInWhere, isTrue);
      expect(controller.lastKernelEventId, 'chat-event-1');
      expect(
          controller.governanceSummary, 'chat turn stayed inside governance');
      expect(controller.governanceDomains, contains('why'));

      verify(
        () => chatService.chatWithKernelContext(
          'user-1',
          'Hello OS',
          currentLocation: any(named: 'currentLocation'),
        ),
      ).called(1);
    });

    test('builds a personal-agent event draft from an event-planning chat turn',
        () async {
      when(
        () => chatService.chatWithKernelContext(
          'user-1',
          'Help me plan a spring music festival this weekend',
          currentLocation: any(named: 'currentLocation'),
        ),
      ).thenAnswer(
        (_) async => PersonalityAgentChatResult(
          response:
              'This could feel joyful, welcoming, and community-first with live music and a clear local gathering point.',
          realityKernelFusionInput: _buildModelTruth(),
          governanceReport: _buildGovernanceReport(),
        ),
      );

      final controller = HumanChatController(
        chatService: chatService,
        agentIdService: agentIdService,
        prefsProvider: () async => prefs,
        locationProvider: () async => null,
        nowLocal: () => DateTime.utc(2026, 3, 14, 12),
      );

      await controller.initialize(userId: 'user-1');
      await controller.sendMessage(
        'Help me plan a spring music festival this weekend',
      );

      final draft = controller.lastEventPlanningDraft;
      expect(draft, isNotNull);
      expect(
        draft!.planningInput.sourceKind,
        EventPlanningSourceKind.personalAgent,
      );
      expect(draft.suggestedTemplate?.id, 'concert_meetup');
      expect(draft.planningInput.preferredStartDate, isNotNull);
      expect(
        draft.planningInput.purposeText,
        contains('spring music festival'),
      );
    });
  });
}

RealityKernelFusionInput _buildModelTruth() {
  final envelope = KernelEventEnvelope(
    eventId: 'chat-event-1',
    userId: 'user-1',
    agentId: 'agent-1',
    occurredAtUtc: DateTime.utc(2026, 3, 7),
    sourceSystem: 'test',
    eventType: 'chat_completed',
    actionType: 'chat_with_agent',
  );
  const bundle = KernelContextBundle(
    who: null,
    what: null,
    when: null,
    where: null,
    how: null,
    why: null,
  );
  return RealityKernelFusionInput(
    envelope: envelope,
    bundle: bundle,
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

KernelGovernanceReport _buildGovernanceReport() {
  final envelope = KernelEventEnvelope(
    eventId: 'chat-event-1',
    userId: 'user-1',
    agentId: 'agent-1',
    occurredAtUtc: DateTime.utc(2026, 3, 7),
    sourceSystem: 'test',
    eventType: 'chat_completed',
    actionType: 'chat_with_agent',
  );
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
        summary: 'chat turn stayed inside governance',
        confidence: 0.8,
      ),
    ],
    generatedAtUtc: DateTime.utc(2026, 3, 7),
  );
}

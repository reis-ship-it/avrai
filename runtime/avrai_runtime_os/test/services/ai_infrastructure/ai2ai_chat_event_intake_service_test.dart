import 'dart:io';

import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import '../../support/fake_language_kernels.dart';

class _FakeLegacyAi2AiExchangeTransportAdapter
    implements LegacyAi2AiExchangeTransportAdapter {
  final List<_CapturedExchangeDispatch> dispatches =
      <_CapturedExchangeDispatch>[];

  @override
  Future<void> dispatchExchange({
    required String peerId,
    required Ai2AiExchangeArtifactClass artifactClass,
    required Map<String, dynamic> payload,
    String? legacyMessageTypeName,
  }) async {
    dispatches.add(
      _CapturedExchangeDispatch(
        peerId: peerId,
        artifactClass: artifactClass,
        payload: payload,
        legacyMessageTypeName: legacyMessageTypeName,
      ),
    );
  }
}

class _CapturedExchangeDispatch {
  const _CapturedExchangeDispatch({
    required this.peerId,
    required this.artifactClass,
    required this.payload,
    this.legacyMessageTypeName,
  });

  final String peerId;
  final Ai2AiExchangeArtifactClass artifactClass;
  final Map<String, dynamic> payload;
  final String? legacyMessageTypeName;
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
    storageRoot = await Directory.systemTemp.createTemp('ai2ai_intake_test_');
    await GetStorage('ai2ai_chat_event_intake', storageRoot.path).initStorage;
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // GetStorage can keep temp files around briefly in tests; ignore cleanup failures.
    }
  });

  group('Ai2AiChatEventIntakeService', () {
    late SharedPreferencesCompat prefs;
    late AI2AIChatAnalyzer analyzer;
    late HumanLanguageBoundaryReviewLane boundaryLane;
    late Ai2AiChatEventIntakeService service;
    late DartAi2AiRuntimeKernel kernel;
    late Ai2AiMeshGovernanceBindingService governanceBindingService;
    late _FakeLegacyAi2AiExchangeTransportAdapter transportAdapter;
    late Ai2AiExchangeSubmissionLane exchangeSubmissionLane;
    late NetworkActivityMonitor monitor;

    setUp(() async {
      final storage = GetStorage('ai2ai_chat_event_intake');
      await storage.erase();
      prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      await prefs.setBool('user_runtime_learning_enabled', true);
      await prefs.setBool('ai2ai_learning_enabled', true);
      analyzer = AI2AIChatAnalyzer(
        prefs: prefs,
        personalityLearning: PersonalityLearning.withPrefs(prefs),
      );
      boundaryLane = TestHumanLanguageBoundaryReviewLane();
      monitor = NetworkActivityMonitor();
      kernel = DartAi2AiRuntimeKernel(
        networkActivityMonitor: monitor,
        nowUtc: () => DateTime.utc(2026, 3, 12, 10),
      );
      governanceBindingService = Ai2AiMeshGovernanceBindingService(
        kernelOs: _FakeFunctionalKernelOs(),
      );
      transportAdapter = _FakeLegacyAi2AiExchangeTransportAdapter();
      exchangeSubmissionLane = Ai2AiExchangeSubmissionLane(
        ai2aiKernel: kernel,
        transportAdapter: transportAdapter,
      );
      service = Ai2AiChatEventIntakeService(
        chatAnalyzer: analyzer,
        humanLanguageBoundaryReviewLane: boundaryLane,
        governanceBindingService: governanceBindingService,
        ai2aiKernel: kernel,
        exchangeSubmissionLane: exchangeSubmissionLane,
      );
    });

    test(
        'adds a separate learnable artifact for sent direct messages even when transport metadata is egress-only',
        () async {
      final transportReview = await boundaryLane.reviewOutboundText(
        actorAgentId: 'agt_userA',
        rawText: 'I prefer collaborative planning and trying new local spots.',
        egressPurpose: BoundaryEgressPurpose.directMessage,
        egressRequested: true,
        userId: 'userA',
        chatType: 'friend',
        channel: 'friend_chat',
        consentScopes: const <String>{
          'user_runtime_learning',
          'ai2ai_learning'
        },
      );

      final result = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userA',
        counterpartUserId: 'userB',
        messageId: 'msg-1',
        plaintext:
            'I prefer collaborative planning and trying new local spots.',
        occurredAt: DateTime.utc(2026, 3, 12, 9),
        direction: Ai2AiChatFlowDirection.outbound,
        metadata: transportReview.toMetadata(),
      );

      expect(result.analyzed, isTrue);
      expect(result.learningAllowed, isTrue);
      expect(
        result.metadata[HumanLanguageBoundaryReview.metadataKey],
        isA<Map<String, dynamic>>(),
      );
      expect(
        result.metadata[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map<String, dynamic>>(),
      );
      expect(
        result.chatEvent?.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );

      final history = await analyzer.getChatHistoryForAdmin('userA');
      expect(history, hasLength(1));
      expect(history.single.messages.single.hasStructuredLearnableArtifact,
          isTrue);
      expect(
        history.single.messages.single.learnableArtifactSource,
        ChatMessage.humanLanguageLearningMetadataKey,
      );
    });

    test('skips ingestion when local learning review blocks sensitive content',
        () async {
      final result = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-sensitive',
        plaintext: 'My phone number is 5551234567 and email is me@example.com',
        occurredAt: DateTime.utc(2026, 3, 12, 10),
        direction: Ai2AiChatFlowDirection.inbound,
      );

      expect(result.analyzed, isFalse);
      expect(result.learningAllowed, isFalse);
      expect(
        result.metadata[HumanLanguageBoundaryReview.learningMetadataKey],
        isA<Map<String, dynamic>>(),
      );

      final history = await analyzer.getChatHistoryForAdmin('userA');
      expect(history, isEmpty);
    });

    test('observes receipt artifacts into canonical AI2AI exchange truth',
        () async {
      await _primeExchangeSnapshot(
        kernel,
        exchangeId: 'exchange-1',
        conversationId: 'userB',
      );

      final result = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-receipt',
        plaintext: 'receipt payload',
        occurredAt: DateTime.utc(2026, 3, 12, 10),
        direction: Ai2AiChatFlowDirection.inbound,
        metadata: const <String, dynamic>{
          'ai2ai_artifact_class': 'receipt',
          'ai2ai_receipt_stage': 'peerApplied',
          'ai2ai_exchange_id': 'exchange-1',
          'ai2ai_conversation_id': 'userB',
          'ai2ai_source_message_id': 'msg-outbound-prime',
        },
        routeReceipt: _routeReceipt(
          receiptId: 'receipt-1',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 9, 59),
        ),
      );

      expect(result.analyzed, isFalse);
      expect(result.skipReason, 'exchange_receipt_observed');
      expect(
        kernel.snapshotExchange('exchange-1')?.lifecycleState,
        Ai2AiExchangeLifecycleState.peerApplied,
      );
      final health = await kernel.diagnoseAi2Ai();
      expect(health.diagnostics['peer_applied_count'], 1);
    });

    test('ignores receipt artifacts that try to advance without a primed exchange',
        () async {
      final result = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-receipt-unprimed',
        plaintext: 'receipt payload',
        occurredAt: DateTime.utc(2026, 3, 12, 10, 1),
        direction: Ai2AiChatFlowDirection.inbound,
        metadata: const <String, dynamic>{
          'ai2ai_artifact_class': 'receipt',
          'ai2ai_receipt_stage': 'peerApplied',
          'ai2ai_exchange_id': 'exchange-unprimed',
          'ai2ai_conversation_id': 'userB',
          'ai2ai_source_message_id': 'msg-unprimed',
        },
        routeReceipt: _routeReceipt(
          receiptId: 'receipt-unprimed',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 10),
        ),
      );

      expect(result.analyzed, isFalse);
      expect(result.skipReason, 'exchange_receipt_ignored');
      expect(kernel.snapshotExchange('exchange-unprimed'), isNull);
    });

    test('ignores receipt artifacts with mismatched correlation metadata',
        () async {
      final result = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-receipt-mismatch',
        plaintext: 'receipt payload',
        occurredAt: DateTime.utc(2026, 3, 12, 10, 5),
        direction: Ai2AiChatFlowDirection.inbound,
        metadata: const <String, dynamic>{
          'ai2ai_artifact_class': 'receipt',
          'ai2ai_receipt_stage': 'peerApplied',
          'ai2ai_exchange_id': 'exchange-mismatch',
          'ai2ai_conversation_id': 'conversation-1',
          'ai2ai_receiver_user_id': 'userZ',
        },
        routeReceipt: _routeReceipt(
          receiptId: 'receipt-mismatch',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 10, 4),
        ),
      );

      expect(result.analyzed, isFalse);
      expect(result.skipReason, 'exchange_receipt_ignored');
      expect(kernel.snapshotExchange('exchange-mismatch'), isNull);
      final health = await kernel.diagnoseAi2Ai();
      expect(health.diagnostics['peer_applied_count'], isNot(1));
      expect(health.diagnostics['peer_applied_count'], 0);
    });

    test('ignores regressive receipt stages after a higher peer-truth stage',
        () async {
      await _primeExchangeSnapshot(
        kernel,
        exchangeId: 'exchange-ordered',
        conversationId: 'userB',
      );

      final firstResult = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-receipt-peer-applied',
        plaintext: 'receipt payload',
        occurredAt: DateTime.utc(2026, 3, 12, 10, 7),
        direction: Ai2AiChatFlowDirection.inbound,
        metadata: const <String, dynamic>{
          'ai2ai_artifact_class': 'receipt',
          'ai2ai_receipt_stage': 'peerApplied',
          'ai2ai_exchange_id': 'exchange-ordered',
          'ai2ai_conversation_id': 'userB',
          'ai2ai_source_message_id': 'msg-outbound-ordered',
        },
        routeReceipt: _routeReceipt(
          receiptId: 'receipt-peer-applied',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 10, 7),
        ),
      );
      expect(firstResult.skipReason, 'exchange_receipt_observed');

      final regressiveResult = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-receipt-peer-received',
        plaintext: 'receipt payload',
        occurredAt: DateTime.utc(2026, 3, 12, 10, 8),
        direction: Ai2AiChatFlowDirection.inbound,
        metadata: const <String, dynamic>{
          'ai2ai_artifact_class': 'receipt',
          'ai2ai_receipt_stage': 'peerReceived',
          'ai2ai_exchange_id': 'exchange-ordered',
          'ai2ai_conversation_id': 'userB',
          'ai2ai_source_message_id': 'msg-outbound-ordered',
        },
        routeReceipt: _routeReceipt(
          receiptId: 'receipt-peer-received',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 10, 8),
        ),
      );

      expect(regressiveResult.analyzed, isFalse);
      expect(regressiveResult.skipReason, 'exchange_receipt_ignored');
      expect(
        kernel.snapshotExchange('exchange-ordered')?.lifecycleState,
        Ai2AiExchangeLifecycleState.peerApplied,
      );
    });

    test('emits peer-truth receipt artifacts for inbound governed exchanges',
        () async {
      final result = await service.ingestDirectMessage(
        localUserId: 'userA',
        senderUserId: 'userB',
        counterpartUserId: 'userB',
        messageId: 'msg-exchange',
        plaintext: 'I learn best from collaborative planning and neighborhood patterns.',
        occurredAt: DateTime.utc(2026, 3, 12, 10, 15),
        direction: Ai2AiChatFlowDirection.inbound,
        metadata: const <String, dynamic>{
          'ai2ai_exchange_id': 'exchange-inbound',
        },
        routeReceipt: _routeReceipt(
          receiptId: 'receipt-2',
          recordedAtUtc: DateTime.utc(2026, 3, 12, 10, 14),
        ),
      );

      expect(result.analyzed, isTrue);
      expect(result.learningAllowed, isTrue);

      expect(
        transportAdapter.dispatches
            .where(
              (entry) =>
                  entry.peerId == 'userB' &&
                  entry.artifactClass == Ai2AiExchangeArtifactClass.receipt,
            )
            .length,
        4,
      );
      final stages = transportAdapter.dispatches
          .map((dispatch) => dispatch.payload['ai2ai_receipt_stage']?.toString())
          .whereType<String>()
          .toList(growable: false);
      expect(
        stages,
        containsAll(<String>[
          'peerReceived',
          'peerValidated',
          'peerConsumed',
          'peerApplied',
        ]),
      );
      expect(
        kernel.snapshotExchange('exchange-inbound')?.lifecycleState,
        Ai2AiExchangeLifecycleState.peerApplied,
      );
    });
  });
}

Future<void> _primeExchangeSnapshot(
  DartAi2AiRuntimeKernel kernel, {
  required String exchangeId,
  required String conversationId,
}) {
  return kernel.observeExchange(
    Ai2AiExchangeObservation(
      observationId: 'prime-$exchangeId',
      exchangeId: exchangeId,
      conversationId: conversationId,
      lifecycleState: Ai2AiExchangeLifecycleState.planned,
      observedAtUtc: DateTime.utc(2026, 3, 12, 9, 57),
      envelope: KernelEventEnvelope(
        eventId: 'prime-envelope-$exchangeId',
        occurredAtUtc: DateTime.utc(2026, 3, 12, 9, 57),
        userId: 'userA',
        sourceSystem: 'test',
        eventType: 'ai2ai_exchange_prime',
        entityId: exchangeId,
        entityType: 'ai2ai_exchange',
        privacyMode: 'private_mesh',
      ),
      governanceBundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
      ),
      routeReceipt: _routeReceipt(
        receiptId: 'prime-receipt-$exchangeId',
        recordedAtUtc: DateTime.utc(2026, 3, 12, 9, 57),
      ),
    ),
  );
}

TransportRouteReceipt _routeReceipt({
  required String receiptId,
  required DateTime recordedAtUtc,
}) {
  const route = TransportRouteCandidate(
    routeId: 'ble:userB:node-b',
    mode: TransportMode.ble,
    confidence: 0.9,
    estimatedLatencyMs: 80,
    metadata: <String, dynamic>{
      'peer_id': 'userB',
      'peer_node_id': 'node-b',
    },
  );
  return TransportRouteReceipt(
    receiptId: receiptId,
    channel: 'mesh_ble_forward',
    status: 'forwarded',
    recordedAtUtc: recordedAtUtc,
    plannedRoutes: const <TransportRouteCandidate>[route],
    attemptedRoutes: const <TransportRouteCandidate>[route],
    winningRoute: route,
    hopCount: 1,
    queuedAtUtc: recordedAtUtc,
    custodyAcceptedAtUtc: recordedAtUtc.add(const Duration(milliseconds: 500)),
    custodyAcceptedBy: 'node-b',
    metadata: const <String, dynamic>{'peer_id': 'userB'},
  );
}

class _FakeFunctionalKernelOs implements FunctionalKernelOs {
  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<KernelBundleRecord> resolveAndExplain({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return KernelBundleRecord(
      recordId: 'record-1',
      eventId: envelope.eventId,
      bundle: KernelContextBundle(
        who: const WhoKernelSnapshot(
          primaryActor: 'agent-a',
          affectedActor: 'peer-b',
          companionActors: <String>[],
          actorRoles: <String>['peer'],
          trustScope: 'private',
          cohortRefs: <String>[],
          identityConfidence: 0.9,
        ),
        what: const WhatKernelSnapshot(
          actionType: 'deliver',
          targetEntityType: 'message',
          targetEntityId: 'message-1',
          stateTransitionType: 'queued_to_delivered',
          outcomeType: 'pending',
          semanticTags: <String>['mesh', 'ai2ai'],
          taxonomyConfidence: 0.88,
        ),
        when: WhenKernelSnapshot(
          observedAt: DateTime.utc(2026, 3, 12, 10),
          freshness: 0.8,
          recencyBucket: 'hot',
          timingConflictFlags: const <String>['none'],
          temporalConfidence: 0.91,
        ),
        where: const WhereKernelSnapshot(
          localityToken: 'where:bham:1',
          cityCode: 'bham',
          localityCode: 'southside',
          projection: <String, dynamic>{'mode': 'local'},
          boundaryTension: 0.1,
          spatialConfidence: 0.85,
          travelFriction: 0.22,
          placeFitFlags: <String>['proximate'],
        ),
        how: const HowKernelSnapshot(
          executionPath: 'governed_runtime',
          workflowStage: 'delivery',
          transportMode: 'mesh',
          plannerMode: 'governed',
          modelFamily: 'signal_reticulum',
          interventionChain: <String>['resolve', 'explain'],
          failureMechanism: 'none',
          mechanismConfidence: 0.89,
        ),
        why: WhyKernelSnapshot(
          goal: 'deliver_message',
          summary: 'Governed delivery path selected.',
          rootCauseType: WhyRootCauseType.mechanism,
          confidence: 0.84,
          drivers: const <WhySignal>[
            WhySignal(label: 'delivery_probability', weight: 0.9),
          ],
          inhibitors: const <WhySignal>[],
          counterfactuals: const <WhyCounterfactual>[],
          createdAtUtc: DateTime.utc(2026, 3, 12, 10),
        ),
      ),
      createdAtUtc: DateTime.utc(2026, 3, 12, 10),
    );
  }

  @override
  Future<KernelContextBundle> resolveKernelContext(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhereKernelSnapshot> resolveWhere(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }

  @override
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope) {
    throw UnimplementedError();
  }
}

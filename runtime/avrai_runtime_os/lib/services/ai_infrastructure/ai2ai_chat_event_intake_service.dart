import 'dart:developer' as developer;

import 'package:avrai_core/models/interpretation/interpretation_models.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart'
    hide ChatMessage, ChatMessageType;
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

enum Ai2AiChatFlowDirection {
  outbound,
  inbound,
}

enum Ai2AiChatScope {
  direct,
  community,
}

class Ai2AiChatEventIntakeResult {
  const Ai2AiChatEventIntakeResult({
    required this.analyzed,
    required this.learningAllowed,
    required this.metadata,
    this.chatEvent,
    this.analysisResult,
    this.skipReason,
  });

  final bool analyzed;
  final bool learningAllowed;
  final Map<String, dynamic> metadata;
  final AI2AIChatEvent? chatEvent;
  final AI2AIChatAnalysisResult? analysisResult;
  final String? skipReason;
}

class Ai2AiChatEventIntakeService {
  static const String _logName = 'Ai2AiChatEventIntakeService';

  Ai2AiChatEventIntakeService({
    required AI2AIChatAnalyzer chatAnalyzer,
    HumanLanguageBoundaryReviewLane? humanLanguageBoundaryReviewLane,
    AgentIdService? agentIdService,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    Ai2AiKernelContract? ai2aiKernel,
    Ai2AiExchangeSubmissionLane? exchangeSubmissionLane,
  })  : _chatAnalyzer = chatAnalyzer,
        _humanLanguageBoundaryReviewLane = humanLanguageBoundaryReviewLane ??
            HumanLanguageBoundaryReviewLane(),
        _agentIdService = agentIdService,
        _governanceBindingService = governanceBindingService,
        _ai2aiKernel = ai2aiKernel,
        _exchangeSubmissionLane = exchangeSubmissionLane;

  final AI2AIChatAnalyzer _chatAnalyzer;
  final HumanLanguageBoundaryReviewLane _humanLanguageBoundaryReviewLane;
  final AgentIdService? _agentIdService;
  final Ai2AiMeshGovernanceBindingService? _governanceBindingService;
  final Ai2AiKernelContract? _ai2aiKernel;
  final Ai2AiExchangeSubmissionLane? _exchangeSubmissionLane;

  Future<Map<String, dynamic>> buildLearningMetadata({
    required String localUserId,
    required String sourceUserId,
    required String rawText,
    required String chatType,
    required String channel,
    String surface = 'chat',
    Set<String>? consentScopes,
    String? sourceAgentId,
  }) async {
    final review =
        await _humanLanguageBoundaryReviewLane.reviewLocalLearningText(
      actorAgentId: await _resolveActorAgentId(
        sourceUserId,
        explicitAgentId: sourceAgentId,
      ),
      rawText: rawText,
      userId: localUserId,
      chatType: chatType,
      surface: surface,
      channel: channel,
      consentScopes: consentScopes,
    );
    return review.toMetadata(
      metadataKey: HumanLanguageBoundaryReview.learningMetadataKey,
    );
  }

  Future<Ai2AiChatEventIntakeResult> ingestDirectMessage({
    required String localUserId,
    required String senderUserId,
    required String counterpartUserId,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    required Ai2AiChatFlowDirection direction,
    Map<String, dynamic>? metadata,
    TransportRouteReceipt? routeReceipt,
    String? localAgentId,
    String? senderAgentId,
    String? counterpartAgentId,
  }) {
    return _ingest(
      scope: Ai2AiChatScope.direct,
      localUserId: localUserId,
      senderUserId: senderUserId,
      remoteRef: counterpartUserId,
      messageId: messageId,
      plaintext: plaintext,
      occurredAt: occurredAt,
      direction: direction,
      chatType: 'friend',
      channel: 'friend_chat',
      metadata: metadata,
      routeReceipt: routeReceipt,
      localAgentId: localAgentId,
      senderAgentId: senderAgentId,
      remoteAgentId: counterpartAgentId,
    );
  }

  Future<Ai2AiChatEventIntakeResult> ingestCommunityMessage({
    required String localUserId,
    required String senderUserId,
    required String communityId,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    required Ai2AiChatFlowDirection direction,
    Map<String, dynamic>? metadata,
    TransportRouteReceipt? routeReceipt,
    int? memberCount,
    String? localAgentId,
    String? senderAgentId,
  }) {
    return _ingest(
      scope: Ai2AiChatScope.community,
      localUserId: localUserId,
      senderUserId: senderUserId,
      remoteRef: communityId,
      messageId: messageId,
      plaintext: plaintext,
      occurredAt: occurredAt,
      direction: direction,
      chatType: 'community',
      channel: 'community_chat',
      metadata: metadata,
      routeReceipt: routeReceipt,
      localAgentId: localAgentId,
      senderAgentId: senderAgentId,
      extraEventMetadata: <String, dynamic>{
        if (memberCount != null) 'member_count': memberCount,
      },
    );
  }

  Future<Ai2AiChatEventIntakeResult> _ingest({
    required Ai2AiChatScope scope,
    required String localUserId,
    required String senderUserId,
    required String remoteRef,
    required String messageId,
    required String plaintext,
    required DateTime occurredAt,
    required Ai2AiChatFlowDirection direction,
    required String chatType,
    required String channel,
    Map<String, dynamic>? metadata,
    TransportRouteReceipt? routeReceipt,
    String? localAgentId,
    String? senderAgentId,
    String? remoteAgentId,
    Map<String, dynamic> extraEventMetadata = const <String, dynamic>{},
  }) async {
    try {
      final baseMetadata =
          Map<String, dynamic>.from(metadata ?? const <String, dynamic>{});
      if (_isExchangeReceiptArtifact(baseMetadata)) {
        final observed = await _observeExchangeReceipt(
          metadata: baseMetadata,
          localUserId: localUserId,
          senderUserId: senderUserId,
          remoteRef: remoteRef,
          occurredAt: occurredAt.toUtc(),
          routeReceipt: routeReceipt,
        );
        return Ai2AiChatEventIntakeResult(
          analyzed: false,
          learningAllowed: false,
          metadata: baseMetadata,
          skipReason:
              observed ? 'exchange_receipt_observed' : 'exchange_receipt_ignored',
        );
      }
      final effectiveMetadata = await _ensureLearningMetadata(
        localUserId: localUserId,
        sourceUserId: senderUserId,
        rawText: plaintext,
        chatType: chatType,
        channel: channel,
        metadata: metadata,
        sourceAgentId: senderAgentId,
      );
      final learningMetadata = _extractMetadata(
        effectiveMetadata,
        HumanLanguageBoundaryReview.learningMetadataKey,
      );
      final learningAllowed = learningMetadata['accepted'] == true &&
          learningMetadata['learning_allowed'] == true;
      if (!learningAllowed) {
        return Ai2AiChatEventIntakeResult(
          analyzed: false,
          learningAllowed: false,
          metadata: effectiveMetadata,
          skipReason: 'learning_not_allowed',
        );
      }

      final timestamp = occurredAt.toUtc();
      final participants = scope == Ai2AiChatScope.direct
          ? <String>[
              senderUserId,
              direction == Ai2AiChatFlowDirection.inbound
                  ? localUserId
                  : remoteRef,
            ]
          : <String>[senderUserId, 'community:$remoteRef'];
      final messageContext = <String, dynamic>{
        ...effectiveMetadata,
        'chat_scope': scope.name,
        'flow_direction': direction.name,
        'local_user_id': localUserId,
        'sender_user_id': senderUserId,
        if (scope == Ai2AiChatScope.direct)
          'counterpart_user_id': remoteRef
        else
          'community_id': remoteRef,
        if (routeReceipt != null)
          'transport_route_receipt': routeReceipt.toJson(),
      };
      final chatEvent = AI2AIChatEvent(
        eventId: '${scope.name}:${direction.name}:$messageId',
        participants: participants,
        messages: <ChatMessage>[
          ChatMessage(
            senderId: senderUserId,
            content: plaintext,
            timestamp: timestamp,
            context: messageContext,
          ),
        ],
        messageType: _inferMessageType(
          learningMetadata,
          plaintext: plaintext,
        ),
        timestamp: timestamp,
        duration: Duration.zero,
        metadata: <String, dynamic>{
          'chat_scope': scope.name,
          'flow_direction': direction.name,
          'message_id': messageId,
          if (scope == Ai2AiChatScope.direct)
            'counterpart_user_id': remoteRef
          else
            'community_id': remoteRef,
          if (routeReceipt != null)
            'transport_route_receipt': routeReceipt.toJson(),
          ...extraEventMetadata,
        },
      );
      final analysisResult = await _chatAnalyzer.analyzeChatConversation(
        localUserId,
        chatEvent,
        ConnectionMetrics.initial(
          localAISignature: await _resolveActorAgentId(
            localUserId,
            explicitAgentId: localAgentId,
          ),
          remoteAISignature: await _resolveRemoteSignature(
            scope: scope,
            remoteRef: remoteRef,
            explicitAgentId: remoteAgentId,
          ),
          compatibility: scope == Ai2AiChatScope.direct ? 0.62 : 0.58,
        ),
      );
      await _recordKernelTruth(
        scope: scope,
        localUserId: localUserId,
        senderUserId: senderUserId,
        remoteRef: remoteRef,
        exchangeId: effectiveMetadata['ai2ai_exchange_id']?.toString(),
        messageId: messageId,
        occurredAt: timestamp,
        direction: direction,
        routeReceipt: routeReceipt,
        analysisApplied: true,
        learningAllowed: learningAllowed,
        metadata: effectiveMetadata,
      );

      return Ai2AiChatEventIntakeResult(
        analyzed: true,
        learningAllowed: true,
        metadata: effectiveMetadata,
        chatEvent: chatEvent,
        analysisResult: analysisResult,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to ingest live chat event for AI2AI learning',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const Ai2AiChatEventIntakeResult(
        analyzed: false,
        learningAllowed: false,
        metadata: <String, dynamic>{},
        skipReason: 'intake_error',
      );
    }
  }

  Future<Map<String, dynamic>> _ensureLearningMetadata({
    required String localUserId,
    required String sourceUserId,
    required String rawText,
    required String chatType,
    required String channel,
    Map<String, dynamic>? metadata,
    String? sourceAgentId,
  }) async {
    final base =
        Map<String, dynamic>.from(metadata ?? const <String, dynamic>{});
    if (base.containsKey(HumanLanguageBoundaryReview.learningMetadataKey)) {
      return base;
    }
    final learningMetadata = await buildLearningMetadata(
      localUserId: localUserId,
      sourceUserId: sourceUserId,
      rawText: rawText,
      chatType: chatType,
      channel: channel,
      sourceAgentId: sourceAgentId,
    );
    base.addAll(learningMetadata);
    return base;
  }

  Map<String, dynamic> _extractMetadata(
    Map<String, dynamic> metadata,
    String key,
  ) {
    final raw = metadata[key];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  Future<void> _recordKernelTruth({
    required Ai2AiChatScope scope,
    required String localUserId,
    required String senderUserId,
    required String remoteRef,
    required String? exchangeId,
    required String messageId,
    required DateTime occurredAt,
    required Ai2AiChatFlowDirection direction,
    required TransportRouteReceipt? routeReceipt,
    required bool analysisApplied,
    required bool learningAllowed,
    required Map<String, dynamic> metadata,
  }) async {
    final governanceBindingService = _governanceBindingService;
    final ai2aiKernel = _ai2aiKernel;
    if (governanceBindingService == null || ai2aiKernel == null) {
      return;
    }

    final canonicalExchangeId =
        exchangeId != null && exchangeId.isNotEmpty ? exchangeId : messageId;
    final conversationId =
        scope == Ai2AiChatScope.direct ? remoteRef : 'community:$remoteRef';
    final peerId = scope == Ai2AiChatScope.direct ? remoteRef : conversationId;
    final effectiveRouteReceipt = _routeReceiptForExchangeContext(
      routeReceipt: routeReceipt,
      occurredAt: occurredAt,
      peerId: peerId,
      localUserId: localUserId,
      learningApplied: analysisApplied && learningAllowed,
    );
    final envelope = KernelEventEnvelope(
      eventId: 'ai2ai-chat-intake-$canonicalExchangeId',
      occurredAtUtc: occurredAt,
      userId: localUserId,
      agentId: await _resolveActorAgentId(localUserId),
      sourceSystem: 'ai2ai_chat_event_intake',
      eventType: 'ai2ai_chat_intake',
      actionType: direction.name,
      entityId: canonicalExchangeId,
      entityType: 'chat_message',
      privacyMode: 'private_mesh',
      routeReceipt: effectiveRouteReceipt,
      context: <String, dynamic>{
        'sender_user_id': senderUserId,
        'remote_ref': remoteRef,
        'chat_scope': scope.name,
      },
      policyContext: <String, dynamic>{
        'learning_allowed': learningAllowed,
        'governed_runtime_path': true,
        'egress_allowed': direction == Ai2AiChatFlowDirection.outbound,
      },
    );

    final candidate =
        await governanceBindingService.buildAi2AiExchangeCandidate(
      messageId: canonicalExchangeId,
      conversationId: conversationId,
      peerId: peerId,
      artifactClass: Ai2AiExchangeArtifactClass.learningDelta,
      envelope: envelope,
      routeReceipt: effectiveRouteReceipt,
      requiresApplyReceipt: true,
      predictedOutcome:
          effectiveRouteReceipt?.lifecycleStage.name ?? 'no_transport_receipt',
      predictedConfidence: 0.82,
      coreSignals: <WhySignal>[
        WhySignal(
          label: 'learning_allowed',
          weight: learningAllowed ? 1.0 : 0.0,
          source: 'boundary_kernel',
          durable: true,
        ),
      ],
      memoryContext: <String, dynamic>{
        'chat_scope': scope.name,
        'flow_direction': direction.name,
      },
      severity: learningAllowed ? 'info' : 'warning',
    );
    final plan = await ai2aiKernel.planExchange(candidate);
    await ai2aiKernel.commitExchange(
      Ai2AiExchangeCommit(
        attemptId: 'ai2ai-chat-intake-commit-$canonicalExchangeId',
        plan: plan,
        envelope: envelope,
        commitContext: <String, dynamic>{
          'chat_scope': scope.name,
          'flow_direction': direction.name,
        },
      ),
    );
    final lifecycleState = _exchangeLifecycleStateForReceipt(
      effectiveRouteReceipt,
      learningApplied: analysisApplied && learningAllowed,
    );
    final observation =
        await governanceBindingService.buildAi2AiExchangeObservation(
      observationId: 'ai2ai-chat-intake-observation-$canonicalExchangeId',
      messageId: canonicalExchangeId,
      conversationId: conversationId,
      lifecycleState: lifecycleState,
      observedAtUtc: occurredAt,
      envelope: envelope,
      routeReceipt: effectiveRouteReceipt,
      actualOutcome: lifecycleState.name,
      actualOutcomeScore: analysisApplied && learningAllowed ? 1.0 : 0.72,
      coreSignals: <WhySignal>[
        WhySignal(
          label: 'learning_applied',
          weight: analysisApplied && learningAllowed ? 1.0 : 0.0,
          source: 'ai2ai_chat_intake',
          durable: true,
        ),
      ],
      memoryContext: <String, dynamic>{
        'chat_scope': scope.name,
        'flow_direction': direction.name,
      },
      severity: analysisApplied && learningAllowed ? 'info' : 'warning',
    );
    await ai2aiKernel.observeExchange(observation);
    if (direction == Ai2AiChatFlowDirection.inbound) {
      await _emitPeerTruthReceipts(
        localUserId: localUserId,
        senderUserId: senderUserId,
        peerId: peerId,
        conversationId: conversationId,
        exchangeId: canonicalExchangeId,
        routeReceipt: effectiveRouteReceipt,
        occurredAt: occurredAt,
        learningAllowed: learningAllowed,
        analysisApplied: analysisApplied,
        metadata: metadata,
      );
    }
  }

  TransportRouteReceipt? _routeReceiptForExchangeContext({
    required TransportRouteReceipt? routeReceipt,
    required DateTime occurredAt,
    required String peerId,
    required String localUserId,
    required bool learningApplied,
  }) {
    if (routeReceipt == null) {
      return null;
    }
    final metadata = <String, dynamic>{
      ...routeReceipt.metadata,
      'peer_id': peerId,
      'exchange_artifact_class': Ai2AiExchangeArtifactClass.learningDelta.name,
    };
    if (!learningApplied || routeReceipt.learningAppliedAtUtc != null) {
      return routeReceipt.copyWith(metadata: metadata);
    }
    return routeReceipt.copyWith(
      metadata: metadata,
      learningAppliedAtUtc: occurredAt,
      learningAppliedBy: localUserId,
    );
  }

  Ai2AiExchangeLifecycleState _exchangeLifecycleStateForReceipt(
    TransportRouteReceipt? receipt, {
    required bool learningApplied,
  }) {
    if (learningApplied || receipt?.learningAppliedAtUtc != null) {
      return Ai2AiExchangeLifecycleState.peerApplied;
    }
    if (receipt == null) {
      return Ai2AiExchangeLifecycleState.planned;
    }
    if (receipt.readAtUtc != null) {
      return Ai2AiExchangeLifecycleState.peerConsumed;
    }
    if (receipt.deliveredAtUtc != null) {
      return Ai2AiExchangeLifecycleState.peerReceived;
    }
    if (receipt.status == 'queued') {
      return Ai2AiExchangeLifecycleState.deferred;
    }
    if (receipt.custodyAcceptedAtUtc != null) {
      return Ai2AiExchangeLifecycleState.committed;
    }
    if (receipt.quarantined) {
      return Ai2AiExchangeLifecycleState.quarantined;
    }
    if (receipt.status == 'failed') {
      return Ai2AiExchangeLifecycleState.failed;
    }
    return Ai2AiExchangeLifecycleState.planned;
  }

  bool _isExchangeReceiptArtifact(Map<String, dynamic> metadata) {
    final artifactClass = metadata['ai2ai_artifact_class']?.toString();
    return artifactClass == Ai2AiExchangeArtifactClass.receipt.name &&
        metadata['ai2ai_receipt_stage'] != null;
  }

  Future<bool> _observeExchangeReceipt({
    required Map<String, dynamic> metadata,
    required String localUserId,
    required String senderUserId,
    required String remoteRef,
    required DateTime occurredAt,
    required TransportRouteReceipt? routeReceipt,
  }) async {
    final exchangeId = metadata['ai2ai_exchange_id']?.toString();
    final receiptStage = metadata['ai2ai_receipt_stage']?.toString();
    final lifecycleState = _exchangeLifecycleStateForReceiptStage(receiptStage);
    final governanceBindingService = _governanceBindingService;
    final ai2aiKernel = _ai2aiKernel;
    if (exchangeId == null ||
        exchangeId.isEmpty ||
        lifecycleState == null ||
        governanceBindingService == null ||
        ai2aiKernel == null) {
      return false;
    }
    if (!_isReceiptCorrelationValid(
      metadata: metadata,
      localUserId: localUserId,
      senderUserId: senderUserId,
      remoteRef: remoteRef,
    )) {
      return false;
    }
    if (!_isReceiptStageAdvanceAllowed(
      exchangeId: exchangeId,
      receiptStage: receiptStage,
      metadata: metadata,
      ai2aiKernel: ai2aiKernel,
    )) {
      return false;
    }
    final conversationId =
        metadata['ai2ai_conversation_id']?.toString() ?? remoteRef;
    final effectiveRouteReceipt = _routeReceiptForReceiptStage(
      routeReceipt: routeReceipt,
      metadata: metadata,
      occurredAt: occurredAt,
      localUserId: localUserId,
    );
    final envelope = KernelEventEnvelope(
      eventId: 'ai2ai-exchange-receipt-$exchangeId-$receiptStage',
      occurredAtUtc: occurredAt,
      userId: localUserId,
      agentId: await _resolveActorAgentId(localUserId),
      sourceSystem: 'ai2ai_exchange_receipt',
      eventType: 'ai2ai_exchange_receipt',
      actionType: 'observe',
      entityId: exchangeId,
      entityType: 'ai2ai_exchange',
      privacyMode: 'private_mesh',
      routeReceipt: effectiveRouteReceipt,
      context: <String, dynamic>{
        'sender_user_id': senderUserId,
        'remote_ref': remoteRef,
        'receipt_stage': receiptStage,
      },
      policyContext: const <String, dynamic>{
        'governed_runtime_path': true,
      },
    );
    final observation =
        await governanceBindingService.buildAi2AiExchangeObservation(
      observationId: 'ai2ai-exchange-receipt-observation-$exchangeId-$receiptStage',
      messageId: exchangeId,
      conversationId: conversationId,
      lifecycleState: lifecycleState,
      observedAtUtc: occurredAt,
      envelope: envelope,
      routeReceipt: effectiveRouteReceipt,
      actualOutcome: lifecycleState.name,
      outcomeContext: <String, dynamic>{
        'exchange_receipt_stage': receiptStage,
        'source_message_id': metadata['ai2ai_source_message_id']?.toString(),
      },
      coreSignals: <WhySignal>[
        WhySignal(
          label: 'receipt_stage',
          weight: 1.0,
          source: 'ai2ai_exchange_receipt',
          durable: true,
        ),
      ],
      memoryContext: <String, dynamic>{
        'receipt_stage': receiptStage,
      },
      severity: 'info',
    );
    await ai2aiKernel.observeExchange(observation);
    return true;
  }

  bool _isReceiptCorrelationValid({
    required Map<String, dynamic> metadata,
    required String localUserId,
    required String senderUserId,
    required String remoteRef,
  }) {
    final expectedReceiverUserId =
        metadata['ai2ai_receiver_user_id']?.toString();
    if (expectedReceiverUserId != null &&
        expectedReceiverUserId.isNotEmpty &&
        expectedReceiverUserId != localUserId) {
      return false;
    }
    final expectedSenderUserId =
        metadata['ai2ai_sender_user_id']?.toString();
    if (expectedSenderUserId != null &&
        expectedSenderUserId.isNotEmpty &&
        expectedSenderUserId != senderUserId) {
      return false;
    }
    final expectedConversationId =
        metadata['ai2ai_conversation_id']?.toString();
    if (expectedConversationId != null &&
        expectedConversationId.isNotEmpty &&
        expectedConversationId != remoteRef) {
      return false;
    }
    return true;
  }

  bool _isReceiptStageAdvanceAllowed({
    required String exchangeId,
    required String? receiptStage,
    required Map<String, dynamic> metadata,
    required Ai2AiKernelContract ai2aiKernel,
  }) {
    final nextRank = _receiptStageRank(receiptStage);
    if (nextRank == null) {
      return false;
    }
    if (nextRank >= 1) {
      final sourceMessageId = metadata['ai2ai_source_message_id']?.toString();
      if (sourceMessageId == null || sourceMessageId.isEmpty) {
        return false;
      }
    }
    final snapshot = ai2aiKernel.snapshotExchange(exchangeId);
    if (snapshot == null) {
      return nextRank == 0;
    }
    final currentRank = _lifecycleStateReceiptRank(snapshot.lifecycleState);
    if (currentRank == null) {
      return false;
    }
    return nextRank > currentRank;
  }

  Future<void> _emitPeerTruthReceipts({
    required String localUserId,
    required String senderUserId,
    required String peerId,
    required String conversationId,
    required String exchangeId,
    required TransportRouteReceipt? routeReceipt,
    required DateTime occurredAt,
    required bool learningAllowed,
    required bool analysisApplied,
    required Map<String, dynamic> metadata,
  }) async {
    final submissionLane = _exchangeSubmissionLane;
    if (submissionLane == null || exchangeId.isEmpty) {
      return;
    }
    final stages = <String>[
      Ai2AiExchangeLifecycleState.peerReceived.name,
      if (learningAllowed) Ai2AiExchangeLifecycleState.peerValidated.name,
      if (learningAllowed) Ai2AiExchangeLifecycleState.peerConsumed.name,
      if (analysisApplied && learningAllowed)
        Ai2AiExchangeLifecycleState.peerApplied.name,
    ];
    for (final stage in stages) {
      await submissionLane.submit(
        Ai2AiExchangeSubmissionRequest(
          exchangeId: '$exchangeId-receipt-$stage',
          conversationId: conversationId,
          peerId: senderUserId,
          artifactClass: Ai2AiExchangeArtifactClass.receipt,
          payload: <String, dynamic>{
            'ai2ai_exchange_id': exchangeId,
            'ai2ai_artifact_class': Ai2AiExchangeArtifactClass.receipt.name,
            'ai2ai_receipt_stage': stage,
            'ai2ai_source_message_id':
                metadata['message_id']?.toString() ?? exchangeId,
            'ai2ai_conversation_id': conversationId,
            'ai2ai_peer_id': peerId,
            'ai2ai_sender_user_id': localUserId,
            'ai2ai_receiver_user_id': senderUserId,
            'ai2ai_requires_apply_receipt': false,
          },
          routeReceipt: routeReceipt,
          context: <String, dynamic>{
            'exchange_receipt_stage': stage,
            'governed_runtime_path': true,
          },
        ),
      );
    }
  }

  TransportRouteReceipt? _routeReceiptForReceiptStage({
    required TransportRouteReceipt? routeReceipt,
    required Map<String, dynamic> metadata,
    required DateTime occurredAt,
    required String localUserId,
  }) {
    final receiptStage = metadata['ai2ai_receipt_stage']?.toString();
    if (routeReceipt == null || receiptStage == null || receiptStage.isEmpty) {
      return routeReceipt;
    }
    switch (receiptStage) {
      case 'peerReceived':
        return routeReceipt.deliveredAtUtc != null
            ? routeReceipt
            : routeReceipt.copyWith(deliveredAtUtc: occurredAt);
      case 'peerConsumed':
        return routeReceipt.readAtUtc != null
            ? routeReceipt
            : routeReceipt.copyWith(readAtUtc: occurredAt, readBy: localUserId);
      case 'peerApplied':
        return routeReceipt.learningAppliedAtUtc != null
            ? routeReceipt
            : routeReceipt.copyWith(
                learningAppliedAtUtc: occurredAt,
                learningAppliedBy: localUserId,
              );
      case 'peerValidated':
      default:
        return routeReceipt;
    }
  }

  Ai2AiExchangeLifecycleState? _exchangeLifecycleStateForReceiptStage(
    String? stage,
  ) {
    if (stage == null || stage.isEmpty) {
      return null;
    }
    return switch (stage) {
      'peerReceived' => Ai2AiExchangeLifecycleState.peerReceived,
      'peerValidated' => Ai2AiExchangeLifecycleState.peerValidated,
      'peerConsumed' => Ai2AiExchangeLifecycleState.peerConsumed,
      'peerApplied' => Ai2AiExchangeLifecycleState.peerApplied,
      _ => null,
    };
  }

  int? _receiptStageRank(String? stage) {
    return switch (stage) {
      'peerReceived' => 0,
      'peerValidated' => 1,
      'peerConsumed' => 2,
      'peerApplied' => 3,
      _ => null,
    };
  }

  int? _lifecycleStateReceiptRank(Ai2AiExchangeLifecycleState state) {
    return switch (state) {
      Ai2AiExchangeLifecycleState.candidate => -1,
      Ai2AiExchangeLifecycleState.planned => -1,
      Ai2AiExchangeLifecycleState.committed => -1,
      Ai2AiExchangeLifecycleState.deferred => -1,
      Ai2AiExchangeLifecycleState.peerReceived => 0,
      Ai2AiExchangeLifecycleState.peerValidated => 1,
      Ai2AiExchangeLifecycleState.peerConsumed => 2,
      Ai2AiExchangeLifecycleState.peerApplied => 3,
      Ai2AiExchangeLifecycleState.rejected => null,
      Ai2AiExchangeLifecycleState.failed => null,
      Ai2AiExchangeLifecycleState.quarantined => null,
    };
  }

  ChatMessageType _inferMessageType(
    Map<String, dynamic> learningMetadata, {
    required String plaintext,
  }) {
    final intent = InterpretationIntent.fromWireValue(
      learningMetadata['intent']?.toString(),
    );
    final summary = learningMetadata['sanitized_summary']?.toString() ?? '';
    final content = '$summary $plaintext'.toLowerCase();
    if (content.contains('trust') ||
        content.contains('safe') ||
        content.contains('confide')) {
      return ChatMessageType.trustBuilding;
    }
    switch (intent) {
      case InterpretationIntent.prefer:
        return ChatMessageType.personalitySharing;
      case InterpretationIntent.ask:
      case InterpretationIntent.plan:
      case InterpretationIntent.reflect:
        return ChatMessageType.insightExchange;
      case InterpretationIntent.share:
      case InterpretationIntent.inform:
      case InterpretationIntent.correct:
      case InterpretationIntent.confirm:
      case InterpretationIntent.reject:
      case InterpretationIntent.unknown:
        return ChatMessageType.experienceSharing;
    }
  }

  Future<String> _resolveActorAgentId(
    String userId, {
    String? explicitAgentId,
  }) async {
    if (explicitAgentId != null && explicitAgentId.isNotEmpty) {
      return explicitAgentId;
    }
    final service = _agentIdService;
    if (service == null) {
      return 'agt_$userId';
    }
    try {
      return await service.getUserAgentId(userId);
    } catch (_) {
      return 'agt_$userId';
    }
  }

  Future<String> _resolveRemoteSignature({
    required Ai2AiChatScope scope,
    required String remoteRef,
    String? explicitAgentId,
  }) async {
    if (explicitAgentId != null && explicitAgentId.isNotEmpty) {
      return explicitAgentId;
    }
    if (scope == Ai2AiChatScope.community) {
      return 'community:$remoteRef';
    }
    return _resolveActorAgentId(remoteRef);
  }
}

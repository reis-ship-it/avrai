import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/monitoring/ai2ai_network_activity_event.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';

class DartAi2AiRuntimeKernel extends Ai2AiKernelFallbackSurface {
  DartAi2AiRuntimeKernel({
    NetworkActivityMonitor? networkActivityMonitor,
    Ai2AiRuntimeStateFrameService? stateFrameService,
    Ai2AiRendezvousStore? rendezvousStore,
    DateTime Function()? nowUtc,
    Map<String, Ai2AiKernelSnapshot>? seededSnapshots,
  })  : _networkActivityMonitor =
            networkActivityMonitor ?? NetworkActivityMonitor(),
        _stateFrameService = stateFrameService ?? const Ai2AiRuntimeStateFrameService(),
        _rendezvousStore = rendezvousStore,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _snapshots = seededSnapshots ?? <String, Ai2AiKernelSnapshot>{};

  final NetworkActivityMonitor _networkActivityMonitor;
  final Ai2AiRuntimeStateFrameService _stateFrameService;
  final Ai2AiRendezvousStore? _rendezvousStore;
  final DateTime Function() _nowUtc;
  final Map<String, Ai2AiKernelSnapshot> _snapshots;

  NetworkActivityMonitor get networkActivityMonitor => _networkActivityMonitor;

  @override
  Future<Ai2AiExchangePlan> planExchange(
    Ai2AiExchangeCandidate candidate,
  ) async {
    final legacyPlan = await planAi2Ai(candidate.toLegacyCandidate());
    Ai2AiRendezvousTicket? rendezvousTicket;
    if (candidate.decision != Ai2AiExchangeDecision.exchangeNow &&
        candidate.rendezvousPolicy != null) {
      rendezvousTicket = Ai2AiRendezvousTicket(
        ticketId: 'exchange-rendezvous-${candidate.exchangeId}',
        peerId: candidate.peerId,
        decision: candidate.decision,
        policy: candidate.rendezvousPolicy!,
        createdAtUtc: _nowUtc(),
        exchangeId: candidate.exchangeId,
        artifactClass: candidate.artifactClass,
        context: candidate.context,
      );
      await _rendezvousStore?.upsert(
        ticket: rendezvousTicket,
        candidate: candidate,
      );
    }
    return legacyPlan.toExchangePlan(
      decision: candidate.decision,
      rendezvousTicket: rendezvousTicket,
    );
  }

  @override
  Future<Ai2AiExchangeReceipt> commitExchange(
    Ai2AiExchangeCommit request,
  ) async {
    final legacyReceipt = await commitAi2Ai(request.toLegacyCommitRequest());
    return legacyReceipt.toExchangeReceipt(
      exchangeId: request.plan.exchangeId,
    );
  }

  @override
  Future<Ai2AiExchangeReceipt> observeExchange(
    Ai2AiExchangeObservation observation,
  ) async {
    final legacyReceipt = await observeAi2Ai(observation.toLegacyObservation());
    _logExchangeLifecycleEvent(
      observation,
      peerRef: observation.routeReceipt?.metadata['peer_id']?.toString(),
    );
    final snapshot = _snapshotFrom(
      subjectId: observation.exchangeId,
      conversationId: observation.conversationId,
      lifecycleState: observation.lifecycleState.toLegacyLifecycleState(),
      payloadClass: _payloadClassFromRouteReceipt(observation.routeReceipt),
      routeReceipt: observation.routeReceipt,
      nowUtc: _nowUtc(),
      diagnostics: <String, dynamic>{
        ...observation.outcomeContext,
        'exchange_lifecycle_state': observation.lifecycleState.name,
      },
    );
    _storeSnapshot(snapshot);
    return legacyReceipt.toExchangeReceipt(
      exchangeId: observation.exchangeId,
    );
  }

  @override
  Ai2AiExchangeSnapshot? snapshotExchange(String subjectId) {
    final legacySnapshot = snapshotAi2Ai(subjectId);
    final exchangeSnapshot = legacySnapshot?.toExchangeSnapshot();
    final rendezvousEntry = _rendezvousStore?.entryForSubject(subjectId);
    if (exchangeSnapshot != null) {
      final exactLifecycleState =
          legacySnapshot?.diagnostics['exchange_lifecycle_state']?.toString();
      return Ai2AiExchangeSnapshot(
        subjectId: exchangeSnapshot.subjectId,
        conversationId: exchangeSnapshot.conversationId,
        lifecycleState: exactLifecycleState == null
            ? exchangeSnapshot.lifecycleState
            : Ai2AiExchangeLifecycleState.values.byName(exactLifecycleState),
        savedAtUtc: exchangeSnapshot.savedAtUtc,
        artifactClass: exchangeSnapshot.artifactClass,
        routeReceipt: exchangeSnapshot.routeReceipt,
        rendezvousTicket:
            rendezvousEntry?.ticket ?? exchangeSnapshot.rendezvousTicket,
        diagnostics: <String, dynamic>{
          ...exchangeSnapshot.diagnostics,
          'active_rendezvous_count': _rendezvousStore?.activeCount() ?? 0,
        },
      );
    }
    if (rendezvousEntry != null) {
      return Ai2AiExchangeSnapshot(
        subjectId: rendezvousEntry.candidate.exchangeId,
        conversationId: rendezvousEntry.candidate.conversationId,
        lifecycleState: Ai2AiExchangeLifecycleState.deferred,
        savedAtUtc: rendezvousEntry.storedAtUtc,
        artifactClass: rendezvousEntry.candidate.artifactClass,
        routeReceipt: rendezvousEntry.candidate.routeReceipt,
        rendezvousTicket: rendezvousEntry.ticket,
        diagnostics: <String, dynamic>{
          'active_rendezvous_count': _rendezvousStore?.activeCount() ?? 0,
        },
      );
    }
    return null;
  }

  @override
  Future<Ai2AiLifecyclePlan> planAi2Ai(Ai2AiMessageCandidate candidate) async {
    final now = _nowUtc();
    final routeReceipt = candidate.routeReceipt ??
        TransportRouteReceipt(
          receiptId: candidate.messageId,
          channel: 'ai2ai_runtime_kernel',
          status: 'planned',
          recordedAtUtc: now,
          queuedAtUtc: now,
          metadata: <String, dynamic>{
            'conversation_id': candidate.conversationId,
            'peer_id': candidate.peerId,
            'payload_class': candidate.payloadClass.name,
          },
        );
    final allowed = !_isRejected(routeReceipt, candidate);
    final lifecycleState = !allowed
        ? Ai2AiLifecycleState.rejected
        : switch (routeReceipt.lifecycleStage) {
            TransportReceiptLifecycleStage.queued => Ai2AiLifecycleState.queued,
            TransportReceiptLifecycleStage.custodyAccepted =>
              Ai2AiLifecycleState.sent,
            TransportReceiptLifecycleStage.delivered =>
              Ai2AiLifecycleState.delivered,
            TransportReceiptLifecycleStage.read => Ai2AiLifecycleState.read,
            TransportReceiptLifecycleStage.learningApplied =>
              Ai2AiLifecycleState.learningApplied,
            TransportReceiptLifecycleStage.failed => Ai2AiLifecycleState.failed,
            _ => Ai2AiLifecycleState.planned,
          };
    final snapshot = _snapshotFrom(
      subjectId: candidate.messageId,
      conversationId: candidate.conversationId,
      lifecycleState: lifecycleState,
      payloadClass: candidate.payloadClass,
      routeReceipt: routeReceipt,
      nowUtc: now,
      diagnostics: <String, dynamic>{
        'peer_id': candidate.peerId,
        'requires_learning_receipt': candidate.requiresLearningReceipt,
      },
    );
    _storeSnapshot(snapshot);
    return Ai2AiLifecyclePlan(
      planId: 'ai2ai-plan-${candidate.messageId}',
      messageId: candidate.messageId,
      lifecycleState: lifecycleState,
      allowed: allowed,
      plannedAtUtc: now,
      reason: allowed ? null : 'ai2ai_candidate_rejected',
      routeReceipt: routeReceipt,
      context: <String, dynamic>{
        ...candidate.context,
        'payload_class': candidate.payloadClass.name,
        'requires_learning_receipt': candidate.requiresLearningReceipt,
      },
    );
  }

  @override
  Future<Ai2AiCommitReceipt> commitAi2Ai(Ai2AiCommitRequest request) async {
    final now = _nowUtc();
    final routeReceipt = request.plan.routeReceipt;
    final lifecycleState = switch (request.plan.lifecycleState) {
      Ai2AiLifecycleState.queued => Ai2AiLifecycleState.queued,
      Ai2AiLifecycleState.rejected => Ai2AiLifecycleState.rejected,
      Ai2AiLifecycleState.failed => Ai2AiLifecycleState.failed,
      _ => routeReceipt?.lifecycleStage == TransportReceiptLifecycleStage.custodyAccepted
          ? Ai2AiLifecycleState.sent
          : Ai2AiLifecycleState.sent,
    };
    _logLifecycleEvent(
      lifecycleState,
      routeReceipt: routeReceipt,
      conversationId: request.plan.messageId,
      peerRef: routeReceipt?.metadata['peer_id']?.toString(),
    );
    final snapshot = _snapshotFrom(
      subjectId: request.plan.messageId,
      conversationId:
          routeReceipt?.metadata['conversation_id']?.toString() ??
              request.plan.messageId,
      lifecycleState: lifecycleState,
      payloadClass: _payloadClassFromRouteReceipt(routeReceipt),
      routeReceipt: routeReceipt,
      nowUtc: now,
      diagnostics: <String, dynamic>{
        'attempt_id': request.attemptId,
        ...request.commitContext,
      },
    );
    _storeSnapshot(snapshot);
    if (request.plan.context['rendezvous_ticket'] == null) {
      await _rendezvousStore?.removeExchange(request.plan.messageId);
    }
    return Ai2AiCommitReceipt(
      attemptId: request.attemptId,
      lifecycleState: lifecycleState,
      committedAtUtc: now,
      routeReceipt: routeReceipt,
      context: <String, dynamic>{
        ...request.commitContext,
        'conversation_id': snapshot.conversationId,
      },
    );
  }

  @override
  Future<Ai2AiObservationReceipt> observeAi2Ai(
    Ai2AiObservation observation,
  ) async {
    final now = _nowUtc();
    _logLifecycleEvent(
      observation.lifecycleState,
      routeReceipt: observation.routeReceipt,
      conversationId: observation.conversationId,
      peerRef: observation.routeReceipt?.metadata['peer_id']?.toString(),
    );
    final snapshot = _snapshotFrom(
      subjectId: observation.messageId,
      conversationId: observation.conversationId,
      lifecycleState: observation.lifecycleState,
      payloadClass: _payloadClassFromRouteReceipt(observation.routeReceipt),
      routeReceipt: observation.routeReceipt,
      nowUtc: now,
      diagnostics: observation.outcomeContext,
    );
    _storeSnapshot(snapshot);
    if (switch (observation.lifecycleState) {
      Ai2AiLifecycleState.learningApplied ||
      Ai2AiLifecycleState.rejected ||
      Ai2AiLifecycleState.failed => true,
      _ => false,
    }) {
      await _rendezvousStore?.removeExchange(observation.messageId);
    }
    return Ai2AiObservationReceipt(
      observationId: observation.observationId,
      accepted: observation.lifecycleState != Ai2AiLifecycleState.rejected,
      lifecycleState: observation.lifecycleState,
      recordedAtUtc: now,
      routeReceipt: observation.routeReceipt,
      learnableTuple: <String, dynamic>{
        'message_id': observation.messageId,
        'conversation_id': observation.conversationId,
        'lifecycle_state': observation.lifecycleState.name,
        'privacy_mode': observation.envelope.privacyMode,
        'policy_lineage': observation.envelope.policyRef,
      },
    );
  }

  @override
  Ai2AiKernelSnapshot? snapshotAi2Ai(String subjectId) {
    return _snapshots[subjectId];
  }

  @override
  Future<List<Ai2AiReplayRecord>> replayAi2Ai(
    KernelReplayRequest request,
  ) async {
    final snapshot = snapshotAi2Ai(request.subjectId);
    if (snapshot == null) {
      return const <Ai2AiReplayRecord>[];
    }
    final records = <Ai2AiReplayRecord>[
      Ai2AiReplayRecord(
        recordId: 'ai2ai:${request.subjectId}:snapshot',
        subjectId: request.subjectId,
        occurredAtUtc: snapshot.savedAtUtc,
        lifecycleState: snapshot.lifecycleState,
        summary: 'AI2AI snapshot replay for ${snapshot.conversationId}',
        routeReceipt: snapshot.routeReceipt,
        payload: snapshot.toJson(),
      ),
    ];
    final recentEvents = _networkActivityMonitor.getRecentEvents(limit: request.limit);
    for (final event in recentEvents.where((entry) {
      return entry.connectionId == request.subjectId ||
          entry.remoteNodeId == request.subjectId;
    })) {
      records.add(
        Ai2AiReplayRecord(
          recordId:
              'ai2ai:${request.subjectId}:${event.eventType}:${event.occurredAt.microsecondsSinceEpoch}',
          subjectId: request.subjectId,
          occurredAtUtc: event.occurredAt.toUtc(),
          lifecycleState: _lifecycleStateForEventType(event.eventType),
          summary: 'AI2AI event ${event.eventType}',
          payload: <String, dynamic>{
            if (event.connectionId != null) 'connection_id': event.connectionId,
            if (event.remoteNodeId != null) 'remote_node_id': event.remoteNodeId,
            if (event.reason != null) 'reason': event.reason,
          },
        ),
      );
    }
    return records.take(request.limit).toList();
  }

  @override
  Future<Ai2AiRecoveryReport> recoverAi2Ai(
    KernelRecoveryRequest request,
  ) async {
    final now = _nowUtc();
    final restoredSnapshot = request.persistedEnvelope == null
        ? null
        : Ai2AiKernelSnapshot(
            subjectId: request.persistedEnvelope!['subject_id'] as String? ??
                request.subjectId,
            conversationId:
                request.persistedEnvelope!['conversation_id'] as String? ??
                    'unknown_conversation',
            lifecycleState: Ai2AiLifecycleState.values.byName(
              request.persistedEnvelope!['lifecycle_state'] as String? ??
                  Ai2AiLifecycleState.queued.name,
            ),
            savedAtUtc: DateTime.tryParse(
                      request.persistedEnvelope!['saved_at_utc'] as String? ??
                          '',
                    )?.toUtc() ??
                now,
            payloadClass: request.persistedEnvelope!['payload_class'] == null
                ? null
                : Ai2AiPayloadClass.values.byName(
                    request.persistedEnvelope!['payload_class'] as String,
                  ),
            diagnostics: Map<String, dynamic>.from(
              request.persistedEnvelope!['diagnostics'] as Map? ??
                  const <String, dynamic>{},
            ),
          );
    if (restoredSnapshot != null) {
      _storeSnapshot(restoredSnapshot);
    }
    return Ai2AiRecoveryReport(
      subjectId: request.subjectId,
      restoredCount: restoredSnapshot == null ? 0 : 1,
      droppedCount: 0,
      recoveredAtUtc: now,
      summary: restoredSnapshot == null
          ? 'no persisted AI2AI snapshot to recover'
          : 'AI2AI snapshot restored into runtime kernel',
      diagnostics: <String, dynamic>{
        ...request.hints,
      },
    );
  }

  @override
  Future<Ai2AiKernelHealthSnapshot> diagnoseAi2Ai() async {
    final frame = _stateFrameService.buildFrame(
      events: _networkActivityMonitor.getRecentEvents(
        limit: NetworkActivityMonitor.maxBufferedEvents,
      ),
    );
    final hasDeliveryTruth = frame.deliverySuccessCount > 0 ||
        frame.deliveryFailureCount > 0 ||
        frame.readConfirmedCount > 0 ||
        frame.peerReceivedCount > 0;
    final hasLearningTruth =
        frame.learningAppliedCount > 0 ||
        frame.learningBufferedCount > 0 ||
        frame.peerAppliedCount > 0;
    final status = frame.encryptionFailureCount > 0 || frame.anomalyCount > 0
        ? Ai2AiHealthStatus.degraded
        : Ai2AiHealthStatus.healthy;
    return Ai2AiKernelHealthSnapshot(
      kernelId: 'ai2ai_runtime_governance',
      status: status,
      nativeBacked: false,
      headlessReady: true,
      summary:
          'AI2AI runtime kernel is bound to governed lifecycle truth and activity monitoring',
      diagnostics: <String, dynamic>{
        'recent_event_count': frame.recentEventCount,
        'routing_attempt_count': frame.routingAttemptCount,
        'custody_accepted_count': frame.custodyAcceptedCount,
        'delivery_success_count': frame.deliverySuccessCount,
        'delivery_failure_count': frame.deliveryFailureCount,
        'read_confirmed_count': frame.readConfirmedCount,
        'learning_applied_count': frame.learningAppliedCount,
        'learning_buffered_count': frame.learningBufferedCount,
        'peer_received_count': frame.peerReceivedCount,
        'peer_validated_count': frame.peerValidatedCount,
        'peer_consumed_count': frame.peerConsumedCount,
        'peer_applied_count': frame.peerAppliedCount,
        'encryption_failure_count': frame.encryptionFailureCount,
        'active_rendezvous_count': _rendezvousStore?.activeCount() ?? 0,
        'delivery_truth_present': hasDeliveryTruth,
        'learning_truth_present': hasLearningTruth,
        'snapshot_supported': true,
        'replay_supported': true,
      },
    );
  }

  void _storeSnapshot(Ai2AiKernelSnapshot snapshot) {
    _snapshots[snapshot.subjectId] = snapshot;
    _snapshots[snapshot.conversationId] = snapshot;
    final receiptId = snapshot.routeReceipt?.receiptId;
    if (receiptId != null && receiptId.isNotEmpty) {
      _snapshots[receiptId] = snapshot;
    }
  }

  Ai2AiKernelSnapshot _snapshotFrom({
    required String subjectId,
    required String conversationId,
    required Ai2AiLifecycleState lifecycleState,
    required DateTime nowUtc,
    required Ai2AiPayloadClass? payloadClass,
    TransportRouteReceipt? routeReceipt,
    Map<String, dynamic> diagnostics = const <String, dynamic>{},
  }) {
    return Ai2AiKernelSnapshot(
      subjectId: subjectId,
      conversationId: conversationId,
      lifecycleState: lifecycleState,
      savedAtUtc: nowUtc,
      payloadClass: payloadClass,
      routeReceipt: routeReceipt,
      diagnostics: diagnostics,
    );
  }

  bool _isRejected(
    TransportRouteReceipt routeReceipt,
    Ai2AiMessageCandidate candidate,
  ) {
    return routeReceipt.quarantined ||
        routeReceipt.status == 'failed' ||
        candidate.envelope.policyContext['egress_allowed'] == false;
  }

  Ai2AiPayloadClass? _payloadClassFromRouteReceipt(
    TransportRouteReceipt? routeReceipt,
  ) {
    final payloadClass = routeReceipt?.metadata['payload_class']?.toString();
    if (payloadClass == null) {
      return null;
    }
    return Ai2AiPayloadClass.values.firstWhere(
      (value) => value.name == payloadClass,
      orElse: () => Ai2AiPayloadClass.message,
    );
  }

  Ai2AiLifecycleState _lifecycleStateForEventType(String eventType) {
    switch (eventType) {
      case AI2AINetworkActivityEventType.deliverySuccess:
      case AI2AINetworkActivityEventType.peerReceived:
        return Ai2AiLifecycleState.delivered;
      case AI2AINetworkActivityEventType.peerValidated:
        return Ai2AiLifecycleState.sent;
      case AI2AINetworkActivityEventType.peerConsumed:
      case AI2AINetworkActivityEventType.readConfirmed:
        return Ai2AiLifecycleState.read;
      case AI2AINetworkActivityEventType.peerApplied:
      case AI2AINetworkActivityEventType.learningApplied:
        return Ai2AiLifecycleState.learningApplied;
      case AI2AINetworkActivityEventType.learningBuffered:
        return Ai2AiLifecycleState.sent;
      case AI2AINetworkActivityEventType.deliveryFailure:
      case AI2AINetworkActivityEventType.encryptionFailure:
        return Ai2AiLifecycleState.failed;
      case AI2AINetworkActivityEventType.custodyAccepted:
        return Ai2AiLifecycleState.sent;
      case AI2AINetworkActivityEventType.routingAttempt:
      case AI2AINetworkActivityEventType.connectionEstablished:
        return Ai2AiLifecycleState.sent;
      case AI2AINetworkActivityEventType.connectionClosed:
        return Ai2AiLifecycleState.failed;
      case AI2AINetworkActivityEventType.nodeDiscovery:
      case AI2AINetworkActivityEventType.anomaly:
        return Ai2AiLifecycleState.candidate;
    }
    return Ai2AiLifecycleState.failed;
  }

  void _logLifecycleEvent(
    Ai2AiLifecycleState lifecycleState, {
    required TransportRouteReceipt? routeReceipt,
    required String conversationId,
    String? peerRef,
  }) {
    switch (lifecycleState) {
      case Ai2AiLifecycleState.sent:
        _networkActivityMonitor.logRoutingAttempt(
          connectionId: conversationId,
          remoteNodeId: peerRef,
          hopCount: routeReceipt?.hopCount,
          reason: routeReceipt?.metadata['mesh_route_resolution_mode']?.toString(),
        );
        if (routeReceipt?.custodyAcceptedAtUtc != null) {
          _networkActivityMonitor.logEvent(
            AI2AINetworkActivityEvent(
              eventType: AI2AINetworkActivityEventType.custodyAccepted,
              occurredAt: routeReceipt!.custodyAcceptedAtUtc!,
              connectionId: conversationId,
              remoteNodeId: peerRef,
            ),
          );
        }
        break;
      case Ai2AiLifecycleState.delivered:
        _networkActivityMonitor.logDeliverySuccess(
          connectionId: conversationId,
          remoteNodeId: peerRef,
        );
        break;
      case Ai2AiLifecycleState.read:
        _networkActivityMonitor.logEvent(
          AI2AINetworkActivityEvent(
            eventType: AI2AINetworkActivityEventType.readConfirmed,
            occurredAt: routeReceipt?.readAtUtc ?? _nowUtc(),
            connectionId: conversationId,
            remoteNodeId: peerRef,
          ),
        );
        break;
      case Ai2AiLifecycleState.learningApplied:
        _networkActivityMonitor.logEvent(
          AI2AINetworkActivityEvent(
            eventType: AI2AINetworkActivityEventType.learningApplied,
            occurredAt: routeReceipt?.learningAppliedAtUtc ?? _nowUtc(),
            connectionId: conversationId,
            remoteNodeId: peerRef,
          ),
        );
        break;
      case Ai2AiLifecycleState.queued:
      case Ai2AiLifecycleState.planned:
      case Ai2AiLifecycleState.candidate:
        _networkActivityMonitor.logRoutingAttempt(
          connectionId: conversationId,
          remoteNodeId: peerRef,
          hopCount: routeReceipt?.hopCount,
        );
        break;
      case Ai2AiLifecycleState.suppressed:
      case Ai2AiLifecycleState.rejected:
      case Ai2AiLifecycleState.failed:
        final reason =
            routeReceipt?.fallbackReason ?? routeReceipt?.metadata['reason']?.toString();
        if (reason == 'encryption_failure') {
          _networkActivityMonitor.logEncryptionFailure(
            connectionId: conversationId,
            reason: reason,
          );
        } else {
          _networkActivityMonitor.logDeliveryFailure(
            connectionId: conversationId,
            reason: reason,
          );
        }
        break;
    }
  }

  void _logExchangeLifecycleEvent(
    Ai2AiExchangeObservation observation, {
    required String? peerRef,
  }) {
    final occurredAt = observation.routeReceipt?.recordedAtUtc ?? _nowUtc();
    switch (observation.lifecycleState) {
      case Ai2AiExchangeLifecycleState.peerReceived:
        _networkActivityMonitor.logEvent(
          AI2AINetworkActivityEvent(
            eventType: AI2AINetworkActivityEventType.peerReceived,
            occurredAt:
                observation.routeReceipt?.deliveredAtUtc ?? observation.observedAtUtc,
            connectionId: observation.conversationId,
            remoteNodeId: peerRef,
            payload: <String, Object?>{
              'ai2ai_exchange_id': observation.exchangeId,
            },
          ),
        );
        break;
      case Ai2AiExchangeLifecycleState.peerValidated:
        _networkActivityMonitor.logEvent(
          AI2AINetworkActivityEvent(
            eventType: AI2AINetworkActivityEventType.peerValidated,
            occurredAt: observation.observedAtUtc,
            connectionId: observation.conversationId,
            remoteNodeId: peerRef,
            payload: <String, Object?>{
              'ai2ai_exchange_id': observation.exchangeId,
            },
          ),
        );
        break;
      case Ai2AiExchangeLifecycleState.peerConsumed:
        _networkActivityMonitor.logEvent(
          AI2AINetworkActivityEvent(
            eventType: AI2AINetworkActivityEventType.peerConsumed,
            occurredAt: observation.routeReceipt?.readAtUtc ?? observation.observedAtUtc,
            connectionId: observation.conversationId,
            remoteNodeId: peerRef,
            payload: <String, Object?>{
              'ai2ai_exchange_id': observation.exchangeId,
            },
          ),
        );
        break;
      case Ai2AiExchangeLifecycleState.peerApplied:
        _networkActivityMonitor.logEvent(
          AI2AINetworkActivityEvent(
            eventType: AI2AINetworkActivityEventType.peerApplied,
            occurredAt: observation.routeReceipt?.learningAppliedAtUtc ??
                observation.observedAtUtc,
            connectionId: observation.conversationId,
            remoteNodeId: peerRef,
            payload: <String, Object?>{
              'ai2ai_exchange_id': observation.exchangeId,
            },
          ),
        );
        break;
      case Ai2AiExchangeLifecycleState.candidate:
      case Ai2AiExchangeLifecycleState.planned:
      case Ai2AiExchangeLifecycleState.committed:
      case Ai2AiExchangeLifecycleState.deferred:
      case Ai2AiExchangeLifecycleState.rejected:
      case Ai2AiExchangeLifecycleState.failed:
      case Ai2AiExchangeLifecycleState.quarantined:
        if (observation.outcomeContext['exchange_receipt_stage']?.toString() ==
            'peer_validated') {
          _networkActivityMonitor.logEvent(
            AI2AINetworkActivityEvent(
              eventType: AI2AINetworkActivityEventType.peerValidated,
              occurredAt: occurredAt,
              connectionId: observation.conversationId,
              remoteNodeId: peerRef,
              payload: <String, Object?>{
                'ai2ai_exchange_id': observation.exchangeId,
              },
            ),
          );
        }
        break;
    }
  }
}

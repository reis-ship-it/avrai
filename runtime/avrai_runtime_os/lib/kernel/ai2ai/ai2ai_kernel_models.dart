import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show
        KernelEventEnvelope,
        KernelContextBundle,
        TransportRouteReceipt,
        WhenKernelSnapshot,
        WhatRealityProjection,
        WhenRealityProjection,
        WhyRealityProjection;

enum Ai2AiPayloadClass {
  message,
  prekeyBundle,
  receipt,
  learningUpdate,
  control,
}

enum Ai2AiLifecycleState {
  candidate,
  planned,
  queued,
  sent,
  delivered,
  read,
  learningApplied,
  suppressed,
  rejected,
  failed,
}

enum Ai2AiHealthStatus { healthy, degraded, unavailable }

enum Ai2AiExchangeArtifactClass {
  probe,
  dnaDelta,
  learningDelta,
  memoryArtifact,
  prekey,
  receipt,
  control,
}

enum Ai2AiExchangeLifecycleState {
  candidate,
  planned,
  committed,
  deferred,
  peerReceived,
  peerValidated,
  peerConsumed,
  peerApplied,
  rejected,
  failed,
  quarantined,
}

enum Ai2AiExchangeDecision {
  exchangeNow,
  exchangeWhenIdle,
  exchangeWhenWifi,
  exchangeWhenWifiOrIdle,
  doNotExchange,
}

enum Ai2AiRendezvousCondition {
  idle,
  wifi,
  unmetered,
  charging,
  trustedNetwork,
}

class Ai2AiMessageCandidate {
  const Ai2AiMessageCandidate({
    required this.messageId,
    required this.conversationId,
    required this.peerId,
    required this.payloadClass,
    required this.envelope,
    required this.governanceBundle,
    this.routeReceipt,
    this.requiresLearningReceipt = false,
    this.context = const <String, dynamic>{},
  });

  final String messageId;
  final String conversationId;
  final String peerId;
  final Ai2AiPayloadClass payloadClass;
  final KernelEventEnvelope envelope;
  final KernelContextBundle governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final bool requiresLearningReceipt;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'message_id': messageId,
        'conversation_id': conversationId,
        'peer_id': peerId,
        'payload_class': payloadClass.name,
        'envelope': envelope.toJson(),
        'governance_bundle': governanceBundle.toJson(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'requires_learning_receipt': requiresLearningReceipt,
        'context': context,
      };
}

class Ai2AiLifecyclePlan {
  const Ai2AiLifecyclePlan({
    required this.planId,
    required this.messageId,
    required this.lifecycleState,
    required this.allowed,
    required this.plannedAtUtc,
    this.reason,
    this.routeReceipt,
    this.context = const <String, dynamic>{},
  });

  final String planId;
  final String messageId;
  final Ai2AiLifecycleState lifecycleState;
  final bool allowed;
  final DateTime plannedAtUtc;
  final String? reason;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'plan_id': planId,
        'message_id': messageId,
        'lifecycle_state': lifecycleState.name,
        'allowed': allowed,
        'planned_at_utc': plannedAtUtc.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'context': context,
      };

  factory Ai2AiLifecyclePlan.fromJson(Map<String, dynamic> json) {
    return Ai2AiLifecyclePlan(
      planId: json['plan_id'] as String? ?? '',
      messageId: json['message_id'] as String? ?? '',
      lifecycleState: Ai2AiLifecycleState.values.byName(
        json['lifecycle_state'] as String? ?? Ai2AiLifecycleState.failed.name,
      ),
      allowed: json['allowed'] as bool? ?? false,
      plannedAtUtc:
          DateTime.tryParse(json['planned_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      reason: json['reason'] as String?,
      routeReceipt: json['route_receipt'] is Map
          ? TransportRouteReceipt.fromJson(
              Map<String, dynamic>.from(json['route_receipt'] as Map),
            )
          : null,
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiCommitRequest {
  const Ai2AiCommitRequest({
    required this.attemptId,
    required this.plan,
    required this.envelope,
    this.commitContext = const <String, dynamic>{},
  });

  final String attemptId;
  final Ai2AiLifecyclePlan plan;
  final KernelEventEnvelope envelope;
  final Map<String, dynamic> commitContext;
}

class Ai2AiCommitReceipt {
  const Ai2AiCommitReceipt({
    required this.attemptId,
    required this.lifecycleState,
    required this.committedAtUtc,
    this.routeReceipt,
    this.context = const <String, dynamic>{},
  });

  final String attemptId;
  final Ai2AiLifecycleState lifecycleState;
  final DateTime committedAtUtc;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> context;
}

class Ai2AiObservation {
  const Ai2AiObservation({
    required this.observationId,
    required this.messageId,
    required this.conversationId,
    required this.lifecycleState,
    required this.observedAtUtc,
    required this.envelope,
    required this.governanceBundle,
    this.routeReceipt,
    this.outcomeContext = const <String, dynamic>{},
  });

  final String observationId;
  final String messageId;
  final String conversationId;
  final Ai2AiLifecycleState lifecycleState;
  final DateTime observedAtUtc;
  final KernelEventEnvelope envelope;
  final KernelContextBundle governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> outcomeContext;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'observation_id': observationId,
        'message_id': messageId,
        'conversation_id': conversationId,
        'lifecycle_state': lifecycleState.name,
        'observed_at_utc': observedAtUtc.toUtc().toIso8601String(),
        'envelope': envelope.toJson(),
        'governance_bundle': governanceBundle.toJson(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'outcome_context': outcomeContext,
      };
}

class Ai2AiObservationReceipt {
  const Ai2AiObservationReceipt({
    required this.observationId,
    required this.accepted,
    required this.lifecycleState,
    required this.recordedAtUtc,
    this.routeReceipt,
    this.learnableTuple = const <String, dynamic>{},
  });

  final String observationId;
  final bool accepted;
  final Ai2AiLifecycleState lifecycleState;
  final DateTime recordedAtUtc;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> learnableTuple;
}

class Ai2AiKernelSnapshot {
  const Ai2AiKernelSnapshot({
    required this.subjectId,
    required this.conversationId,
    required this.lifecycleState,
    required this.savedAtUtc,
    this.payloadClass,
    this.routeReceipt,
    this.diagnostics = const <String, dynamic>{},
  });

  final String subjectId;
  final String conversationId;
  final Ai2AiLifecycleState lifecycleState;
  final DateTime savedAtUtc;
  final Ai2AiPayloadClass? payloadClass;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'conversation_id': conversationId,
        'lifecycle_state': lifecycleState.name,
        'saved_at_utc': savedAtUtc.toUtc().toIso8601String(),
        if (payloadClass != null) 'payload_class': payloadClass!.name,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'diagnostics': diagnostics,
      };
}

class Ai2AiReplayRecord {
  const Ai2AiReplayRecord({
    required this.recordId,
    required this.subjectId,
    required this.occurredAtUtc,
    required this.lifecycleState,
    required this.summary,
    this.routeReceipt,
    this.payload = const <String, dynamic>{},
  });

  final String recordId;
  final String subjectId;
  final DateTime occurredAtUtc;
  final Ai2AiLifecycleState lifecycleState;
  final String summary;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> payload;
}

class Ai2AiRecoveryReport {
  const Ai2AiRecoveryReport({
    required this.subjectId,
    required this.restoredCount,
    required this.droppedCount,
    required this.recoveredAtUtc,
    required this.summary,
    this.diagnostics = const <String, dynamic>{},
  });

  final String subjectId;
  final int restoredCount;
  final int droppedCount;
  final DateTime recoveredAtUtc;
  final String summary;
  final Map<String, dynamic> diagnostics;
}

class Ai2AiRendezvousPolicy {
  const Ai2AiRendezvousPolicy({
    required this.requiredConditions,
    required this.expiresAtUtc,
    this.priority = 0.5,
    this.minimumValueScore = 0.0,
    this.requiresReprobeBeforeRelease = false,
    this.context = const <String, dynamic>{},
  });

  final Set<Ai2AiRendezvousCondition> requiredConditions;
  final DateTime expiresAtUtc;
  final double priority;
  final double minimumValueScore;
  final bool requiresReprobeBeforeRelease;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'required_conditions':
            requiredConditions.map((entry) => entry.name).toList(),
        'expires_at_utc': expiresAtUtc.toUtc().toIso8601String(),
        'priority': priority,
        'minimum_value_score': minimumValueScore,
        'requires_reprobe_before_release': requiresReprobeBeforeRelease,
        'context': context,
      };

  factory Ai2AiRendezvousPolicy.fromJson(Map<String, dynamic> json) {
    return Ai2AiRendezvousPolicy(
      requiredConditions:
          ((json['required_conditions'] as List?) ?? const <dynamic>[])
              .whereType<String>()
              .map(Ai2AiRendezvousCondition.values.byName)
              .toSet(),
      expiresAtUtc:
          DateTime.tryParse(json['expires_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      priority: (json['priority'] as num?)?.toDouble() ?? 0.5,
      minimumValueScore:
          (json['minimum_value_score'] as num?)?.toDouble() ?? 0.0,
      requiresReprobeBeforeRelease:
          json['requires_reprobe_before_release'] as bool? ?? false,
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiRendezvousTicket {
  const Ai2AiRendezvousTicket({
    required this.ticketId,
    required this.peerId,
    required this.decision,
    required this.policy,
    required this.createdAtUtc,
    required this.exchangeId,
    required this.artifactClass,
    this.context = const <String, dynamic>{},
  });

  final String ticketId;
  final String peerId;
  final Ai2AiExchangeDecision decision;
  final Ai2AiRendezvousPolicy policy;
  final DateTime createdAtUtc;
  final String exchangeId;
  final Ai2AiExchangeArtifactClass artifactClass;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ticket_id': ticketId,
        'peer_id': peerId,
        'decision': decision.name,
        'policy': policy.toJson(),
        'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
        'exchange_id': exchangeId,
        'artifact_class': artifactClass.name,
        'context': context,
      };

  factory Ai2AiRendezvousTicket.fromJson(Map<String, dynamic> json) {
    return Ai2AiRendezvousTicket(
      ticketId: json['ticket_id'] as String? ?? '',
      peerId: json['peer_id'] as String? ?? '',
      decision: Ai2AiExchangeDecision.values.byName(
        json['decision'] as String? ?? Ai2AiExchangeDecision.exchangeNow.name,
      ),
      policy: Ai2AiRendezvousPolicy.fromJson(
        Map<String, dynamic>.from(
          json['policy'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      createdAtUtc:
          DateTime.tryParse(json['created_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      exchangeId: json['exchange_id'] as String? ?? '',
      artifactClass: Ai2AiExchangeArtifactClass.values.byName(
        json['artifact_class'] as String? ??
            Ai2AiExchangeArtifactClass.memoryArtifact.name,
      ),
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiExchangeCandidate {
  const Ai2AiExchangeCandidate({
    required this.exchangeId,
    required this.conversationId,
    required this.peerId,
    required this.artifactClass,
    required this.envelope,
    required this.governanceBundle,
    this.routeReceipt,
    this.decision = Ai2AiExchangeDecision.exchangeNow,
    this.rendezvousPolicy,
    this.requiresApplyReceipt = false,
    this.context = const <String, dynamic>{},
  });

  final String exchangeId;
  final String conversationId;
  final String peerId;
  final Ai2AiExchangeArtifactClass artifactClass;
  final KernelEventEnvelope envelope;
  final KernelContextBundle governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final Ai2AiExchangeDecision decision;
  final Ai2AiRendezvousPolicy? rendezvousPolicy;
  final bool requiresApplyReceipt;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exchange_id': exchangeId,
        'conversation_id': conversationId,
        'peer_id': peerId,
        'artifact_class': artifactClass.name,
        'envelope': envelope.toJson(),
        'governance_bundle': governanceBundle.toJson(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'decision': decision.name,
        if (rendezvousPolicy != null)
          'rendezvous_policy': rendezvousPolicy!.toJson(),
        'requires_apply_receipt': requiresApplyReceipt,
        'context': context,
      };

  factory Ai2AiExchangeCandidate.fromJson(Map<String, dynamic> json) {
    return Ai2AiExchangeCandidate(
      exchangeId: json['exchange_id'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      peerId: json['peer_id'] as String? ?? '',
      artifactClass: Ai2AiExchangeArtifactClass.values.byName(
        json['artifact_class'] as String? ??
            Ai2AiExchangeArtifactClass.memoryArtifact.name,
      ),
      envelope: KernelEventEnvelope.fromJson(
        Map<String, dynamic>.from(
          json['envelope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      governanceBundle: KernelContextBundle.fromJson(
        Map<String, dynamic>.from(
          json['governance_bundle'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      routeReceipt: json['route_receipt'] is Map
          ? TransportRouteReceipt.fromJson(
              Map<String, dynamic>.from(json['route_receipt'] as Map),
            )
          : null,
      decision: Ai2AiExchangeDecision.values.byName(
        json['decision'] as String? ?? Ai2AiExchangeDecision.exchangeNow.name,
      ),
      rendezvousPolicy: json['rendezvous_policy'] is Map
          ? Ai2AiRendezvousPolicy.fromJson(
              Map<String, dynamic>.from(json['rendezvous_policy'] as Map),
            )
          : null,
      requiresApplyReceipt: json['requires_apply_receipt'] as bool? ?? false,
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiExchangePlan {
  const Ai2AiExchangePlan({
    required this.planId,
    required this.exchangeId,
    required this.lifecycleState,
    required this.allowed,
    required this.plannedAtUtc,
    required this.decision,
    this.reason,
    this.routeReceipt,
    this.rendezvousTicket,
    this.context = const <String, dynamic>{},
  });

  final String planId;
  final String exchangeId;
  final Ai2AiExchangeLifecycleState lifecycleState;
  final bool allowed;
  final DateTime plannedAtUtc;
  final Ai2AiExchangeDecision decision;
  final String? reason;
  final TransportRouteReceipt? routeReceipt;
  final Ai2AiRendezvousTicket? rendezvousTicket;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'plan_id': planId,
        'exchange_id': exchangeId,
        'lifecycle_state': lifecycleState.name,
        'allowed': allowed,
        'planned_at_utc': plannedAtUtc.toUtc().toIso8601String(),
        'decision': decision.name,
        if (reason != null) 'reason': reason,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        if (rendezvousTicket != null)
          'rendezvous_ticket': rendezvousTicket!.toJson(),
        'context': context,
      };

  factory Ai2AiExchangePlan.fromJson(Map<String, dynamic> json) {
    return Ai2AiExchangePlan(
      planId: json['plan_id'] as String? ?? '',
      exchangeId: json['exchange_id'] as String? ?? '',
      lifecycleState: Ai2AiExchangeLifecycleState.values.byName(
        json['lifecycle_state'] as String? ??
            Ai2AiExchangeLifecycleState.failed.name,
      ),
      allowed: json['allowed'] as bool? ?? false,
      plannedAtUtc:
          DateTime.tryParse(json['planned_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      decision: Ai2AiExchangeDecision.values.byName(
        json['decision'] as String? ?? Ai2AiExchangeDecision.exchangeNow.name,
      ),
      reason: json['reason'] as String?,
      routeReceipt: json['route_receipt'] is Map
          ? TransportRouteReceipt.fromJson(
              Map<String, dynamic>.from(json['route_receipt'] as Map),
            )
          : null,
      rendezvousTicket: json['rendezvous_ticket'] is Map
          ? Ai2AiRendezvousTicket.fromJson(
              Map<String, dynamic>.from(json['rendezvous_ticket'] as Map),
            )
          : null,
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiExchangeCommit {
  const Ai2AiExchangeCommit({
    required this.attemptId,
    required this.plan,
    required this.envelope,
    this.commitContext = const <String, dynamic>{},
  });

  final String attemptId;
  final Ai2AiExchangePlan plan;
  final KernelEventEnvelope envelope;
  final Map<String, dynamic> commitContext;
}

class Ai2AiExchangeObservation {
  const Ai2AiExchangeObservation({
    required this.observationId,
    required this.exchangeId,
    required this.conversationId,
    required this.lifecycleState,
    required this.observedAtUtc,
    required this.envelope,
    required this.governanceBundle,
    this.routeReceipt,
    this.outcomeContext = const <String, dynamic>{},
  });

  final String observationId;
  final String exchangeId;
  final String conversationId;
  final Ai2AiExchangeLifecycleState lifecycleState;
  final DateTime observedAtUtc;
  final KernelEventEnvelope envelope;
  final KernelContextBundle governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> outcomeContext;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'observation_id': observationId,
        'exchange_id': exchangeId,
        'conversation_id': conversationId,
        'lifecycle_state': lifecycleState.name,
        'observed_at_utc': observedAtUtc.toUtc().toIso8601String(),
        'envelope': envelope.toJson(),
        'governance_bundle': governanceBundle.toJson(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'outcome_context': outcomeContext,
      };
}

class Ai2AiExchangeReceipt {
  const Ai2AiExchangeReceipt({
    required this.recordId,
    required this.exchangeId,
    required this.accepted,
    required this.lifecycleState,
    required this.recordedAtUtc,
    this.routeReceipt,
    this.learnableTuple = const <String, dynamic>{},
    this.context = const <String, dynamic>{},
  });

  final String recordId;
  final String exchangeId;
  final bool accepted;
  final Ai2AiExchangeLifecycleState lifecycleState;
  final DateTime recordedAtUtc;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> learnableTuple;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'record_id': recordId,
        'exchange_id': exchangeId,
        'accepted': accepted,
        'lifecycle_state': lifecycleState.name,
        'recorded_at_utc': recordedAtUtc.toUtc().toIso8601String(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'learnable_tuple': learnableTuple,
        'context': context,
      };
}

class Ai2AiExchangeSnapshot {
  const Ai2AiExchangeSnapshot({
    required this.subjectId,
    required this.conversationId,
    required this.lifecycleState,
    required this.savedAtUtc,
    this.artifactClass,
    this.routeReceipt,
    this.rendezvousTicket,
    this.diagnostics = const <String, dynamic>{},
  });

  final String subjectId;
  final String conversationId;
  final Ai2AiExchangeLifecycleState lifecycleState;
  final DateTime savedAtUtc;
  final Ai2AiExchangeArtifactClass? artifactClass;
  final TransportRouteReceipt? routeReceipt;
  final Ai2AiRendezvousTicket? rendezvousTicket;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'conversation_id': conversationId,
        'lifecycle_state': lifecycleState.name,
        'saved_at_utc': savedAtUtc.toUtc().toIso8601String(),
        if (artifactClass != null) 'artifact_class': artifactClass!.name,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        if (rendezvousTicket != null)
          'rendezvous_ticket': rendezvousTicket!.toJson(),
        'diagnostics': diagnostics,
      };
}

extension Ai2AiPayloadClassExchangeMapping on Ai2AiPayloadClass {
  Ai2AiExchangeArtifactClass toExchangeArtifactClass() {
    switch (this) {
      case Ai2AiPayloadClass.message:
        return Ai2AiExchangeArtifactClass.memoryArtifact;
      case Ai2AiPayloadClass.prekeyBundle:
        return Ai2AiExchangeArtifactClass.prekey;
      case Ai2AiPayloadClass.receipt:
        return Ai2AiExchangeArtifactClass.receipt;
      case Ai2AiPayloadClass.learningUpdate:
        return Ai2AiExchangeArtifactClass.learningDelta;
      case Ai2AiPayloadClass.control:
        return Ai2AiExchangeArtifactClass.control;
    }
  }
}

extension Ai2AiExchangeArtifactClassLegacyMapping on Ai2AiExchangeArtifactClass {
  Ai2AiPayloadClass toLegacyPayloadClass() {
    switch (this) {
      case Ai2AiExchangeArtifactClass.probe:
      case Ai2AiExchangeArtifactClass.dnaDelta:
      case Ai2AiExchangeArtifactClass.memoryArtifact:
        return Ai2AiPayloadClass.message;
      case Ai2AiExchangeArtifactClass.learningDelta:
        return Ai2AiPayloadClass.learningUpdate;
      case Ai2AiExchangeArtifactClass.prekey:
        return Ai2AiPayloadClass.prekeyBundle;
      case Ai2AiExchangeArtifactClass.receipt:
        return Ai2AiPayloadClass.receipt;
      case Ai2AiExchangeArtifactClass.control:
        return Ai2AiPayloadClass.control;
    }
  }
}

extension Ai2AiLifecycleStateExchangeMapping on Ai2AiLifecycleState {
  Ai2AiExchangeLifecycleState toExchangeLifecycleState() {
    switch (this) {
      case Ai2AiLifecycleState.candidate:
        return Ai2AiExchangeLifecycleState.candidate;
      case Ai2AiLifecycleState.planned:
        return Ai2AiExchangeLifecycleState.planned;
      case Ai2AiLifecycleState.queued:
        return Ai2AiExchangeLifecycleState.deferred;
      case Ai2AiLifecycleState.sent:
        return Ai2AiExchangeLifecycleState.committed;
      case Ai2AiLifecycleState.delivered:
        return Ai2AiExchangeLifecycleState.peerReceived;
      case Ai2AiLifecycleState.read:
        return Ai2AiExchangeLifecycleState.peerConsumed;
      case Ai2AiLifecycleState.learningApplied:
        return Ai2AiExchangeLifecycleState.peerApplied;
      case Ai2AiLifecycleState.suppressed:
      case Ai2AiLifecycleState.rejected:
        return Ai2AiExchangeLifecycleState.rejected;
      case Ai2AiLifecycleState.failed:
        return Ai2AiExchangeLifecycleState.failed;
    }
  }
}

extension Ai2AiExchangeLifecycleStateLegacyMapping
    on Ai2AiExchangeLifecycleState {
  Ai2AiLifecycleState toLegacyLifecycleState() {
    switch (this) {
      case Ai2AiExchangeLifecycleState.candidate:
        return Ai2AiLifecycleState.candidate;
      case Ai2AiExchangeLifecycleState.planned:
        return Ai2AiLifecycleState.planned;
      case Ai2AiExchangeLifecycleState.committed:
        return Ai2AiLifecycleState.sent;
      case Ai2AiExchangeLifecycleState.deferred:
        return Ai2AiLifecycleState.queued;
      case Ai2AiExchangeLifecycleState.peerReceived:
        return Ai2AiLifecycleState.delivered;
      case Ai2AiExchangeLifecycleState.peerValidated:
        return Ai2AiLifecycleState.delivered;
      case Ai2AiExchangeLifecycleState.peerConsumed:
        return Ai2AiLifecycleState.read;
      case Ai2AiExchangeLifecycleState.peerApplied:
        return Ai2AiLifecycleState.learningApplied;
      case Ai2AiExchangeLifecycleState.rejected:
        return Ai2AiLifecycleState.rejected;
      case Ai2AiExchangeLifecycleState.failed:
      case Ai2AiExchangeLifecycleState.quarantined:
        return Ai2AiLifecycleState.failed;
    }
  }
}

extension Ai2AiLegacyCandidateExchangeAdapter on Ai2AiMessageCandidate {
  Ai2AiExchangeCandidate toExchangeCandidate({
    Ai2AiExchangeDecision decision = Ai2AiExchangeDecision.exchangeNow,
    Ai2AiRendezvousPolicy? rendezvousPolicy,
  }) {
    return Ai2AiExchangeCandidate(
      exchangeId: messageId,
      conversationId: conversationId,
      peerId: peerId,
      artifactClass: payloadClass.toExchangeArtifactClass(),
      envelope: envelope,
      governanceBundle: governanceBundle,
      routeReceipt: routeReceipt,
      decision: decision,
      rendezvousPolicy: rendezvousPolicy,
      requiresApplyReceipt: requiresLearningReceipt,
      context: context,
    );
  }
}

extension Ai2AiExchangeCandidateLegacyAdapter on Ai2AiExchangeCandidate {
  Ai2AiMessageCandidate toLegacyCandidate() {
    return Ai2AiMessageCandidate(
      messageId: exchangeId,
      conversationId: conversationId,
      peerId: peerId,
      payloadClass: artifactClass.toLegacyPayloadClass(),
      envelope: envelope,
      governanceBundle: governanceBundle,
      routeReceipt: routeReceipt,
      requiresLearningReceipt: requiresApplyReceipt,
      context: <String, dynamic>{
        ...context,
        'exchange_decision': decision.name,
        if (rendezvousPolicy != null)
          'rendezvous_policy': rendezvousPolicy!.toJson(),
      },
    );
  }
}

extension Ai2AiLegacyPlanExchangeAdapter on Ai2AiLifecyclePlan {
  Ai2AiExchangePlan toExchangePlan({
    Ai2AiExchangeDecision? decision,
    Ai2AiRendezvousTicket? rendezvousTicket,
  }) {
    final contextDecision = context['exchange_decision']?.toString();
    return Ai2AiExchangePlan(
      planId: planId,
      exchangeId: messageId,
      lifecycleState: lifecycleState.toExchangeLifecycleState(),
      allowed: allowed,
      plannedAtUtc: plannedAtUtc,
      decision: decision ??
          (contextDecision == null
              ? Ai2AiExchangeDecision.exchangeNow
              : Ai2AiExchangeDecision.values.byName(contextDecision)),
      reason: reason,
      routeReceipt: routeReceipt,
      rendezvousTicket: rendezvousTicket,
      context: context,
    );
  }
}

extension Ai2AiExchangePlanLegacyAdapter on Ai2AiExchangePlan {
  Ai2AiLifecyclePlan toLegacyLifecyclePlan() {
    return Ai2AiLifecyclePlan(
      planId: planId,
      messageId: exchangeId,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      allowed: allowed,
      plannedAtUtc: plannedAtUtc,
      reason: reason,
      routeReceipt: routeReceipt,
      context: <String, dynamic>{
        ...context,
        'exchange_decision': decision.name,
        if (rendezvousTicket != null)
          'rendezvous_ticket': rendezvousTicket!.toJson(),
      },
    );
  }
}

extension Ai2AiLegacyCommitExchangeAdapter on Ai2AiCommitRequest {
  Ai2AiExchangeCommit toExchangeCommit({
    Ai2AiExchangeDecision? decision,
  }) {
    return Ai2AiExchangeCommit(
      attemptId: attemptId,
      plan: plan.toExchangePlan(decision: decision),
      envelope: envelope,
      commitContext: commitContext,
    );
  }
}

extension Ai2AiExchangeCommitLegacyAdapter on Ai2AiExchangeCommit {
  Ai2AiCommitRequest toLegacyCommitRequest() {
    return Ai2AiCommitRequest(
      attemptId: attemptId,
      plan: plan.toLegacyLifecyclePlan(),
      envelope: envelope,
      commitContext: commitContext,
    );
  }
}

extension Ai2AiLegacyObservationExchangeAdapter on Ai2AiObservation {
  Ai2AiExchangeObservation toExchangeObservation() {
    return Ai2AiExchangeObservation(
      observationId: observationId,
      exchangeId: messageId,
      conversationId: conversationId,
      lifecycleState: lifecycleState.toExchangeLifecycleState(),
      observedAtUtc: observedAtUtc,
      envelope: envelope,
      governanceBundle: governanceBundle,
      routeReceipt: routeReceipt,
      outcomeContext: outcomeContext,
    );
  }
}

extension Ai2AiExchangeObservationLegacyAdapter on Ai2AiExchangeObservation {
  Ai2AiObservation toLegacyObservation() {
    return Ai2AiObservation(
      observationId: observationId,
      messageId: exchangeId,
      conversationId: conversationId,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      observedAtUtc: observedAtUtc,
      envelope: envelope,
      governanceBundle: governanceBundle,
      routeReceipt: routeReceipt,
      outcomeContext: outcomeContext,
    );
  }
}

extension Ai2AiLegacySnapshotExchangeAdapter on Ai2AiKernelSnapshot {
  Ai2AiExchangeSnapshot toExchangeSnapshot() {
    return Ai2AiExchangeSnapshot(
      subjectId: subjectId,
      conversationId: conversationId,
      lifecycleState: lifecycleState.toExchangeLifecycleState(),
      savedAtUtc: savedAtUtc,
      artifactClass: payloadClass?.toExchangeArtifactClass(),
      routeReceipt: routeReceipt,
      diagnostics: diagnostics,
    );
  }
}

extension Ai2AiExchangeSnapshotLegacyAdapter on Ai2AiExchangeSnapshot {
  Ai2AiKernelSnapshot toLegacySnapshot() {
    return Ai2AiKernelSnapshot(
      subjectId: subjectId,
      conversationId: conversationId,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      savedAtUtc: savedAtUtc,
      payloadClass: artifactClass?.toLegacyPayloadClass(),
      routeReceipt: routeReceipt,
      diagnostics: diagnostics,
    );
  }
}

extension Ai2AiLegacyCommitReceiptExchangeAdapter on Ai2AiCommitReceipt {
  Ai2AiExchangeReceipt toExchangeReceipt({
    required String exchangeId,
  }) {
    return Ai2AiExchangeReceipt(
      recordId: attemptId,
      exchangeId: exchangeId,
      accepted: lifecycleState != Ai2AiLifecycleState.rejected,
      lifecycleState: lifecycleState.toExchangeLifecycleState(),
      recordedAtUtc: committedAtUtc,
      routeReceipt: routeReceipt,
      context: context,
    );
  }
}

extension Ai2AiLegacyObservationReceiptExchangeAdapter
    on Ai2AiObservationReceipt {
  Ai2AiExchangeReceipt toExchangeReceipt({
    required String exchangeId,
  }) {
    return Ai2AiExchangeReceipt(
      recordId: observationId,
      exchangeId: exchangeId,
      accepted: accepted,
      lifecycleState: lifecycleState.toExchangeLifecycleState(),
      recordedAtUtc: recordedAtUtc,
      routeReceipt: routeReceipt,
      learnableTuple: learnableTuple,
    );
  }
}

extension Ai2AiExchangeReceiptLegacyAdapter on Ai2AiExchangeReceipt {
  Ai2AiCommitReceipt toLegacyCommitReceipt() {
    return Ai2AiCommitReceipt(
      attemptId: recordId,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      committedAtUtc: recordedAtUtc,
      routeReceipt: routeReceipt,
      context: context,
    );
  }

  Ai2AiObservationReceipt toLegacyObservationReceipt() {
    return Ai2AiObservationReceipt(
      observationId: recordId,
      accepted: accepted,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      recordedAtUtc: recordedAtUtc,
      routeReceipt: routeReceipt,
      learnableTuple: learnableTuple,
    );
  }
}

class Ai2AiProjectionRequest {
  const Ai2AiProjectionRequest({
    required this.subjectId,
    this.envelope,
    this.whenSnapshot,
    this.snapshot,
    this.context = const <String, dynamic>{},
  });

  final String subjectId;
  final KernelEventEnvelope? envelope;
  final WhenKernelSnapshot? whenSnapshot;
  final Ai2AiKernelSnapshot? snapshot;
  final Map<String, dynamic> context;
}

class Ai2AiKernelHealthSnapshot {
  const Ai2AiKernelHealthSnapshot({
    required this.kernelId,
    required this.status,
    required this.nativeBacked,
    required this.headlessReady,
    required this.summary,
    this.diagnostics = const <String, dynamic>{},
  });

  final String kernelId;
  final Ai2AiHealthStatus status;
  final bool nativeBacked;
  final bool headlessReady;
  final String summary;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kernel_id': kernelId,
        'status': status.name,
        'native_backed': nativeBacked,
        'headless_ready': headlessReady,
        'summary': summary,
        'diagnostics': diagnostics,
      };

  factory Ai2AiKernelHealthSnapshot.fromJson(Map<String, dynamic> json) {
    return Ai2AiKernelHealthSnapshot(
      kernelId: json['kernel_id'] as String? ?? 'ai2ai_runtime_governance',
      status: Ai2AiHealthStatus.values.byName(
        json['status'] as String? ?? Ai2AiHealthStatus.unavailable.name,
      ),
      nativeBacked: json['native_backed'] as bool? ?? false,
      headlessReady: json['headless_ready'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      diagnostics: Map<String, dynamic>.from(
        json['diagnostics'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiSimulationRequest {
  const Ai2AiSimulationRequest({
    required this.simulationId,
    required this.runContext,
    this.seedCandidates = const <Ai2AiMessageCandidate>[],
    this.topology = const <String, dynamic>{},
    this.constraints = const <String, dynamic>{},
  });

  final String simulationId;
  final MonteCarloRunContext runContext;
  final List<Ai2AiMessageCandidate> seedCandidates;
  final Map<String, dynamic> topology;
  final Map<String, dynamic> constraints;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'simulation_id': simulationId,
        'run_context': runContext.toJson(),
        'seed_candidates':
            seedCandidates.map((entry) => entry.toJson()).toList(),
        'topology': topology,
        'constraints': constraints,
      };

  factory Ai2AiSimulationRequest.fromJson(Map<String, dynamic> json) {
    return Ai2AiSimulationRequest(
      simulationId: json['simulation_id'] as String? ?? '',
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(
          json['run_context'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      seedCandidates: (json['seed_candidates'] as List? ?? const <dynamic>[])
          .map((entry) => Ai2AiMessageCandidate(
                messageId: (entry as Map)['message_id'] as String? ??
                    'unknown_message',
                conversationId: entry['conversation_id'] as String? ??
                    'unknown_conversation',
                peerId: entry['peer_id'] as String? ?? 'unknown_peer',
                payloadClass: Ai2AiPayloadClass.values.byName(
                  entry['payload_class'] as String? ??
                      Ai2AiPayloadClass.message.name,
                ),
                envelope: KernelEventEnvelope.fromJson(
                  Map<String, dynamic>.from(
                    entry['envelope'] as Map? ?? const <String, dynamic>{},
                  ),
                ),
                governanceBundle: KernelContextBundle.fromJson(
                  Map<String, dynamic>.from(
                    entry['governance_bundle'] as Map? ??
                        const <String, dynamic>{},
                  ),
                ),
                routeReceipt: entry['route_receipt'] is Map
                    ? TransportRouteReceipt.fromJson(
                        Map<String, dynamic>.from(
                          entry['route_receipt'] as Map,
                        ),
                      )
                    : null,
                requiresLearningReceipt:
                    entry['requires_learning_receipt'] as bool? ?? false,
                context: Map<String, dynamic>.from(
                  entry['context'] as Map? ?? const <String, dynamic>{},
                ),
              ))
          .toList(),
      topology: Map<String, dynamic>.from(
        json['topology'] as Map? ?? const <String, dynamic>{},
      ),
      constraints: Map<String, dynamic>.from(
        json['constraints'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class Ai2AiSimulationResult {
  const Ai2AiSimulationResult({
    required this.simulationId,
    required this.generatedReceipts,
    required this.acceptedEvents,
    required this.droppedEvents,
    this.telemetry = const <String, dynamic>{},
  });

  final String simulationId;
  final List<TransportRouteReceipt> generatedReceipts;
  final int acceptedEvents;
  final int droppedEvents;
  final Map<String, dynamic> telemetry;
}

class Ai2AiRealityProjectionBundle {
  const Ai2AiRealityProjectionBundle({
    required this.what,
    required this.when,
    required this.why,
  });

  final WhatRealityProjection what;
  final WhenRealityProjection when;
  final WhyRealityProjection why;

  List<dynamic> asList() => <dynamic>[what, when, why];
}

Ai2AiRealityProjectionBundle projectAi2AiSnapshotForRealityModel(
  Ai2AiKernelSnapshot? snapshot, {
  KernelEventEnvelope? envelope,
  WhenKernelSnapshot? whenSnapshot,
  Map<String, dynamic> context = const <String, dynamic>{},
}) {
  final projectedAtUtc = whenSnapshot?.observedAt.toUtc() ??
      envelope?.occurredAtUtc.toUtc() ??
      snapshot?.savedAtUtc.toUtc();
  final lifecycleState = snapshot?.lifecycleState.name ?? 'unknown';
  final conversationId = snapshot?.conversationId ?? 'unknown_conversation';
  final basePayload = <String, dynamic>{
    'source_kernel': 'ai2ai_runtime_governance',
    'projection_surfaces': const <String>['what', 'when', 'why'],
    if (projectedAtUtc != null)
      'projected_at_utc': projectedAtUtc.toIso8601String(),
    'projection_context': context,
    if (whenSnapshot != null) 'when_snapshot': whenSnapshot.toJson(),
    ...?snapshot?.toJson(),
  };

  return Ai2AiRealityProjectionBundle(
    what: WhatRealityProjection(
      summary: 'AI2AI state for $conversationId',
      confidence: snapshot == null ? 0.0 : 1.0,
      features: <String, dynamic>{
        'conversation_id': conversationId,
        'payload_class': snapshot?.payloadClass?.name,
        'lifecycle_state': lifecycleState,
      },
      payload: <String, dynamic>{
        ...basePayload,
        'projection_surface': 'what',
      },
    ),
    when: WhenRealityProjection(
      summary:
          'AI2AI lifecycle $lifecycleState at ${projectedAtUtc?.toIso8601String() ?? 'unknown_time'}',
      confidence:
          whenSnapshot?.temporalConfidence ?? (snapshot == null ? 0.0 : 1.0),
      features: <String, dynamic>{
        'observed_at_utc': projectedAtUtc?.toIso8601String(),
        'lifecycle_state': lifecycleState,
        'payload_class': snapshot?.payloadClass?.name,
        'recency_bucket': whenSnapshot?.recencyBucket,
        'freshness': whenSnapshot?.freshness,
        'timing_conflict_flags':
            whenSnapshot?.timingConflictFlags ?? const <String>[],
      },
      payload: <String, dynamic>{
        ...basePayload,
        'projection_surface': 'when',
      },
    ),
    why: WhyRealityProjection(
      summary: 'AI2AI intent and delivery rationale for $conversationId',
      confidence: snapshot == null ? 0.0 : 1.0,
      features: <String, dynamic>{
        'lifecycle_state': lifecycleState,
        'learning_required':
            context['requires_learning_receipt'] as bool? ?? false,
        'failure_reason': snapshot?.diagnostics['failure_reason'],
      },
      payload: <String, dynamic>{
        ...basePayload,
        'projection_surface': 'why',
      },
    ),
  );
}

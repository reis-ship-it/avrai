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

enum MeshLifecycleState {
  candidate,
  planned,
  queued,
  custodyAccepted,
  forwarded,
  delivered,
  expired,
  quarantined,
  failed,
}

enum MeshHealthStatus { healthy, degraded, unavailable }

enum MeshTransportLifecycleState {
  planned,
  queued,
  custodyAccepted,
  forwarded,
  transportDelivered,
  failed,
  quarantined,
}

class MeshRoutePlanningRequest {
  const MeshRoutePlanningRequest({
    required this.planningId,
    required this.destinationId,
    required this.envelope,
    required this.governanceBundle,
    this.routeReceipt,
    this.storeCarryForwardAllowed = true,
    this.runtimeContext = const <String, dynamic>{},
    this.policyContext = const <String, dynamic>{},
    this.runContext,
  });

  final String planningId;
  final String destinationId;
  final KernelEventEnvelope envelope;
  final KernelContextBundle governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final bool storeCarryForwardAllowed;
  final Map<String, dynamic> runtimeContext;
  final Map<String, dynamic> policyContext;
  final MonteCarloRunContext? runContext;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'planning_id': planningId,
        'destination_id': destinationId,
        'envelope': envelope.toJson(),
        'governance_bundle': governanceBundle.toJson(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'store_carry_forward_allowed': storeCarryForwardAllowed,
        'runtime_context': runtimeContext,
        'policy_context': policyContext,
        if (runContext != null) 'run_context': runContext!.toJson(),
      };
}

class MeshRoutePlan {
  const MeshRoutePlan({
    required this.planningId,
    required this.destinationId,
    required this.plannedAtUtc,
    required this.lifecycleState,
    required this.allowed,
    this.queued = false,
    this.reason,
    this.routeReceipt,
    this.context = const <String, dynamic>{},
  });

  final String planningId;
  final String destinationId;
  final DateTime plannedAtUtc;
  final MeshLifecycleState lifecycleState;
  final bool allowed;
  final bool queued;
  final String? reason;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'planning_id': planningId,
        'destination_id': destinationId,
        'planned_at_utc': plannedAtUtc.toUtc().toIso8601String(),
        'lifecycle_state': lifecycleState.name,
        'allowed': allowed,
        'queued': queued,
        if (reason != null) 'reason': reason,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'context': context,
      };

  factory MeshRoutePlan.fromJson(Map<String, dynamic> json) {
    return MeshRoutePlan(
      planningId: json['planning_id'] as String? ?? '',
      destinationId: json['destination_id'] as String? ?? '',
      plannedAtUtc:
          DateTime.tryParse(json['planned_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lifecycleState: MeshLifecycleState.values.byName(
        json['lifecycle_state'] as String? ?? MeshLifecycleState.failed.name,
      ),
      allowed: json['allowed'] as bool? ?? false,
      queued: json['queued'] as bool? ?? false,
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

class MeshCommitRequest {
  const MeshCommitRequest({
    required this.attemptId,
    required this.plan,
    required this.envelope,
    this.commitContext = const <String, dynamic>{},
  });

  final String attemptId;
  final MeshRoutePlan plan;
  final KernelEventEnvelope envelope;
  final Map<String, dynamic> commitContext;
}

class MeshCommitReceipt {
  const MeshCommitReceipt({
    required this.attemptId,
    required this.lifecycleState,
    required this.committedAtUtc,
    this.routeReceipt,
    this.context = const <String, dynamic>{},
  });

  final String attemptId;
  final MeshLifecycleState lifecycleState;
  final DateTime committedAtUtc;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> context;
}

class MeshObservation {
  const MeshObservation({
    required this.observationId,
    required this.subjectId,
    required this.lifecycleState,
    required this.observedAtUtc,
    required this.envelope,
    required this.governanceBundle,
    this.routeReceipt,
    this.outcomeContext = const <String, dynamic>{},
  });

  final String observationId;
  final String subjectId;
  final MeshLifecycleState lifecycleState;
  final DateTime observedAtUtc;
  final KernelEventEnvelope envelope;
  final KernelContextBundle governanceBundle;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> outcomeContext;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'observation_id': observationId,
        'subject_id': subjectId,
        'lifecycle_state': lifecycleState.name,
        'observed_at_utc': observedAtUtc.toUtc().toIso8601String(),
        'envelope': envelope.toJson(),
        'governance_bundle': governanceBundle.toJson(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'outcome_context': outcomeContext,
      };
}

class MeshObservationReceipt {
  const MeshObservationReceipt({
    required this.observationId,
    required this.accepted,
    required this.lifecycleState,
    required this.recordedAtUtc,
    this.routeReceipt,
    this.learnableTuple = const <String, dynamic>{},
  });

  final String observationId;
  final bool accepted;
  final MeshLifecycleState lifecycleState;
  final DateTime recordedAtUtc;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> learnableTuple;
}

class MeshKernelSnapshot {
  const MeshKernelSnapshot({
    required this.subjectId,
    required this.destinationId,
    required this.lifecycleState,
    required this.savedAtUtc,
    this.queueDepth = 0,
    this.routeReceipt,
    this.diagnostics = const <String, dynamic>{},
  });

  final String subjectId;
  final String destinationId;
  final MeshLifecycleState lifecycleState;
  final DateTime savedAtUtc;
  final int queueDepth;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'destination_id': destinationId,
        'lifecycle_state': lifecycleState.name,
        'saved_at_utc': savedAtUtc.toUtc().toIso8601String(),
        'queue_depth': queueDepth,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'diagnostics': diagnostics,
      };
}

class MeshReplayRecord {
  const MeshReplayRecord({
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
  final MeshLifecycleState lifecycleState;
  final String summary;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> payload;
}

class MeshRecoveryReport {
  const MeshRecoveryReport({
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

class MeshTransportPlan {
  const MeshTransportPlan({
    required this.planningId,
    required this.destinationId,
    required this.plannedAtUtc,
    required this.lifecycleState,
    required this.allowed,
    this.queued = false,
    this.reason,
    this.routeReceipt,
    this.context = const <String, dynamic>{},
  });

  final String planningId;
  final String destinationId;
  final DateTime plannedAtUtc;
  final MeshTransportLifecycleState lifecycleState;
  final bool allowed;
  final bool queued;
  final String? reason;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'planning_id': planningId,
        'destination_id': destinationId,
        'planned_at_utc': plannedAtUtc.toUtc().toIso8601String(),
        'lifecycle_state': lifecycleState.name,
        'allowed': allowed,
        'queued': queued,
        if (reason != null) 'reason': reason,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'context': context,
      };
}

class MeshTransportCommit {
  const MeshTransportCommit({
    required this.attemptId,
    required this.plan,
    required this.envelope,
    this.commitContext = const <String, dynamic>{},
  });

  final String attemptId;
  final MeshTransportPlan plan;
  final KernelEventEnvelope envelope;
  final Map<String, dynamic> commitContext;
}

class MeshTransportReceipt {
  const MeshTransportReceipt({
    required this.recordId,
    required this.subjectId,
    required this.lifecycleState,
    required this.recordedAtUtc,
    this.accepted = true,
    this.routeReceipt,
    this.learnableTuple = const <String, dynamic>{},
    this.context = const <String, dynamic>{},
  });

  final String recordId;
  final String subjectId;
  final bool accepted;
  final MeshTransportLifecycleState lifecycleState;
  final DateTime recordedAtUtc;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> learnableTuple;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'record_id': recordId,
        'subject_id': subjectId,
        'accepted': accepted,
        'lifecycle_state': lifecycleState.name,
        'recorded_at_utc': recordedAtUtc.toUtc().toIso8601String(),
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'learnable_tuple': learnableTuple,
        'context': context,
      };
}

class MeshTransportSnapshot {
  const MeshTransportSnapshot({
    required this.subjectId,
    required this.destinationId,
    required this.lifecycleState,
    required this.savedAtUtc,
    this.queueDepth = 0,
    this.routeReceipt,
    this.diagnostics = const <String, dynamic>{},
  });

  final String subjectId;
  final String destinationId;
  final MeshTransportLifecycleState lifecycleState;
  final DateTime savedAtUtc;
  final int queueDepth;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject_id': subjectId,
        'destination_id': destinationId,
        'lifecycle_state': lifecycleState.name,
        'saved_at_utc': savedAtUtc.toUtc().toIso8601String(),
        'queue_depth': queueDepth,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'diagnostics': diagnostics,
      };
}

extension MeshLifecycleTransportMapping on MeshLifecycleState {
  MeshTransportLifecycleState toTransportLifecycleState() {
    switch (this) {
      case MeshLifecycleState.candidate:
      case MeshLifecycleState.planned:
        return MeshTransportLifecycleState.planned;
      case MeshLifecycleState.queued:
        return MeshTransportLifecycleState.queued;
      case MeshLifecycleState.custodyAccepted:
        return MeshTransportLifecycleState.custodyAccepted;
      case MeshLifecycleState.forwarded:
        return MeshTransportLifecycleState.forwarded;
      case MeshLifecycleState.delivered:
        return MeshTransportLifecycleState.transportDelivered;
      case MeshLifecycleState.quarantined:
        return MeshTransportLifecycleState.quarantined;
      case MeshLifecycleState.expired:
      case MeshLifecycleState.failed:
        return MeshTransportLifecycleState.failed;
    }
  }
}

extension MeshTransportLifecycleLegacyMapping on MeshTransportLifecycleState {
  MeshLifecycleState toLegacyLifecycleState() {
    switch (this) {
      case MeshTransportLifecycleState.planned:
        return MeshLifecycleState.planned;
      case MeshTransportLifecycleState.queued:
        return MeshLifecycleState.queued;
      case MeshTransportLifecycleState.custodyAccepted:
        return MeshLifecycleState.custodyAccepted;
      case MeshTransportLifecycleState.forwarded:
        return MeshLifecycleState.forwarded;
      case MeshTransportLifecycleState.transportDelivered:
        return MeshLifecycleState.delivered;
      case MeshTransportLifecycleState.failed:
        return MeshLifecycleState.failed;
      case MeshTransportLifecycleState.quarantined:
        return MeshLifecycleState.quarantined;
    }
  }
}

extension MeshLegacyPlanTransportAdapter on MeshRoutePlan {
  MeshTransportPlan toTransportPlan() {
    return MeshTransportPlan(
      planningId: planningId,
      destinationId: destinationId,
      plannedAtUtc: plannedAtUtc,
      lifecycleState: lifecycleState.toTransportLifecycleState(),
      allowed: allowed,
      queued: queued,
      reason: reason,
      routeReceipt: routeReceipt,
      context: context,
    );
  }
}

extension MeshTransportPlanLegacyAdapter on MeshTransportPlan {
  MeshRoutePlan toLegacyRoutePlan() {
    return MeshRoutePlan(
      planningId: planningId,
      destinationId: destinationId,
      plannedAtUtc: plannedAtUtc,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      allowed: allowed,
      queued: queued,
      reason: reason,
      routeReceipt: routeReceipt,
      context: context,
    );
  }
}

extension MeshLegacyCommitTransportAdapter on MeshCommitRequest {
  MeshTransportCommit toTransportCommit() {
    return MeshTransportCommit(
      attemptId: attemptId,
      plan: plan.toTransportPlan(),
      envelope: envelope,
      commitContext: commitContext,
    );
  }
}

extension MeshTransportCommitLegacyAdapter on MeshTransportCommit {
  MeshCommitRequest toLegacyCommitRequest() {
    return MeshCommitRequest(
      attemptId: attemptId,
      plan: plan.toLegacyRoutePlan(),
      envelope: envelope,
      commitContext: commitContext,
    );
  }
}

extension MeshLegacyObservationTransportAdapter on MeshObservation {
  MeshTransportReceipt toTransportReceipt() {
    return MeshTransportReceipt(
      recordId: observationId,
      subjectId: subjectId,
      accepted: true,
      lifecycleState: lifecycleState.toTransportLifecycleState(),
      recordedAtUtc: observedAtUtc,
      routeReceipt: routeReceipt,
      learnableTuple: outcomeContext,
    );
  }
}

extension MeshLegacyCommitReceiptTransportAdapter on MeshCommitReceipt {
  MeshTransportReceipt toTransportReceipt({
    required String subjectId,
  }) {
    return MeshTransportReceipt(
      recordId: attemptId,
      subjectId: subjectId,
      lifecycleState: lifecycleState.toTransportLifecycleState(),
      recordedAtUtc: committedAtUtc,
      routeReceipt: routeReceipt,
      context: context,
    );
  }
}

extension MeshLegacyObservationReceiptTransportAdapter on MeshObservationReceipt {
  MeshTransportReceipt toTransportReceipt({
    required String subjectId,
  }) {
    return MeshTransportReceipt(
      recordId: observationId,
      subjectId: subjectId,
      accepted: accepted,
      lifecycleState: lifecycleState.toTransportLifecycleState(),
      recordedAtUtc: recordedAtUtc,
      routeReceipt: routeReceipt,
      learnableTuple: learnableTuple,
    );
  }
}

extension MeshTransportReceiptLegacyAdapter on MeshTransportReceipt {
  MeshCommitReceipt toLegacyCommitReceipt() {
    return MeshCommitReceipt(
      attemptId: recordId,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      committedAtUtc: recordedAtUtc,
      routeReceipt: routeReceipt,
      context: context,
    );
  }

  MeshObservationReceipt toLegacyObservationReceipt() {
    return MeshObservationReceipt(
      observationId: recordId,
      accepted: accepted,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      recordedAtUtc: recordedAtUtc,
      routeReceipt: routeReceipt,
      learnableTuple: learnableTuple,
    );
  }
}

extension MeshLegacySnapshotTransportAdapter on MeshKernelSnapshot {
  MeshTransportSnapshot toTransportSnapshot() {
    return MeshTransportSnapshot(
      subjectId: subjectId,
      destinationId: destinationId,
      lifecycleState: lifecycleState.toTransportLifecycleState(),
      savedAtUtc: savedAtUtc,
      queueDepth: queueDepth,
      routeReceipt: routeReceipt,
      diagnostics: diagnostics,
    );
  }
}

extension MeshTransportSnapshotLegacyAdapter on MeshTransportSnapshot {
  MeshKernelSnapshot toLegacySnapshot() {
    return MeshKernelSnapshot(
      subjectId: subjectId,
      destinationId: destinationId,
      lifecycleState: lifecycleState.toLegacyLifecycleState(),
      savedAtUtc: savedAtUtc,
      queueDepth: queueDepth,
      routeReceipt: routeReceipt,
      diagnostics: diagnostics,
    );
  }
}

class MeshProjectionRequest {
  const MeshProjectionRequest({
    required this.subjectId,
    this.envelope,
    this.whenSnapshot,
    this.snapshot,
    this.context = const <String, dynamic>{},
  });

  final String subjectId;
  final KernelEventEnvelope? envelope;
  final WhenKernelSnapshot? whenSnapshot;
  final MeshKernelSnapshot? snapshot;
  final Map<String, dynamic> context;
}

class MeshKernelHealthSnapshot {
  const MeshKernelHealthSnapshot({
    required this.kernelId,
    required this.status,
    required this.nativeBacked,
    required this.headlessReady,
    required this.summary,
    this.diagnostics = const <String, dynamic>{},
  });

  final String kernelId;
  final MeshHealthStatus status;
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

  factory MeshKernelHealthSnapshot.fromJson(Map<String, dynamic> json) {
    return MeshKernelHealthSnapshot(
      kernelId: json['kernel_id'] as String? ?? 'mesh_runtime_governance',
      status: MeshHealthStatus.values.byName(
        json['status'] as String? ?? MeshHealthStatus.unavailable.name,
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

class MeshSimulationRequest {
  const MeshSimulationRequest({
    required this.simulationId,
    required this.runContext,
    this.seedEnvelopes = const <KernelEventEnvelope>[],
    this.topology = const <String, dynamic>{},
    this.constraints = const <String, dynamic>{},
  });

  final String simulationId;
  final MonteCarloRunContext runContext;
  final List<KernelEventEnvelope> seedEnvelopes;
  final Map<String, dynamic> topology;
  final Map<String, dynamic> constraints;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'simulation_id': simulationId,
        'run_context': runContext.toJson(),
        'seed_envelopes': seedEnvelopes.map((entry) => entry.toJson()).toList(),
        'topology': topology,
        'constraints': constraints,
      };

  factory MeshSimulationRequest.fromJson(Map<String, dynamic> json) {
    return MeshSimulationRequest(
      simulationId: json['simulation_id'] as String? ?? '',
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(
          json['run_context'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      seedEnvelopes: (json['seed_envelopes'] as List? ?? const <dynamic>[])
          .map((entry) => KernelEventEnvelope.fromJson(
                Map<String, dynamic>.from(entry as Map),
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

class MeshSimulationResult {
  const MeshSimulationResult({
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

class MeshRealityProjectionBundle {
  const MeshRealityProjectionBundle({
    required this.what,
    required this.when,
    required this.why,
  });

  final WhatRealityProjection what;
  final WhenRealityProjection when;
  final WhyRealityProjection why;

  List<dynamic> asList() => <dynamic>[what, when, why];
}

MeshRealityProjectionBundle projectMeshSnapshotForRealityModel(
  MeshKernelSnapshot? snapshot, {
  KernelEventEnvelope? envelope,
  WhenKernelSnapshot? whenSnapshot,
  Map<String, dynamic> context = const <String, dynamic>{},
}) {
  final projectedAtUtc = whenSnapshot?.observedAt.toUtc() ??
      envelope?.occurredAtUtc.toUtc() ??
      snapshot?.savedAtUtc.toUtc();
  final lifecycleState = snapshot?.lifecycleState.name ?? 'unknown';
  final destinationId = snapshot?.destinationId ?? 'unknown_destination';
  final basePayload = <String, dynamic>{
    'source_kernel': 'mesh_runtime_governance',
    'projection_surfaces': const <String>['what', 'when', 'why'],
    if (projectedAtUtc != null)
      'projected_at_utc': projectedAtUtc.toIso8601String(),
    'projection_context': context,
    if (whenSnapshot != null) 'when_snapshot': whenSnapshot.toJson(),
    ...?snapshot?.toJson(),
  };

  return MeshRealityProjectionBundle(
    what: WhatRealityProjection(
      summary: 'Mesh state for $destinationId',
      confidence: snapshot == null ? 0.0 : 1.0,
      features: <String, dynamic>{
        'destination_id': destinationId,
        'queue_depth': snapshot?.queueDepth ?? 0,
        'lifecycle_state': lifecycleState,
      },
      payload: <String, dynamic>{
        ...basePayload,
        'projection_surface': 'what',
      },
    ),
    when: WhenRealityProjection(
      summary:
          'Mesh lifecycle $lifecycleState at ${projectedAtUtc?.toIso8601String() ?? 'unknown_time'}',
      confidence:
          whenSnapshot?.temporalConfidence ?? (snapshot == null ? 0.0 : 1.0),
      features: <String, dynamic>{
        'observed_at_utc': projectedAtUtc?.toIso8601String(),
        'lifecycle_state': lifecycleState,
        'queue_depth': snapshot?.queueDepth ?? 0,
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
      summary: 'Mesh delivery rationale for $destinationId',
      confidence: snapshot == null ? 0.0 : 1.0,
      features: <String, dynamic>{
        'lifecycle_state': lifecycleState,
        'store_carry_forward_candidate':
            context['store_carry_forward_allowed'] as bool? ?? true,
        'failure_reason': snapshot?.diagnostics['failure_reason'],
      },
      payload: <String, dynamic>{
        ...basePayload,
        'projection_surface': 'why',
      },
    ),
  );
}

import 'package:avrai_core/models/vibe/vibe_models.dart';

class KernelEventEnvelope {
  const KernelEventEnvelope({
    required this.eventId,
    required this.occurredAtUtc,
    this.agentId,
    this.userId,
    this.sessionId,
    this.sourceSystem,
    this.eventType,
    this.actionType,
    this.entityId,
    this.entityType,
    this.whoRef,
    this.whatRef,
    this.whenRef,
    this.whereRef,
    this.whyRef,
    this.howRef,
    this.policyRef,
    this.privacyMode,
    this.provenance,
    this.realityProjectionRef,
    this.primarySliceId,
    this.relatedSliceIds = const <String>[],
    this.routeReceipt,
    this.adminProvenance = const <String, dynamic>{},
    this.uncertainty = const <String, dynamic>{},
    this.context = const <String, dynamic>{},
    this.predictionContext = const <String, dynamic>{},
    this.policyContext = const <String, dynamic>{},
    this.runtimeContext = const <String, dynamic>{},
  });

  final String eventId;
  final DateTime occurredAtUtc;
  final String? agentId;
  final String? userId;
  final String? sessionId;
  final String? sourceSystem;
  final String? eventType;
  final String? actionType;
  final String? entityId;
  final String? entityType;
  final String? whoRef;
  final String? whatRef;
  final String? whenRef;
  final String? whereRef;
  final String? whyRef;
  final String? howRef;
  final String? policyRef;
  final String? privacyMode;
  final String? provenance;
  final String? realityProjectionRef;
  final String? primarySliceId;
  final List<String> relatedSliceIds;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> adminProvenance;
  final Map<String, dynamic> uncertainty;
  final Map<String, dynamic> context;
  final Map<String, dynamic> predictionContext;
  final Map<String, dynamic> policyContext;
  final Map<String, dynamic> runtimeContext;

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
        if (agentId != null) 'agent_id': agentId,
        if (userId != null) 'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
        if (sourceSystem != null) 'source_system': sourceSystem,
        if (eventType != null) 'event_type': eventType,
        if (actionType != null) 'action_type': actionType,
        if (entityId != null) 'entity_id': entityId,
        if (entityType != null) 'entity_type': entityType,
        if (whoRef != null) 'who_ref': whoRef,
        if (whatRef != null) 'what_ref': whatRef,
        if (whenRef != null) 'when_ref': whenRef,
        if (whereRef != null) 'where_ref': whereRef,
        if (whyRef != null) 'why_ref': whyRef,
        if (howRef != null) 'how_ref': howRef,
        if (policyRef != null) 'policy_ref': policyRef,
        if (privacyMode != null) 'privacy_mode': privacyMode,
        if (provenance != null) 'provenance': provenance,
        if (realityProjectionRef != null)
          'reality_projection_ref': realityProjectionRef,
        if (primarySliceId != null) 'primary_slice_id': primarySliceId,
        'related_slice_ids': relatedSliceIds,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'admin_provenance': adminProvenance,
        'uncertainty': uncertainty,
        'context': context,
        'prediction_context': predictionContext,
        'policy_context': policyContext,
        'runtime_context': runtimeContext,
      };

  factory KernelEventEnvelope.fromJson(Map<String, dynamic> json) {
    return KernelEventEnvelope(
      eventId: json['event_id'] as String? ?? 'unknown_event',
      occurredAtUtc: DateTime.tryParse(json['occurred_at_utc'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      agentId: json['agent_id'] as String?,
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      sourceSystem: json['source_system'] as String?,
      eventType: json['event_type'] as String?,
      actionType: json['action_type'] as String?,
      entityId: json['entity_id'] as String?,
      entityType: json['entity_type'] as String?,
      whoRef: json['who_ref'] as String?,
      whatRef: json['what_ref'] as String?,
      whenRef: json['when_ref'] as String?,
      whereRef: json['where_ref'] as String?,
      whyRef: json['why_ref'] as String?,
      howRef: json['how_ref'] as String?,
      policyRef: json['policy_ref'] as String?,
      privacyMode: json['privacy_mode'] as String?,
      provenance: json['provenance'] as String?,
      realityProjectionRef: json['reality_projection_ref'] as String?,
      primarySliceId: json['primary_slice_id'] as String?,
      relatedSliceIds: List<String>.from(
        json['related_slice_ids'] as List? ?? const <String>[],
      ),
      routeReceipt: json['route_receipt'] is Map
          ? TransportRouteReceipt.fromJson(
              Map<String, dynamic>.from(json['route_receipt'] as Map),
            )
          : null,
      adminProvenance: Map<String, dynamic>.from(
        json['admin_provenance'] as Map? ?? const <String, dynamic>{},
      ),
      uncertainty: Map<String, dynamic>.from(
        json['uncertainty'] as Map? ?? const <String, dynamic>{},
      ),
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const <String, dynamic>{},
      ),
      predictionContext: Map<String, dynamic>.from(
        json['prediction_context'] as Map? ?? const <String, dynamic>{},
      ),
      policyContext: Map<String, dynamic>.from(
        json['policy_context'] as Map? ?? const <String, dynamic>{},
      ),
      runtimeContext: Map<String, dynamic>.from(
        json['runtime_context'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class TransportRouteReceipt {
  const TransportRouteReceipt({
    required this.receiptId,
    required this.channel,
    required this.status,
    required this.recordedAtUtc,
    this.localOnly = true,
    this.plannedRoutes = const <TransportRouteCandidate>[],
    this.attemptedRoutes = const <TransportRouteCandidate>[],
    this.winningRoute,
    this.winningRouteReason,
    this.hopCount,
    this.queuedAtUtc,
    this.releasedAtUtc,
    this.custodyAcceptedAtUtc,
    this.custodyAcceptedBy,
    this.deliveredAtUtc,
    this.readAtUtc,
    this.readBy,
    this.learningAppliedAtUtc,
    this.learningAppliedBy,
    this.expiresAtUtc,
    this.quarantined = false,
    this.fallbackReason,
    this.metadata = const <String, dynamic>{},
  });

  final String receiptId;
  final String channel;
  final String status;
  final DateTime recordedAtUtc;
  final bool localOnly;
  final List<TransportRouteCandidate> plannedRoutes;
  final List<TransportRouteCandidate> attemptedRoutes;
  final TransportRouteCandidate? winningRoute;
  final String? winningRouteReason;
  final int? hopCount;
  final DateTime? queuedAtUtc;
  final DateTime? releasedAtUtc;
  final DateTime? custodyAcceptedAtUtc;
  final String? custodyAcceptedBy;
  final DateTime? deliveredAtUtc;
  final DateTime? readAtUtc;
  final String? readBy;
  final DateTime? learningAppliedAtUtc;
  final String? learningAppliedBy;
  final DateTime? expiresAtUtc;
  final bool quarantined;
  final String? fallbackReason;
  final Map<String, dynamic> metadata;

  TransportReceiptLifecycleStage get lifecycleStage {
    if (learningAppliedAtUtc != null) {
      return TransportReceiptLifecycleStage.learningApplied;
    }
    if (readAtUtc != null) {
      return TransportReceiptLifecycleStage.read;
    }
    if (deliveredAtUtc != null) {
      return TransportReceiptLifecycleStage.delivered;
    }
    if (custodyAcceptedAtUtc != null) {
      return TransportReceiptLifecycleStage.custodyAccepted;
    }
    switch (status) {
      case 'released':
      case 'forwarded':
        return TransportReceiptLifecycleStage.released;
      case 'failed':
        return TransportReceiptLifecycleStage.failed;
      default:
        return TransportReceiptLifecycleStage.queued;
    }
  }

  TransportRouteReceipt copyWith({
    String? status,
    DateTime? recordedAtUtc,
    List<TransportRouteCandidate>? attemptedRoutes,
    TransportRouteCandidate? winningRoute,
    String? winningRouteReason,
    DateTime? releasedAtUtc,
    DateTime? custodyAcceptedAtUtc,
    String? custodyAcceptedBy,
    DateTime? deliveredAtUtc,
    DateTime? readAtUtc,
    String? readBy,
    DateTime? learningAppliedAtUtc,
    String? learningAppliedBy,
    String? fallbackReason,
    Map<String, dynamic>? metadata,
  }) {
    return TransportRouteReceipt(
      receiptId: receiptId,
      channel: channel,
      status: status ?? this.status,
      recordedAtUtc: recordedAtUtc ?? this.recordedAtUtc,
      localOnly: localOnly,
      plannedRoutes: plannedRoutes,
      attemptedRoutes: attemptedRoutes ?? this.attemptedRoutes,
      winningRoute: winningRoute ?? this.winningRoute,
      winningRouteReason: winningRouteReason ?? this.winningRouteReason,
      hopCount: hopCount,
      queuedAtUtc: queuedAtUtc,
      releasedAtUtc: releasedAtUtc ?? this.releasedAtUtc,
      custodyAcceptedAtUtc: custodyAcceptedAtUtc ?? this.custodyAcceptedAtUtc,
      custodyAcceptedBy: custodyAcceptedBy ?? this.custodyAcceptedBy,
      deliveredAtUtc: deliveredAtUtc ?? this.deliveredAtUtc,
      readAtUtc: readAtUtc ?? this.readAtUtc,
      readBy: readBy ?? this.readBy,
      learningAppliedAtUtc: learningAppliedAtUtc ?? this.learningAppliedAtUtc,
      learningAppliedBy: learningAppliedBy ?? this.learningAppliedBy,
      expiresAtUtc: expiresAtUtc,
      quarantined: quarantined,
      fallbackReason: fallbackReason ?? this.fallbackReason,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'receipt_id': receiptId,
        'channel': channel,
        'status': status,
        'recorded_at_utc': recordedAtUtc.toUtc().toIso8601String(),
        'local_only': localOnly,
        'planned_routes': plannedRoutes.map((route) => route.toJson()).toList(),
        'attempted_routes':
            attemptedRoutes.map((route) => route.toJson()).toList(),
        if (winningRoute != null) 'winning_route': winningRoute!.toJson(),
        if (winningRouteReason != null)
          'winning_route_reason': winningRouteReason,
        if (hopCount != null) 'hop_count': hopCount,
        if (queuedAtUtc != null)
          'queued_at_utc': queuedAtUtc!.toUtc().toIso8601String(),
        if (releasedAtUtc != null)
          'released_at_utc': releasedAtUtc!.toUtc().toIso8601String(),
        if (custodyAcceptedAtUtc != null)
          'custody_accepted_at_utc':
              custodyAcceptedAtUtc!.toUtc().toIso8601String(),
        if (custodyAcceptedBy != null) 'custody_accepted_by': custodyAcceptedBy,
        if (deliveredAtUtc != null)
          'delivered_at_utc': deliveredAtUtc!.toUtc().toIso8601String(),
        if (readAtUtc != null)
          'read_at_utc': readAtUtc!.toUtc().toIso8601String(),
        if (readBy != null) 'read_by': readBy,
        if (learningAppliedAtUtc != null)
          'learning_applied_at_utc':
              learningAppliedAtUtc!.toUtc().toIso8601String(),
        if (learningAppliedBy != null) 'learning_applied_by': learningAppliedBy,
        if (expiresAtUtc != null)
          'expires_at_utc': expiresAtUtc!.toUtc().toIso8601String(),
        'quarantined': quarantined,
        if (fallbackReason != null) 'fallback_reason': fallbackReason,
        'metadata': metadata,
      };

  factory TransportRouteReceipt.fromJson(Map<String, dynamic> json) {
    return TransportRouteReceipt(
      receiptId: json['receipt_id'] as String? ?? 'unknown_receipt',
      channel: json['channel'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      recordedAtUtc: DateTime.tryParse(
            json['recorded_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localOnly: json['local_only'] as bool? ?? true,
      plannedRoutes: (json['planned_routes'] as List<dynamic>? ?? const [])
          .map(
            (route) => TransportRouteCandidate.fromJson(
              Map<String, dynamic>.from(route as Map),
            ),
          )
          .toList(),
      attemptedRoutes: (json['attempted_routes'] as List<dynamic>? ?? const [])
          .map(
            (route) => TransportRouteCandidate.fromJson(
              Map<String, dynamic>.from(route as Map),
            ),
          )
          .toList(),
      winningRoute: json['winning_route'] is Map
          ? TransportRouteCandidate.fromJson(
              Map<String, dynamic>.from(json['winning_route'] as Map),
            )
          : null,
      winningRouteReason: json['winning_route_reason'] as String?,
      hopCount: (json['hop_count'] as num?)?.toInt(),
      queuedAtUtc:
          DateTime.tryParse(json['queued_at_utc'] as String? ?? '')?.toUtc(),
      releasedAtUtc:
          DateTime.tryParse(json['released_at_utc'] as String? ?? '')?.toUtc(),
      custodyAcceptedAtUtc:
          DateTime.tryParse(json['custody_accepted_at_utc'] as String? ?? '')
              ?.toUtc(),
      custodyAcceptedBy: json['custody_accepted_by'] as String?,
      deliveredAtUtc:
          DateTime.tryParse(json['delivered_at_utc'] as String? ?? '')?.toUtc(),
      readAtUtc:
          DateTime.tryParse(json['read_at_utc'] as String? ?? '')?.toUtc(),
      readBy: json['read_by'] as String?,
      learningAppliedAtUtc:
          DateTime.tryParse(json['learning_applied_at_utc'] as String? ?? '')
              ?.toUtc(),
      learningAppliedBy: json['learning_applied_by'] as String?,
      expiresAtUtc:
          DateTime.tryParse(json['expires_at_utc'] as String? ?? '')?.toUtc(),
      quarantined: json['quarantined'] as bool? ?? false,
      fallbackReason: json['fallback_reason'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

enum TransportReceiptLifecycleStage {
  queued,
  released,
  custodyAccepted,
  delivered,
  read,
  learningApplied,
  failed,
}

enum TransportMode { ble, localWifi, nearbyRelay, wormhole, cloudAssist }

class TransportRouteCandidate {
  const TransportRouteCandidate({
    required this.routeId,
    required this.mode,
    required this.confidence,
    required this.estimatedLatencyMs,
    this.expiryFit = 1.0,
    this.localityFit = 1.0,
    this.availabilityScore = 1.0,
    this.rationale,
    this.metadata = const <String, dynamic>{},
  });

  final String routeId;
  final TransportMode mode;
  final double confidence;
  final int estimatedLatencyMs;
  final double expiryFit;
  final double localityFit;
  final double availabilityScore;
  final String? rationale;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'route_id': routeId,
        'mode': mode.name,
        'confidence': confidence,
        'estimated_latency_ms': estimatedLatencyMs,
        'expiry_fit': expiryFit,
        'locality_fit': localityFit,
        'availability_score': availabilityScore,
        if (rationale != null) 'rationale': rationale,
        'metadata': metadata,
      };

  factory TransportRouteCandidate.fromJson(Map<String, dynamic> json) {
    return TransportRouteCandidate(
      routeId: json['route_id'] as String? ?? 'unknown_route',
      mode: TransportMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => TransportMode.wormhole,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      estimatedLatencyMs: (json['estimated_latency_ms'] as num?)?.toInt() ?? 0,
      expiryFit: (json['expiry_fit'] as num?)?.toDouble() ?? 1.0,
      localityFit: (json['locality_fit'] as num?)?.toDouble() ?? 1.0,
      availabilityScore:
          (json['availability_score'] as num?)?.toDouble() ?? 1.0,
      rationale: json['rationale'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

enum KernelDomain { who, what, when, where, why, how, vibe }

enum KernelAuthorityLevel { thin, transitional, authoritative }

enum KernelHealthStatus { healthy, degraded, unavailable }

enum KernelProjectionAudience {
  modelTruth,
  trustGovernance,
  runtimeExecution,
  appShell,
  adminShell,
}

class KernelProjectionRequest {
  const KernelProjectionRequest({
    this.subjectId,
    this.audience = KernelProjectionAudience.modelTruth,
    this.summaryFocus,
    this.envelope,
    this.bundle,
    this.who,
    this.what,
    this.when,
    this.where,
    this.how,
    this.why,
    this.vibe,
    this.context = const <String, dynamic>{},
  });

  final String? subjectId;
  final KernelProjectionAudience audience;
  final String? summaryFocus;
  final KernelEventEnvelope? envelope;
  final KernelContextBundleWithoutWhy? bundle;
  final WhoKernelSnapshot? who;
  final WhatKernelSnapshot? what;
  final WhenKernelSnapshot? when;
  final WhereKernelSnapshot? where;
  final HowKernelSnapshot? how;
  final WhyKernelSnapshot? why;
  final VibeStateSnapshot? vibe;
  final Map<String, dynamic> context;
}

class KernelReplayRequest {
  const KernelReplayRequest({
    required this.subjectId,
    this.limit = 20,
    this.sinceUtc,
    this.untilUtc,
    this.filters = const <String, dynamic>{},
  });

  final String subjectId;
  final int limit;
  final DateTime? sinceUtc;
  final DateTime? untilUtc;
  final Map<String, dynamic> filters;
}

class KernelReplayRecord {
  const KernelReplayRecord({
    required this.domain,
    required this.recordId,
    required this.occurredAtUtc,
    required this.summary,
    this.payload = const <String, dynamic>{},
  });

  final KernelDomain domain;
  final String recordId;
  final DateTime occurredAtUtc;
  final String summary;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'record_id': recordId,
        'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
        'summary': summary,
        'payload': payload,
      };
}

class KernelRecoveryRequest {
  const KernelRecoveryRequest({
    required this.subjectId,
    this.persistedEnvelope,
    this.hints = const <String, dynamic>{},
  });

  final String subjectId;
  final Map<String, dynamic>? persistedEnvelope;
  final Map<String, dynamic> hints;
}

class KernelRecoveryReport {
  const KernelRecoveryReport({
    required this.domain,
    required this.subjectId,
    required this.restoredCount,
    required this.droppedCount,
    required this.recoveredAtUtc,
    required this.summary,
  });

  final KernelDomain domain;
  final String subjectId;
  final int restoredCount;
  final int droppedCount;
  final DateTime recoveredAtUtc;
  final String summary;

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'subject_id': subjectId,
        'restored_count': restoredCount,
        'dropped_count': droppedCount,
        'recovered_at_utc': recoveredAtUtc.toUtc().toIso8601String(),
        'summary': summary,
      };
}

class KernelHealthReport {
  const KernelHealthReport({
    required this.domain,
    required this.status,
    required this.nativeBacked,
    required this.headlessReady,
    required this.authorityLevel,
    required this.summary,
    this.diagnostics = const <String, dynamic>{},
  });

  final KernelDomain domain;
  final KernelHealthStatus status;
  final bool nativeBacked;
  final bool headlessReady;
  final KernelAuthorityLevel authorityLevel;
  final String summary;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'status': status.name,
        'native_backed': nativeBacked,
        'headless_ready': headlessReady,
        'authority_level': authorityLevel.name,
        'summary': summary,
        'diagnostics': diagnostics,
      };

  factory KernelHealthReport.fromJson(Map<String, dynamic> json) {
    return KernelHealthReport(
      domain: KernelDomain.values.byName(json['domain'] as String? ?? 'what'),
      status: KernelHealthStatus.values.byName(
        json['status'] as String? ?? KernelHealthStatus.unavailable.name,
      ),
      nativeBacked: json['native_backed'] as bool? ?? false,
      headlessReady: json['headless_ready'] as bool? ?? false,
      authorityLevel: KernelAuthorityLevel.values.byName(
        json['authority_level'] as String? ??
            KernelAuthorityLevel.transitional.name,
      ),
      summary: json['summary'] as String? ?? 'kernel health restored',
      diagnostics: Map<String, dynamic>.from(
        json['diagnostics'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class KernelGovernanceProjection {
  const KernelGovernanceProjection({
    required this.domain,
    required this.summary,
    required this.confidence,
    this.highlights = const <String>[],
    this.payload = const <String, dynamic>{},
  });

  final KernelDomain domain;
  final String summary;
  final double confidence;
  final List<String> highlights;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'summary': summary,
        'confidence': confidence,
        'highlights': highlights,
        'payload': payload,
      };
}

class KernelRealityProjection {
  const KernelRealityProjection({
    required this.domain,
    required this.summary,
    required this.confidence,
    this.features = const <String, dynamic>{},
    this.payload = const <String, dynamic>{},
  });

  final KernelDomain domain;
  final String summary;
  final double confidence;
  final Map<String, dynamic> features;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'summary': summary,
        'confidence': confidence,
        'features': features,
        'payload': payload,
      };
}

class WhoRuntimeBindingRequest {
  const WhoRuntimeBindingRequest({
    required this.runtimeId,
    required this.actorId,
    this.trustScope = 'private',
    this.cohortRefs = const <String>[],
  });

  final String runtimeId;
  final String actorId;
  final String trustScope;
  final List<String> cohortRefs;

  Map<String, dynamic> toJson() => {
        'runtime_id': runtimeId,
        'actor_id': actorId,
        'trust_scope': trustScope,
        'cohort_refs': cohortRefs,
      };
}

class WhoRuntimeBindingReceipt {
  const WhoRuntimeBindingReceipt({
    required this.runtimeId,
    required this.actorId,
    required this.boundAtUtc,
    required this.continuityRef,
  });

  final String runtimeId;
  final String actorId;
  final DateTime boundAtUtc;
  final String continuityRef;
}

class WhoSigningRequest {
  const WhoSigningRequest({
    required this.actorId,
    required this.payload,
    this.algorithm = 'avrai_local_signature_v1',
  });

  final String actorId;
  final Map<String, dynamic> payload;
  final String algorithm;
}

class WhoSignatureRecord {
  const WhoSignatureRecord({
    required this.actorId,
    required this.algorithm,
    required this.signature,
    required this.issuedAtUtc,
  });

  final String actorId;
  final String algorithm;
  final String signature;
  final DateTime issuedAtUtc;
}

class WhoVerificationRequest {
  const WhoVerificationRequest({
    required this.actorId,
    required this.payload,
    required this.signature,
    this.algorithm = 'avrai_local_signature_v1',
  });

  final String actorId;
  final Map<String, dynamic> payload;
  final String signature;
  final String algorithm;
}

class WhoVerificationResult {
  const WhoVerificationResult({
    required this.valid,
    required this.reason,
  });

  final bool valid;
  final String reason;
}

class WhenTimestampRequest {
  const WhenTimestampRequest({
    required this.referenceId,
    required this.occurredAtUtc,
    this.runtimeId,
    this.context = const <String, dynamic>{},
  });

  final String referenceId;
  final DateTime occurredAtUtc;
  final String? runtimeId;
  final Map<String, dynamic> context;
}

class WhenTimestamp {
  const WhenTimestamp({
    required this.referenceId,
    required this.observedAtUtc,
    required this.quantumAtomicTick,
    required this.confidence,
  });

  final String referenceId;
  final DateTime observedAtUtc;
  final int quantumAtomicTick;
  final double confidence;

  Map<String, dynamic> toJson() => {
        'reference_id': referenceId,
        'observed_at_utc': observedAtUtc.toUtc().toIso8601String(),
        'quantum_atomic_tick': quantumAtomicTick,
        'confidence': confidence,
      };
}

class WhenValidityWindow {
  const WhenValidityWindow({
    required this.timestamp,
    this.effectiveAtUtc,
    this.expiresAtUtc,
    this.allowedDriftMs = 0,
  });

  final WhenTimestamp timestamp;
  final DateTime? effectiveAtUtc;
  final DateTime? expiresAtUtc;
  final int allowedDriftMs;
}

class WhenValidationResult {
  const WhenValidationResult({
    required this.valid,
    required this.reason,
    required this.observedDriftMs,
  });

  final bool valid;
  final String reason;
  final int observedDriftMs;
}

class WhenComparisonResult {
  const WhenComparisonResult({
    required this.orderedAscending,
    required this.deltaMs,
  });

  final bool orderedAscending;
  final int deltaMs;
}

class WhenClockHealth {
  const WhenClockHealth({
    required this.clockState,
    required this.maxObservedDriftMs,
    required this.quantumAtomicReady,
  });

  final String clockState;
  final int maxObservedDriftMs;
  final bool quantumAtomicReady;
}

class WhenEventRecord {
  const WhenEventRecord({
    required this.eventId,
    required this.runtimeId,
    required this.occurredAtUtc,
    required this.stratum,
    this.payload = const <String, dynamic>{},
  });

  final String eventId;
  final String runtimeId;
  final DateTime occurredAtUtc;
  final String stratum;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'runtime_id': runtimeId,
        'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
        'stratum': stratum,
        'payload': payload,
      };
}

class WhenReconciliationResult {
  const WhenReconciliationResult({
    required this.canonicalTimestamp,
    required this.conflictCount,
    required this.summary,
  });

  final WhenTimestamp canonicalTimestamp;
  final int conflictCount;
  final String summary;
}

class HowPlanningRequest {
  const HowPlanningRequest({
    required this.executionId,
    required this.goal,
    this.runtimeId,
    this.context = const <String, dynamic>{},
  });

  final String executionId;
  final String goal;
  final String? runtimeId;
  final Map<String, dynamic> context;
}

class HowExecutionPlan {
  const HowExecutionPlan({
    required this.executionId,
    required this.path,
    required this.workflowStage,
    required this.capabilityChain,
  });

  final String executionId;
  final String path;
  final String workflowStage;
  final List<String> capabilityChain;
}

class HowExecutionTrace {
  const HowExecutionTrace({
    required this.executionId,
    required this.path,
    required this.completedAtUtc,
    required this.status,
    this.capabilityChain = const <String>[],
  });

  final String executionId;
  final String path;
  final DateTime completedAtUtc;
  final String status;
  final List<String> capabilityChain;
}

class HowInterventionDirective {
  const HowInterventionDirective({
    required this.executionId,
    required this.directive,
    this.reason,
  });

  final String executionId;
  final String directive;
  final String? reason;
}

class HowInterventionReceipt {
  const HowInterventionReceipt({
    required this.executionId,
    required this.directive,
    required this.accepted,
    required this.recordedAtUtc,
  });

  final String executionId;
  final String directive;
  final bool accepted;
  final DateTime recordedAtUtc;
}

class HowRollbackRequest {
  const HowRollbackRequest({
    required this.executionId,
    this.reason,
  });

  final String executionId;
  final String? reason;
}

class HowRollbackReceipt {
  const HowRollbackReceipt({
    required this.executionId,
    required this.rolledBack,
    required this.recordedAtUtc,
  });

  final String executionId;
  final bool rolledBack;
  final DateTime recordedAtUtc;
}

class HowCapabilityReport {
  const HowCapabilityReport({
    required this.runtimeId,
    required this.capabilities,
    required this.governanceChannel,
  });

  final String runtimeId;
  final List<String> capabilities;
  final String governanceChannel;
}

class WhyConviction {
  const WhyConviction({
    required this.goal,
    required this.convictionTier,
    required this.confidence,
    required this.summary,
  });

  final String goal;
  final String convictionTier;
  final double confidence;
  final String summary;
}

class WhyCounterfactualRequest {
  const WhyCounterfactualRequest({
    required this.request,
    required this.condition,
  });

  final KernelWhyRequest request;
  final String condition;
}

class WhyAnomalyInterpretation {
  const WhyAnomalyInterpretation({
    required this.anomalous,
    required this.summary,
    required this.severity,
  });

  final bool anomalous;
  final String summary;
  final String severity;
}

class WhoKernelSnapshot {
  const WhoKernelSnapshot({
    required this.primaryActor,
    required this.affectedActor,
    required this.companionActors,
    required this.actorRoles,
    required this.trustScope,
    required this.cohortRefs,
    required this.identityConfidence,
  });

  final String primaryActor;
  final String affectedActor;
  final List<String> companionActors;
  final List<String> actorRoles;
  final String trustScope;
  final List<String> cohortRefs;
  final double identityConfidence;

  Map<String, dynamic> toJson() => {
        'primary_actor': primaryActor,
        'affected_actor': affectedActor,
        'companion_actors': companionActors,
        'actor_roles': actorRoles,
        'trust_scope': trustScope,
        'cohort_refs': cohortRefs,
        'identity_confidence': identityConfidence,
      };

  factory WhoKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return WhoKernelSnapshot(
      primaryActor: json['primary_actor'] as String? ?? 'unknown_actor',
      affectedActor: json['affected_actor'] as String? ??
          json['primary_actor'] as String? ??
          'unknown_actor',
      companionActors:
          ((json['companion_actors'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      actorRoles: ((json['actor_roles'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      trustScope: json['trust_scope'] as String? ?? 'private',
      cohortRefs: ((json['cohort_refs'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      identityConfidence:
          (json['identity_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WhatKernelSnapshot {
  const WhatKernelSnapshot({
    required this.actionType,
    required this.targetEntityType,
    required this.targetEntityId,
    required this.stateTransitionType,
    required this.outcomeType,
    required this.semanticTags,
    required this.taxonomyConfidence,
  });

  final String actionType;
  final String targetEntityType;
  final String targetEntityId;
  final String stateTransitionType;
  final String outcomeType;
  final List<String> semanticTags;
  final double taxonomyConfidence;

  Map<String, dynamic> toJson() => {
        'action_type': actionType,
        'target_entity_type': targetEntityType,
        'target_entity_id': targetEntityId,
        'state_transition_type': stateTransitionType,
        'outcome_type': outcomeType,
        'semantic_tags': semanticTags,
        'taxonomy_confidence': taxonomyConfidence,
      };

  factory WhatKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return WhatKernelSnapshot(
      actionType: json['action_type'] as String? ?? 'unknown_action',
      targetEntityType:
          json['target_entity_type'] as String? ?? 'unknown_entity',
      targetEntityId:
          json['target_entity_id'] as String? ?? 'unknown_entity_id',
      stateTransitionType:
          json['state_transition_type'] as String? ?? 'observation',
      outcomeType: json['outcome_type'] as String? ?? 'pending',
      semanticTags: ((json['semantic_tags'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      taxonomyConfidence:
          (json['taxonomy_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WhenKernelSnapshot {
  const WhenKernelSnapshot({
    required this.observedAt,
    this.effectiveAt,
    this.expiresAt,
    required this.freshness,
    this.cadence,
    required this.recencyBucket,
    required this.timingConflictFlags,
    required this.temporalConfidence,
  });

  final DateTime observedAt;
  final DateTime? effectiveAt;
  final DateTime? expiresAt;
  final double freshness;
  final String? cadence;
  final String recencyBucket;
  final List<String> timingConflictFlags;
  final double temporalConfidence;

  Map<String, dynamic> toJson() => {
        'observed_at': observedAt.toUtc().toIso8601String(),
        if (effectiveAt != null)
          'effective_at': effectiveAt!.toUtc().toIso8601String(),
        if (expiresAt != null)
          'expires_at': expiresAt!.toUtc().toIso8601String(),
        'freshness': freshness,
        if (cadence != null) 'cadence': cadence,
        'recency_bucket': recencyBucket,
        'timing_conflict_flags': timingConflictFlags,
        'temporal_confidence': temporalConfidence,
      };

  factory WhenKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return WhenKernelSnapshot(
      observedAt:
          DateTime.tryParse(json['observed_at'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      effectiveAt:
          DateTime.tryParse(json['effective_at'] as String? ?? '')?.toUtc(),
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '')?.toUtc(),
      freshness: (json['freshness'] as num?)?.toDouble() ?? 0.0,
      cadence: json['cadence'] as String?,
      recencyBucket: json['recency_bucket'] as String? ?? 'unknown',
      timingConflictFlags:
          ((json['timing_conflict_flags'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      temporalConfidence:
          (json['temporal_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WhereKernelSnapshot {
  const WhereKernelSnapshot({
    required this.localityToken,
    required this.cityCode,
    required this.localityCode,
    required this.projection,
    required this.boundaryTension,
    required this.spatialConfidence,
    required this.travelFriction,
    required this.placeFitFlags,
  });

  final String localityToken;
  final String cityCode;
  final String localityCode;
  final Map<String, dynamic> projection;
  final double boundaryTension;
  final double spatialConfidence;
  final double travelFriction;
  final List<String> placeFitFlags;

  Map<String, dynamic> toJson() => {
        'locality_token': localityToken,
        'city_code': cityCode,
        'locality_code': localityCode,
        'projection': projection,
        'boundary_tension': boundaryTension,
        'spatial_confidence': spatialConfidence,
        'travel_friction': travelFriction,
        'place_fit_flags': placeFitFlags,
      };

  factory WhereKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return WhereKernelSnapshot(
      localityToken: json['locality_token'] as String? ?? 'where:bootstrap',
      cityCode: json['city_code'] as String? ?? 'unknown_city',
      localityCode: json['locality_code'] as String? ?? 'unknown_locality',
      projection: Map<String, dynamic>.from(
        json['projection'] as Map? ?? const <String, dynamic>{},
      ),
      boundaryTension: (json['boundary_tension'] as num?)?.toDouble() ?? 0.0,
      spatialConfidence:
          (json['spatial_confidence'] as num?)?.toDouble() ?? 0.0,
      travelFriction: (json['travel_friction'] as num?)?.toDouble() ?? 0.0,
      placeFitFlags: ((json['place_fit_flags'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
    );
  }
}

class HowKernelSnapshot {
  const HowKernelSnapshot({
    required this.executionPath,
    required this.workflowStage,
    required this.transportMode,
    required this.plannerMode,
    required this.modelFamily,
    required this.interventionChain,
    required this.failureMechanism,
    required this.mechanismConfidence,
  });

  final String executionPath;
  final String workflowStage;
  final String transportMode;
  final String plannerMode;
  final String modelFamily;
  final List<String> interventionChain;
  final String failureMechanism;
  final double mechanismConfidence;

  Map<String, dynamic> toJson() => {
        'execution_path': executionPath,
        'workflow_stage': workflowStage,
        'transport_mode': transportMode,
        'planner_mode': plannerMode,
        'model_family': modelFamily,
        'intervention_chain': interventionChain,
        'failure_mechanism': failureMechanism,
        'mechanism_confidence': mechanismConfidence,
      };

  factory HowKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return HowKernelSnapshot(
      executionPath: json['execution_path'] as String? ?? 'native_orchestrated',
      workflowStage: json['workflow_stage'] as String? ?? 'inference',
      transportMode: json['transport_mode'] as String? ?? 'in_process',
      plannerMode: json['planner_mode'] as String? ?? 'heuristic',
      modelFamily: json['model_family'] as String? ?? 'baseline',
      interventionChain:
          ((json['intervention_chain'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      failureMechanism: json['failure_mechanism'] as String? ?? 'none',
      mechanismConfidence:
          (json['mechanism_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

enum WhyRootCauseType {
  traitDriven,
  contextDriven,
  socialDriven,
  temporal,
  locality,
  policy,
  pheromone,
  mechanism,
  mixed,
  unknown;

  String toWireValue() => switch (this) {
        WhyRootCauseType.traitDriven => 'trait_driven',
        WhyRootCauseType.contextDriven => 'context_driven',
        WhyRootCauseType.socialDriven => 'social_driven',
        WhyRootCauseType.temporal => 'temporal',
        WhyRootCauseType.locality => 'locality',
        WhyRootCauseType.policy => 'policy',
        WhyRootCauseType.pheromone => 'pheromone',
        WhyRootCauseType.mechanism => 'mechanism',
        WhyRootCauseType.mixed => 'mixed',
        WhyRootCauseType.unknown => 'unknown',
      };

  static WhyRootCauseType fromWireValue(String? value) => switch (value) {
        'trait_driven' => WhyRootCauseType.traitDriven,
        'context_driven' => WhyRootCauseType.contextDriven,
        'social_driven' => WhyRootCauseType.socialDriven,
        'temporal' => WhyRootCauseType.temporal,
        'locality' => WhyRootCauseType.locality,
        'policy' => WhyRootCauseType.policy,
        'pheromone' => WhyRootCauseType.pheromone,
        'mechanism' => WhyRootCauseType.mechanism,
        'mixed' => WhyRootCauseType.mixed,
        _ => WhyRootCauseType.unknown,
      };
}

class WhySignal {
  const WhySignal({
    required this.label,
    required this.weight,
    this.source,
    this.durable,
  });

  final String label;
  final double weight;
  final String? source;
  final bool? durable;

  Map<String, dynamic> toJson() => {
        'label': label,
        'weight': weight,
        if (source != null) 'source': source,
        if (durable != null) 'durable': durable,
      };

  factory WhySignal.fromJson(Map<String, dynamic> json) {
    return WhySignal(
      label: json['label'] as String? ?? 'unknown',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String?,
      durable: json['durable'] as bool?,
    );
  }
}

class WhyCounterfactual {
  const WhyCounterfactual({
    required this.condition,
    required this.expectedEffect,
    required this.confidenceDelta,
  });

  final String condition;
  final String expectedEffect;
  final double confidenceDelta;

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'expected_effect': expectedEffect,
        'confidence_delta': confidenceDelta,
      };

  factory WhyCounterfactual.fromJson(Map<String, dynamic> json) {
    return WhyCounterfactual(
      condition: json['condition'] as String? ?? 'unknown',
      expectedEffect: json['expected_effect'] as String? ?? 'unknown',
      confidenceDelta: (json['confidence_delta'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WhyFailureSignature {
  const WhyFailureSignature({
    required this.signatureId,
    required this.signatureFamily,
    required this.novelty,
    required this.replayRisk,
    required this.recommendedGuardrail,
  });

  final String signatureId;
  final String signatureFamily;
  final String novelty;
  final String replayRisk;
  final String recommendedGuardrail;

  Map<String, dynamic> toJson() => {
        'signature_id': signatureId,
        'signature_family': signatureFamily,
        'novelty': novelty,
        'replay_risk': replayRisk,
        'recommended_guardrail': recommendedGuardrail,
      };

  factory WhyFailureSignature.fromJson(Map<String, dynamic> json) {
    return WhyFailureSignature(
      signatureId: json['signature_id'] as String? ?? 'unknown',
      signatureFamily: json['signature_family'] as String? ?? 'unknown_failure',
      novelty: json['novelty'] as String? ?? 'unknown',
      replayRisk: json['replay_risk'] as String? ?? 'unknown',
      recommendedGuardrail:
          json['recommended_guardrail'] as String? ?? 'adjust_confidence',
    );
  }
}

class WhyKernelSnapshot {
  const WhyKernelSnapshot({
    required this.goal,
    required this.summary,
    required this.rootCauseType,
    required this.confidence,
    required this.drivers,
    required this.inhibitors,
    required this.counterfactuals,
    this.failureSignature,
    this.recommendationAction,
    this.schemaVersion = 1,
    required this.createdAtUtc,
  });

  final String goal;
  final String summary;
  final WhyRootCauseType rootCauseType;
  final double confidence;
  final List<WhySignal> drivers;
  final List<WhySignal> inhibitors;
  final List<WhyCounterfactual> counterfactuals;
  final WhyFailureSignature? failureSignature;
  final String? recommendationAction;
  final int schemaVersion;
  final DateTime createdAtUtc;

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'summary': summary,
        'root_cause_type': rootCauseType.toWireValue(),
        'confidence': confidence,
        'drivers': drivers.map((entry) => entry.toJson()).toList(),
        'inhibitors': inhibitors.map((entry) => entry.toJson()).toList(),
        'counterfactuals':
            counterfactuals.map((entry) => entry.toJson()).toList(),
        if (failureSignature != null)
          'failure_signature': failureSignature!.toJson(),
        if (recommendationAction != null)
          'recommendation_action': recommendationAction,
        'schema_version': schemaVersion,
        'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
      };

  factory WhyKernelSnapshot.fromJson(Map<String, dynamic> json) {
    return WhyKernelSnapshot(
      goal: json['goal'] as String? ?? 'explain_outcome',
      summary: json['summary'] as String? ?? 'No causal attribution available.',
      rootCauseType:
          WhyRootCauseType.fromWireValue(json['root_cause_type'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      drivers: ((json['drivers'] as List?) ?? const <dynamic>[])
          .map((entry) =>
              WhySignal.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      inhibitors: ((json['inhibitors'] as List?) ?? const <dynamic>[])
          .map((entry) =>
              WhySignal.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      counterfactuals: ((json['counterfactuals'] as List?) ?? const <dynamic>[])
          .map((entry) => WhyCounterfactual.fromJson(
              Map<String, dynamic>.from(entry as Map)))
          .toList(),
      failureSignature: json['failure_signature'] is Map
          ? WhyFailureSignature.fromJson(
              Map<String, dynamic>.from(json['failure_signature'] as Map),
            )
          : null,
      recommendationAction: json['recommendation_action'] as String?,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      createdAtUtc:
          DateTime.tryParse(json['created_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
    );
  }
}

class KernelContextBundleWithoutWhy {
  const KernelContextBundleWithoutWhy({
    this.who,
    this.what,
    this.when,
    this.where,
    this.how,
    this.vibe,
    this.vibeStack,
  });

  final WhoKernelSnapshot? who;
  final WhatKernelSnapshot? what;
  final WhenKernelSnapshot? when;
  final WhereKernelSnapshot? where;
  final HowKernelSnapshot? how;
  final VibeStateSnapshot? vibe;
  final HierarchicalVibeStack? vibeStack;

  Map<String, dynamic> toJson() => {
        if (who != null) 'who': who!.toJson(),
        if (what != null) 'what': what!.toJson(),
        if (when != null) 'when': when!.toJson(),
        if (where != null) 'where': where!.toJson(),
        if (how != null) 'how': how!.toJson(),
        if (vibe != null) 'vibe': vibe!.toJson(),
        if (vibeStack != null) 'vibe_stack': vibeStack!.toJson(),
      };
}

class KernelContextBundle extends KernelContextBundleWithoutWhy {
  const KernelContextBundle({
    required super.who,
    required super.what,
    required super.when,
    required super.where,
    required super.how,
    super.vibe,
    super.vibeStack,
    this.why,
  });

  final WhyKernelSnapshot? why;

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (why != null) 'why': why!.toJson(),
      };

  KernelContextBundleWithoutWhy withoutWhy() => KernelContextBundleWithoutWhy(
        who: who,
        what: what,
        when: when,
        where: where,
        how: how,
        vibe: vibe,
        vibeStack: vibeStack,
      );

  factory KernelContextBundle.fromJson(Map<String, dynamic> json) {
    return KernelContextBundle(
      who: json['who'] is Map
          ? WhoKernelSnapshot.fromJson(
              Map<String, dynamic>.from(json['who'] as Map),
            )
          : null,
      what: json['what'] is Map
          ? WhatKernelSnapshot.fromJson(
              Map<String, dynamic>.from(json['what'] as Map),
            )
          : null,
      when: json['when'] is Map
          ? WhenKernelSnapshot.fromJson(
              Map<String, dynamic>.from(json['when'] as Map),
            )
          : null,
      where: json['where'] is Map
          ? WhereKernelSnapshot.fromJson(
              Map<String, dynamic>.from(json['where'] as Map),
            )
          : null,
      how: json['how'] is Map
          ? HowKernelSnapshot.fromJson(
              Map<String, dynamic>.from(json['how'] as Map),
            )
          : null,
      vibe: json['vibe'] is Map
          ? VibeStateSnapshot.fromJson(
              Map<String, dynamic>.from(json['vibe'] as Map),
            )
          : null,
      vibeStack: json['vibe_stack'] is Map
          ? HierarchicalVibeStack.fromJson(
              Map<String, dynamic>.from(json['vibe_stack'] as Map),
            )
          : null,
      why: json['why'] is Map
          ? WhyKernelSnapshot.fromJson(
              Map<String, dynamic>.from(json['why'] as Map),
            )
          : null,
    );
  }
}

class KernelWhyRequest {
  const KernelWhyRequest({
    required this.bundle,
    this.goal,
    this.predictedOutcome,
    this.predictedConfidence,
    this.actualOutcome,
    this.actualOutcomeScore,
    this.coreSignals = const <WhySignal>[],
    this.pheromoneSignals = const <WhySignal>[],
    this.policySignals = const <WhySignal>[],
    this.memoryContext = const <String, dynamic>{},
    this.severity,
  });

  final KernelContextBundleWithoutWhy bundle;
  final String? goal;
  final String? predictedOutcome;
  final double? predictedConfidence;
  final String? actualOutcome;
  final double? actualOutcomeScore;
  final List<WhySignal> coreSignals;
  final List<WhySignal> pheromoneSignals;
  final List<WhySignal> policySignals;
  final Map<String, dynamic> memoryContext;
  final String? severity;

  Map<String, dynamic> toJson() => {
        'bundle': bundle.toJson(),
        if (goal != null) 'goal': goal,
        if (predictedOutcome != null) 'predicted_outcome': predictedOutcome,
        if (predictedConfidence != null)
          'predicted_confidence': predictedConfidence,
        if (actualOutcome != null) 'actual_outcome': actualOutcome,
        if (actualOutcomeScore != null)
          'actual_outcome_score': actualOutcomeScore,
        'core_signals': coreSignals.map((entry) => entry.toJson()).toList(),
        'pheromone_signals':
            pheromoneSignals.map((entry) => entry.toJson()).toList(),
        'policy_signals': policySignals.map((entry) => entry.toJson()).toList(),
        'memory_context': memoryContext,
        if (severity != null) 'severity': severity,
      };
}

class KernelBundleRecord {
  const KernelBundleRecord({
    required this.recordId,
    required this.eventId,
    required this.bundle,
    required this.createdAtUtc,
    this.schemaVersion = 1,
  });

  final String recordId;
  final String eventId;
  final KernelContextBundle bundle;
  final DateTime createdAtUtc;
  final int schemaVersion;

  Map<String, dynamic> toJson() => {
        'record_id': recordId,
        'event_id': eventId,
        'bundle': bundle.toJson(),
        'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
        'schema_version': schemaVersion,
      };

  factory KernelBundleRecord.fromJson(Map<String, dynamic> json) {
    return KernelBundleRecord(
      recordId: json['record_id'] as String? ?? 'unknown_record',
      eventId: json['event_id'] as String? ?? 'unknown_event',
      bundle: KernelContextBundle.fromJson(
        Map<String, dynamic>.from(
          json['bundle'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      createdAtUtc:
          DateTime.tryParse(json['created_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );
  }
}

class WhoRealityProjection extends KernelRealityProjection {
  const WhoRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.who);
}

class WhatRealityProjection extends KernelRealityProjection {
  const WhatRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.what);
}

class WhenRealityProjection extends KernelRealityProjection {
  const WhenRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.when);
}

class WhereRealityProjection extends KernelRealityProjection {
  const WhereRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.where);
}

class WhyRealityProjection extends KernelRealityProjection {
  const WhyRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.why);
}

class HowRealityProjection extends KernelRealityProjection {
  const HowRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.how);
}

class VibeRealityProjection extends KernelRealityProjection {
  const VibeRealityProjection({
    required super.summary,
    required super.confidence,
    super.features = const <String, dynamic>{},
    super.payload = const <String, dynamic>{},
  }) : super(domain: KernelDomain.vibe);
}

class RealityKernelFusionInput {
  const RealityKernelFusionInput({
    required this.envelope,
    required this.bundle,
    required this.who,
    required this.what,
    required this.when,
    required this.where,
    required this.why,
    required this.how,
    this.vibe,
    required this.generatedAtUtc,
    this.localityContainedInWhere = true,
  });

  final KernelEventEnvelope envelope;
  final KernelContextBundle bundle;
  final WhoRealityProjection who;
  final WhatRealityProjection what;
  final WhenRealityProjection when;
  final WhereRealityProjection where;
  final WhyRealityProjection why;
  final HowRealityProjection how;
  final VibeRealityProjection? vibe;
  final DateTime generatedAtUtc;
  final bool localityContainedInWhere;

  Map<String, dynamic> toJson() => {
        'envelope': envelope.toJson(),
        'bundle': bundle.toJson(),
        'who': who.toJson(),
        'what': what.toJson(),
        'when': when.toJson(),
        'where': where.toJson(),
        'why': why.toJson(),
        'how': how.toJson(),
        if (vibe != null) 'vibe': vibe!.toJson(),
        'generated_at_utc': generatedAtUtc.toUtc().toIso8601String(),
        'locality_contained_in_where': localityContainedInWhere,
      };
}

class KernelGovernanceReport {
  const KernelGovernanceReport({
    required this.envelope,
    required this.bundle,
    required this.projections,
    required this.generatedAtUtc,
  });

  final KernelEventEnvelope envelope;
  final KernelContextBundle bundle;
  final List<KernelGovernanceProjection> projections;
  final DateTime generatedAtUtc;

  Map<String, dynamic> toJson() => {
        'envelope': envelope.toJson(),
        'bundle': bundle.toJson(),
        'projections': projections.map((entry) => entry.toJson()).toList(),
        'generated_at_utc': generatedAtUtc.toUtc().toIso8601String(),
      };
}

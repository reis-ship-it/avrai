import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_priority.dart';

class KnowledgeVector {
  const KnowledgeVector({
    required this.senderAgentId,
    required this.insightWeights,
    required this.contextCategory,
    required this.timestamp,
  });

  final String senderAgentId;
  final List<double> insightWeights;
  final String contextCategory;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sender_agent_id': senderAgentId,
        'insight_weights': insightWeights,
        'context_category': contextCategory,
        'timestamp_utc': timestamp.toUtc().toIso8601String(),
      };

  factory KnowledgeVector.fromJson(Map<String, dynamic> json) {
    return KnowledgeVector(
      senderAgentId: json['sender_agent_id'] as String? ?? 'unknown_sender',
      insightWeights: ((json['insight_weights'] as List?) ?? const <dynamic>[])
          .map((entry) => (entry as num?)?.toDouble() ?? 0.0)
          .toList(),
      contextCategory:
          json['context_category'] as String? ?? 'unknown_category',
      timestamp:
          DateTime.tryParse(json['timestamp_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class SecurityClearance {
  const SecurityClearance._({
    required this.isApproved,
    this.sanitizedVector,
    this.rejectionReason,
  });

  final bool isApproved;
  final KnowledgeVector? sanitizedVector;
  final String? rejectionReason;

  factory SecurityClearance.approved(KnowledgeVector vector) {
    return SecurityClearance._(isApproved: true, sanitizedVector: vector);
  }

  factory SecurityClearance.rejected(String reason) {
    return SecurityClearance._(isApproved: false, rejectionReason: reason);
  }
}

class SecurityInterventionClearance {
  const SecurityInterventionClearance({
    required this.isApproved,
    required this.scopeChannels,
    required this.reasonCodes,
    required this.disposition,
    this.evidenceTraceId,
    this.metadata = const <String, dynamic>{},
  });

  final bool isApproved;
  final SecurityScopeChannels scopeChannels;
  final List<String> reasonCodes;
  final SecurityInterventionDisposition disposition;
  final String? evidenceTraceId;
  final Map<String, dynamic> metadata;
}

class CountermeasurePromotionReview {
  const CountermeasurePromotionReview({
    required this.isApproved,
    required this.bundleId,
    required this.targetScope,
    required this.reasonCodes,
    required this.requiredApprovals,
    required this.propagationAuthorized,
    this.metadata = const <String, dynamic>{},
  });

  final bool isApproved;
  final String bundleId;
  final TruthScopeDescriptor targetScope;
  final List<String> reasonCodes;
  final List<String> requiredApprovals;
  final bool propagationAuthorized;
  final Map<String, dynamic> metadata;
}

class GovernanceKernelService {
  GovernanceKernelService({
    KernelGovernanceNativeInvocationBridge? nativeBridge,
    KernelGovernanceNativeExecutionPolicy policy =
        const KernelGovernanceNativeExecutionPolicy(),
  })  : _nativeBridge = nativeBridge ?? KernelGovernanceNativeBridgeBindings(),
        _policy = policy;

  final KernelGovernanceNativeInvocationBridge _nativeBridge;
  final KernelGovernanceNativeExecutionPolicy _policy;
  static const TruthScopeRegistry _truthScopeRegistry = TruthScopeRegistry();

  SecurityClearance interceptOutgoing(KnowledgeVector vector) {
    final payload = _invokeRequired(
      syscall: 'intercept_outgoing_vector',
      payload: <String, dynamic>{'vector': vector.toJson()},
    );
    return _toSecurityClearance(payload);
  }

  SecurityClearance interceptIncoming(KnowledgeVector vector) {
    final payload = _invokeRequired(
      syscall: 'intercept_incoming_vector',
      payload: <String, dynamic>{'vector': vector.toJson()},
    );
    return _toSecurityClearance(payload);
  }

  VibeMutationDecision authorizeVibeMutation({
    required String subjectId,
    required VibeEvidence evidence,
    required String governanceScope,
  }) {
    final payload = _invokeRequired(
      syscall: 'authorize_vibe_mutation',
      payload: <String, dynamic>{
        'subject_id': subjectId,
        'evidence': evidence.toJson(),
        'governance_scope': governanceScope,
      },
    );
    return VibeMutationDecision.fromJson(payload);
  }

  Map<String, dynamic> inspectGovernance({
    required String scope,
    String? subjectId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return _invokeRequired(
      syscall: 'inspect_governance',
      payload: <String, dynamic>{
        'scope': scope,
        if (subjectId != null) 'subject_id': subjectId,
        'metadata': metadata,
      },
    );
  }

  SecurityInterventionClearance authorizeSecurityIntervention({
    required String actionId,
    required SecurityScopeChannels scopeChannels,
    TruthEvidenceEnvelope? evidenceEnvelope,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalizedScopeChannels = _normalizeScopeChannels(scopeChannels);
    final rejectionReasons = _validateSecurityScopeChannels(
      scopeChannels: normalizedScopeChannels,
      evidenceEnvelope: evidenceEnvelope,
    );
    final preflightDisposition = _resolveInterventionDisposition(
      metadata: metadata,
      reasonCodes: rejectionReasons,
    );
    if (rejectionReasons.isNotEmpty) {
      return SecurityInterventionClearance(
        isApproved: false,
        scopeChannels: normalizedScopeChannels,
        reasonCodes: rejectionReasons,
        disposition: preflightDisposition,
        evidenceTraceId: evidenceEnvelope?.traceId,
        metadata: metadata,
      );
    }

    final payload = _invokeRequired(
      syscall: 'authorize_security_intervention',
      payload: <String, dynamic>{
        'action_id': actionId,
        'scope_channels': normalizedScopeChannels.toJson(),
        if (evidenceEnvelope != null)
          'evidence_envelope': evidenceEnvelope.toJson(),
        'metadata': metadata,
      },
    );
    return SecurityInterventionClearance(
      isApproved: payload['approved'] as bool? ?? false,
      scopeChannels: payload['scope_channels'] is Map
          ? SecurityScopeChannels.fromJson(
              Map<String, dynamic>.from(payload['scope_channels'] as Map),
            )
          : normalizedScopeChannels,
      reasonCodes: (payload['reason_codes'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>['governance_rejected'],
      disposition: _resolveInterventionDisposition(
        metadata: Map<String, dynamic>.from(
          payload['metadata'] as Map? ?? metadata,
        ),
        reasonCodes: (payload['reason_codes'] as List?)
                ?.map((entry) => entry.toString())
                .toList(growable: false) ??
            const <String>['governance_rejected'],
      ),
      evidenceTraceId:
          payload['evidence_trace_id']?.toString() ?? evidenceEnvelope?.traceId,
      metadata: Map<String, dynamic>.from(
        payload['metadata'] as Map? ?? metadata,
      ),
    );
  }

  CountermeasurePromotionReview reviewCountermeasureBundle({
    required SecurityCountermeasureBundle bundle,
    required TruthEvidenceEnvelope evidenceEnvelope,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalizedTargetScope = _truthScopeRegistry.normalizeSecurityScope(
      scope: bundle.targetScope,
      metadata: bundle.metadata,
    );
    final normalizedBundle = SecurityCountermeasureBundle(
      bundleId: bundle.bundleId,
      targetScope: normalizedTargetScope,
      allowedStrata: bundle.allowedStrata,
      tenantScope: bundle.tenantScope,
      tenantId: bundle.tenantId,
      expiresAt: bundle.expiresAt,
      rollbackTtl: bundle.rollbackTtl,
      minimumAcknowledgements: bundle.minimumAcknowledgements,
      signature: bundle.signature,
      signedBy: bundle.signedBy,
      signedAt: bundle.signedAt,
      evidenceEnvelopeTraceIds: bundle.evidenceEnvelopeTraceIds,
      requiredApprovals: bundle.requiredApprovals,
      metadata: bundle.metadata,
    );
    final normalizedEvidence = TruthEvidenceEnvelope(
      scope: _truthScopeRegistry.normalizeSecurityScope(
        scope: evidenceEnvelope.scope,
        metadata: evidenceEnvelope.metadata,
      ),
      traceId: evidenceEnvelope.traceId,
      evidenceClass: evidenceEnvelope.evidenceClass,
      privacyLadderTag: evidenceEnvelope.privacyLadderTag,
      sourceRefs: evidenceEnvelope.sourceRefs,
      approvals: evidenceEnvelope.approvals,
      rollbackRefs: evidenceEnvelope.rollbackRefs,
      metadata: evidenceEnvelope.metadata,
    );

    final rejectionReasons = _validateCountermeasureBundle(
      bundle: normalizedBundle,
      evidenceEnvelope: normalizedEvidence,
    );
    if (rejectionReasons.isNotEmpty) {
      return CountermeasurePromotionReview(
        isApproved: false,
        bundleId: normalizedBundle.bundleId,
        targetScope: normalizedBundle.targetScope,
        reasonCodes: rejectionReasons,
        requiredApprovals: normalizedBundle.requiredApprovals,
        propagationAuthorized: false,
        metadata: metadata,
      );
    }

    final payload = _invokeRequired(
      syscall: 'review_countermeasure_bundle',
      payload: <String, dynamic>{
        'bundle': normalizedBundle.toJson(),
        'evidence_envelope': normalizedEvidence.toJson(),
        'metadata': metadata,
      },
    );
    return CountermeasurePromotionReview(
      isApproved: payload['approved'] as bool? ?? false,
      bundleId: payload['bundle_id']?.toString() ?? normalizedBundle.bundleId,
      targetScope: payload['target_scope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(payload['target_scope'] as Map),
            )
          : normalizedBundle.targetScope,
      reasonCodes: (payload['reason_codes'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>['governance_rejected'],
      requiredApprovals: (payload['required_approvals'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          normalizedBundle.requiredApprovals,
      propagationAuthorized:
          payload['propagation_authorized'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(
        payload['metadata'] as Map? ?? metadata,
      ),
    );
  }

  Map<String, dynamic> _invokeRequired({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    _nativeBridge.initialize();
    if (!_nativeBridge.isAvailable) {
      _policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: KernelGovernanceNativeFallbackReason.unavailable,
      );
      throw StateError(
          'Native governance kernel is unavailable for "$syscall".');
    }
    final response = _nativeBridge.invoke(syscall: syscall, payload: payload);
    if (response['handled'] != true) {
      _policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: KernelGovernanceNativeFallbackReason.deferred,
      );
      throw StateError('Native governance kernel did not handle "$syscall".');
    }
    final nativePayload = response['payload'];
    if (nativePayload is Map<String, dynamic>) {
      return nativePayload;
    }
    if (nativePayload is Map) {
      return Map<String, dynamic>.from(nativePayload);
    }
    throw StateError(
      'Native governance kernel returned an invalid payload for "$syscall".',
    );
  }

  SecurityClearance _toSecurityClearance(Map<String, dynamic> payload) {
    final approved = payload['approved'] as bool? ?? false;
    if (!approved) {
      return SecurityClearance.rejected(
        payload['reason'] as String? ?? 'governance_rejected',
      );
    }
    return SecurityClearance.approved(
      KnowledgeVector.fromJson(
        Map<String, dynamic>.from(
          (payload['sanitized_vector'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  SecurityScopeChannels _normalizeScopeChannels(
    SecurityScopeChannels scopeChannels,
  ) {
    return SecurityScopeChannels(
      observationScope: _truthScopeRegistry.normalizeSecurityScope(
        scope: scopeChannels.observationScope,
      ),
      interventionScope: _truthScopeRegistry.normalizeSecurityScope(
        scope: scopeChannels.interventionScope,
      ),
      promotionScope: _truthScopeRegistry.normalizeSecurityScope(
        scope: scopeChannels.promotionScope,
      ),
      propagationScope: _truthScopeRegistry.normalizeSecurityScope(
        scope: scopeChannels.propagationScope,
      ),
    );
  }

  List<String> _validateSecurityScopeChannels({
    required SecurityScopeChannels scopeChannels,
    TruthEvidenceEnvelope? evidenceEnvelope,
  }) {
    final reasons = <String>[];
    final observationScope = scopeChannels.observationScope;
    final interventionScope = scopeChannels.interventionScope;
    final promotionScope = scopeChannels.promotionScope;
    final propagationScope = scopeChannels.propagationScope;

    if (_hasTenantMismatch(
      observationScope: observationScope,
      otherScope: interventionScope,
    )) {
      reasons.add('intervention_scope_tenant_mismatch');
    }
    if (_hasTenantMismatch(
      observationScope: observationScope,
      otherScope: promotionScope,
    )) {
      reasons.add('promotion_scope_tenant_mismatch');
    }
    if (_hasTenantMismatch(
      observationScope: observationScope,
      otherScope: propagationScope,
    )) {
      reasons.add('propagation_scope_tenant_mismatch');
    }
    if (_widensStratum(
      source: observationScope.governanceStratum,
      target: interventionScope.governanceStratum,
    )) {
      reasons.add('intervention_scope_widens_observation');
    }
    if (_widensStratum(
      source: observationScope.governanceStratum,
      target: promotionScope.governanceStratum,
    )) {
      reasons.add('promotion_scope_widens_surveillance');
    }
    if (_widensStratum(
      source: promotionScope.governanceStratum,
      target: propagationScope.governanceStratum,
    )) {
      reasons.add('propagation_scope_exceeds_promotion');
    }
    if (evidenceEnvelope != null &&
        evidenceEnvelope.scope.scopeKey != observationScope.scopeKey) {
      reasons.add('evidence_scope_mismatch');
    }
    return reasons;
  }

  List<String> _validateCountermeasureBundle({
    required SecurityCountermeasureBundle bundle,
    required TruthEvidenceEnvelope evidenceEnvelope,
  }) {
    final reasons = <String>[];
    final targetScope = bundle.targetScope;
    if (targetScope.truthSurfaceKind != TruthSurfaceKind.security) {
      reasons.add('countermeasure_requires_security_scope');
    }
    if (bundle.tenantScope != targetScope.tenantScope) {
      reasons.add('countermeasure_tenant_scope_mismatch');
    }
    if (bundle.tenantScope == TruthTenantScope.trustedPartnerPrivate &&
        (bundle.tenantId == null || bundle.tenantId != targetScope.tenantId)) {
      reasons.add('countermeasure_partner_tenant_missing_or_mismatched');
    }
    if (_hasTenantMismatch(
      observationScope: targetScope,
      otherScope: evidenceEnvelope.scope,
    )) {
      reasons.add('countermeasure_evidence_tenant_mismatch');
    }
    if (!bundle.allowedStrata.contains(targetScope.governanceStratum)) {
      reasons.add('target_scope_not_in_allowed_strata');
    }
    if (bundle.expiresAt != null &&
        bundle.expiresAt!.toUtc().isBefore(DateTime.now().toUtc())) {
      reasons.add('countermeasure_bundle_expired');
    }
    if ((bundle.signature ?? '').isEmpty || bundle.signedAt == null) {
      reasons.add('countermeasure_bundle_unsigned');
    }
    if (bundle.metadata['bypass_air_gap'] == true) {
      reasons.add('countermeasure_cannot_bypass_air_gap');
    }
    final missingApprovals = bundle.requiredApprovals
        .where((approval) => !evidenceEnvelope.approvals.contains(approval))
        .toList(growable: false);
    if (missingApprovals.isNotEmpty) {
      reasons.add('missing_required_approvals');
    }
    if (targetScope.governanceStratum == GovernanceStratum.universal &&
        bundle.requiredApprovals.isEmpty) {
      reasons.add('universal_countermeasure_requires_approvals');
    }
    return reasons;
  }

  bool _hasTenantMismatch({
    required TruthScopeDescriptor observationScope,
    required TruthScopeDescriptor otherScope,
  }) {
    return observationScope.tenantScope != otherScope.tenantScope ||
        observationScope.tenantId != otherScope.tenantId;
  }

  bool _widensStratum({
    required GovernanceStratum source,
    required GovernanceStratum target,
  }) {
    return target.index > source.index;
  }

  SecurityInterventionDisposition _resolveInterventionDisposition({
    required Map<String, dynamic> metadata,
    required List<String> reasonCodes,
  }) {
    const hardStopReasonCodes = <String>{
      'promotion_scope_widens_surveillance',
      'propagation_scope_exceeds_promotion',
      'intervention_scope_tenant_mismatch',
      'promotion_scope_tenant_mismatch',
      'propagation_scope_tenant_mismatch',
      'evidence_scope_mismatch',
      'countermeasure_cannot_bypass_air_gap',
    };
    if (reasonCodes.any(hardStopReasonCodes.contains) ||
        metadata['air_gap_breach'] == true ||
        metadata['kernel_manifest_violation'] == true ||
        metadata['cross_tenant_leak'] == true ||
        metadata['unauthorized_surveillance_widening'] == true ||
        metadata['promotion_provenance_compromise'] == true ||
        metadata['world_scope_exploit'] == true ||
        metadata['universal_scope_exploit'] == true ||
        metadata['failed_containment_within_ttl'] == true ||
        ((metadata['failed_containment_count'] as num?)?.toInt() ?? 0) >= 2) {
      return SecurityInterventionDisposition.hardStop;
    }

    final confidence = (metadata['confidence'] as num?)?.toDouble() ?? 0.0;
    final sandboxOnly = metadata['sandbox_only'] == true;
    final recurrenceCount =
        (metadata['recurrence_count'] as num?)?.toInt() ?? 0;
    if (sandboxOnly || (confidence < 0.45 && recurrenceCount == 0)) {
      return SecurityInterventionDisposition.observe;
    }
    return SecurityInterventionDisposition.boundedDegrade;
  }
}

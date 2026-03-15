import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_priority.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';

class TestKernelGovernanceNativeBridge
    implements KernelGovernanceNativeInvocationBridge {
  const TestKernelGovernanceNativeBridge();

  static const Set<String> _approvedCategories = <String>{
    'spot_affinity',
    'event_resonance',
  };

  static const Set<String> _supportedScopes = <String>{
    'personal',
    'geographic:locality',
    'geographic:district',
    'geographic:city',
    'geographic:region',
    'geographic:country',
    'geographic:global',
    'scoped:university',
    'scoped:campus',
    'scoped:organization',
    'scoped:scene',
    'entity',
  };

  @override
  bool get isAvailable => true;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    return <String, dynamic>{
      'handled': true,
      'payload': switch (syscall) {
        'intercept_outgoing_vector' => _interceptOutgoing(
            Map<String, dynamic>.from(
              (payload['vector'] as Map?) ?? const <String, dynamic>{},
            ),
          ),
        'intercept_incoming_vector' => _interceptIncoming(
            Map<String, dynamic>.from(
              (payload['vector'] as Map?) ?? const <String, dynamic>{},
            ),
          ),
        'authorize_vibe_mutation' => _authorizeVibeMutation(payload),
        'inspect_governance' => _inspectGovernance(payload),
        'authorize_security_intervention' =>
          _authorizeSecurityIntervention(payload),
        'review_countermeasure_bundle' => _reviewCountermeasureBundle(payload),
        _ => <String, dynamic>{
            'approved': false,
            'reason': 'unsupported_syscall:$syscall',
          },
      },
    };
  }

  Map<String, dynamic> _interceptOutgoing(Map<String, dynamic> vector) {
    final category = vector['context_category'] as String? ?? '';
    final weights = ((vector['insight_weights'] as List?) ?? const <dynamic>[])
        .map((entry) => (entry as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);

    if (!_approvedCategories.contains(category)) {
      return <String, dynamic>{
        'approved': false,
        'reason': 'Unauthorized category: $category',
      };
    }
    if (weights.length > 512) {
      return <String, dynamic>{
        'approved': false,
        'reason': 'Vector exceeds maximum dimensionality',
      };
    }

    return <String, dynamic>{
      'approved': true,
      'sanitized_vector': <String, dynamic>{
        ...vector,
        'insight_weights': weights
            .map((entry) => entry.clamp(-1.0, 1.0))
            .toList(growable: false),
      },
    };
  }

  Map<String, dynamic> _interceptIncoming(Map<String, dynamic> vector) {
    final weights = ((vector['insight_weights'] as List?) ?? const <dynamic>[])
        .map((entry) => (entry as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    final timestampUtc = DateTime.tryParse(
      vector['timestamp_utc'] as String? ?? '',
    )?.toUtc();

    if (weights.any((entry) => entry < -1.0 || entry > 1.0)) {
      return <String, dynamic>{
        'approved': false,
        'reason': 'Rejected potential poisoning attempt',
      };
    }
    if (timestampUtc != null &&
        DateTime.now().toUtc().difference(timestampUtc) >
            const Duration(days: 7)) {
      return <String, dynamic>{
        'approved': false,
        'reason': 'Rejected expired vector',
      };
    }

    return <String, dynamic>{
      'approved': true,
      'sanitized_vector': vector,
    };
  }

  Map<String, dynamic> _authorizeVibeMutation(Map<String, dynamic> payload) {
    final subjectId = payload['subject_id'] as String? ?? '';
    final governanceScope =
        payload['governance_scope'] as String? ?? 'personal';
    if (!_supportedScopes.contains(governanceScope)) {
      return _decision(
        allowed: false,
        governanceScope: governanceScope,
        reasonCodes: const <String>['unsupported_governance_scope'],
      );
    }
    if (!_matchesSubjectScope(subjectId, governanceScope)) {
      return _decision(
        allowed: false,
        governanceScope: governanceScope,
        reasonCodes: const <String>['subject_scope_mismatch'],
      );
    }
    return _decision(
      allowed: true,
      governanceScope: governanceScope,
      reasonCodes: const <String>['governance_approved'],
    );
  }

  Map<String, dynamic> _inspectGovernance(Map<String, dynamic> payload) {
    return <String, dynamic>{
      'scope': payload['scope'] as String? ?? 'unknown',
      'subject_id': payload['subject_id'],
      'approved': true,
      'reason_codes': const <String>['governance_inspected'],
      'metadata': Map<String, dynamic>.from(
        (payload['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    };
  }

  Map<String, dynamic> _authorizeSecurityIntervention(
    Map<String, dynamic> payload,
  ) {
    final scopeChannels = SecurityScopeChannels.fromJson(
      Map<String, dynamic>.from(
        payload['scope_channels'] as Map? ?? const <String, dynamic>{},
      ),
    );
    final evidenceEnvelope = payload['evidence_envelope'] is Map
        ? TruthEvidenceEnvelope.fromJson(
            Map<String, dynamic>.from(payload['evidence_envelope'] as Map),
          )
        : null;
    final reasonCodes = <String>[
      if (_widensStratum(
        source: scopeChannels.observationScope.governanceStratum,
        target: scopeChannels.interventionScope.governanceStratum,
      ))
        'intervention_scope_widens_observation',
      if (_widensStratum(
        source: scopeChannels.observationScope.governanceStratum,
        target: scopeChannels.promotionScope.governanceStratum,
      ))
        'promotion_scope_widens_surveillance',
      if (_widensStratum(
        source: scopeChannels.promotionScope.governanceStratum,
        target: scopeChannels.propagationScope.governanceStratum,
      ))
        'propagation_scope_exceeds_promotion',
      if (_hasTenantMismatch(
        left: scopeChannels.observationScope,
        right: scopeChannels.interventionScope,
      ))
        'intervention_scope_tenant_mismatch',
      if (_hasTenantMismatch(
        left: scopeChannels.observationScope,
        right: scopeChannels.promotionScope,
      ))
        'promotion_scope_tenant_mismatch',
      if (_hasTenantMismatch(
        left: scopeChannels.observationScope,
        right: scopeChannels.propagationScope,
      ))
        'propagation_scope_tenant_mismatch',
      if (evidenceEnvelope != null &&
          evidenceEnvelope.scope.scopeKey !=
              scopeChannels.observationScope.scopeKey)
        'evidence_scope_mismatch',
    ];
    return <String, dynamic>{
      'approved': reasonCodes.isEmpty,
      'scope_channels': scopeChannels.toJson(),
      'reason_codes': reasonCodes.isEmpty
          ? const <String>['security_intervention_authorized']
          : reasonCodes,
      'evidence_trace_id': evidenceEnvelope?.traceId,
      'metadata': Map<String, dynamic>.from(
        (payload['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    };
  }

  Map<String, dynamic> _reviewCountermeasureBundle(
    Map<String, dynamic> payload,
  ) {
    final bundle = SecurityCountermeasureBundle.fromJson(
      Map<String, dynamic>.from(
        payload['bundle'] as Map? ?? const <String, dynamic>{},
      ),
    );
    final evidenceEnvelope = TruthEvidenceEnvelope.fromJson(
      Map<String, dynamic>.from(
        payload['evidence_envelope'] as Map? ?? const <String, dynamic>{},
      ),
    );
    final reasonCodes = <String>[
      if (bundle.tenantScope != bundle.targetScope.tenantScope)
        'countermeasure_tenant_scope_mismatch',
      if (bundle.tenantScope == TruthTenantScope.trustedPartnerPrivate &&
          (bundle.tenantId == null ||
              bundle.tenantId != bundle.targetScope.tenantId))
        'countermeasure_partner_tenant_missing_or_mismatched',
      if (!bundle.allowedStrata.contains(bundle.targetScope.governanceStratum))
        'target_scope_not_in_allowed_strata',
      if (_hasTenantMismatch(
        left: bundle.targetScope,
        right: evidenceEnvelope.scope,
      ))
        'countermeasure_evidence_tenant_mismatch',
      if (bundle.metadata['bypass_air_gap'] == true)
        'countermeasure_cannot_bypass_air_gap',
      if (bundle.requiredApprovals.any(
        (approval) => !evidenceEnvelope.approvals.contains(approval),
      ))
        'missing_required_approvals',
      if (bundle.targetScope.governanceStratum == GovernanceStratum.universal &&
          bundle.requiredApprovals.isEmpty)
        'universal_countermeasure_requires_approvals',
    ];
    return <String, dynamic>{
      'approved': reasonCodes.isEmpty,
      'bundle_id': bundle.bundleId,
      'target_scope': bundle.targetScope.toJson(),
      'required_approvals': bundle.requiredApprovals,
      'propagation_authorized': reasonCodes.isEmpty,
      'reason_codes': reasonCodes.isEmpty
          ? const <String>['countermeasure_bundle_approved']
          : reasonCodes,
      'metadata': Map<String, dynamic>.from(
        (payload['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    };
  }

  Map<String, dynamic> _decision({
    required bool allowed,
    required String governanceScope,
    required List<String> reasonCodes,
  }) {
    return <String, dynamic>{
      'state_write_allowed': allowed,
      'dna_write_allowed': allowed,
      'pheromone_write_allowed': allowed,
      'behavior_write_allowed': allowed,
      'affective_write_allowed': allowed,
      'style_write_allowed': allowed,
      'reason_codes': reasonCodes,
      'governance_scope': governanceScope,
      'air_gap_envelope_required': false,
      'schema_version': 1,
    };
  }

  bool _matchesSubjectScope(String subjectId, String governanceScope) {
    if (governanceScope == 'personal') {
      return subjectId.isNotEmpty &&
          !subjectId.contains('-agent:') &&
          !subjectId.startsWith('scene:') &&
          !subjectId.startsWith('entity:');
    }
    return switch (governanceScope) {
      'geographic:locality' => subjectId.startsWith('locality-agent:'),
      'geographic:district' => subjectId.startsWith('district-agent:'),
      'geographic:city' => subjectId.startsWith('city-agent:'),
      'geographic:region' => subjectId.startsWith('region-agent:'),
      'geographic:country' => subjectId.startsWith('country-agent:'),
      'geographic:global' => subjectId.startsWith('global-agent:') ||
          subjectId.startsWith('top-level-agent:'),
      'scoped:university' => subjectId.startsWith('university:'),
      'scoped:campus' => subjectId.startsWith('campus:'),
      'scoped:organization' => subjectId.startsWith('organization:'),
      'scoped:scene' => subjectId.startsWith('scene:'),
      'entity' => subjectId.startsWith('entity:'),
      _ => false,
    };
  }

  bool _widensStratum({
    required GovernanceStratum source,
    required GovernanceStratum target,
  }) {
    return target.index > source.index;
  }

  bool _hasTenantMismatch({
    required TruthScopeDescriptor left,
    required TruthScopeDescriptor right,
  }) {
    return left.tenantScope != right.tenantScope ||
        left.tenantId != right.tenantId;
  }
}

GovernanceKernelService buildTestGovernanceKernelService() {
  return GovernanceKernelService(
    nativeBridge: const TestKernelGovernanceNativeBridge(),
    policy: const KernelGovernanceNativeExecutionPolicy(requireNative: true),
  );
}

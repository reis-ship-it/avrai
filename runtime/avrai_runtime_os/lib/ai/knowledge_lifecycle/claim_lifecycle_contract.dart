// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
enum ClaimLifecycleState {
  hypothesis,
  observed,
  reproduced,
  operational,
  canonical,
  deprecated,
}

enum ClaimDecisionType {
  promote,
  demote,
  quarantine,
  rollback,
}

class ClaimTransitionRequest {
  const ClaimTransitionRequest({
    required this.fromState,
    required this.toState,
    required this.decisionType,
    required this.evidenceCount,
  });

  final ClaimLifecycleState fromState;
  final ClaimLifecycleState toState;
  final ClaimDecisionType decisionType;
  final int evidenceCount;
}

class ClaimTransitionValidationResult {
  const ClaimTransitionValidationResult._(this.isAllowed, this.reasonCode);

  factory ClaimTransitionValidationResult.allowed() {
    return const ClaimTransitionValidationResult._(true, null);
  }

  factory ClaimTransitionValidationResult.denied(String reasonCode) {
    return ClaimTransitionValidationResult._(false, reasonCode);
  }

  final bool isAllowed;
  final String? reasonCode;
}

class ClaimLifecycleTransitionValidator {
  const ClaimLifecycleTransitionValidator();

  static const Map<ClaimLifecycleState, int> _requiredEvidenceByTargetState = {
    ClaimLifecycleState.observed: 1,
    ClaimLifecycleState.reproduced: 2,
    ClaimLifecycleState.operational: 3,
    ClaimLifecycleState.canonical: 4,
  };

  ClaimTransitionValidationResult validate(ClaimTransitionRequest request) {
    if (request.fromState == request.toState) {
      return ClaimTransitionValidationResult.denied('same_state_noop');
    }

    if (request.fromState == ClaimLifecycleState.deprecated) {
      return ClaimTransitionValidationResult.denied(
          'deprecated_terminal_state');
    }

    if (request.toState == ClaimLifecycleState.deprecated) {
      return ClaimTransitionValidationResult.allowed();
    }

    final fromRank = request.fromState.index;
    final toRank = request.toState.index;

    if (toRank > fromRank) {
      return _validatePromotion(request, fromRank, toRank);
    }

    return _validateDemotion(request);
  }

  ClaimTransitionValidationResult _validatePromotion(
    ClaimTransitionRequest request,
    int fromRank,
    int toRank,
  ) {
    if (request.decisionType != ClaimDecisionType.promote) {
      return ClaimTransitionValidationResult.denied(
        'promotion_requires_promote_decision',
      );
    }

    if (toRank != fromRank + 1) {
      return ClaimTransitionValidationResult.denied(
        'promotion_step_skip_not_allowed',
      );
    }

    final minEvidence = _requiredEvidenceByTargetState[request.toState] ?? 1;
    if (request.evidenceCount < minEvidence) {
      return ClaimTransitionValidationResult.denied(
        'insufficient_evidence_for_target_state',
      );
    }

    return ClaimTransitionValidationResult.allowed();
  }

  ClaimTransitionValidationResult _validateDemotion(
    ClaimTransitionRequest request,
  ) {
    const allowedDecisions = {
      ClaimDecisionType.demote,
      ClaimDecisionType.quarantine,
      ClaimDecisionType.rollback,
    };

    if (!allowedDecisions.contains(request.decisionType)) {
      return ClaimTransitionValidationResult.denied(
        'demotion_requires_demote_quarantine_or_rollback',
      );
    }

    if (request.evidenceCount < 1) {
      return ClaimTransitionValidationResult.denied(
          'demotion_requires_evidence');
    }

    return ClaimTransitionValidationResult.allowed();
  }
}

class ClaimLifecycleApiPaths {
  const ClaimLifecycleApiPaths._();

  static const String createClaim = 'POST /claims';
  static const String getClaim = 'GET /claims/{claim_id}';
  static const String addEvidence = 'POST /claims/{claim_id}/evidence';
  static const String transition = 'POST /claims/{claim_id}/transitions';
  static const String audit = 'GET /claims/{claim_id}/audit';
}

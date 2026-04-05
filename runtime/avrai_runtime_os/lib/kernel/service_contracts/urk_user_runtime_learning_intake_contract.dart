// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
/// Deterministic intake gate for user-origin realtime learning signals.
///
/// This kernel contract enforces:
/// - pseudonymous actor-only ingestion,
/// - explicit user-runtime learning consent,
/// - on-device-first payload safety (no raw sensitive body ingestion).
class UrkUserRuntimeLearningIntakeRequest {
  const UrkUserRuntimeLearningIntakeRequest({
    required this.actorAgentId,
    required this.signalType,
    required this.consentScopes,
    required this.containsSensitiveRawContent,
  });

  final String actorAgentId;
  final String signalType;
  final Set<String> consentScopes;
  final bool containsSensitiveRawContent;
}

class UrkUserRuntimeLearningIntakeResult {
  const UrkUserRuntimeLearningIntakeResult({
    required this.accepted,
    required this.reasonCode,
    required this.pseudonymousActorRef,
  });

  final bool accepted;
  final String reasonCode;
  final String pseudonymousActorRef;
}

class UrkUserRuntimeLearningIntakeContract {
  const UrkUserRuntimeLearningIntakeContract();

  static const Set<String> _allowedSignalTypes = <String>{
    'recommendation_feedback',
    'in_app_behavior',
    'calendar_availability_delta',
    'semantic_time_preference',
  };

  UrkUserRuntimeLearningIntakeResult validate(
    UrkUserRuntimeLearningIntakeRequest request,
  ) {
    final actorAgentId = request.actorAgentId.trim();
    if (!actorAgentId.startsWith('agt_') || actorAgentId.length <= 4) {
      return const UrkUserRuntimeLearningIntakeResult(
        accepted: false,
        reasonCode: 'invalid_actor_agent_id',
        pseudonymousActorRef: 'anon_unknown',
      );
    }
    if (!request.consentScopes.contains('user_runtime_learning')) {
      return UrkUserRuntimeLearningIntakeResult(
        accepted: false,
        reasonCode: 'missing_user_runtime_learning_consent',
        pseudonymousActorRef: _toPseudoRef(actorAgentId),
      );
    }
    if (request.containsSensitiveRawContent) {
      return UrkUserRuntimeLearningIntakeResult(
        accepted: false,
        reasonCode: 'sensitive_raw_content_blocked',
        pseudonymousActorRef: _toPseudoRef(actorAgentId),
      );
    }
    if (!_allowedSignalTypes.contains(request.signalType)) {
      return UrkUserRuntimeLearningIntakeResult(
        accepted: false,
        reasonCode: 'unsupported_signal_type',
        pseudonymousActorRef: _toPseudoRef(actorAgentId),
      );
    }
    return UrkUserRuntimeLearningIntakeResult(
      accepted: true,
      reasonCode: 'accepted',
      pseudonymousActorRef: _toPseudoRef(actorAgentId),
    );
  }

  static String _toPseudoRef(String actorAgentId) {
    final tail = actorAgentId.length > 6
        ? actorAgentId.substring(actorAgentId.length - 6)
        : actorAgentId;
    return 'anon_$tail';
  }
}

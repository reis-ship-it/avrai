// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class FederatedForwardingGuard {
  const FederatedForwardingGuard._();

  static bool isEnabled({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
  }) {
    return allowBleSideEffects && federatedLearningParticipationEnabled;
  }
}

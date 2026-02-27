class FederatedForwardingGuard {
  const FederatedForwardingGuard._();

  static bool isEnabled({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
  }) {
    return allowBleSideEffects && federatedLearningParticipationEnabled;
  }
}

import 'package:avrai/core/ai2ai/routing/federated_forwarding_guard.dart';

class FederatedForwardingPrecheck {
  const FederatedForwardingPrecheck._();

  static bool allow({
    required bool allowBleSideEffects,
    required bool federatedLearningParticipationEnabled,
    required String? originId,
    required String localNodeId,
  }) {
    if (!FederatedForwardingGuard.isEnabled(
      allowBleSideEffects: allowBleSideEffects,
      federatedLearningParticipationEnabled:
          federatedLearningParticipationEnabled,
    )) {
      return false;
    }

    return originId != localNodeId;
  }
}

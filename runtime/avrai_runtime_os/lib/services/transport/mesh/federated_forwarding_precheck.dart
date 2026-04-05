// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/federated_forwarding_guard.dart';

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

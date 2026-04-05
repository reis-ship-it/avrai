// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';

class AdaptiveHopGuard {
  const AdaptiveHopGuard._();

  static bool shouldForward({
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required int currentHop,
    required mesh_policy.MessagePriority priority,
    required mesh_policy.MessageType messageType,
    required String geographicScope,
    int? fallbackMaxHopExclusive,
  }) {
    if (adaptiveMeshService != null) {
      return adaptiveMeshService.shouldForwardMessage(
        currentHop: currentHop,
        priority: priority,
        messageType: messageType,
        geographicScope: geographicScope,
      );
    }

    if (fallbackMaxHopExclusive == null) return true;
    return currentHop < fallbackMaxHopExclusive;
  }
}

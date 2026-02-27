import 'package:avrai/core/ai2ai/adaptive_mesh_hop_policy.dart' as mesh_policy;
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';

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

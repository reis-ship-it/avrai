// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart' as mesh_policy;
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/adaptive_hop_guard.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/bloom_loop_guard.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/mesh/gossip_fingerprint.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_network/network/bloom_filter.dart';

class FederatedGossipForwardingGate {
  const FederatedGossipForwardingGate._();

  static bool allow({
    required Map<String, dynamic> payload,
    required int hop,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required OptimizedBloomFilter Function(String scope)
        getOrCreateBloomFilter,
    required AppLogger logger,
    required String logName,
    required mesh_policy.MessagePriority priority,
    required mesh_policy.MessageType messageType,
    int? fallbackMaxHopExclusive,
    String duplicateLabel = 'message',
  }) {
    final fingerprint = GossipFingerprint.fromPayload(payload);
    final bloomFilter = getOrCreateBloomFilter(fingerprint.scope);

    if (!BloomLoopGuard.allowForward(
      bloomFilter: bloomFilter,
      messageHash: fingerprint.messageHash,
      scope: fingerprint.scope,
      logger: logger,
      logName: logName,
      duplicateLabel: duplicateLabel,
    )) {
      return false;
    }

    return AdaptiveHopGuard.shouldForward(
      adaptiveMeshService: adaptiveMeshService,
      currentHop: hop,
      priority: priority,
      messageType: messageType,
      geographicScope: fingerprint.scope,
      fallbackMaxHopExclusive: fallbackMaxHopExclusive,
    );
  }
}

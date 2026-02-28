// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/ai2ai/discovery/peer_candidate_selector.dart';

class MeshForwardingTargetSelector {
  const MeshForwardingTargetSelector._();

  static List<String> select({
    required Iterable<String> discoveredNodeIds,
    Set<String> excludedNodeIds = const <String>{},
    int maxCandidates = 2,
  }) {
    return PeerCandidateSelector.select(
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: excludedNodeIds,
      maxCandidates: maxCandidates,
    );
  }

  static List<String> excludingReceivedFromAndOrigin({
    required Iterable<String> discoveredNodeIds,
    required String receivedFromDeviceId,
    required String originId,
    int maxCandidates = 2,
  }) {
    return select(
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: <String>{receivedFromDeviceId, originId},
      maxCandidates: maxCandidates,
    );
  }

  static List<String> excludingRecipientAndLocalNode({
    required Iterable<String> discoveredNodeIds,
    required String recipientId,
    required String localNodeId,
    int maxCandidates = 2,
  }) {
    return select(
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: <String>{recipientId, localNodeId},
      maxCandidates: maxCandidates,
    );
  }

  static List<String> excludingOptionalOrigin({
    required Iterable<String> discoveredNodeIds,
    required String? originId,
    int maxCandidates = 2,
  }) {
    final excludedNodeIds = <String>{};
    if (originId != null) {
      excludedNodeIds.add(originId);
    }
    return select(
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: excludedNodeIds,
      maxCandidates: maxCandidates,
    );
  }
}

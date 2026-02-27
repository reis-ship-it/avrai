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
}

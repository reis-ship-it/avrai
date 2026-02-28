// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class PeerCandidateSelector {
  const PeerCandidateSelector._();

  static List<String> select({
    required Iterable<String> discoveredNodeIds,
    Set<String> excludedNodeIds = const <String>{},
    int maxCandidates = 2,
  }) {
    return discoveredNodeIds
        .where((id) => !excludedNodeIds.contains(id))
        .take(maxCandidates)
        .toList();
  }
}

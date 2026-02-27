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

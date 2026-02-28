// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
part of 'community_service.dart';

/// Breakdown of a user's true compatibility with a community.
class CommunityTrueCompatibilityBreakdown {
  final double combined;
  final double quantum;
  final double topological;
  final double weaveFit;

  const CommunityTrueCompatibilityBreakdown({
    required this.combined,
    required this.quantum,
    required this.topological,
    required this.weaveFit,
  });
}

class _ScoredCommunity {
  final Community community;
  final double score;

  const _ScoredCommunity({
    required this.community,
    required this.score,
  });
}

class _CachedScore {
  final double score;
  final DateTime cachedAt;
  final double? quantum;
  final double? topological;
  final double? weaveFit;

  const _CachedScore({
    required this.score,
    required this.cachedAt,
    this.quantum,
    this.topological,
    this.weaveFit,
  });
}

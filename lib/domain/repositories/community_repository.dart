import 'package:avrai/core/models/community/community.dart';

/// Community repository abstraction.
///
/// This enables **local-first** behavior while allowing an optional remote
/// backend (e.g., Supabase) behind a feature flag.
abstract class CommunityRepository {
  /// Load all known communities.
  Future<List<Community>> getAllCommunities();

  /// Load a single community by id (returns null if not found).
  Future<Community?> getCommunityById(String communityId);

  /// Create or update a community.
  Future<void> upsertCommunity(Community community);

  /// Delete a community by id.
  Future<void> deleteCommunity(String communityId);

  /// Join/leave membership rows.
  ///
  /// Local implementations may also update cached memberIds/memberCount.
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  });

  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  });

  /// Get community ids a user is a member of (best-effort; may be empty offline).
  Future<Set<String>> getMembershipCommunityIdsForUser({
    required String userId,
  });

  /// Per-member anonymized 12D contributions keyed by agentId (privacy safe).
  Future<Map<String, Map<String, double>>> getVibeContributions({
    required String communityId,
  });

  Future<void> upsertVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
    required Map<String, double> dimensions,
    required int quantizationBins,
  });

  Future<void> removeVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
  });
}


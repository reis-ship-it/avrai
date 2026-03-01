import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/domain/repositories/community_repository.dart';

/// Local-first community repository with optional Supabase sync behind a feature flag.
class HybridCommunityRepository implements CommunityRepository {
  static const String _logName = 'HybridCommunityRepository';

  /// Feature flag: enable Supabase community sync (definitions + own membership + own contribution).
  static const String supabaseCommunitySyncFlag =
      'communities_supabase_sync_v1';

  final CommunityRepository _local;
  final CommunityRepository _remote;
  final FeatureFlagService _flags;

  HybridCommunityRepository({
    required CommunityRepository local,
    required CommunityRepository remote,
    required FeatureFlagService featureFlags,
  })  : _local = local,
        _remote = remote,
        _flags = featureFlags;

  Future<bool> _remoteEnabled({String? userId}) async {
    return _flags.isEnabled(
      supabaseCommunitySyncFlag,
      userId: userId,
      defaultValue: false,
    );
  }

  @override
  Future<List<Community>> getAllCommunities() async {
    final local = await _local.getAllCommunities();

    // Best-effort background refresh from remote.
    if (await _remoteEnabled()) {
      unawaited(_syncCommunitiesFromRemoteToLocal());
    }
    return local;
  }

  @override
  Future<Community?> getCommunityById(String communityId) async {
    final local = await _local.getCommunityById(communityId);
    if (local != null) return local;

    if (await _remoteEnabled()) {
      try {
        final remote = await _remote.getCommunityById(communityId);
        if (remote != null) {
          await _local.upsertCommunity(remote);
          return remote;
        }
      } catch (e, st) {
        developer.log(
          'Remote getCommunityById failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
    return null;
  }

  @override
  Future<void> upsertCommunity(Community community) async {
    await _local.upsertCommunity(community);
    if (await _remoteEnabled(userId: community.founderId)) {
      try {
        await _remote.upsertCommunity(community);
      } catch (e, st) {
        developer.log(
          'Remote upsertCommunity failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> deleteCommunity(String communityId) async {
    await _local.deleteCommunity(communityId);
    if (await _remoteEnabled()) {
      try {
        await _remote.deleteCommunity(communityId);
      } catch (e, st) {
        developer.log(
          'Remote deleteCommunity failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    await _local.joinCommunity(communityId: communityId, userId: userId);
    if (await _remoteEnabled(userId: userId)) {
      try {
        await _remote.joinCommunity(communityId: communityId, userId: userId);
      } catch (e, st) {
        developer.log(
          'Remote joinCommunity failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    await _local.leaveCommunity(communityId: communityId, userId: userId);
    if (await _remoteEnabled(userId: userId)) {
      try {
        await _remote.leaveCommunity(communityId: communityId, userId: userId);
      } catch (e, st) {
        developer.log(
          'Remote leaveCommunity failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<Set<String>> getMembershipCommunityIdsForUser({
    required String userId,
  }) async {
    final local = await _local.getMembershipCommunityIdsForUser(userId: userId);
    if (!await _remoteEnabled(userId: userId)) return local;

    try {
      final remote =
          await _remote.getMembershipCommunityIdsForUser(userId: userId);
      // Best-effort: ensure local includes remote memberships.
      for (final id in remote.difference(local)) {
        await _local.joinCommunity(communityId: id, userId: userId);
      }
      return {...local, ...remote};
    } catch (e, st) {
      developer.log(
        'Remote getMembershipCommunityIdsForUser failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return local;
    }
  }

  @override
  Future<Map<String, Map<String, double>>> getVibeContributions({
    required String communityId,
  }) {
    // Privacy: we keep full contribution maps local-first.
    return _local.getVibeContributions(communityId: communityId);
  }

  @override
  Future<void> upsertVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
    required Map<String, double> dimensions,
    required int quantizationBins,
  }) async {
    await _local.upsertVibeContribution(
      communityId: communityId,
      userId: userId,
      agentId: agentId,
      dimensions: dimensions,
      quantizationBins: quantizationBins,
    );

    if (await _remoteEnabled(userId: userId)) {
      try {
        await _remote.upsertVibeContribution(
          communityId: communityId,
          userId: userId,
          agentId: agentId,
          dimensions: dimensions,
          quantizationBins: quantizationBins,
        );
      } catch (e, st) {
        developer.log(
          'Remote upsertVibeContribution failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> removeVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
  }) async {
    await _local.removeVibeContribution(
      communityId: communityId,
      userId: userId,
      agentId: agentId,
    );

    if (await _remoteEnabled(userId: userId)) {
      try {
        await _remote.removeVibeContribution(
          communityId: communityId,
          userId: userId,
          agentId: agentId,
        );
      } catch (e, st) {
        developer.log(
          'Remote removeVibeContribution failed: $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> _syncCommunitiesFromRemoteToLocal() async {
    try {
      final remote = await _remote.getAllCommunities();
      final local = await _local.getAllCommunities();
      final localById = <String, Community>{
        for (final c in local) c.id: c,
      };

      for (final r in remote) {
        final l = localById[r.id];
        if (l == null) {
          await _local.upsertCommunity(r);
          continue;
        }

        // Merge: keep local-only memberIds; prefer the larger member_count.
        final merged = r.copyWith(
          memberIds: l.memberIds,
          memberCount:
              (r.memberCount > l.memberCount) ? r.memberCount : l.memberCount,
          vibeCentroidDimensions:
              l.vibeCentroidDimensions ?? r.vibeCentroidDimensions,
          vibeCentroidContributors:
              (l.vibeCentroidContributors > r.vibeCentroidContributors)
                  ? l.vibeCentroidContributors
                  : r.vibeCentroidContributors,
        );

        final shouldWrite = r.updatedAt.isAfter(l.updatedAt);
        if (shouldWrite) {
          await _local.upsertCommunity(merged);
        }
      }
    } catch (e, st) {
      developer.log(
        'Sync communities from remote failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}

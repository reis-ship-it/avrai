import 'dart:developer' as developer;

import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/domain/repositories/community_repository.dart';

/// Supabase-backed community repository (remote).
///
/// Intended to be used behind a feature flag in a local-first hybrid repository.
class SupabaseCommunityRepository implements CommunityRepository {
  static const String _logName = 'SupabaseCommunityRepository';

  final SupabaseService _supabase;

  SupabaseCommunityRepository({SupabaseService? supabaseService})
      : _supabase = supabaseService ?? SupabaseService();

  @override
  Future<List<Community>> getAllCommunities() async {
    final client = _supabase.tryGetClient();
    if (client == null) return [];

    final rows = await client.from('communities_v1').select();
    final out = <Community>[];
    for (final r in rows) {
      out.add(_communityFromRow(r));
    }
    return out;
  }

  @override
  Future<Community?> getCommunityById(String communityId) async {
    final client = _supabase.tryGetClient();
    if (client == null) return null;

    final row = await client
        .from('communities_v1')
        .select()
        .eq('id', communityId)
        .maybeSingle();

    if (row is Map<String, dynamic>) {
      return _communityFromRow(row);
    }
    return null;
  }

  @override
  Future<void> upsertCommunity(Community community) async {
    final client = _supabase.tryGetClient();
    if (client == null) return;

    // RLS: community definitions are founder-owned. If the current auth user
    // is not the founder, skip (local-first will still persist locally).
    final currentUser = _supabase.currentUser;
    if (currentUser == null || currentUser.id != community.founderId) {
      return;
    }

    final payload = <String, dynamic>{
      'id': community.id,
      'name': community.name,
      'description': community.description,
      'category': community.category,
      'originating_event_id': community.originatingEventId,
      'originating_event_type': community.originatingEventType.name,
      // best-effort: founderId is a string userId (uuid) in this app layer
      'founder_user_id': community.founderId,
      'original_locality': community.originalLocality,
      'current_localities': community.currentLocalities,
      'member_count': community.memberCount,
      'event_count': community.eventCount,
      'activity_level': community.activityLevel.name,
      'engagement_score': community.engagementScore,
      'diversity_score': community.diversityScore,
      'vibe_centroid': community.vibeCentroidDimensions,
      'vibe_centroid_contributors': community.vibeCentroidContributors,
      'created_at': community.createdAt.toUtc().toIso8601String(),
      'updated_at': community.updatedAt.toUtc().toIso8601String(),
    };

    // RLS: only founder can upsert community definition by default.
    await client.from('communities_v1').upsert(payload);
  }

  @override
  Future<void> deleteCommunity(String communityId) async {
    final client = _supabase.tryGetClient();
    if (client == null) return;
    // Best-effort: RLS will enforce founder ownership; avoid noisy failures
    // when user is not permitted.
    if (_supabase.currentUser == null) return;
    await client.from('communities_v1').delete().eq('id', communityId);
  }

  @override
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    final client = _supabase.tryGetClient();
    if (client == null) return;

    // RLS expects auth.uid() == user_id; userId is included for symmetry.
    await client.from('community_members_v1').upsert({
      'community_id': communityId,
      'user_id': userId,
    });
  }

  @override
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    final client = _supabase.tryGetClient();
    if (client == null) return;

    await client
        .from('community_members_v1')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  @override
  Future<Set<String>> getMembershipCommunityIdsForUser({
    required String userId,
  }) async {
    final client = _supabase.tryGetClient();
    if (client == null) return <String>{};

    final rows = await client
        .from('community_members_v1')
        .select('community_id')
        .eq('user_id', userId);

    final out = <String>{};
    for (final r in rows) {
      final id = r['community_id'];
      if (id is String && id.isNotEmpty) {
        out.add(id);
      }
    }
    return out;
  }

  @override
  Future<Map<String, Map<String, double>>> getVibeContributions({
    required String communityId,
  }) async {
    // Remote store is per-user; to preserve privacy, we do not fetch all members'
    // contributions here. Returning empty is acceptable for hybrid flows because
    // centroid lifecycle is local-first.
    return const {};
  }

  @override
  Future<void> upsertVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
    required Map<String, double> dimensions,
    required int quantizationBins,
  }) async {
    final client = _supabase.tryGetClient();
    if (client == null) return;

    await client.from('community_vibe_contributions_v1').upsert({
      'community_id': communityId,
      'user_id': userId,
      'agent_id': agentId,
      'dimensions': _ensureAllDimensions(dimensions),
      'quantization_bins': quantizationBins,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> removeVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
  }) async {
    final client = _supabase.tryGetClient();
    if (client == null) return;

    // Primary key is (community_id, user_id); agentId is included for symmetry.
    await client
        .from('community_vibe_contributions_v1')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  Community _communityFromRow(Map<String, dynamic> row) {
    OriginatingEventType parseOriginating(dynamic v) {
      final s = (v ?? '').toString();
      if (s == OriginatingEventType.expertiseEvent.name) {
        return OriginatingEventType.expertiseEvent;
      }
      return OriginatingEventType.communityEvent;
    }

    ActivityLevel parseActivity(dynamic v) {
      final s = (v ?? '').toString();
      for (final lvl in ActivityLevel.values) {
        if (lvl.name == s) return lvl;
      }
      return ActivityLevel.active;
    }

    DateTime parseTime(dynamic v) {
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    Map<String, double>? parseDoubleMap(dynamic v) {
      if (v is! Map) return null;
      final out = <String, double>{};
      for (final e in v.entries) {
        final k = e.key?.toString();
        final val = e.value;
        if (k == null || k.isEmpty) continue;
        if (val is num) out[k] = val.toDouble().clamp(0.0, 1.0);
      }
      return out.isEmpty ? null : _ensureAllDimensions(out);
    }

    final id = (row['id'] ?? '').toString();
    if (id.isEmpty) {
      developer.log('Row missing id', name: _logName);
    }

    final createdAt = parseTime(row['created_at']);
    final updatedAt = parseTime(row['updated_at']);

    return Community(
      id: id,
      name: (row['name'] ?? 'Community').toString(),
      description: row['description']?.toString(),
      category: (row['category'] ?? 'Unknown').toString(),
      originatingEventId: (row['originating_event_id'] ?? '').toString(),
      originatingEventType: parseOriginating(row['originating_event_type']),
      memberIds: const [],
      memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
      founderId: (row['founder_user_id'] ?? '').toString(),
      eventIds: const [],
      eventCount: (row['event_count'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      lastEventAt: null,
      engagementScore: (row['engagement_score'] as num?)?.toDouble() ?? 0.0,
      diversityScore: (row['diversity_score'] as num?)?.toDouble() ?? 0.0,
      activityLevel: parseActivity(row['activity_level']),
      originalLocality: (row['original_locality'] ?? 'Unknown').toString(),
      currentLocalities:
          (row['current_localities'] as List?)?.whereType<String>().toList() ??
              const [],
      vibeCentroidDimensions: parseDoubleMap(row['vibe_centroid']),
      vibeCentroidContributors:
          (row['vibe_centroid_contributors'] as num?)?.toInt() ?? 0,
      updatedAt: updatedAt,
    );
  }

  Map<String, double> _ensureAllDimensions(Map<String, double> input) {
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] =
          (input[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
    }
    return dims;
  }
}


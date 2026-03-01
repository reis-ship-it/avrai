import 'dart:developer' as developer;

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/domain/repositories/community_repository.dart';

/// Local-first community repository backed by in-memory state and optional
/// best-effort persistence via `StorageService`.
class LocalCommunityRepository implements CommunityRepository {
  static const String _logName = 'LocalCommunityRepository';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  static const String _communitiesStorageKey = 'communities:all_v1';
  static const String _communityVibeContribsKeyPrefix =
      'community:vibe_contribs_v1:';

  final StorageService? _storage;

  final Map<String, Community> _communities = <String, Community>{};
  bool _hydrated = false;

  final Map<String, Map<String, Map<String, double>>> _vibeContribsCache =
      <String, Map<String, Map<String, double>>>{};

  LocalCommunityRepository({StorageService? storageService})
      : _storage = storageService;

  @override
  Future<List<Community>> getAllCommunities() async {
    await _hydrateIfNeeded();
    return _communities.values.toList();
  }

  @override
  Future<Community?> getCommunityById(String communityId) async {
    await _hydrateIfNeeded();
    return _communities[communityId];
  }

  @override
  Future<void> upsertCommunity(Community community) async {
    await _hydrateIfNeeded();
    _communities[community.id] = community;
    await _persistCommunitiesBestEffort();
  }

  @override
  Future<void> deleteCommunity(String communityId) async {
    await _hydrateIfNeeded();
    _communities.remove(communityId);
    await _persistCommunitiesBestEffort();
  }

  @override
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    await _hydrateIfNeeded();
    final community = _communities[communityId];
    if (community == null) return;
    if (community.memberIds.contains(userId)) return;

    final updated = community.copyWith(
      memberIds: [...community.memberIds, userId],
      memberCount: community.memberCount + 1,
    );
    _communities[communityId] = updated;
    await _persistCommunitiesBestEffort();
  }

  @override
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    await _hydrateIfNeeded();
    final community = _communities[communityId];
    if (community == null) return;
    if (!community.memberIds.contains(userId)) return;

    final updated = community.copyWith(
      memberIds: community.memberIds.where((id) => id != userId).toList(),
      memberCount: (community.memberCount - 1).clamp(0, 1 << 30),
    );
    _communities[communityId] = updated;
    await _persistCommunitiesBestEffort();
  }

  @override
  Future<Set<String>> getMembershipCommunityIdsForUser({
    required String userId,
  }) async {
    await _hydrateIfNeeded();
    final ids = <String>{};
    for (final c in _communities.values) {
      if (c.memberIds.contains(userId)) ids.add(c.id);
    }
    return ids;
  }

  @override
  Future<Map<String, Map<String, double>>> getVibeContributions({
    required String communityId,
  }) async {
    if (_vibeContribsCache.containsKey(communityId)) {
      return Map<String, Map<String, double>>.from(
        _vibeContribsCache[communityId]!,
      );
    }

    final key = _vibeContribsStorageKey(communityId);
    final raw = _storage?.getObject<dynamic>(key);
    final parsed = <String, Map<String, double>>{};

    if (raw is Map) {
      for (final entry in raw.entries) {
        final agentId = entry.key?.toString();
        final v = entry.value;
        if (agentId == null || agentId.isEmpty) continue;
        if (v is Map) {
          final dims = <String, double>{};
          for (final e in v.entries) {
            final k = e.key?.toString();
            final val = e.value;
            if (k == null || k.isEmpty) continue;
            if (val is num) {
              dims[k] = val.toDouble().clamp(0.0, 1.0);
            }
          }
          parsed[agentId] = _ensureAllDimensions(dims);
        }
      }
    }

    _vibeContribsCache[communityId] =
        Map<String, Map<String, double>>.from(parsed);
    return parsed;
  }

  @override
  Future<void> upsertVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
    required Map<String, double> dimensions,
    required int quantizationBins,
  }) async {
    final contribs = await getVibeContributions(communityId: communityId);
    // Note: local store is keyed by agentId; userId is included for symmetry with
    // remote backends and for audit/debug.
    if (userId.isEmpty) {
      _logger.warn('Empty userId for vibe contribution upsert', tag: _logName);
    }
    contribs[agentId] = _quantizeDimensions(_ensureAllDimensions(dimensions),
        bins: quantizationBins);
    await _persistVibeContributionsBestEffort(
      communityId: communityId,
      contributions: contribs,
    );
  }

  @override
  Future<void> removeVibeContribution({
    required String communityId,
    required String userId,
    required String agentId,
  }) async {
    if (userId.isEmpty) {
      _logger.warn('Empty userId for vibe contribution remove', tag: _logName);
    }
    final contribs = await getVibeContributions(communityId: communityId);
    contribs.remove(agentId);
    await _persistVibeContributionsBestEffort(
      communityId: communityId,
      contributions: contribs,
    );
  }

  String _vibeContribsStorageKey(String communityId) =>
      '$_communityVibeContribsKeyPrefix$communityId';

  Future<void> _hydrateIfNeeded() async {
    if (_hydrated) return;
    _hydrated = true;

    if (_storage == null) return;
    try {
      final jsonList = _storage.getObject<List<dynamic>>(
        _communitiesStorageKey,
      );
      if (jsonList == null) return;

      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          final community = Community.fromJson(item);
          _communities[community.id] = community;
        }
      }
    } catch (e, st) {
      developer.log(
        'Failed to hydrate communities from storage: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _persistCommunitiesBestEffort() async {
    if (_storage == null) return;
    try {
      final list = _communities.values.map((c) => c.toJson()).toList();
      await _storage.setObject(_communitiesStorageKey, list);
    } catch (e, st) {
      // Best-effort: do not fail core flows if storage fails.
      _logger.warn(
        'Failed to persist communities to storage: $e',
        tag: _logName,
      );
      developer.log(
        'Persist communities failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _persistVibeContributionsBestEffort({
    required String communityId,
    required Map<String, Map<String, double>> contributions,
  }) async {
    _vibeContribsCache[communityId] =
        Map<String, Map<String, double>>.from(contributions);

    if (_storage == null) return;
    try {
      final key = _vibeContribsStorageKey(communityId);
      final payload = <String, dynamic>{};
      for (final entry in contributions.entries) {
        payload[entry.key] = entry.value;
      }
      await _storage.setObject(key, payload);
    } catch (e) {
      _logger.warn(
        'Failed to persist community vibe contributions: $e',
        tag: _logName,
      );
    }
  }

  Map<String, double> _ensureAllDimensions(Map<String, double> input) {
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] =
          (input[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
    }
    return dims;
  }

  Map<String, double> _quantizeDimensions(
    Map<String, double> dims, {
    required int bins,
  }) {
    final safeBins = bins < 2 ? 2 : bins;
    final denom = (safeBins - 1).toDouble();

    final out = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      final v =
          (dims[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
      final q = (v * denom).round() / denom;
      out[d] = q.clamp(0.0, 1.0);
    }
    return out;
  }
}

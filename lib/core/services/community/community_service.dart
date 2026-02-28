import 'dart:async';
import 'dart:math' as math;

import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/models/community/community_event.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/geographic/geographic_expansion.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/domain/repositories/community_repository.dart';
import 'package:avrai_knot/models/knot/community_metrics.dart';
import 'package:avrai_knot/models/knot/fabric_cluster.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/geographic/geographic_expansion_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_core/services/community_reader.dart';

part 'community_service_compat_models.dart';

/// Community Service
///
/// Manages communities that form from events (people who attend together).
///
/// **Philosophy Alignment:**
/// - Events naturally create communities (doors open from events)
/// - Communities form organically from successful events
/// - People find their communities through events
/// - Communities can organize as clubs when structure is needed
///
/// **Key Features:**
/// - Auto-create community from successful events
/// - Manage community members (add, remove, get, check membership)
/// - Manage community events (add, get, get upcoming)
/// - Track community growth (member growth, event growth)
/// - Calculate community metrics (engagement, diversity)
/// - Community management (get, update, delete)
class CommunityService implements CommunityReader {
  static const String _logName = 'CommunityService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // In-memory storage (in production, use database)
  final Map<String, Community> _communities = {};
  static const String _communitiesStorageKey = 'communities:all_v1';
  final StorageService? _storageService;
  bool _storageHydrated = false;

  // Community vibe contributions (privacy-safe, per-member).
  //
  // We store anonymized 12D contributions keyed by (communityId, agentId) so we
  // can update the community centroid on join/leave without requiring access to
  // full member profiles.
  static const String _communityVibeContribsKeyPrefix =
      'community:vibe_contribs_v1:';
  final Map<String, Map<String, Map<String, double>>> _vibeContribsCache =
      <String, Map<String, Map<String, double>>>{};

  // Cache true-compat scores for ranking (best-effort, short TTL).
  static const Duration _trueCompatCacheTtl = Duration(minutes: 5);
  final Map<String, _CachedScore> _trueCompatCache = <String, _CachedScore>{};

  final GeographicExpansionService _expansionService;
  final KnotFabricService? _knotFabricService;
  final KnotStorageService? _knotStorageService;
  final AtomicClockService _atomicClock;
  final CommunityRepository? _repository;
  final LedgerRecorderServiceV0 _ledger;

  CommunityService({
    GeographicExpansionService? expansionService,
    KnotFabricService? knotFabricService,
    KnotStorageService? knotStorageService,
    StorageService? storageService,
    AtomicClockService? atomicClockService,
    CommunityRepository? repository,
    LedgerRecorderServiceV0? ledgerRecorder,
  })  : _expansionService = expansionService ?? GeographicExpansionService(),
        _knotFabricService = knotFabricService,
        _knotStorageService = knotStorageService,
        _storageService = storageService,
        _atomicClock = atomicClockService ?? _resolveAtomicClockService(),
        _repository = repository,
        _ledger = ledgerRecorder ??
            LedgerRecorderServiceV0(
              supabaseService: SupabaseService(),
              agentIdService: AgentIdService(),
              storage: StorageService.instance,
            );

  Future<void> _tryLedgerAppendForUser({
    required String expectedOwnerUserId,
    required String eventType,
    required String entityType,
    required String entityId,
    String? category,
    String? cityCode,
    String? localityCode,
    required Map<String, Object?> payload,
  }) async {
    try {
      final currentUserId = SupabaseService().currentUser?.id;
      if (currentUserId == null || currentUserId != expectedOwnerUserId) {
        return;
      }

      await _ledger.append(
        domain: LedgerDomainV0.expertise,
        eventType: eventType,
        occurredAt: DateTime.now(),
        payload: payload,
        entityType: entityType,
        entityId: entityId,
        category: category,
        cityCode: cityCode,
        localityCode: localityCode,
        correlationId: entityId,
      );
    } catch (e) {
      _logger.warning(
        'Ledger write skipped/failed for $eventType: ${e.toString()}',
        tag: _logName,
      );
    }
  }

  static AtomicClockService _resolveAtomicClockService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AtomicClockService>()) {
        return sl<AtomicClockService>();
      }
    } catch (_) {
      // Fall through.
    }
    return AtomicClockService();
  }

  Future<DateTime> _now() async {
    try {
      final ts = await _atomicClock.getAtomicTimestamp();
      return ts.serverTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  /// List all communities (persistence-backed when available).
  ///
  /// This is the primitive used by community discovery flows (and by knot-tribe
  /// onboarding once wired).
  @override
  Future<List<Community>> getAllCommunities({int maxResults = 200}) async {
    final all = await _getAllCommunities();
    all.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return all.take(maxResults).toList();
  }

  /// Upsert a community record (persistence-backed when available).
  ///
  /// Useful for sync/admin tooling and for tests that need to seed communities.
  Future<void> upsertCommunity(Community community) async {
    await _saveCommunity(community);
    _invalidateCommunityCaches(community.id);
  }

  /// Auto-create community from successful event
  ///
  /// Creates a community when an event is successful (meets success criteria).
  ///
  /// **Success Criteria:**
  /// - Event had X+ attendees (default: 5)
  /// - Event had Y+ repeat attendees (default: 2)
  /// - Event had high engagement (engagement score >= 0.6)
  /// - Event host wants to create community (optional)
  ///
  /// **What Gets Created:**
  /// - Community linked to originating event
  /// - Event host becomes founder
  /// - Event attendees become initial members
  /// - Community name based on event title/category
  Future<Community> createCommunityFromEvent({
    required ExpertiseEvent event,
    int minAttendees = 5,
    int minRepeatAttendees = 2,
    double minEngagementScore = 0.6,
    bool hostWantsCommunity = true,
  }) async {
    try {
      _logger.info(
        'Creating community from event: ${event.id}',
        tag: _logName,
      );

      // Determine event type
      OriginatingEventType eventType;
      if (event is CommunityEvent) {
        eventType = OriginatingEventType.communityEvent;
      } else {
        eventType = OriginatingEventType.expertiseEvent;
      }

      // Check success criteria
      final meetsAttendeeCriteria = event.attendeeCount >= minAttendees;

      // For CommunityEvent, check repeat attendees and engagement
      int repeatAttendees = 0;
      double engagementScore = 0.0;
      if (event is CommunityEvent) {
        repeatAttendees = event.repeatAttendeesCount;
        engagementScore = event.engagementScore;
      }

      final meetsRepeatAttendeeCriteria = repeatAttendees >= minRepeatAttendees;
      final meetsEngagementCriteria = engagementScore >= minEngagementScore;

      // Check if event meets success criteria
      if (!meetsAttendeeCriteria) {
        throw Exception(
          'Event must have at least $minAttendees attendees to create community',
        );
      }

      // For CommunityEvent, also check repeat attendees and engagement
      if (event is CommunityEvent) {
        if (!meetsRepeatAttendeeCriteria) {
          throw Exception(
            'Event must have at least $minRepeatAttendees repeat attendees to create community',
          );
        }
        if (!meetsEngagementCriteria) {
          throw Exception(
            'Event must have engagement score >= $minEngagementScore to create community',
          );
        }
      }

      // Extract locality from event location
      String originalLocality = 'Unknown';
      if (event.location != null && event.location!.isNotEmpty) {
        // Location format: "Locality, City, State, Country" or "Locality, City"
        final parts = event.location!.split(',');
        originalLocality = parts.first.trim();
      }

      // Create community name from event
      final communityName = '${event.category} Community - ${event.title}';

      // Create community
      final now = await _now();
      final community = Community(
        id: _generateCommunityId(),
        name: communityName,
        description: 'Community formed from event: ${event.title}',
        category: event.category,
        originatingEventId: event.id,
        originatingEventType: eventType,
        memberIds: [event.host.id, ...event.attendeeIds],
        memberCount: event.attendeeCount + 1, // +1 for host
        founderId: event.host.id,
        eventIds: [event.id],
        eventCount: 1,
        memberGrowthRate: 0.0,
        eventGrowthRate: 0.0,
        createdAt: now,
        lastEventAt: event.startTime,
        engagementScore: event is CommunityEvent ? event.engagementScore : 0.0,
        diversityScore: event is CommunityEvent ? event.diversityMetrics : 0.0,
        activityLevel: ActivityLevel.active,
        originalLocality: originalLocality,
        currentLocalities: [originalLocality],
        updatedAt: now,
      );

      // Save community
      await _saveCommunity(community);

      // Best-effort dual-write to ledger (must never block UX).
      unawaited(_tryLedgerAppendForUser(
        expectedOwnerUserId: community.founderId,
        eventType: 'community_created_from_event',
        entityType: 'community',
        entityId: community.id,
        category: community.category,
        cityCode: event.cityCode,
        localityCode: event.localityCode,
        payload: <String, Object?>{
          'community_id': community.id,
          'originating_event_id': event.id,
          'originating_event_type': eventType.name,
          'min_attendees': minAttendees,
          if (event is CommunityEvent)
            'min_repeat_attendees': minRepeatAttendees,
          if (event is CommunityEvent)
            'min_engagement_score': minEngagementScore,
          'host_wants_community': hostWantsCommunity,
          'attendee_count': event.attendeeCount,
          'repeat_attendees_count':
              event is CommunityEvent ? event.repeatAttendeesCount : 0,
          'engagement_score':
              event is CommunityEvent ? event.engagementScore : 0.0,
          'diversity_score':
              event is CommunityEvent ? event.diversityMetrics : 0.0,
          'original_locality': community.originalLocality,
        },
      ));

      _logger.info('Created community: ${community.id}', tag: _logName);
      return community;
    } catch (e) {
      _logger.error('Error creating community from event',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Add member to community
  ///
  /// **Note:** Retrieves latest community from storage to ensure correct memberCount
  Future<void> addMember(Community community, String userId) async {
    try {
      _logger.info(
        'Adding member $userId to community ${community.id}',
        tag: _logName,
      );

      final before = await getCommunityById(community.id);
      if (before == null) {
        throw Exception('Community not found: ${community.id}');
      }

      if (before.memberIds.contains(userId)) {
        _logger.warning(
          'User $userId is already a member of community ${community.id}',
          tag: _logName,
        );
        return;
      }

      // Local-first: update membership; optional repository may also sync remotely.
      if (_repository != null) {
        await _repository.joinCommunity(
          communityId: community.id,
          userId: userId,
        );
      }

      final latestCommunity = await getCommunityById(community.id) ?? before;

      final now = await _now();
      Map<String, double>? nextCentroid =
          latestCommunity.vibeCentroidDimensions;
      int nextContributors = latestCommunity.vibeCentroidContributors;

      // Best-effort: update privacy-safe centroid via per-member contribution map
      // so we can also support leave updates deterministically.
      try {
        final agentIdService = _tryGetAgentIdService();
        final personalityLearning = _tryGetPersonalityLearning();
        if (agentIdService != null && personalityLearning != null) {
          final agentId = await agentIdService.getUserAgentId(userId);
          final profile =
              await personalityLearning.initializePersonality(userId);
          final dims = _ensureAllDimensions(profile.dimensions);
          final anon = UserVibe.fromPersonalityProfile(userId, dims)
              .anonymizedDimensions;

          final quantized = _quantizeDimensions(anon, bins: 64);
          if (_repository != null) {
            await _repository.upsertVibeContribution(
              communityId: community.id,
              userId: userId,
              agentId: agentId,
              dimensions: quantized,
              quantizationBins: 64,
            );
          } else {
            final contribs = await _loadCommunityVibeContributions(
              communityId: community.id,
            );
            contribs[agentId] = quantized;
            await _persistCommunityVibeContributions(
              communityId: community.id,
              contributions: contribs,
            );
          }

          final contribs = _repository != null
              ? await _repository
                  .getVibeContributions(communityId: community.id)
              : await _loadCommunityVibeContributions(
                  communityId: community.id);
          final centroid = _computeCentroidFromContributions(contribs);
          nextCentroid = centroid.isEmpty ? null : centroid;
          nextContributors = contribs.length;
        }
      } catch (_) {
        // Ignore centroid update failures; membership must still succeed.
      }

      final hasMember = latestCommunity.memberIds.contains(userId);
      final nextMemberIds = hasMember
          ? latestCommunity.memberIds
          : [...latestCommunity.memberIds, userId];
      final nextMemberCount = hasMember
          ? latestCommunity.memberCount
          : (latestCommunity.memberCount + 1);

      final updated = latestCommunity.copyWith(
        memberIds: nextMemberIds,
        memberCount: nextMemberCount,
        vibeCentroidDimensions: nextCentroid,
        vibeCentroidContributors: nextContributors,
        updatedAt: now,
      );

      await _saveCommunity(updated);
      _invalidateCommunityCaches(updated.id);
      _logger.info('Added member to community', tag: _logName);
    } catch (e) {
      _logger.error('Error adding member', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove member from community
  Future<void> removeMember(Community community, String userId) async {
    try {
      _logger.info(
        'Removing member $userId from community ${community.id}',
        tag: _logName,
      );

      final before = await getCommunityById(community.id);
      if (before == null) {
        throw Exception('Community not found: ${community.id}');
      }

      if (!before.memberIds.contains(userId)) {
        _logger.warning(
          'User $userId is not a member of community ${community.id}',
          tag: _logName,
        );
        return;
      }

      // Cannot remove founder
      if (before.founderId == userId) {
        throw Exception('Cannot remove founder from community');
      }

      // Local-first: update membership; optional repository may also sync remotely.
      if (_repository != null) {
        await _repository.leaveCommunity(
          communityId: community.id,
          userId: userId,
        );
      }

      final latestCommunity = await getCommunityById(community.id) ?? before;

      final now = await _now();
      Map<String, double>? nextCentroid =
          latestCommunity.vibeCentroidDimensions;
      int nextContributors = latestCommunity.vibeCentroidContributors;

      // Best-effort: remove contribution + recompute centroid.
      try {
        final agentIdService = _tryGetAgentIdService();
        if (agentIdService != null) {
          final agentId = await agentIdService.getUserAgentId(userId);
          if (_repository != null) {
            await _repository.removeVibeContribution(
              communityId: community.id,
              userId: userId,
              agentId: agentId,
            );
          } else {
            final contribs = await _loadCommunityVibeContributions(
              communityId: community.id,
            );
            contribs.remove(agentId);
            await _persistCommunityVibeContributions(
              communityId: community.id,
              contributions: contribs,
            );
          }

          final contribs = _repository != null
              ? await _repository
                  .getVibeContributions(communityId: community.id)
              : await _loadCommunityVibeContributions(
                  communityId: community.id);
          final centroid = _computeCentroidFromContributions(contribs);
          nextCentroid = centroid.isEmpty ? null : centroid;
          nextContributors = contribs.length;
        }
      } catch (_) {
        // Ignore; removal must still succeed.
      }

      final stillHasMember = latestCommunity.memberIds.contains(userId);
      final nextMemberIds = stillHasMember
          ? latestCommunity.memberIds.where((id) => id != userId).toList()
          : latestCommunity.memberIds;
      final nextMemberCount = stillHasMember
          ? (latestCommunity.memberCount - 1).clamp(0, 1 << 30)
          : latestCommunity.memberCount;

      final updated = latestCommunity.copyWith(
        memberIds: nextMemberIds,
        memberCount: nextMemberCount,
        vibeCentroidDimensions: nextCentroid,
        clearVibeCentroidDimensions: nextContributors == 0,
        vibeCentroidContributors: nextContributors,
        updatedAt: now,
      );

      await _saveCommunity(updated);
      _invalidateCommunityCaches(updated.id);
      _logger.info('Removed member from community', tag: _logName);
    } catch (e) {
      _logger.error('Error removing member', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Record/update a user's privacy-safe vibe contribution for a community.
  ///
  /// This supports deterministic centroid lifecycle updates in cases where the
  /// caller can provide anonymized dimensions directly (e.g., future sync or
  /// device capability gates).
  Future<void> recordCommunityVibeContribution({
    required String communityId,
    required String userId,
    required Map<String, double> anonymizedDimensions,
    int quantizationBins = 64,
  }) async {
    final community = await getCommunityById(communityId);
    if (community == null) return;
    if (!community.isMember(userId)) return;

    final agentIdService = _tryGetAgentIdService();
    if (agentIdService == null) return;

    final agentId = await agentIdService.getUserAgentId(userId);
    final quantized = _quantizeDimensions(
      _ensureAllDimensions(anonymizedDimensions),
      bins: quantizationBins,
    );
    if (_repository != null) {
      await _repository.upsertVibeContribution(
        communityId: communityId,
        userId: userId,
        agentId: agentId,
        dimensions: quantized,
        quantizationBins: quantizationBins,
      );
    } else {
      final contribs =
          await _loadCommunityVibeContributions(communityId: communityId);
      contribs[agentId] = quantized;
      await _persistCommunityVibeContributions(
        communityId: communityId,
        contributions: contribs,
      );
    }

    final contribs = _repository != null
        ? await _repository.getVibeContributions(communityId: communityId)
        : await _loadCommunityVibeContributions(communityId: communityId);
    final centroid = _computeCentroidFromContributions(contribs);
    final now = await _now();
    await _saveCommunity(
      community.copyWith(
        vibeCentroidDimensions: centroid.isEmpty ? null : centroid,
        clearVibeCentroidDimensions: centroid.isEmpty,
        vibeCentroidContributors: contribs.length,
        updatedAt: now,
      ),
    );
    _invalidateCommunityCaches(communityId);
  }

  /// Remove a user's privacy-safe vibe contribution for a community and recompute centroid.
  Future<void> removeCommunityVibeContribution({
    required String communityId,
    required String userId,
  }) async {
    final community = await getCommunityById(communityId);
    if (community == null) return;

    final agentIdService = _tryGetAgentIdService();
    if (agentIdService == null) return;

    final agentId = await agentIdService.getUserAgentId(userId);
    if (_repository != null) {
      await _repository.removeVibeContribution(
        communityId: communityId,
        userId: userId,
        agentId: agentId,
      );
    } else {
      final contribs =
          await _loadCommunityVibeContributions(communityId: communityId);
      contribs.remove(agentId);
      await _persistCommunityVibeContributions(
        communityId: communityId,
        contributions: contribs,
      );
    }

    final contribs = _repository != null
        ? await _repository.getVibeContributions(communityId: communityId)
        : await _loadCommunityVibeContributions(communityId: communityId);
    final centroid = _computeCentroidFromContributions(contribs);
    final now = await _now();
    await _saveCommunity(
      community.copyWith(
        vibeCentroidDimensions: centroid.isEmpty ? null : centroid,
        clearVibeCentroidDimensions: centroid.isEmpty,
        vibeCentroidContributors: contribs.length,
        updatedAt: now,
      ),
    );
    _invalidateCommunityCaches(communityId);
  }

  /// Get all members of a community
  List<String> getMembers(Community community) {
    return community.memberIds;
  }

  /// Check if user is a member
  bool isMember(Community community, String userId) {
    return community.isMember(userId);
  }

  /// Add event to community
  Future<void> addEvent(Community community, String eventId) async {
    try {
      _logger.info(
        'Adding event $eventId to community ${community.id}',
        tag: _logName,
      );

      // Retrieve latest community from storage to ensure we have the correct eventCount
      final latestCommunity = await getCommunityById(community.id);
      if (latestCommunity == null) {
        throw Exception('Community not found: ${community.id}');
      }

      if (latestCommunity.eventIds.contains(eventId)) {
        _logger.warning(
          'Event $eventId is already in community ${community.id}',
          tag: _logName,
        );
        return;
      }

      final now = await _now();
      final updated = latestCommunity.copyWith(
        eventIds: [...latestCommunity.eventIds, eventId],
        eventCount: latestCommunity.eventCount + 1,
        lastEventAt: now,
        updatedAt: now,
      );

      await _saveCommunity(updated);
      _invalidateCommunityCaches(updated.id);
      _logger.info('Added event to community', tag: _logName);
    } catch (e) {
      _logger.error('Error adding event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all events hosted by community
  List<String> getEvents(Community community) {
    return community.eventIds;
  }

  /// Get upcoming events (requires event service to filter by date)
  /// This is a placeholder - actual implementation would filter by event dates
  List<String> getUpcomingEvents(Community community) {
    // In production, would filter by event dates using event service
    return community.eventIds;
  }

  /// Update growth metrics
  ///
  /// **Note:** Retrieves latest community from storage to ensure we update the correct version
  Future<void> updateGrowthMetrics(
    Community community, {
    double? memberGrowthRate,
    double? eventGrowthRate,
  }) async {
    try {
      _logger.info(
        'Updating growth metrics for community ${community.id}',
        tag: _logName,
      );

      // Retrieve latest community from storage to ensure we update the correct version
      final latestCommunity = await getCommunityById(community.id);
      if (latestCommunity == null) {
        throw Exception('Community not found: ${community.id}');
      }

      final now = await _now();
      final updated = latestCommunity.copyWith(
        memberGrowthRate: memberGrowthRate ?? latestCommunity.memberGrowthRate,
        eventGrowthRate: eventGrowthRate ?? latestCommunity.eventGrowthRate,
        updatedAt: now,
      );

      await _saveCommunity(updated);
      _logger.info('Updated growth metrics', tag: _logName);
    } catch (e) {
      _logger.error('Error updating growth metrics', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate engagement score
  ///
  /// Engagement score is based on:
  /// - Member activity (attendance, participation)
  /// - Event frequency
  /// - Member retention
  double calculateEngagementScore(Community community) {
    double score = 0.0;

    // Member activity (40%)
    // Based on member count and growth
    final memberActivity = (community.memberCount / 50.0).clamp(0.0, 1.0);
    score += memberActivity * 0.4;

    // Event frequency (30%)
    // Based on event count and recency
    final eventFrequency = (community.eventCount / 10.0).clamp(0.0, 1.0);
    score += eventFrequency * 0.3;

    // Member retention (30%)
    // Based on member growth rate
    score += community.memberGrowthRate * 0.3;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate diversity score
  ///
  /// Diversity score is based on:
  /// - Member diversity (from event diversity metrics)
  /// - Geographic diversity (multiple localities)
  double calculateDiversityScore(Community community) {
    double score = 0.0;

    // Member diversity (60%)
    // Use existing diversity score from community
    score += community.diversityScore * 0.6;

    // Geographic diversity (40%)
    // Based on number of localities
    final localityCount = community.currentLocalities.length;
    final geographicDiversity = (localityCount / 5.0).clamp(0.0, 1.0);
    score += geographicDiversity * 0.4;

    return score.clamp(0.0, 1.0);
  }

  /// Get community by ID
  Future<Community?> getCommunityById(String communityId) async {
    try {
      if (_repository != null) {
        return await _repository.getCommunityById(communityId);
      }
      final allCommunities = await _getAllCommunities();
      return allCommunities.firstWhere(
        (c) => c.id == communityId,
        orElse: () => throw Exception('Community not found'),
      );
    } catch (e) {
      _logger.error('Error getting community by ID', error: e, tag: _logName);
      return null;
    }
  }

  /// Get communities by founder
  Future<List<Community>> getCommunitiesByFounder(String founderId) async {
    try {
      final allCommunities = await _getAllCommunities();
      return allCommunities.where((c) => c.founderId == founderId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error(
        'Error getting communities by founder',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get communities by category
  Future<List<Community>> getCommunitiesByCategory(
    String category, {
    int maxResults = 20,
  }) async {
    try {
      final allCommunities = await _getAllCommunities();
      return allCommunities
          .where((c) => c.category == category)
          .take(maxResults)
          .toList()
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } catch (e) {
      _logger.error(
        'Error getting communities by category',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Update community details
  Future<Community> updateCommunity({
    required Community community,
    String? name,
    String? description,
    List<String>? currentLocalities,
  }) async {
    try {
      _logger.info('Updating community: ${community.id}', tag: _logName);

      final now = await _now();
      final updated = community.copyWith(
        name: name,
        description: description,
        currentLocalities: currentLocalities,
        updatedAt: now,
      );

      await _saveCommunity(updated);
      _invalidateCommunityCaches(updated.id);
      _logger.info('Updated community', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating community', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Delete community (only if empty)
  Future<void> deleteCommunity(Community community) async {
    try {
      _logger.info('Deleting community: ${community.id}', tag: _logName);

      // Only allow deletion if community is empty
      if (community.memberCount > 0) {
        throw Exception('Cannot delete community with members');
      }

      if (community.eventCount > 0) {
        throw Exception('Cannot delete community with events');
      }

      await _deleteCommunity(community.id);
      _invalidateCommunityCaches(community.id);
      _logger.info('Deleted community', tag: _logName);
    } catch (e) {
      _logger.error('Error deleting community', error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods

  String _generateCommunityId() {
    return 'community_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _vibeContribsStorageKey(String communityId) =>
      '$_communityVibeContribsKeyPrefix$communityId';

  Future<Map<String, Map<String, double>>> _loadCommunityVibeContributions({
    required String communityId,
  }) async {
    if (_vibeContribsCache.containsKey(communityId)) {
      return Map<String, Map<String, double>>.from(
        _vibeContribsCache[communityId]!,
      );
    }

    final key = _vibeContribsStorageKey(communityId);
    final raw = _storageService?.getObject<dynamic>(key);
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

  Future<void> _persistCommunityVibeContributions({
    required String communityId,
    required Map<String, Map<String, double>> contributions,
  }) async {
    _vibeContribsCache[communityId] =
        Map<String, Map<String, double>>.from(contributions);

    if (_storageService == null) return;
    try {
      final key = _vibeContribsStorageKey(communityId);
      final payload = <String, dynamic>{};
      for (final entry in contributions.entries) {
        payload[entry.key] = entry.value;
      }
      await _storageService.setObject(key, payload);
    } catch (e) {
      _logger.warn(
        'Failed to persist community vibe contributions: $e',
        tag: _logName,
      );
    }
  }

  Map<String, double> _computeCentroidFromContributions(
    Map<String, Map<String, double>> contributions,
  ) {
    if (contributions.isEmpty) return const {};

    final sums = <String, double>{
      for (final d in VibeConstants.coreDimensions) d: 0.0,
    };
    var count = 0;

    for (final dims in contributions.values) {
      final safe = _ensureAllDimensions(dims);
      for (final d in VibeConstants.coreDimensions) {
        sums[d] =
            (sums[d] ?? 0.0) + (safe[d] ?? VibeConstants.defaultDimensionValue);
      }
      count++;
    }

    if (count <= 0) return const {};
    final centroid = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      centroid[d] = ((sums[d] ?? 0.0) / count).clamp(0.0, 1.0);
    }
    return centroid;
  }

  Map<String, double> _quantizeDimensions(
    Map<String, double> dims, {
    int bins = 64,
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

  Future<void> _saveCommunity(Community community) async {
    if (_repository != null) {
      await _repository.upsertCommunity(community);
      return;
    }
    // Local fallback: in-memory + best-effort persistence.
    _communities[community.id] = community;
    await _persistCommunitiesBestEffort();
  }

  Future<void> _deleteCommunity(String communityId) async {
    if (_repository != null) {
      await _repository.deleteCommunity(communityId);
      return;
    }
    // Local fallback: in-memory + best-effort persistence.
    _communities.remove(communityId);
    await _persistCommunitiesBestEffort();
  }

  Future<List<Community>> _getAllCommunities() async {
    if (_repository != null) {
      return _repository.getAllCommunities();
    }
    await _hydrateFromStorageIfNeeded();
    return _communities.values.toList();
  }

  Future<void> _hydrateFromStorageIfNeeded() async {
    if (_storageHydrated) return;
    _storageHydrated = true;

    if (_storageService == null) return;

    try {
      final jsonList = _storageService.getObject<List<dynamic>>(
        _communitiesStorageKey,
      );
      if (jsonList == null) return;

      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          final community = Community.fromJson(item);
          _communities[community.id] = community;
        }
      }
    } catch (e) {
      // Best-effort: keep in-memory behavior if persistence is unavailable.
      _logger.warn(
        'Failed to hydrate communities from storage: $e',
        tag: _logName,
      );
    }
  }

  Future<void> _persistCommunitiesBestEffort() async {
    if (_storageService == null) return;
    try {
      final list = _communities.values.map((c) => c.toJson()).toList();
      await _storageService.setObject(_communitiesStorageKey, list);
    } catch (e) {
      // Best-effort: do not fail core community flows if storage fails.
      _logger.warn(
        'Failed to persist communities to storage: $e',
        tag: _logName,
      );
    }
  }

  void _invalidateCommunityCaches(String communityId) {
    if (_trueCompatCache.isEmpty) return;

    final keysToRemove = <String>[];
    for (final key in _trueCompatCache.keys) {
      if (key.endsWith(':$communityId')) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _trueCompatCache.remove(key);
    }
  }

  /// Track expansion when community hosts events in new localities
  ///
  /// Called when a community hosts an event in a new locality.
  ///
  /// **Philosophy Alignment:**
  /// - Communities can expand naturally (doors open through growth)
  /// - Geographic expansion enabled (locality → universe)
  ///
  /// **Parameters:**
  /// - `community`: Community
  /// - `event`: Event that triggered expansion
  /// - `eventLocation`: Location of the event (locality, city, state, nation)
  ///
  /// **Returns:**
  /// Updated GeographicExpansion
  Future<GeographicExpansion> trackExpansion({
    required Community community,
    required ExpertiseEvent event,
    required String eventLocation,
  }) async {
    try {
      _logger.info(
        'Tracking expansion: community=${community.id}, event=${event.id}, location=$eventLocation',
        tag: _logName,
      );

      // Track event expansion
      final expansion = await _expansionService.trackEventExpansion(
        clubId: community.id,
        isClub: false, // This is a community, not a club
        event: event,
        eventLocation: eventLocation,
      );

      // Update community's current localities if new locality
      final locality = _extractLocality(eventLocation);
      if (locality != null && !community.currentLocalities.contains(locality)) {
        final updatedCommunity = community.copyWith(
          currentLocalities: [...community.currentLocalities, locality],
          updatedAt: DateTime.now(),
        );
        await _saveCommunity(updatedCommunity);
      }

      _logger.info(
        'Expansion tracked: community=${community.id}, localities=${expansion.expandedLocalities.length}',
        tag: _logName,
      );

      return expansion;
    } catch (e) {
      _logger.error('Error tracking expansion', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Update expansion history
  ///
  /// Updates expansion history when community expands.
  ///
  /// **Parameters:**
  /// - `community`: Community
  /// - `expansion`: Updated expansion
  ///
  /// **Returns:**
  /// Updated expansion
  Future<GeographicExpansion> updateExpansionHistory({
    required Community community,
    required GeographicExpansion expansion,
  }) async {
    try {
      _logger.info(
        'Updating expansion history: community=${community.id}',
        tag: _logName,
      );

      final updatedExpansion =
          await _expansionService.updateExpansion(expansion);

      _logger.info(
        'Expansion history updated: community=${community.id}',
        tag: _logName,
      );

      return updatedExpansion;
    } catch (e) {
      _logger.error('Error updating expansion history',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Extract locality from location string
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Get community health metrics from knot fabric
  ///
  /// **Phase 5: Knot Fabric Integration**
  ///
  /// Generates a knot fabric from all community members' knots and calculates
  /// health metrics including cohesion, diversity, clusters, and bridges.
  Future<CommunityMetrics?> getCommunityHealth(String communityId) async {
    if (_knotFabricService == null || _knotStorageService == null) {
      _logger.warning(
        'Knot fabric services not available',
        tag: _logName,
      );
      return null;
    }

    try {
      final community = await getCommunityById(communityId);
      if (community == null) {
        throw Exception('Community not found: $communityId');
      }

      // Get knots for all community members
      final knots = await _getUserKnots(community.memberIds);

      if (knots.isEmpty) {
        _logger.warning(
          'No knots found for community members',
          tag: _logName,
        );
        return null;
      }

      // Generate fabric from member knots
      final fabric = await _knotFabricService.generateMultiStrandBraidFabric(
        userKnots: knots,
      );

      // Calculate fabric invariants
      final invariants = await _knotFabricService.calculateFabricInvariants(
        fabric,
      );

      // Identify clusters
      final clusters = await _knotFabricService.identifyFabricClusters(fabric);

      // Identify bridges
      final bridges = await _knotFabricService.identifyBridgeStrands(fabric);

      // Measure stability (cohesion) using the real stability function (not the
      // placeholder invariant default).
      final cohesion = await _knotFabricService.measureFabricStability(fabric);

      // Calculate diversity
      final diversity = _calculateDiversity(knots);

      return CommunityMetrics(
        cohesion: cohesion,
        diversity: diversity,
        bridges: bridges,
        clusters: clusters,
        density: invariants.density,
      );
    } catch (e) {
      _logger.error(
        'Error getting community health: $e',
        error: e,
        tag: _logName,
      );
      return null;
    }
  }

  /// Discover communities from fabric clusters
  ///
  /// **Phase 5: Knot Fabric Integration**
  ///
  /// Analyzes all users' knots to identify natural clusters (knot tribes)
  /// and creates communities from those clusters.
  Future<List<Community>> discoverCommunitiesFromFabric({
    required List<String> allUserIds,
  }) async {
    if (_knotFabricService == null || _knotStorageService == null) {
      _logger.warning(
        'Knot fabric services not available',
        tag: _logName,
      );
      return [];
    }

    try {
      // Get knots for all users
      final agentIdToUserId = <String, String>{};
      final knots = await _getUserKnots(
        allUserIds,
        agentIdToUserId: agentIdToUserId,
      );

      if (knots.isEmpty) {
        _logger.warning('No knots found for users', tag: _logName);
        return [];
      }

      // Generate fabric from all knots
      final fabric = await _knotFabricService.generateMultiStrandBraidFabric(
        userKnots: knots,
      );

      // Identify clusters
      final clusters = await _knotFabricService.identifyFabricClusters(fabric);

      // Create communities from clusters
      final communities = <Community>[];
      for (final cluster in clusters) {
        // Extract **user IDs** from cluster knots (knot IDs are agentIds).
        final memberIds = cluster.userKnots
            .map((knot) => agentIdToUserId[knot.agentId])
            .whereType<String>()
            .toList();

        if (memberIds.isEmpty) continue;

        final now = await _now();
        // Create community from cluster
        final community = Community(
          id: 'fabric_cluster_${cluster.clusterId}',
          name: 'Knot Tribe ${cluster.clusterId}',
          description: 'Community discovered from knot fabric analysis',
          category: cluster.knotTypeDistribution.primaryType,
          originatingEventId:
              '', // No originating event for fabric-discovered communities
          originatingEventType: OriginatingEventType.communityEvent,
          memberIds: memberIds,
          memberCount: memberIds.length,
          founderId: memberIds.first, // First member as founder
          eventIds: const [],
          eventCount: 0,
          createdAt: now,
          originalLocality:
              'Unknown', // Would be determined from user locations
          updatedAt: now,
        );

        communities.add(community);
        await _saveCommunity(community);
      }

      _logger.info(
        'Discovered ${communities.length} communities from fabric',
        tag: _logName,
      );

      return communities;
    } catch (e) {
      _logger.error(
        'Error discovering communities from fabric: $e',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Discover communities from fabric clusters, then rank them for a specific user.
  ///
  /// This is the **discover + rank** primitive for “communities to join”.
  Future<List<Community>> discoverCommunitiesFromFabricForUser({
    required String userId,
    required List<String> allUserIds,
    int maxResults = 20,
  }) async {
    final discovered =
        await discoverCommunitiesFromFabric(allUserIds: allUserIds);
    if (discovered.isEmpty) return [];

    final scored = <_ScoredCommunity>[];
    for (final community in discovered) {
      final score = await calculateUserCommunityTrueCompatibility(
        communityId: community.id,
        userId: userId,
      );
      scored.add(_ScoredCommunity(community: community, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((s) => s.community).toList();
  }

  /// Get user knots from user IDs
  Future<List<PersonalityKnot>> _getUserKnots(
    List<String> userIds, {
    Map<String, String>? agentIdToUserId,
  }) async {
    if (_knotStorageService == null) {
      return [];
    }

    final knots = <PersonalityKnot>[];

    for (final userId in userIds) {
      try {
        // Some workflows (including certain tests) may already provide agentIds
        // instead of userIds. Try direct lookup first; if not found, fall back
        // to userId→agentId resolution.
        final direct = await _knotStorageService.loadKnot(userId);
        if (direct != null) {
          knots.add(direct);
          agentIdToUserId?[direct.agentId] = userId;
          continue;
        }

        final agentIdService = _tryGetAgentIdService();
        if (agentIdService == null) continue;

        final agentId = await agentIdService.getUserAgentId(userId);
        final knot = await _knotStorageService.loadKnot(agentId);
        if (knot != null) {
          knots.add(knot);
          agentIdToUserId?[knot.agentId] = userId;
        }
      } catch (e) {
        // Skip users without knots
        continue;
      }
    }

    return knots;
  }

  /// Calculate how well a user's knot "fits" into the community weave.
  ///
  /// This is the **true compatibility** signal for communities:
  /// - Build baseline fabric from existing members
  /// - Build a second fabric with the user inserted
  /// - Compare stability and return a fit score in [0, 1]
  Future<double?> calculateUserCommunityWeaveFit({
    required String communityId,
    required String userId,
  }) async {
    if (_knotFabricService == null || _knotStorageService == null) return null;

    try {
      final community = await getCommunityById(communityId);
      if (community == null) return null;

      final agentIdService = _tryGetAgentIdService();
      if (agentIdService == null) return null;

      final agentId = await agentIdService.getUserAgentId(userId);
      final userKnot = await _knotStorageService.loadKnot(agentId);
      if (userKnot == null) return null;

      // Build baseline knots (exclude the user if they are already a member).
      final baselineMemberIds =
          community.memberIds.where((id) => id != userId).toList();
      final baselineKnots = await _getUserKnots(baselineMemberIds);
      if (baselineKnots.isEmpty) return null;

      final baselineFabric =
          await _knotFabricService.generateMultiStrandBraidFabric(
        userKnots: baselineKnots,
      );
      final baselineStability =
          await _knotFabricService.measureFabricStability(baselineFabric);

      final withUserFabric =
          await _knotFabricService.generateMultiStrandBraidFabric(
        userKnots: [userKnot, ...baselineKnots],
      );
      final withUserStability =
          await _knotFabricService.measureFabricStability(withUserFabric);

      // Penalize only if the user decreases stability.
      final stabilityDrop =
          (baselineStability - withUserStability).clamp(0.0, 1.0);
      final fit = (withUserStability * (1.0 - stabilityDrop)).clamp(0.0, 1.0);

      _logger.debug(
        'Community weave fit: community=$communityId user=$userId '
        'baseline=${baselineStability.toStringAsFixed(3)} '
        'withUser=${withUserStability.toStringAsFixed(3)} '
        'fit=${fit.toStringAsFixed(3)}',
        tag: _logName,
      );

      return fit;
    } catch (e) {
      _logger.warn(
        'Error calculating community weave fit: $e',
        tag: _logName,
      );
      return null;
    }
  }

  /// Recommend communities for a user by **combined true compatibility**.
  ///
  /// \[
  /// C = 0.5·C_{quantum} + 0.3·C_{topological} + 0.2·C_{weaveFit}
  /// \]
  Future<List<Community>> getRecommendedCommunitiesForUser({
    required String userId,
    String? category,
    int maxResults = 20,
    bool excludeJoined = true,
  }) async {
    final all = await _getAllCommunities();
    final candidates = all.where((c) {
      if (category != null && c.category != category) return false;
      if (excludeJoined && c.isMember(userId)) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) return [];

    final scored = <_ScoredCommunity>[];
    for (final community in candidates) {
      final score = await calculateUserCommunityTrueCompatibility(
        communityId: community.id,
        userId: userId,
      );
      scored.add(_ScoredCommunity(community: community, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((s) => s.community).toList();
  }

  /// Calculate a user's **combined true compatibility** with a community.
  Future<double> calculateUserCommunityTrueCompatibility({
    required String communityId,
    required String userId,
    int memberSampleSize = 10,
  }) async {
    final breakdown = await calculateUserCommunityTrueCompatibilityBreakdown(
      communityId: communityId,
      userId: userId,
      memberSampleSize: memberSampleSize,
    );
    return breakdown.combined;
  }

  /// Calculate a user's **true compatibility breakdown** with a community.
  ///
  /// \[
  /// C = 0.5·C_{quantum} + 0.3·C_{topological} + 0.2·C_{weaveFit}
  /// \]
  Future<CommunityTrueCompatibilityBreakdown>
      calculateUserCommunityTrueCompatibilityBreakdown({
    required String communityId,
    required String userId,
    int memberSampleSize = 10,
  }) async {
    try {
      final cacheKey = '$userId:$communityId';
      final cached = _trueCompatCache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) < _trueCompatCacheTtl) {
        final quantum = cached.quantum;
        final topological = cached.topological;
        final weaveFit = cached.weaveFit;
        if (quantum != null && topological != null && weaveFit != null) {
          return CommunityTrueCompatibilityBreakdown(
            combined: cached.score,
            quantum: quantum,
            topological: topological,
            weaveFit: weaveFit,
          );
        }
      }

      final community = await getCommunityById(communityId);
      if (community == null) {
        return const CommunityTrueCompatibilityBreakdown(
          combined: 0.5,
          quantum: 0.5,
          topological: 0.5,
          weaveFit: 0.5,
        );
      }

      final quantum = await _calculateUserCommunityQuantumCompatibility(
        community: community,
        userId: userId,
        memberSampleSize: memberSampleSize,
      );

      final topological = await _calculateUserCommunityTopologicalCompatibility(
        community: community,
        userId: userId,
        memberSampleSize: memberSampleSize,
      );

      final weaveFitOrNull = await calculateUserCommunityWeaveFit(
        communityId: communityId,
        userId: userId,
      );
      final weaveFit = (weaveFitOrNull ?? 0.5).clamp(0.0, 1.0);

      final combined = (0.5 * quantum) + (0.3 * topological) + (0.2 * weaveFit);

      final clamped = combined.clamp(0.0, 1.0);
      _trueCompatCache[cacheKey] = _CachedScore(
        score: clamped,
        cachedAt: DateTime.now(),
        quantum: quantum,
        topological: topological,
        weaveFit: weaveFit,
      );
      return CommunityTrueCompatibilityBreakdown(
        combined: clamped,
        quantum: quantum,
        topological: topological,
        weaveFit: weaveFit,
      );
    } catch (e) {
      _logger.warn(
        'Error calculating community true compatibility: $e',
        tag: _logName,
      );
      return const CommunityTrueCompatibilityBreakdown(
        combined: 0.5,
        quantum: 0.5,
        topological: 0.5,
        weaveFit: 0.5,
      );
    }
  }

  Future<double> _calculateUserCommunityQuantumCompatibility({
    required Community community,
    required String userId,
    required int memberSampleSize,
  }) async {
    try {
      final personalityLearning = _tryGetPersonalityLearning();
      if (personalityLearning == null) return 0.5;

      // User: OK to initialize (this is the requesting user).
      final userProfile =
          await personalityLearning.initializePersonality(userId);
      final userDims = _ensureAllDimensions(userProfile.dimensions);

      // Prefer a privacy-safe aggregated community centroid when available.
      final centroidFromCommunity = community.vibeCentroidDimensions;
      if (centroidFromCommunity != null &&
          community.vibeCentroidContributors > 0) {
        final centroidDims = _ensureAllDimensions(centroidFromCommunity);
        return _quantumFidelity(userDims, centroidDims);
      }

      // Members: do not create new profiles as a side effect.
      final memberIds = community.memberIds
          .where((id) => id != userId)
          .take(memberSampleSize)
          .toList();
      if (memberIds.isEmpty) return 0.5;

      final sums = <String, double>{
        for (final d in VibeConstants.coreDimensions) d: 0.0,
      };
      var count = 0;

      for (final memberId in memberIds) {
        final profile =
            await personalityLearning.getCurrentPersonality(memberId);
        if (profile == null) continue;

        final dims = _ensureAllDimensions(profile.dimensions);
        for (final d in VibeConstants.coreDimensions) {
          sums[d] = (sums[d] ?? 0.0) +
              (dims[d] ?? VibeConstants.defaultDimensionValue);
        }
        count++;
      }

      if (count == 0) return 0.5;

      final centroid = <String, double>{};
      for (final d in VibeConstants.coreDimensions) {
        centroid[d] = ((sums[d] ?? 0.0) / count).clamp(0.0, 1.0);
      }

      return _quantumFidelity(userDims, centroid);
    } catch (_) {
      return 0.5;
    }
  }

  Future<double> _calculateUserCommunityTopologicalCompatibility({
    required Community community,
    required String userId,
    required int memberSampleSize,
  }) async {
    if (_knotStorageService == null) return 0.5;

    try {
      final agentIdService = _tryGetAgentIdService();
      if (agentIdService == null) return 0.5;

      final userAgentId = await agentIdService.getUserAgentId(userId);
      final userKnot = await _knotStorageService.loadKnot(userAgentId);
      if (userKnot == null) return 0.5;

      final memberIds = community.memberIds
          .where((id) => id != userId)
          .take(memberSampleSize)
          .toList();
      if (memberIds.isEmpty) return 0.5;

      var sum = 0.0;
      var count = 0;

      for (final memberId in memberIds) {
        try {
          final memberAgentId = await agentIdService.getUserAgentId(memberId);
          final memberKnot = await _knotStorageService.loadKnot(memberAgentId);
          if (memberKnot == null) continue;

          final topo = calculateTopologicalCompatibility(
            braidDataA: userKnot.braidData,
            braidDataB: memberKnot.braidData,
          ).clamp(0.0, 1.0);

          sum += topo;
          count++;
        } catch (_) {
          // Skip members without knots.
        }
      }

      if (count == 0) return 0.5;
      return (sum / count).clamp(0.0, 1.0);
    } catch (_) {
      return 0.5;
    }
  }

  AgentIdService? _tryGetAgentIdService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        return sl<AgentIdService>();
      }
    } catch (_) {}
    return AgentIdService();
  }

  PersonalityLearning? _tryGetPersonalityLearning() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<PersonalityLearning>()) {
        return sl<PersonalityLearning>();
      }
    } catch (_) {}
    return PersonalityLearning();
  }

  Map<String, double> _ensureAllDimensions(Map<String, double> input) {
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] =
          (input[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
    }
    return dims;
  }

  double _quantumFidelity(Map<String, double> a, Map<String, double> b) {
    final vecA = <double>[];
    final vecB = <double>[];
    for (final d in VibeConstants.coreDimensions) {
      vecA.add((a[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0));
      vecB.add((b[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0));
    }

    final normA = math.sqrt(vecA.fold<double>(0.0, (s, v) => s + v * v));
    final normB = math.sqrt(vecB.fold<double>(0.0, (s, v) => s + v * v));
    if (normA < 1e-9 || normB < 1e-9) return 0.0;

    var inner = 0.0;
    for (var i = 0; i < vecA.length; i++) {
      inner += (vecA[i] / normA) * (vecB[i] / normB);
    }

    return (inner * inner).clamp(0.0, 1.0);
  }

  /// Calculate diversity from knots
  KnotTypeDistribution _calculateDiversity(
    List<PersonalityKnot> knots,
  ) {
    if (knots.isEmpty) {
      return const KnotTypeDistribution(
        primaryType: 'unknown',
        typeCounts: {},
        diversity: 0.0,
      );
    }

    // Count knot types (using crossing number as type)
    final typeCounts = <String, int>{};

    for (final knot in knots) {
      final type = 'type_${knot.invariants.crossingNumber}';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    // Find primary type
    String primaryType = 'unknown';
    int maxCount = 0;
    for (final entry in typeCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        primaryType = entry.key;
      }
    }

    // Calculate diversity (Shannon entropy normalized)
    double diversity = 0.0;
    if (knots.isNotEmpty && typeCounts.length > 1) {
      final total = knots.length;
      double entropy = 0.0;
      for (final count in typeCounts.values) {
        final p = count / total;
        if (p > 0) {
          entropy -= p * (p > 0 ? (p * p).clamp(0.0, 1.0) : 0.0);
        }
      }
      diversity = (entropy / (typeCounts.length - 1)).clamp(0.0, 1.0);
    }

    return KnotTypeDistribution(
      primaryType: primaryType,
      typeCounts: typeCounts,
      diversity: diversity,
    );
  }
}

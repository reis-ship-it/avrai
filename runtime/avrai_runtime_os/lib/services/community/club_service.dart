import 'dart:async';

import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/community/club.dart';
import 'package:avrai_core/models/community/club_hierarchy.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_expansion_service.dart';
import 'package:avrai_runtime_os/services/expertise/expansion_expertise_gain_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Club Service
///
/// Manages clubs (communities with organizational structure).
///
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth and geographic expansion
///
/// **Key Features:**
/// - Upgrade community to club
/// - Manage club leaders (add, remove, get, check)
/// - Manage admin team (add, remove, get, check)
/// - Manage member roles (assign, get, check permissions)
/// - Club management (get, update)
/// - Integration with CommunityService
class ClubService {
  static const String _logName = 'ClubService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // Reserved for future: Club ↔ Community persistence integration.
  // ignore: unused_field
  final CommunityService _communityService;
  final LedgerRecorderServiceV0 _ledger;
  final StorageService? _storageService;

  // In-memory storage (in production, use database)
  final Map<String, Club> _clubs = {};
  static const String _clubsStorageKey = 'clubs:all_v1';
  bool _storageHydrated = false;

  ClubService({
    CommunityService? communityService,
    LedgerRecorderServiceV0? ledgerRecorder,
    StorageService? storageService,
  })  : _communityService = communityService ?? CommunityService(),
        _storageService = storageService ?? StorageService.instance,
        _ledger = ledgerRecorder ??
            LedgerRecorderServiceV0(
              supabaseService: SupabaseService(),
              agentIdService: AgentIdService(),
              storage: StorageService.instance,
            );

  Future<Club> createClub({
    required String founderId,
    required String name,
    required String description,
    required String category,
    required String originalLocality,
    String? cityCode,
    String? localityCode,
  }) async {
    final now = DateTime.now();
    final club = Club(
      id: 'club_${now.microsecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      originatingEventId: '',
      originatingEventType: OriginatingEventType.communityEvent,
      founderId: founderId,
      memberIds: <String>[founderId],
      memberCount: 1,
      createdAt: now,
      updatedAt: now,
      originalLocality: originalLocality,
      currentLocalities: originalLocality.isEmpty
          ? const <String>[]
          : <String>[originalLocality],
      cityCode: cityCode,
      localityCode: localityCode,
      leaders: <String>[founderId],
      organizationalMaturity: 0.4,
      leadershipStability: 0.65,
      activityLevel: ActivityLevel.growing,
    );
    await _saveClub(club);
    return club;
  }

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

  /// Upgrade community to club
  ///
  /// Upgrades a community to a club when organizational structure is needed.
  ///
  /// **Upgrade Criteria:**
  /// - Community has X+ members (default: 10)
  /// - Community has hosted Y+ events (default: 3)
  /// - Community has stable leadership (founder active)
  /// - Community needs organizational structure
  ///
  /// **What Gets Created:**
  /// - Club extends Community
  /// - Founder becomes initial leader
  /// - Organizational structure (hierarchy) created
  /// - Preserves community history
  Future<Club> upgradeToClub({
    required Community community,
    int minMembers = 10,
    int minEvents = 3,
    bool needsStructure = true,
  }) async {
    try {
      _logger.info(
        'Upgrading community ${community.id} to club',
        tag: _logName,
      );

      // Check upgrade criteria
      if (community.memberCount < minMembers) {
        throw Exception(
          'Community must have at least $minMembers members to upgrade to club',
        );
      }

      if (community.eventCount < minEvents) {
        throw Exception(
          'Community must have hosted at least $minEvents events to upgrade to club',
        );
      }

      if (!needsStructure) {
        throw Exception(
            'Community must need organizational structure to upgrade');
      }

      // Create club from community
      final club = Club.fromCommunity(
        community: community,
        leaders: [community.founderId], // Founder becomes initial leader
        adminTeam: const [],
        hierarchy: ClubHierarchy(),
        memberRoles: const {}, // All members start as regular members
        pendingMembers: const [],
        bannedMembers: const [],
        organizationalMaturity: 0.5, // Starting maturity
        leadershipStability: 0.7, // Founder is stable
        expansionLocalities: const [],
        expansionCities: const [],
        coveragePercentage: const {},
      );

      // Save club
      await _saveClub(club);

      // Best-effort dual-write to ledger (must never block UX).
      unawaited(_tryLedgerAppendForUser(
        expectedOwnerUserId: community.founderId,
        eventType: 'community_upgraded_to_club',
        entityType: 'club',
        entityId: club.id,
        category: community.category,
        payload: <String, Object?>{
          'club_id': club.id,
          'community_id': community.id,
          'min_members': minMembers,
          'min_events': minEvents,
          'needs_structure': needsStructure,
          'member_count': community.memberCount,
          'event_count': community.eventCount,
          'founder_id': community.founderId,
          'originating_event_id': community.originatingEventId,
          'originating_event_type': community.originatingEventType.name,
        },
      ));

      _logger.info('Upgraded community to club: ${club.id}', tag: _logName);
      return club;
    } catch (e) {
      _logger.error('Error upgrading community to club',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Add leader to club
  Future<void> addLeader(Club club, String userId) async {
    try {
      _logger.info('Adding leader $userId to club ${club.id}', tag: _logName);

      // Retrieve latest club from storage to ensure we have the correct state
      final latestClub = await getClubById(club.id);
      if (latestClub == null) {
        throw Exception('Club not found: ${club.id}');
      }

      if (latestClub.leaders.contains(userId)) {
        _logger.warning(
          'User $userId is already a leader of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      // User must be a member
      if (!latestClub.isMember(userId)) {
        throw Exception('User must be a member to become a leader');
      }

      // Remove from admin team if present
      List<String> updatedAdminTeam = latestClub.adminTeam;
      if (updatedAdminTeam.contains(userId)) {
        updatedAdminTeam =
            updatedAdminTeam.where((id) => id != userId).toList();
      }

      // Remove from member roles if present
      Map<String, ClubRole> updatedMemberRoles =
          Map.from(latestClub.memberRoles);
      updatedMemberRoles.remove(userId);

      final updated = latestClub.copyWith(
        leaders: [...latestClub.leaders, userId],
        adminTeam: updatedAdminTeam,
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Added leader to club', tag: _logName);
    } catch (e) {
      _logger.error('Error adding leader', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove leader from club
  Future<void> removeLeader(Club club, String userId) async {
    try {
      _logger.info('Removing leader $userId from club ${club.id}',
          tag: _logName);

      if (!club.leaders.contains(userId)) {
        _logger.warning(
          'User $userId is not a leader of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      // Cannot remove founder if they're the only leader
      if (club.founderId == userId && club.leaders.length == 1) {
        throw Exception('Cannot remove founder if they are the only leader');
      }

      final updated = club.copyWith(
        leaders: club.leaders.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Removed leader from club', tag: _logName);
    } catch (e) {
      _logger.error('Error removing leader', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all leaders
  List<String> getLeaders(Club club) {
    return club.leaders;
  }

  /// Check if user is a leader
  bool isLeader(Club club, String userId) {
    return club.isLeader(userId);
  }

  /// Add admin to club
  ///
  /// **Note:** Retrieves latest club from storage to ensure correct state
  Future<void> addAdmin(Club club, String userId) async {
    try {
      _logger.info('Adding admin $userId to club ${club.id}', tag: _logName);

      // Retrieve latest club from storage to ensure we have the correct state
      final latestClub = await getClubById(club.id);
      if (latestClub == null) {
        throw Exception('Club not found: ${club.id}');
      }

      if (latestClub.adminTeam.contains(userId)) {
        _logger.warning(
          'User $userId is already an admin of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      // User must be a member
      if (!latestClub.isMember(userId)) {
        throw Exception('User must be a member to become an admin');
      }

      // Cannot add if already a leader
      if (latestClub.isLeader(userId)) {
        throw Exception('User is already a leader');
      }

      // Remove from member roles if present
      Map<String, ClubRole> updatedMemberRoles =
          Map.from(latestClub.memberRoles);
      updatedMemberRoles.remove(userId);

      final updated = latestClub.copyWith(
        adminTeam: [...latestClub.adminTeam, userId],
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Added admin to club', tag: _logName);
    } catch (e) {
      _logger.error('Error adding admin', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove admin from club
  Future<void> removeAdmin(Club club, String userId) async {
    try {
      _logger.info('Removing admin $userId from club ${club.id}',
          tag: _logName);

      if (!club.adminTeam.contains(userId)) {
        _logger.warning(
          'User $userId is not an admin of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      final updated = club.copyWith(
        adminTeam: club.adminTeam.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Removed admin from club', tag: _logName);
    } catch (e) {
      _logger.error('Error removing admin', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all admins
  List<String> getAdmins(Club club) {
    return club.adminTeam;
  }

  /// Check if user is an admin
  bool isAdmin(Club club, String userId) {
    return club.isAdmin(userId);
  }

  /// Assign role to member
  ///
  /// **Note:** Retrieves latest club from storage to ensure correct state
  Future<void> assignRole(
    Club club,
    String userId,
    ClubRole role,
  ) async {
    try {
      _logger.info(
        'Assigning role ${role.name} to user $userId in club ${club.id}',
        tag: _logName,
      );

      // Retrieve latest club from storage to ensure we have the correct state
      final latestClub = await getClubById(club.id);
      if (latestClub == null) {
        throw Exception('Club not found: ${club.id}');
      }

      // User must be a member
      if (!latestClub.isMember(userId)) {
        throw Exception('User must be a member to assign a role');
      }

      // Cannot assign leader or admin role (use addLeader/addAdmin)
      if (role == ClubRole.leader) {
        throw Exception('Use addLeader() to assign leader role');
      }
      if (role == ClubRole.admin) {
        throw Exception('Use addAdmin() to assign admin role');
      }

      // Remove from leaders/admins if present
      List<String> updatedLeaders = latestClub.leaders;
      List<String> updatedAdminTeam = latestClub.adminTeam;
      if (updatedLeaders.contains(userId)) {
        updatedLeaders = updatedLeaders.where((id) => id != userId).toList();
      }
      if (updatedAdminTeam.contains(userId)) {
        updatedAdminTeam =
            updatedAdminTeam.where((id) => id != userId).toList();
      }

      // Update member roles
      Map<String, ClubRole> updatedMemberRoles =
          Map.from(latestClub.memberRoles);
      if (role == ClubRole.member) {
        updatedMemberRoles.remove(userId); // Default role, no need to store
      } else {
        updatedMemberRoles[userId] = role;
      }

      final updated = latestClub.copyWith(
        leaders: updatedLeaders,
        adminTeam: updatedAdminTeam,
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Assigned role to member', tag: _logName);
    } catch (e) {
      _logger.error('Error assigning role', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get member's role
  ClubRole? getMemberRole(Club club, String userId) {
    return club.getMemberRole(userId);
  }

  /// Check if member has permission
  bool hasPermission(Club club, String userId, String permission) {
    return club.hasPermission(userId, permission);
  }

  /// Get club by ID
  Future<Club?> getClubById(String clubId) async {
    try {
      final allClubs = await _getAllClubs();
      return allClubs.firstWhere(
        (c) => c.id == clubId,
        orElse: () => throw Exception('Club not found'),
      );
    } catch (e) {
      _logger.error('Error getting club by ID', error: e, tag: _logName);
      return null;
    }
  }

  /// Get clubs by leader
  Future<List<Club>> getClubsByLeader(String leaderId) async {
    try {
      final allClubs = await _getAllClubs();
      return allClubs.where((c) => c.isLeader(leaderId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting clubs by leader', error: e, tag: _logName);
      return [];
    }
  }

  /// Get clubs by category
  Future<List<Club>> getClubsByCategory(
    String category, {
    int maxResults = 20,
  }) async {
    try {
      final allClubs = await _getAllClubs();
      return allClubs
          .where((c) => c.category == category)
          .take(maxResults)
          .toList()
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } catch (e) {
      _logger.error('Error getting clubs by category', error: e, tag: _logName);
      return [];
    }
  }

  Future<List<Club>> getAllClubs({int maxResults = 100}) async {
    final allClubs = await _getAllClubs();
    allClubs.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return allClubs.take(maxResults).toList();
  }

  Future<List<Club>> searchClubs(
    String query, {
    int maxResults = 30,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final allClubs = await _getAllClubs();
    if (normalizedQuery.isEmpty) {
      return getAllClubs(maxResults: maxResults);
    }
    return allClubs
        .where((club) {
          return club.name.toLowerCase().contains(normalizedQuery) ||
              club.category.toLowerCase().contains(normalizedQuery) ||
              (club.description ?? '').toLowerCase().contains(normalizedQuery);
        })
        .take(maxResults)
        .toList();
  }

  Future<void> leaveClub({
    required String clubId,
    required String userId,
  }) async {
    final club = await getClubById(clubId);
    if (club == null || !club.memberIds.contains(userId)) {
      return;
    }
    if (club.founderId == userId) {
      return;
    }

    final updated = club.copyWith(
      memberIds:
          club.memberIds.where((memberId) => memberId != userId).toList(),
      memberCount: (club.memberCount - 1).clamp(0, 1 << 31),
      leaders: club.leaders.where((memberId) => memberId != userId).toList(),
      adminTeam:
          club.adminTeam.where((memberId) => memberId != userId).toList(),
      memberRoles: Map<String, ClubRole>.from(club.memberRoles)..remove(userId),
      updatedAt: DateTime.now(),
    );
    await _saveClub(updated);
  }

  /// Update club details
  Future<Club> updateClub({
    required Club club,
    String? name,
    String? description,
    List<String>? currentLocalities,
    List<String>? expansionLocalities,
    List<String>? expansionCities,
    Map<String, double>? coveragePercentage,
    double? organizationalMaturity,
    double? leadershipStability,
  }) async {
    try {
      _logger.info('Updating club: ${club.id}', tag: _logName);

      final updated = club.copyWith(
        name: name,
        description: description,
        currentLocalities: currentLocalities,
        expansionLocalities: expansionLocalities,
        expansionCities: expansionCities,
        coveragePercentage: coveragePercentage,
        organizationalMaturity: organizationalMaturity,
        leadershipStability: leadershipStability,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Updated club', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating club', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Grant expertise to club leaders
  ///
  /// Grants expertise to club leaders in all localities where club hosts events.
  ///
  /// **Philosophy Alignment:**
  /// - Club leaders recognized as experts (doors for leaders)
  /// - Leaders gain expertise in all localities where club hosts events
  ///
  /// **Parameters:**
  /// - `club`: Club
  /// - `category`: Category for expertise
  /// - `expansionExpertiseGainService`: Service to grant expertise from expansion
  ///
  /// **Returns:**
  /// Map of leader ID → updated user (with new expertise)
  Future<Map<String, UnifiedUser>> grantLeaderExpertise({
    required Club club,
    required String category,
    required ExpansionExpertiseGainService expansionExpertiseGainService,
  }) async {
    try {
      _logger.info(
        'Granting leader expertise: club=${club.id}, category=$category, leaders=${club.leaders.length}',
        tag: _logName,
      );

      final updatedLeaders = <String, UnifiedUser>{};

      // Get expansion for club
      final expansionService = GeographicExpansionService();
      final expansion = expansionService.getExpansionByClub(club.id);

      if (expansion == null) {
        _logger.warning(
          'No expansion found for club ${club.id}',
          tag: _logName,
        );
        return updatedLeaders;
      }

      // Grant expertise to each leader
      for (final leaderId in club.leaders) {
        // In production, would fetch user from database
        // For now, create a placeholder user (this would be replaced with actual user fetch)
        // TODO: Replace with actual user fetch from user service
        final leader = UnifiedUser(
          id: leaderId,
          email: '$leaderId@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Grant expertise from expansion
        final updatedLeader =
            await expansionExpertiseGainService.grantExpertiseFromExpansion(
          user: leader,
          expansion: expansion,
          category: category,
        );

        updatedLeaders[leaderId] = updatedLeader;
      }

      _logger.info(
        'Granted leader expertise: club=${club.id}, leaders=${updatedLeaders.length}',
        tag: _logName,
      );

      return updatedLeaders;
    } catch (e) {
      _logger.error('Error granting leader expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Update leader expertise when club expands
  ///
  /// Called when club expands to new localities.
  ///
  /// **Parameters:**
  /// - `club`: Club
  /// - `category`: Category for expertise
  /// - `expansionExpertiseGainService`: Service to grant expertise from expansion
  ///
  /// **Returns:**
  /// Updated club with leader expertise tracked
  Future<Club> updateLeaderExpertise({
    required Club club,
    required String category,
    required ExpansionExpertiseGainService expansionExpertiseGainService,
  }) async {
    try {
      _logger.info(
        'Updating leader expertise: club=${club.id}, category=$category',
        tag: _logName,
      );

      // Grant expertise to leaders
      final updatedLeaders = await grantLeaderExpertise(
        club: club,
        category: category,
        expansionExpertiseGainService: expansionExpertiseGainService,
      );

      // Update club with leader expertise (stored in leaderExpertise map)
      // Note: This would require updating Club model to include leaderExpertise field
      // For now, just log the update
      _logger.info(
        'Updated leader expertise: club=${club.id}, leaders=${updatedLeaders.length}',
        tag: _logName,
      );

      return club;
    } catch (e) {
      _logger.error('Error updating leader expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get expertise for a club leader
  ///
  /// **Parameters:**
  /// - `club`: Club
  /// - `leaderId`: Leader user ID
  /// - `category`: Category for expertise
  ///
  /// **Returns:**
  /// Expertise level for leader in category, or null if not found
  ExpertiseLevel? getLeaderExpertise({
    required Club club,
    required String leaderId,
    required String category,
  }) {
    try {
      // Check if user is a leader
      if (!club.isLeader(leaderId)) {
        return null;
      }

      // In production, would fetch user from database and get expertise
      // For now, return null (would be replaced with actual user fetch)
      // TODO: Replace with actual user fetch from user service
      return null;
    } catch (e) {
      _logger.error('Error getting leader expertise', error: e, tag: _logName);
      return null;
    }
  }

  // Private helper methods

  Future<void> _saveClub(Club club) async {
    await _hydrateFromStorageIfNeeded();
    _clubs[club.id] = club;
    await _persistClubs();
  }

  Future<List<Club>> _getAllClubs() async {
    await _hydrateFromStorageIfNeeded();
    return _clubs.values.toList();
  }

  Future<void> _hydrateFromStorageIfNeeded() async {
    if (_storageHydrated) {
      return;
    }
    _storageHydrated = true;
    final stored = _storageService?.getObject<List<dynamic>>(_clubsStorageKey);
    if (stored == null) {
      return;
    }
    for (final item in stored) {
      if (item is Map) {
        final club = Club.fromJson(Map<String, dynamic>.from(item));
        _clubs[club.id] = club;
      }
    }
  }

  Future<void> _persistClubs() async {
    await _storageService?.setObject(
      _clubsStorageKey,
      _clubs.values.map((club) => club.toJson()).toList(),
    );
  }
}

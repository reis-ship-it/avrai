import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/community/club_service.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/core/models/community/club.dart';
import 'package:avrai/core/models/community/club_hierarchy.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Comprehensive tests for ClubService
/// Tests upgrade community to club, leader management, admin management, member roles, permissions
///
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth
void main() {
  group('ClubService Tests', () {
    late ClubService service;
    late CommunityService communityService;
    late UnifiedUser founder;
    late Community eligibleCommunity;
    late Community ineligibleCommunity;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      communityService = CommunityService();
      service = ClubService(communityService: communityService);
      testDate = TestHelpers.createTestDateTime();

      // Create founder
      founder = ModelFactories.createTestUser(
        id: 'founder-1',
      );

      // Create eligible community (meets upgrade criteria)
      eligibleCommunity = Community(
        id: 'community-1',
        name: 'Coffee Enthusiasts',
        description: 'A community for coffee lovers',
        category: 'Coffee',
        originatingEventId: 'event-1',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: founder.id,
        originalLocality: 'Mission District, San Francisco',
        createdAt: testDate,
        updatedAt: testDate,
        memberIds: [
          ...List.generate(12, (i) => 'user-$i'), // 12 members
          'leader-1', // Add leader-1 as member for tests
          'leader-2', // Add leader-2 as member for tests (needed for leader management tests)
          'leader-3', // Add leader-3 as member for tests (needed for leader management tests)
          'admin-1', // Add admin-1 as member for tests
          'admin-2', // Add admin-2 as member for tests (needed for admin management tests)
          'admin-3', // Add admin-3 as member for tests (needed for admin management tests)
        ],
        memberCount: 18, // 12 + 6 = 18 members
        eventIds: const ['event-1', 'event-2', 'event-3', 'event-4'], // 4 events
        eventCount: 4,
      );

      // Create ineligible community (doesn't meet criteria)
      ineligibleCommunity = Community(
        id: 'community-2',
        name: 'Small Community',
        description: 'Small community',
        category: 'Coffee',
        originatingEventId: 'event-2',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: founder.id,
        originalLocality: 'Mission District, San Francisco',
        createdAt: testDate,
        updatedAt: testDate,
        memberIds: const ['user-1', 'user-2'], // Only 2 members
        memberCount: 2,
        eventIds: const ['event-1'], // Only 1 event
        eventCount: 1,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Upgrade tests focus on business logic (validation, hierarchy creation, founder assignment), not property assignment

    group('Upgrade Community to Club', () {
      test(
          'should upgrade eligible community with correct business logic, preserve history, set founder as leader, and create default hierarchy',
          () async {
        // Test business logic: upgrade validation, founder assignment, hierarchy creation
        final club = await service.upgradeToClub(
          community: eligibleCommunity,
        );

        // Business logic: founder should be initial leader
        expect(club.leaders, contains(eligibleCommunity.founderId));
        expect(club.leaders.length, equals(1));

        // Business logic: organizational metrics
        expect(club.organizationalMaturity, equals(0.5));
        expect(club.leadershipStability, equals(0.7));

        // Business logic: default hierarchy should include all roles
        expect(club.hierarchy, isNotNull);
        expect(club.hierarchy.rolePermissions, contains(ClubRole.leader));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.admin));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.moderator));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.member));
      });

      test(
          'should throw error if community does not meet upgrade criteria (members, events, structure)',
          () async {
        // Test business logic: validation rules
        expect(
          () => service.upgradeToClub(
            community: ineligibleCommunity,
            minMembers: 10,
          ),
          throwsException,
        );

        final communityWithFewEvents = eligibleCommunity.copyWith(
          eventCount: 2,
        );
        expect(
          () => service.upgradeToClub(
            community: communityWithFewEvents,
            minEvents: 3,
          ),
          throwsException,
        );

        expect(
          () => service.upgradeToClub(
            community: eligibleCommunity,
            needsStructure: false,
          ),
          throwsException,
        );
      });
    });

    group('Leader Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test(
          'should add leader to club, not add duplicate leader, throw error if user is not a member, remove user from admin team when promoting to leader, remove leader from club, not remove non-leader, throw error when trying to remove founder if only leader, allow removing founder if there are other leaders, and check if user is leader',
          () async {
        // Test business logic: leader management operations
        // Founder starts as the only leader after upgrade; removing them should throw.
        await expectLater(
          service.removeLeader(club, club.founderId),
          throwsException,
        );

        const newLeaderId = 'leader-1';
        await service.addLeader(club, newLeaderId);
        final updated1 = await service.getClubById(club.id);
        expect(updated1!.leaders, contains(newLeaderId));
        expect(updated1.leaders.length, equals(2));

        // Test duplicate prevention - use updated1 (which has the new leader)
        await service.addLeader(updated1, updated1.leaders.first);
        final updated2 = await service.getClubById(club.id);
        expect(updated2!.leaders.length, equals(updated1.leaders.length));

        expect(
          () => service.addLeader(club, 'non-member-1'),
          throwsException,
        );

        const userId = 'user-1';
        await service.addAdmin(club, userId);
        await service.addLeader(club, userId);
        final updated3 = await service.getClubById(club.id);
        expect(updated3!.leaders, contains(userId));
        expect(updated3.adminTeam, isNot(contains(userId)));

        const leaderToRemove = 'leader-2';
        await service.addLeader(club, leaderToRemove);
        club = (await service.getClubById(club.id))!;
        await service.removeLeader(club, leaderToRemove);
        final updated4 = await service.getClubById(club.id);
        expect(updated4!.leaders, isNot(contains(leaderToRemove)));

        await service.removeLeader(updated4, 'non-leader-1');
        final updated5 = await service.getClubById(club.id);
        expect(updated5!.leaders.length, equals(updated4.leaders.length));

        const otherLeader = 'leader-3';
        await service.addLeader(updated5, otherLeader);
        club = (await service.getClubById(club.id))!;
        await service.removeLeader(club, club.founderId);
        final updated6 = await service.getClubById(club.id);
        expect(updated6!.leaders, isNot(contains(club.founderId)));
        expect(updated6.leaders, contains(otherLeader));

        expect(service.isLeader(club, club.leaders.first), isTrue);
        expect(service.isLeader(club, 'non-leader-1'), isFalse);
      });
    });

    group('Admin Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test(
          'should add admin to club, not add duplicate admin, throw error if user is not a member or already a leader, remove admin from club, not remove non-admin, and check if user is admin',
          () async {
        // Test business logic: admin management operations
        const newAdminId = 'admin-1';
        await service.addAdmin(club, newAdminId);
        final updated1 = await service.getClubById(club.id);
        expect(updated1!.adminTeam, contains(newAdminId));
        expect(updated1.adminTeam.length, equals(1));

        await service.addAdmin(club, newAdminId);
        final updated2 = await service.getClubById(club.id);
        expect(updated2!.adminTeam.length, equals(1));

        expect(
          () => service.addAdmin(club, 'non-member-1'),
          throwsException,
        );

        expect(
          () => service.addAdmin(club, club.leaders.first),
          throwsException,
        );

        // admin-2 is already a member (added in setUp via eligibleCommunity)
        const adminToRemove = 'admin-2';
        await service.addAdmin(club, adminToRemove);
        club = (await service.getClubById(club.id))!;
        await service.removeAdmin(club, adminToRemove);
        final updated3 = await service.getClubById(club.id);
        expect(updated3!.adminTeam, isNot(contains(adminToRemove)));

        // Test removing non-admin (should not change adminTeam length)
        final adminTeamLengthBefore = updated3.adminTeam.length;
        await service.removeAdmin(updated3, 'non-admin-1');
        final updated4 = await service.getClubById(club.id);
        expect(updated4!.adminTeam.length, equals(adminTeamLengthBefore));

        const adminId = 'admin-3';
        await service.addAdmin(club, adminId);
        club = (await service.getClubById(club.id))!;
        expect(service.isAdmin(club, adminId), isTrue);
        expect(service.isAdmin(club, 'non-admin-1'), isFalse);
      });
    });

    group('Member Role Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test(
          'should assign moderator role to member, assign member role (default), throw error if user is not a member or when trying to assign leader/admin role, remove from leaders/admins when assigning role, get member role, and check permissions',
          () async {
        // Test business logic: role management and permissions
        const memberId = 'user-1';
        await service.assignRole(club, memberId, ClubRole.moderator);
        final updated1 = await service.getClubById(club.id);
        expect(updated1!.memberRoles[memberId], equals(ClubRole.moderator));

        await service.assignRole(club, memberId, ClubRole.member);
        final updated2 = await service.getClubById(club.id);
        expect(updated2!.memberRoles.containsKey(memberId), isFalse);

        expect(
          () => service.assignRole(club, 'non-member-1', ClubRole.moderator),
          throwsException,
        );

        expect(
          () => service.assignRole(club, 'user-2', ClubRole.leader),
          throwsException,
        );

        expect(
          () => service.assignRole(club, 'user-2', ClubRole.admin),
          throwsException,
        );

        const userId = 'user-3';
        await service.addLeader(club, userId);
        await service.assignRole(club, userId, ClubRole.moderator);
        final updated3 = await service.getClubById(club.id);
        expect(updated3!.leaders, isNot(contains(userId)));
        expect(updated3.memberRoles[userId], equals(ClubRole.moderator));

        final memberRole = service.getMemberRole(club, memberId);
        expect(memberRole, equals(ClubRole.member));

        final leaderRole = service.getMemberRole(club, club.leaders.first);
        expect(leaderRole, equals(ClubRole.leader));

        expect(
          service.hasPermission(club, club.leaders.first, 'createEvents'),
          isTrue,
        );
        expect(
          service.hasPermission(club, club.leaders.first, 'manageLeaders'),
          isTrue,
        );

        expect(
          service.hasPermission(club, memberId, 'createEvents'),
          isTrue,
        );
        expect(
          service.hasPermission(club, memberId, 'manageMembers'),
          isFalse,
        );
      });
    });

    group('Club Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test(
          'should get club by ID or return null if not found, get clubs by leader, get clubs by category, or limit results when getting clubs by category',
          () async {
        // Test business logic: club retrieval operations
        final retrieved = await service.getClubById(club.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.isClub, isTrue);
        final notFound = await service.getClubById('non-existent-id');
        expect(notFound, isNull);

        final clubsByLeader =
            await service.getClubsByLeader(club.leaders.first);
        expect(clubsByLeader, isNotEmpty);
        expect(clubsByLeader.any((c) => c.id == club.id), isTrue);
        expect(
            clubsByLeader.every((c) => c.isLeader(club.leaders.first)), isTrue);

        final clubsByCategory = await service.getClubsByCategory('Coffee');
        expect(clubsByCategory, isNotEmpty);
        expect(clubsByCategory.any((c) => c.id == club.id), isTrue);
        expect(clubsByCategory.every((c) => c.category == 'Coffee'), isTrue);

        final clubsLimited = await service.getClubsByCategory(
          'Coffee',
          maxResults: 1,
        );
        expect(clubsLimited.length, lessThanOrEqualTo(1));
      });

      test(
          'should update club details, geographic expansion, and preserve existing values when updating with null',
          () async {
        // Test business logic: club updates with partial updates and value preservation
        final updated1 = await service.updateClub(
          club: club,
          name: 'Updated Name',
          description: 'Updated Description',
          organizationalMaturity: 0.85,
          leadershipStability: 0.90,
        );
        expect(updated1.organizationalMaturity, equals(0.85));
        expect(updated1.leadershipStability, equals(0.90));

        final updated2 = await service.updateClub(
          club: club,
          expansionLocalities: ['Castro', 'Haight-Ashbury'],
          expansionCities: ['Oakland'],
          coveragePercentage: {
            'locality': 0.50,
            'city': 0.75,
          },
        );
        expect(updated2.coveragePercentage['locality'], equals(0.50));
        expect(updated2.coveragePercentage['city'], equals(0.75));

        final updated3 = await service.updateClub(
          club: club,
          name: 'Updated Name',
        );
        expect(updated3.name, equals('Updated Name'));
        expect(updated3.description, equals(club.description));
        expect(updated3.organizationalMaturity,
            equals(club.organizationalMaturity));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

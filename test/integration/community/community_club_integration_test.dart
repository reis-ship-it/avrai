import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/services/community/club_service.dart';
import 'package:avrai/core/models/community/club.dart';
import 'package:avrai/core/models/community/club_hierarchy.dart';
import 'package:avrai/core/models/community/community_event.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Integration tests for Community/Club system
/// Tests end-to-end flows: Event → Community → Club
/// 
/// **Philosophy Alignment:**
/// - Events naturally create communities (doors open from events)
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
void main() {
  group('Community/Club Integration Tests', () {
    late CommunityService communityService;
    late ClubService clubService;
    late UnifiedUser host;
    late CommunityEvent successfulEvent;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      communityService = CommunityService();
      clubService = ClubService(communityService: communityService);
      testDate = TestHelpers.createTestDateTime();

      // Create host
      host = ModelFactories.createTestUser(
        id: 'host-1',
      );

      // Create successful community event
      successfulEvent = CommunityEvent(
        id: 'event-1',
        title: 'Coffee Meetup',
        description: 'Weekly coffee meetup',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: testDate.add(const Duration(days: 1)),
        endTime: testDate.add(const Duration(days: 1, hours: 2)),
        createdAt: testDate,
        updatedAt: testDate,
        location: 'Mission District, San Francisco, CA, USA',
        attendeeIds: List.generate(12, (i) => 'user-$i'),
        attendeeCount: 12,
        repeatAttendeesCount: 5,
        engagementScore: 0.80,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('End-to-End: Event → Community → Club', () {
      test('should create community from event, then upgrade to club', () async {
        // Step 1: Create community from successful event
        final community = await communityService.createCommunityFromEvent(
          event: successfulEvent,
        );

        expect(community, isNotNull);
        expect(community.memberIds.length, equals(13)); // 12 attendees + 1 host
        expect(community.memberCount, equals(13));
        expect(community.eventCount, equals(1));

        // Step 2: Add more members and events to meet upgrade criteria
        // Add more members
        var currentCommunity = community;
        for (int i = 0; i < 5; i++) {
          await communityService.addMember(currentCommunity, 'new-member-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }

        // Add more events (retrieve updated community after each add)
        for (int i = 2; i <= 4; i++) {
          await communityService.addEvent(currentCommunity, 'event-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }

        // Get updated community
        final updatedCommunity = await communityService.getCommunityById(community.id);
        expect(updatedCommunity, isNotNull);
        expect(updatedCommunity!.memberCount, greaterThanOrEqualTo(10));
        expect(updatedCommunity.eventCount, greaterThanOrEqualTo(3));

        // Step 3: Upgrade community to club
        final club = await clubService.upgradeToClub(
          community: updatedCommunity,
        );

        expect(club, isNotNull);
        expect(club.isClub, isTrue);
        expect(club.leaders, contains(community.founderId));
        expect(club.memberCount, equals(updatedCommunity.memberCount));
        expect(club.eventCount, equals(updatedCommunity.eventCount));
      });

      test('should preserve all community data when upgrading to club', () async {
        // Create community
        final community = await communityService.createCommunityFromEvent(
          event: successfulEvent,
        );

        // Add members and events (retrieve updated community after each operation)
        var currentCommunity = community;
        await communityService.addMember(currentCommunity, 'member-1');
        currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        
        await communityService.addEvent(currentCommunity, 'event-2');
        currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        
        await communityService.addEvent(currentCommunity, 'event-3');
        currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;

        // Update growth metrics (use latest community)
        await communityService.updateGrowthMetrics(
          currentCommunity,
          memberGrowthRate: 0.25,
          eventGrowthRate: 0.15,
        );

        // Get updated community
        final updatedCommunity = await communityService.getCommunityById(community.id);
        expect(updatedCommunity, isNotNull);

        // Upgrade to club
        final club = await clubService.upgradeToClub(
          community: updatedCommunity!,
        );

        // Verify all data preserved
        expect(club.id, equals(community.id));
        expect(club.name, equals(community.name));
        expect(club.description, equals(community.description));
        expect(club.category, equals(community.category));
        expect(club.memberIds, equals(updatedCommunity.memberIds));
        expect(club.memberCount, equals(updatedCommunity.memberCount));
        expect(club.eventIds, equals(updatedCommunity.eventIds));
        expect(club.eventCount, equals(updatedCommunity.eventCount));
        expect(club.memberGrowthRate, equals(updatedCommunity.memberGrowthRate));
        expect(club.eventGrowthRate, equals(updatedCommunity.eventGrowthRate));
        expect(club.originalLocality, equals(updatedCommunity.originalLocality));
      });
    });

    group('End-to-End: Organizational Structure Management', () {
      late Club club;

      setUp(() async {
        // Create community and upgrade to club
        final community = await communityService.createCommunityFromEvent(
          event: successfulEvent,
        );

        // Add members and events to meet criteria (retrieve updated community after each operation)
        var currentCommunity = community;
        for (int i = 0; i < 5; i++) {
          await communityService.addMember(currentCommunity, 'member-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }
        for (int i = 2; i <= 4; i++) {
          await communityService.addEvent(currentCommunity, 'event-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }

        final updatedCommunity = await communityService.getCommunityById(community.id);
        club = await clubService.upgradeToClub(
          community: updatedCommunity!,
        );
      });

      test('should manage organizational structure: add leaders and admins', () async {
        // Add users as members first (they need to be members before becoming leaders/admins)
        // Note: We need to add them to the community before upgrading to club, or add them via club service
        // Since club extends community, we can use existing members
        const leaderId = 'member-1'; // Use existing member
        await clubService.addLeader(club, leaderId);

        // Add admins (use existing members)
        const admin1Id = 'member-2';
        const admin2Id = 'member-3';
        await clubService.addAdmin(club, admin1Id);
        await clubService.addAdmin(club, admin2Id);

        // Verify structure
        final updated = await clubService.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.leaders.length, equals(2)); // Founder + new leader
        expect(updated.adminTeam.length, equals(2));
        expect(updated.hasOrganizationalStructure, isTrue);
      });

      test('should manage member roles and permissions', () async {
        // Assign moderator role (use existing member)
        const moderatorId = 'member-1';
        await clubService.assignRole(club, moderatorId, ClubRole.moderator);

        // Verify role and permissions
        final updated = await clubService.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.getMemberRole(moderatorId), equals(ClubRole.moderator));
        expect(updated.hasPermission(moderatorId, 'createEvents'), isTrue);
        expect(updated.hasPermission(moderatorId, 'moderateContent'), isTrue);
        expect(updated.hasPermission(moderatorId, 'manageMembers'), isFalse);
      });

      test('should enforce role hierarchy in permissions', () async {
        // Add leader and admin (use existing members)
        const leaderId = 'member-1';
        const adminId = 'member-2';
        await clubService.addLeader(club, leaderId);
        await clubService.addAdmin(club, adminId);

        // Verify permissions hierarchy
        final updated = await clubService.getClubById(club.id);
        expect(updated, isNotNull);

        // Leader has all permissions
        expect(updated!.hasPermission(leaderId, 'createEvents'), isTrue);
        expect(updated.hasPermission(leaderId, 'manageLeaders'), isTrue);
        expect(updated.hasPermission(leaderId, 'manageAdmins'), isTrue);

        // Admin has high permissions but not leader permissions
        expect(updated.hasPermission(adminId, 'createEvents'), isTrue);
        expect(updated.hasPermission(adminId, 'manageMembers'), isTrue);
        expect(updated.hasPermission(adminId, 'manageAdmins'), isFalse);
        expect(updated.hasPermission(adminId, 'manageLeaders'), isFalse);

        // Member has basic permissions only
        const memberId = 'user-1';
        expect(updated.hasPermission(memberId, 'createEvents'), isTrue);
        expect(updated.hasPermission(memberId, 'manageMembers'), isFalse);
      });
    });

    group('End-to-End: Member Roles and Permissions Flow', () {
      late Club club;

      setUp(() async {
        // Create community and upgrade to club
        final community = await communityService.createCommunityFromEvent(
          event: successfulEvent,
        );

        // Add members and events (retrieve updated community after each operation)
        var currentCommunity = community;
        for (int i = 0; i < 5; i++) {
          await communityService.addMember(currentCommunity, 'member-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }
        for (int i = 2; i <= 4; i++) {
          await communityService.addEvent(currentCommunity, 'event-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }

        final updatedCommunity = await communityService.getCommunityById(community.id);
        club = await clubService.upgradeToClub(
          community: updatedCommunity!,
        );
      });

      test('should promote member through roles: Member → Moderator → Admin → Leader', () async {
        const userId = 'member-0';

        // Start as member
        var role = clubService.getMemberRole(club, userId);
        expect(role, equals(ClubRole.member));

        // Promote to moderator
        await clubService.assignRole(club, userId, ClubRole.moderator);
        var updated = await clubService.getClubById(club.id);
        role = clubService.getMemberRole(updated!, userId);
        expect(role, equals(ClubRole.moderator));
        expect(updated.hasPermission(userId, 'moderateContent'), isTrue);

        // Promote to admin
        await clubService.addAdmin(updated, userId);
        updated = await clubService.getClubById(club.id);
        role = clubService.getMemberRole(updated!, userId);
        expect(role, equals(ClubRole.admin));
        expect(updated.hasPermission(userId, 'manageMembers'), isTrue);
        expect(updated.hasPermission(userId, 'manageAdmins'), isFalse);

        // Promote to leader
        await clubService.addLeader(updated, userId);
        updated = await clubService.getClubById(club.id);
        role = clubService.getMemberRole(updated!, userId);
        expect(role, equals(ClubRole.leader));
        expect(updated.hasPermission(userId, 'manageLeaders'), isTrue);
      });

      test('should enforce role management permissions', () async {
        // Use existing members for roles
        const leaderId = 'member-1';
        const adminId = 'member-2';
        const moderatorId = 'member-3';
        const memberId = 'member-0';

        // Set up roles
        await clubService.addLeader(club, leaderId);
        await clubService.addAdmin(club, adminId);
        await clubService.assignRole(club, moderatorId, ClubRole.moderator);

        final updated = await clubService.getClubById(club.id);
        expect(updated, isNotNull);

        // Leader can manage all roles
        expect(updated!.canManageUser(leaderId, adminId), isTrue);
        expect(updated.canManageUser(leaderId, moderatorId), isTrue);
        expect(updated.canManageUser(leaderId, memberId), isTrue);

        // Admin can manage moderator and member
        expect(updated.canManageUser(adminId, moderatorId), isTrue);
        expect(updated.canManageUser(adminId, memberId), isTrue);
        expect(updated.canManageUser(adminId, leaderId), isFalse);

        // Moderator can manage member
        expect(updated.canManageUser(moderatorId, memberId), isTrue);
        expect(updated.canManageUser(moderatorId, adminId), isFalse);

        // Member cannot manage anyone
        expect(updated.canManageUser(memberId, moderatorId), isFalse);
      });
    });

    group('End-to-End: Geographic Expansion Tracking', () {
      late Club club;

      setUp(() async {
        // Create community and upgrade to club
        final community = await communityService.createCommunityFromEvent(
          event: successfulEvent,
        );

        // Add members and events (retrieve updated community after each operation)
        var currentCommunity = community;
        for (int i = 0; i < 5; i++) {
          await communityService.addMember(currentCommunity, 'member-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }
        for (int i = 2; i <= 4; i++) {
          await communityService.addEvent(currentCommunity, 'event-$i');
          currentCommunity = await communityService.getCommunityById(community.id) ?? currentCommunity;
        }

        final updatedCommunity = await communityService.getCommunityById(community.id);
        club = await clubService.upgradeToClub(
          community: updatedCommunity!,
        );
      });

      test('should track geographic expansion', () async {
        // Update expansion tracking
        final updated = await clubService.updateClub(
          club: club,
          expansionLocalities: [
            'Castro, San Francisco',
            'Haight-Ashbury, San Francisco',
            'North Beach, San Francisco',
          ],
          expansionCities: ['Oakland', 'Berkeley'],
          coveragePercentage: {
            'locality': 0.50,
            'city': 0.75,
            'state': 0.30,
          },
        );

        expect(updated.expansionLocalities.length, equals(3));
        expect(updated.expansionCities.length, equals(2));
        expect(updated.coveragePercentage['locality'], equals(0.50));
        expect(updated.coveragePercentage['city'], equals(0.75));
        expect(updated.coveragePercentage['state'], equals(0.30));
      });
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_community_service.dart';
import 'package:avrai_core/models/expertise/expertise_community.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Expertise Community Service Tests
/// Tests expertise-based community management functionality
void main() {
  group('ExpertiseCommunityService Tests', () {
    late ExpertiseCommunityService service;
    late UnifiedUser user;

    setUp(() {
      service = ExpertiseCommunityService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
    });

    // Removed: Property assignment tests
    // Expertise community tests focus on business logic (creation, membership, search), not property assignment

    group('createCommunity', () {
      test(
          'should create community when user has expertise with optional parameters (location, minLevel, isPublic), or throw exception when creator lacks expertise',
          () async {
        // Test business logic: community creation with validation and parameters
        final community1 = await service.createCommunity(
          creator: user,
          category: 'food',
          description: 'Food experts community',
        );
        expect(community1, isA<ExpertiseCommunity>());
        expect(community1.category, equals('food'));
        expect(community1.memberIds, contains(user.id));
        expect(community1.memberCount, equals(1));
        expect(community1.createdBy, equals(user.id));

        final community2 = await service.createCommunity(
          creator: user,
          category: 'food',
          location: 'San Francisco',
        );
        expect(community2.name, contains('San Francisco'));
        expect(community2.location, equals('San Francisco'));

        final regionalUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'food': 'regional'},
        );
        final community3 = await service.createCommunity(
          creator: regionalUser,
          category: 'food',
          minLevel: ExpertiseLevel.city,
        );
        expect(community3.minLevel, equals(ExpertiseLevel.city));

        final community4 = await service.createCommunity(
          creator: user,
          category: 'food',
          isPublic: false,
        );
        expect(community4.isPublic, equals(false));

        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        expect(
          () => service.createCommunity(
            creator: userWithoutExpertise,
            category: 'food',
          ),
          throwsException,
        );
      });
    });

    group('joinCommunity', () {
      test(
          'should allow user to join community when eligible, or throw exception when user cannot join or is already a member',
          () async {
        // Test business logic: community membership with validation
        final community1 = await service.createCommunity(
          creator: user,
          category: 'food',
        );

        final newUser = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );
        await service.joinCommunity(community1, newUser);
        expect(community1.canUserJoin(newUser), isTrue);

        final community2 = await service.createCommunity(
          creator: user,
          category: 'food',
          minLevel: ExpertiseLevel.city,
        );
        final localUser = ModelFactories.createTestUser(
          id: 'user-789',
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );
        expect(
          () => service.joinCommunity(community2, localUser),
          throwsException,
        );

        final community3 = await service.createCommunity(
          creator: user,
          category: 'food',
        );
        expect(
          () => service.joinCommunity(community3, user),
          throwsException,
        );
      });
    });

    group('leaveCommunity', () {
      test(
          'should allow user to leave community, or throw exception when user is not a member',
          () async {
        // Test business logic: community leaving with validation
        final community1 = await service.createCommunity(
          creator: user,
          category: 'food',
        );
        await service.leaveCommunity(community1, user);
        final updatedCommunity = service.getCommunityById(community1.id);
        expect(updatedCommunity, isNotNull);
        expect(updatedCommunity!.isMember(user), isFalse);

        final community2 = await service.createCommunity(
          creator: user,
          category: 'food',
        );
        final nonMember = ModelFactories.createTestUser(
          id: 'user-456',
        );
        expect(
          () => service.leaveCommunity(community2, nonMember),
          throwsException,
        );
      });
    });

    group('findCommunitiesForUser', () {
      test(
          'should return communities matching user expertise, or return empty list when user has no expertise',
          () async {
        // Test business logic: community discovery for users
        final communities1 = await service.findCommunitiesForUser(user);
        expect(communities1, isA<List<ExpertiseCommunity>>());

        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final communities2 =
            await service.findCommunitiesForUser(userWithoutExpertise);
        expect(communities2, isEmpty);
      });
    });

    group('searchCommunities', () {
      test(
          'should search communities by category or location, and respect maxResults parameter',
          () async {
        // Test business logic: community search with filters
        final communities1 = await service.searchCommunities(category: 'food');
        expect(communities1, isA<List<ExpertiseCommunity>>());

        final communities2 =
            await service.searchCommunities(location: 'San Francisco');
        expect(communities2, isA<List<ExpertiseCommunity>>());

        final communities3 = await service.searchCommunities(
          category: 'food',
          maxResults: 5,
        );
        expect(communities3.length, lessThanOrEqualTo(5));
      });
    });

    group('getCommunityMembers', () {
      test('should return community members', () async {
        final community = await service.createCommunity(
          creator: user,
          category: 'food',
        );

        final members = await service.getCommunityMembers(community);

        expect(members, isA<List<UnifiedUser>>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

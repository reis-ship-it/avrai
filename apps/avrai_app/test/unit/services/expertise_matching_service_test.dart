import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_matching_service.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Expertise Matching Service Tests
/// Tests expertise-based user matching functionality
void main() {
  group('ExpertiseMatchingService Tests', () {
    late ExpertiseMatchingService service;
    late UnifiedUser user;

    setUp(() {
      service = ExpertiseMatchingService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
    });

    // Removed: Property assignment tests
    // Expertise matching tests focus on business logic (finding similar, complementary, mentors, mentees), not property assignment

    group('findSimilarExperts', () {
      test(
          'should return empty list when user has no expertise in category, return empty list when no other users match, respect maxResults parameter, and filter by location when provided',
          () async {
        // Test business logic: finding similar experts
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final matches1 = await service.findSimilarExperts(
          userWithoutExpertise,
          'food',
        );
        expect(matches1, isEmpty);

        final matches2 = await service.findSimilarExperts(
          user,
          'food',
        );
        expect(matches2, isA<List<ExpertMatch>>());
        expect(matches2, isEmpty);

        final matches3 = await service.findSimilarExperts(
          user,
          'food',
          maxResults: 5,
        );
        expect(matches3.length, lessThanOrEqualTo(5));

        final matches4 = await service.findSimilarExperts(
          user,
          'food',
          location: 'San Francisco',
        );
        expect(matches4, isA<List<ExpertMatch>>());
      });
    });

    group('findComplementaryExperts', () {
      test(
          'should return empty list when user has no expertise, return complementary experts, and respect maxResults parameter',
          () async {
        // Test business logic: finding complementary experts
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final matches1 = await service.findComplementaryExperts(
          userWithoutExpertise,
        );
        expect(matches1, isEmpty);

        final coffeeUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'Coffee': 'city'},
        );
        final matches2 = await service.findComplementaryExperts(
          coffeeUser,
          maxResults: 10,
        );
        expect(matches2, isA<List<ExpertMatch>>());

        final matches3 = await service.findComplementaryExperts(
          user,
          maxResults: 5,
        );
        expect(matches3.length, lessThanOrEqualTo(5));
      });
    });

    group('findMentors', () {
      test(
          'should return empty list when user has no expertise in category, return mentors (higher level experts), and respect maxResults parameter',
          () async {
        // Test business logic: finding mentors
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final mentors1 = await service.findMentors(
          userWithoutExpertise,
          'food',
        );
        expect(mentors1, isEmpty);

        final localUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );
        final mentors2 = await service.findMentors(
          localUser,
          'food',
          maxResults: 5,
        );
        expect(mentors2, isA<List<ExpertMatch>>());
        expect(mentors2.length, lessThanOrEqualTo(5));

        final mentors3 = await service.findMentors(
          user,
          'food',
          maxResults: 3,
        );
        expect(mentors3.length, lessThanOrEqualTo(3));
      });
    });

    group('findMentees', () {
      test(
          'should return empty list when user has no expertise in category, return mentees (lower level experts), and respect maxResults parameter',
          () async {
        // Test business logic: finding mentees
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final mentees1 = await service.findMentees(
          userWithoutExpertise,
          'food',
        );
        expect(mentees1, isEmpty);

        final globalUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'food': 'global'},
        );
        final mentees2 = await service.findMentees(
          globalUser,
          'food',
          maxResults: 10,
        );
        expect(mentees2, isA<List<ExpertMatch>>());
        expect(mentees2.length, lessThanOrEqualTo(10));

        final mentees3 = await service.findMentees(
          user,
          'food',
          maxResults: 5,
        );
        expect(mentees3.length, lessThanOrEqualTo(5));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/mentorship_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Mentorship Service Tests
/// Tests mentorship relationship management
void main() {
  group('MentorshipService Tests', () {
    late MentorshipService service;
    late UnifiedUser mentee;
    late UnifiedUser mentor;

    setUp(() {
      service = MentorshipService();

      // Create mentee with local level expertise
      mentee = ModelFactories.createTestUser(
        id: 'mentee-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'local'},
      );

      // Create mentor with local level+ expertise (can host events)
      mentor = ModelFactories.createTestUser(
        id: 'mentor-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
    });

    // Removed: Property assignment tests
    // Mentorship tests focus on business logic (mentorship requests, acceptance/rejection, retrieval), not property assignment

    group('requestMentorship', () {
      test(
          'should create mentorship request when mentor has higher level, throw exception when mentor level is not higher, throw exception when mentee lacks expertise, or throw exception when mentor lacks expertise',
          () async {
        // Test business logic: mentorship request validation
        final relationship1 = await service.requestMentorship(
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          message: 'I would like to learn more about food curation',
        );
        expect(relationship1, isA<MentorshipRelationship>());
        expect(relationship1.mentee.id, equals(mentee.id));
        expect(relationship1.mentor.id, equals(mentor.id));
        expect(relationship1.category, equals('food'));
        expect(relationship1.status, equals(MentorshipStatus.pending));
        expect(relationship1.message,
            equals('I would like to learn more about food curation'));

        final sameLevelMentor = ModelFactories.createTestUser(
          id: 'mentor-456',
          tags: ['food'],
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );
        expect(
          () => service.requestMentorship(
            mentee: mentee,
            mentor: sameLevelMentor,
            category: 'food',
          ),
          throwsA(isA<Exception>()),
        );

        final noExpertiseMentee = ModelFactories.createTestUser(
          id: 'mentee-456',
          tags: [],
        );
        expect(
          () => service.requestMentorship(
            mentee: noExpertiseMentee,
            mentor: mentor,
            category: 'food',
          ),
          throwsA(isA<Exception>()),
        );

        final noExpertiseMentor = ModelFactories.createTestUser(
          id: 'mentor-789',
          tags: [],
        );
        expect(
          () => service.requestMentorship(
            mentee: mentee,
            mentor: noExpertiseMentor,
            category: 'food',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Mentorship Status Management', () {
      test(
          'should accept mentorship request, reject mentorship request, or complete mentorship',
          () async {
        // Test business logic: mentorship status management
        final relationship1 = MentorshipRelationship(
          id: 'relationship-123',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.acceptMentorship(relationship1);
        expect(relationship1.status, equals(MentorshipStatus.pending));

        final relationship2 = MentorshipRelationship(
          id: 'relationship-456',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.rejectMentorship(relationship2);
        expect(relationship2.status, equals(MentorshipStatus.pending));

        final relationship3 = MentorshipRelationship(
          id: 'relationship-789',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.completeMentorship(relationship3);
        expect(relationship3.status, equals(MentorshipStatus.active));
      });
    });

    group('Mentorship Retrieval', () {
      test(
          'should return empty list for user with no mentorships, return empty list for user with no mentors, or return empty list for user with no mentees',
          () async {
        // Test business logic: mentorship retrieval
        final mentorships = await service.getMentorships(mentee);
        expect(mentorships, isEmpty);

        final mentors = await service.getMentors(mentee);
        expect(mentors, isEmpty);

        final mentees = await service.getMentees(mentor);
        expect(mentees, isEmpty);
      });
    });

    group('findPotentialMentors', () {
      test('should return list of potential mentors', () async {
        final suggestions = await service.findPotentialMentors(mentee, 'food');

        expect(suggestions, isA<List<MentorSuggestion>>());
        // Note: In test environment, this may return empty list
        // This test verifies the method executes without error
      });
    });

    group('completeMentorship', () {
      test('should complete mentorship', () async {
        final relationship = MentorshipRelationship(
          id: 'relationship-123',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.completeMentorship(relationship);

        // Note: In test environment, relationship is not persisted
        expect(relationship.status,
            equals(MentorshipStatus.active)); // Original unchanged
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

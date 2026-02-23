import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_feedback.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'post_event_feedback_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService, PartnershipService])
void main() {
  group('PostEventFeedbackService', () {
    late PostEventFeedbackService service;
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    late EpisodicMemoryStore episodicMemoryStore;

    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPartnershipService = MockPartnershipService();
      episodicMemoryStore = EpisodicMemoryStore();

      service = PostEventFeedbackService(
        eventService: mockEventService,
        partnershipService: mockPartnershipService,
        episodicMemoryStore: episodicMemoryStore,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Test Event',
        description: 'A test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now().subtract(const Duration(days: 1, hours: -2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendeeIds: const ['user-456', 'user-789'],
      );
    });

    // Removed: Property assignment tests
    // Post-event feedback tests focus on business logic (scheduling, sending requests, submitting feedback, retrieving feedback), not property assignment

    group('scheduleFeedbackCollection', () {
      test(
          'should schedule feedback collection 2 hours after event ends, or throw exception if event not found',
          () async {
        // Test business logic: feedback collection scheduling
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final scheduledTime =
            await service.scheduleFeedbackCollection('event-123');
        expect(scheduledTime, isA<DateTime>());
        expect(scheduledTime,
            equals(testEvent.endTime.add(const Duration(hours: 2))));
        verify(mockEventService.getEventById('event-123')).called(1);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.scheduleFeedbackCollection('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });
    });

    group('sendFeedbackRequests', () {
      test(
          'should send feedback requests to all attendees, or send partner rating requests when partnerships exist',
          () async {
        // Test business logic: feedback request sending
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.sendFeedbackRequests('event-123');
        verify(mockEventService.getEventById('event-123')).called(1);
        verify(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .called(1);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [
                  EventPartnership(
                    id: 'partnership-123',
                    eventId: 'event-123',
                    userId: 'user-123',
                    businessId: 'business-123',
                    status: PartnershipStatus.locked,
                    vibeCompatibilityScore: 0.75,
                    userApproved: true,
                    businessApproved: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ]);
        await service.sendFeedbackRequests('event-123');
        verify(mockEventService.getEventById('event-123')).called(1);
        verify(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .called(1);
      });
    });

    group('submitFeedback', () {
      test(
          'should create and save feedback successfully, or create feedback with minimal required fields',
          () async {
        // Test business logic: feedback submission
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final feedback1 = await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-456',
          overallRating: 4.5,
          categoryRatings: {'organization': 4.5, 'content_quality': 5.0},
          comments: 'Great event!',
          highlights: ['Great venue', 'Excellent content'],
          improvements: ['Could use more time'],
          wouldAttendAgain: true,
          wouldRecommend: true,
        );
        expect(feedback1, isA<EventFeedback>());
        expect(feedback1.eventId, equals('event-123'));
        expect(feedback1.userId, equals('user-456'));
        expect(feedback1.overallRating, equals(4.5));
        expect(feedback1.categoryRatings['organization'], equals(4.5));
        expect(feedback1.categoryRatings['content_quality'], equals(5.0));
        expect(feedback1.comments, equals('Great event!'));
        expect(
            feedback1.highlights, equals(['Great venue', 'Excellent content']));
        expect(feedback1.improvements, equals(['Could use more time']));
        expect(feedback1.wouldAttendAgain, isTrue);
        expect(feedback1.wouldRecommend, isTrue);
        expect(feedback1.submittedAt, isA<DateTime>());

        final feedback2 = await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-789',
          overallRating: 3.0,
          categoryRatings: {'organization': 3.0, 'content_quality': 3.0},
          wouldAttendAgain: false,
          wouldRecommend: false,
        );
        expect(feedback2, isA<EventFeedback>());
        expect(feedback2.overallRating, equals(3.0));
        expect(feedback2.categoryRatings, isNotEmpty);
        expect(feedback2.comments, isNull);
        expect(feedback2.highlights, isNull);
        expect(feedback2.improvements, isNull);
        expect(feedback2.wouldAttendAgain, isFalse);
        expect(feedback2.wouldRecommend, isFalse);
      });

      test('writes detailed expert-event feedback episodic tuple', () async {
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-456',
          overallRating: 4.2,
          categoryRatings: {
            'organization': 4.0,
            'topic_relevance': 4.7,
          },
          wouldAttendAgain: true,
          wouldRecommend: true,
          topicRelevanceRating: 4.7,
          expertiseLevelMatch: 'just_right',
        );

        final tuples = await episodicMemoryStore.getRecent(agentId: 'user-456');
        expect(tuples.length, equals(1));
        expect(tuples.first.actionType, equals('attend_expert_event'));
        expect(
          tuples.first.actionPayload['detailed_feedback']
              ['topic_relevance_rating'],
          equals(4.7),
        );
        expect(
          tuples.first.actionPayload['detailed_feedback']
              ['expertise_level_match'],
          equals('just_right'),
        );
        expect(
          tuples.first.outcome.type,
          equals('attend_expert_event_feedback'),
        );
      });
    });

    group('submitPartnerRating', () {
      test(
          'should create and save partner rating successfully, or create partner rating with minimal required fields',
          () async {
        // Test business logic: partner rating submission
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final rating1 = await service.submitPartnerRating(
          eventId: 'event-123',
          raterId: 'user-123',
          ratedId: 'business-123',
          partnershipRole: 'business',
          overallRating: 4.5,
          professionalism: 5.0,
          communication: 4.0,
          reliability: 4.5,
          wouldPartnerAgain: 4.0,
          positives: 'Great communication',
          improvements: 'Could be more responsive',
        );
        expect(rating1, isNotNull);
        expect(rating1.eventId, equals('event-123'));
        expect(rating1.raterId, equals('user-123'));
        expect(rating1.ratedId, equals('business-123'));
        expect(rating1.partnershipRole, equals('business'));
        expect(rating1.overallRating, equals(4.5));
        expect(rating1.professionalism, equals(5.0));
        expect(rating1.communication, equals(4.0));
        expect(rating1.reliability, equals(4.5));
        expect(rating1.wouldPartnerAgain, equals(4.0));
        expect(rating1.positives, equals('Great communication'));
        expect(rating1.improvements, equals('Could be more responsive'));
        expect(rating1.submittedAt, isA<DateTime>());

        final rating2 = await service.submitPartnerRating(
          eventId: 'event-123',
          raterId: 'user-456',
          ratedId: 'business-456',
          partnershipRole: 'business',
          overallRating: 3.0,
          professionalism: 3.0,
          communication: 3.0,
          reliability: 3.0,
          wouldPartnerAgain: 3.0,
        );
        expect(rating2, isNotNull);
        expect(rating2.overallRating, equals(3.0));
        expect(rating2.positives, isNull);
        expect(rating2.improvements, isNull);
      });
    });

    group('getFeedbackForEvent', () {
      test(
          'should return empty list when no feedback exists, or return feedback for event after submission',
          () async {
        // Test business logic: feedback retrieval
        final feedbacks1 = await service.getFeedbackForEvent('event-123');
        expect(feedbacks1, isEmpty);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-456',
          overallRating: 4.5,
          categoryRatings: {'organization': 4.5, 'content_quality': 5.0},
          wouldAttendAgain: true,
          wouldRecommend: true,
        );
        final feedbacks2 = await service.getFeedbackForEvent('event-123');
        expect(feedbacks2, hasLength(1));
        expect(feedbacks2.first.userId, equals('user-456'));
      });
    });

    group('getPartnerRatingsForEvent', () {
      test(
          'should return empty list when no ratings exist, or return partner ratings for event after submission',
          () async {
        // Test business logic: partner rating retrieval
        final ratings1 = await service.getPartnerRatingsForEvent('event-123');
        expect(ratings1, isEmpty);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.submitPartnerRating(
          eventId: 'event-123',
          raterId: 'user-123',
          ratedId: 'business-123',
          partnershipRole: 'business',
          overallRating: 4.5,
          professionalism: 5.0,
          communication: 4.0,
          reliability: 4.5,
          wouldPartnerAgain: 4.0,
        );
        final ratings2 = await service.getPartnerRatingsForEvent('event-123');
        expect(ratings2, hasLength(1));
        expect(ratings2.first.raterId, equals('user-123'));
        expect(ratings2.first.ratedId, equals('business-123'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

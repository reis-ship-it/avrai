import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/events/event_success_metrics.dart';
import 'package:avrai_core/models/events/event_feedback.dart'
    hide PartnerRating;
import 'package:avrai_core/models/expertise/partner_rating.dart'; // Use PartnerRating from partner_rating.dart (matches service)
import 'package:avrai_core/models/events/event_success_level.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'event_success_analysis_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  ExpertiseEventService,
  PostEventFeedbackService,
  PaymentService,
])
void main() {
  group('EventSuccessAnalysisService', () {
    late EventSuccessAnalysisService service;
    late MockExpertiseEventService mockEventService;
    late MockPostEventFeedbackService mockFeedbackService;
    late MockPaymentService mockPaymentService;

    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    late List<EventFeedback> testFeedbacks;
    late List<PartnerRating>
        testPartnerRatings; // PartnerRating from event_feedback.dart

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockFeedbackService = MockPostEventFeedbackService();
      mockPaymentService = MockPaymentService();

      service = EventSuccessAnalysisService(
        eventService: mockEventService,
        feedbackService: mockFeedbackService,
        paymentService: mockPaymentService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
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
        maxAttendees: 50,
        attendeeCount: 40,
        isPaid: true,
        price: 25.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testFeedbacks = [
        EventFeedback(
          id: 'feedback-1',
          eventId: 'event-123',
          userId: 'user-456',
          userRole: 'attendee',
          overallRating: 5.0,
          categoryRatings: const {'organization': 5.0, 'content': 5.0},
          comments: 'Amazing event!',
          highlights: const ['Great venue', 'Excellent content'],
          improvements: const [],
          submittedAt: DateTime.now(),
          wouldAttendAgain: true,
          wouldRecommend: true,
        ),
        EventFeedback(
          id: 'feedback-2',
          eventId: 'event-123',
          userId: 'user-789',
          userRole: 'attendee',
          overallRating: 4.0,
          categoryRatings: const {'organization': 4.0, 'content': 4.0},
          comments: 'Good event',
          highlights: const ['Nice atmosphere'],
          improvements: const ['Could use more time'],
          submittedAt: DateTime.now(),
          wouldAttendAgain: true,
          wouldRecommend: true,
        ),
        EventFeedback(
          id: 'feedback-3',
          eventId: 'event-123',
          userId: 'user-101',
          userRole: 'attendee',
          overallRating: 3.0,
          categoryRatings: const {'organization': 3.0, 'content': 3.0},
          comments: 'It was okay',
          highlights: const [],
          improvements: const ['Needs improvement'],
          submittedAt: DateTime.now(),
          wouldAttendAgain: false,
          wouldRecommend: false,
        ),
      ];

      testPartnerRatings = [
        PartnerRating(
          id: 'rating-1',
          eventId: 'event-123',
          partnershipId: 'partnership-123',
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
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    // Removed: Property assignment tests
    // Event success analysis tests focus on business logic (analysis, metrics calculation, success determination), not property assignment

    group('analyzeEventSuccess', () {
      test(
          'should analyze event success with feedback successfully, throw exception if event not found, and handle event with no feedback',
          () async {
        // Test business logic: basic event success analysis
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => testPartnerRatings);
        final metrics1 = await service.analyzeEventSuccess('event-123');
        expect(metrics1, isA<EventSuccessMetrics>());
        expect(metrics1.eventId, equals('event-123'));
        expect(metrics1.ticketsSold, equals(40));
        expect(metrics1.averageRating, closeTo(4.0, 0.1));
        expect(metrics1.successLevel, isA<EventSuccessLevel>());
        expect(metrics1.successFactors, isNotEmpty);
        expect(metrics1.improvementAreas, isNotEmpty);
        verify(mockEventService.getEventById('event-123')).called(1);
        verify(mockFeedbackService.getFeedbackForEvent('event-123')).called(1);
        verify(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .called(1);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.analyzeEventSuccess('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => []);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final metrics2 = await service.analyzeEventSuccess('event-123');
        expect(metrics2, isA<EventSuccessMetrics>());
        expect(metrics2.averageRating, equals(0.0));
        expect(metrics2.fiveStarCount, equals(0));
        expect(metrics2.fourStarCount, equals(0));
        expect(metrics2.threeStarCount, equals(0));
      });

      test(
          'should calculate attendance metrics, financial metrics, quality metrics, and NPS correctly',
          () async {
        // Test business logic: metrics calculation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final metrics = await service.analyzeEventSuccess('event-123');
        expect(metrics.ticketsSold, equals(40));
        expect(metrics.actualAttendance, greaterThan(0));
        expect(metrics.attendanceRate, greaterThan(0));
        expect(metrics.attendanceRate, lessThanOrEqualTo(1.0));
        expect(metrics.grossRevenue, equals(1000.0));
        expect(metrics.netRevenue, greaterThan(0));
        expect(metrics.netRevenue, lessThan(metrics.grossRevenue));
        expect(metrics.profitMargin, greaterThan(0));
        expect(metrics.averageRating, closeTo(4.0, 0.1));
        expect(metrics.fiveStarCount, equals(1));
        expect(metrics.fourStarCount, equals(1));
        expect(metrics.threeStarCount, equals(1));
        expect(metrics.attendeesWhoWouldReturn, equals(2));
        expect(metrics.attendeesWhoWouldRecommend, equals(2));
        expect(metrics.nps, greaterThan(0));
      });

      test(
          'should determine success level based on metrics, identify success factors from feedback, and identify improvement areas from feedback',
          () async {
        // Test business logic: success determination
        final successfulEvent = testEvent.copyWith(
          attendeeCount: 45,
        );
        final highRatingFeedbacks = [
          EventFeedback(
            id: 'feedback-1',
            eventId: 'event-123',
            userId: 'user-456',
            userRole: 'attendee',
            overallRating: 4.8,
            categoryRatings: const {'organization': 4.8, 'content': 4.8},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
        ];
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => successfulEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => highRatingFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final metrics1 = await service.analyzeEventSuccess('event-123');
        expect(metrics1.successLevel, isA<EventSuccessLevel>());

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final metrics2 = await service.analyzeEventSuccess('event-123');
        expect(metrics2.successFactors, isNotEmpty);
        expect(
            metrics2.successFactors.any((f) =>
                f.contains('High attendance') ||
                f.contains('Excellent ratings') ||
                f.contains('Great venue') ||
                f.contains('Excellent content')),
            isTrue);
        expect(metrics2.improvementAreas, isNotEmpty);
        expect(
            metrics2.improvementAreas.any((a) =>
                a.contains('Needs improvement') ||
                a.contains('Could use more time')),
            isTrue);
      });

      test(
          'should include partner satisfaction scores and handle free events (no financial metrics)',
          () async {
        // Test business logic: special cases (partner satisfaction, free events)
        final singleFeedback = [
          EventFeedback(
            id: 'feedback-1',
            eventId: 'event-123',
            userId: 'user-456',
            userRole: 'attendee',
            overallRating: 4.0,
            categoryRatings: const {'organization': 4.0, 'content': 4.0},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
        ];
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => singleFeedback);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => testPartnerRatings);
        final metrics1 = await service.analyzeEventSuccess('event-123');
        expect(metrics1.partnerSatisfaction, isNotEmpty);
        expect(
            metrics1.partnerSatisfaction.containsKey('business-123'), isTrue);
        expect(metrics1.partnersWouldCollaborateAgain, isA<bool>());

        final freeEvent = testEvent.copyWith(
          isPaid: false,
          price: null,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => freeEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        final metrics2 = await service.analyzeEventSuccess('event-123');
        expect(metrics2.grossRevenue, equals(0.0));
        expect(metrics2.netRevenue, equals(0.0));
      });
    });

    group('getEventMetrics', () {
      test(
          'should return null if metrics not found, or return metrics after analysis',
          () async {
        // Test business logic: metrics retrieval
        final metrics1 = await service.getEventMetrics('event-123');
        expect(metrics1, isNull);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.analyzeEventSuccess('event-123');
        final metrics2 = await service.getEventMetrics('event-123');
        expect(metrics2, isNotNull);
        expect(metrics2!.eventId, equals('event-123'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

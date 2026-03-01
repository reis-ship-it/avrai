import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/events/event_safety_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/events/event_safety_guidelines.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'event_safety_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('EventSafetyService', () {
    late EventSafetyService service;
    late MockExpertiseEventService mockEventService;

    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();

      service = EventSafetyService(
        eventService: mockEventService,
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
        eventType: ExpertiseEventType.workshop,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        maxAttendees: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Event safety tests focus on business logic (guideline generation, emergency info, insurance, requirements), not property assignment

    group('generateGuidelines', () {
      test(
          'should generate guidelines for event with event-type-specific and size-specific requirements, or throw exception if event not found',
          () async {
        // Test business logic: guideline generation with all event types and sizes
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        final guidelines = await service.generateGuidelines('event-123');
        expect(guidelines, isA<EventSafetyGuidelines>());
        expect(guidelines.eventId, equals('event-123'));
        expect(guidelines.type, equals(ExpertiseEventType.workshop));
        expect(guidelines.requirements, isNotEmpty);
        expect(guidelines.acknowledged, isFalse);
        expect(guidelines.emergencyInfo, isNotNull);
        expect(guidelines.insurance, isNotNull);
        expect(
            guidelines.requirements, contains(SafetyRequirement.firstAidKit));
        expect(
            guidelines.requirements, contains(SafetyRequirement.capacityLimit));
        expect(guidelines.requirements,
            contains(SafetyRequirement.emergencyExits));

        final tourEvent = testEvent.copyWith(
            eventType: ExpertiseEventType.tour, maxAttendees: 20);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => tourEvent);
        final tourGuidelines = await service.generateGuidelines('event-123');
        expect(tourGuidelines.requirements,
            contains(SafetyRequirement.weatherPlan));
        expect(tourGuidelines.requirements,
            contains(SafetyRequirement.crowdControl));

        final tastingEvent =
            testEvent.copyWith(eventType: ExpertiseEventType.tasting);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => tastingEvent);
        final tastingGuidelines = await service.generateGuidelines('event-123');
        expect(tastingGuidelines.requirements,
            contains(SafetyRequirement.foodSafety));
        expect(tastingGuidelines.requirements,
            contains(SafetyRequirement.alcoholPolicy));
        expect(tastingGuidelines.requirements,
            contains(SafetyRequirement.firstAidKit));

        final largeEvent = testEvent.copyWith(maxAttendees: 75);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => largeEvent);
        final largeGuidelines = await service.generateGuidelines('event-123');
        expect(largeGuidelines.requirements,
            contains(SafetyRequirement.accessibilityPlan));
        expect(largeGuidelines.requirements,
            contains(SafetyRequirement.crowdControl));

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.generateGuidelines('event-123'),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('Event not found'))),
        );
      });
    });

    group('getEmergencyInfo', () {
      test(
          'should return emergency information for event, use provided event if passed, or throw exception if event not found',
          () async {
        // Test business logic: emergency info retrieval
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        final emergencyInfo = await service.getEmergencyInfo('event-123');
        expect(emergencyInfo, isNotNull);
        expect(emergencyInfo.contacts, isNotEmpty);
        expect(emergencyInfo.contacts.first.role, equals('Host'));
        expect(emergencyInfo.nearestHospital, isNotNull);
        verify(mockEventService.getEventById('event-123')).called(1);

        final providedInfo =
            await service.getEmergencyInfo('event-123', testEvent);
        expect(providedInfo, isNotNull);
        expect(providedInfo.contacts, isNotEmpty);
        verifyNever(mockEventService.getEventById(any));

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.getEmergencyInfo('event-123'),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('Event not found'))),
        );
      });
    });

    group('getInsuranceRecommendation', () {
      test(
          'should return insurance recommendation for event, and recommend insurance for large or paid events',
          () {
        // Test business logic: insurance recommendation with different event types
        final recommendation = service.getInsuranceRecommendation(testEvent);
        expect(recommendation, isNotNull);
        expect(recommendation.suggestedCoverageAmount, greaterThan(0));
        expect(recommendation.recommended, isA<bool>());

        final largeEvent = testEvent.copyWith(maxAttendees: 100);
        final largeRecommendation =
            service.getInsuranceRecommendation(largeEvent);
        expect(largeRecommendation.recommended, isTrue);

        final paidEvent = testEvent.copyWith(isPaid: true, price: 50.0);
        final paidRecommendation =
            service.getInsuranceRecommendation(paidEvent);
        expect(paidRecommendation.recommended, isTrue);
      });
    });

    group('getGuidelines', () {
      test(
          'should return existing guidelines if available, or generate guidelines if not available',
          () async {
        // Test business logic: guideline retrieval with auto-generation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.generateGuidelines('event-123');

        final existingGuidelines = await service.getGuidelines('event-123');
        expect(existingGuidelines, isNotNull);
        expect(existingGuidelines!.eventId, equals('event-123'));

        // Clear and test generation
        final newService = EventSafetyService(eventService: mockEventService);
        final generatedGuidelines = await newService.getGuidelines('event-123');
        expect(generatedGuidelines, isNotNull);
        expect(generatedGuidelines!.eventId, equals('event-123'));
      });
    });

    group('acknowledgeGuidelines', () {
      test(
          'should acknowledge guidelines successfully, or throw exception if guidelines not found',
          () async {
        // Test business logic: guideline acknowledgment with error handling
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.generateGuidelines('event-123');

        await service.acknowledgeGuidelines('event-123');
        final guidelines = await service.getGuidelines('event-123');
        expect(guidelines!.acknowledged, isTrue);
        expect(guidelines.acknowledgedAt, isNotNull);

        // Test with event that has no guidelines (use different event ID)
        when(mockEventService.getEventById('event-no-guidelines'))
            .thenAnswer((_) async => null);
        expect(
          () => service.acknowledgeGuidelines('event-no-guidelines'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Guidelines not found'))),
        );
      });
    });

    group('determineSafetyRequirements', () {
      test(
          'should determine requirements for workshop, tour, and tasting events',
          () {
        // Test business logic: safety requirement determination for all event types
        final workshopRequirements =
            service.determineSafetyRequirements(testEvent);
        expect(workshopRequirements, contains(SafetyRequirement.firstAidKit));
        expect(workshopRequirements, contains(SafetyRequirement.capacityLimit));

        final tourEvent = testEvent.copyWith(
            eventType: ExpertiseEventType.tour, maxAttendees: 20);
        final tourRequirements = service.determineSafetyRequirements(tourEvent);
        expect(tourRequirements, contains(SafetyRequirement.weatherPlan));

        final tastingEvent =
            testEvent.copyWith(eventType: ExpertiseEventType.tasting);
        final tastingRequirements =
            service.determineSafetyRequirements(tastingEvent);
        expect(tastingRequirements, contains(SafetyRequirement.foodSafety));
        expect(tastingRequirements, contains(SafetyRequirement.alcoholPolicy));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

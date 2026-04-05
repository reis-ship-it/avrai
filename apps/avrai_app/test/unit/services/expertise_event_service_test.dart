import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_scope_service.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_locality_connection_service.dart';
import 'package:avrai_runtime_os/services/community/community_event_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/spots/spot.dart';
import '../../fixtures/model_factories.dart';

import 'expertise_event_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  GeographicScopeService,
  CrossLocalityConnectionService,
  CommunityEventService,
])

/// Expertise Event Service Tests
/// Tests expert-led event management functionality
void main() {
  group('ExpertiseEventService Tests', () {
    late ExpertiseEventService service;
    late MockGeographicScopeService mockGeographicScopeService;
    late MockCrossLocalityConnectionService mockCrossLocalityService;
    late MockCommunityEventService mockCommunityEventService;
    late UnifiedUser host;
    late List<Spot> spots;

    setUp(() {
      mockGeographicScopeService = MockGeographicScopeService();
      mockCrossLocalityService = MockCrossLocalityConnectionService();
      mockCommunityEventService = MockCommunityEventService();

      // Mock getCommunityEvents to return empty list by default
      // Tests can override this if they need specific community events
      when(mockCommunityEventService.getCommunityEvents(
        category: anyNamed('category'),
        location: anyNamed('location'),
        eventType: anyNamed('eventType'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => []);

      // Use mocked dependencies to break circular dependency
      service = ExpertiseEventService(
        geographicScopeService: mockGeographicScopeService,
        crossLocalityService: mockCrossLocalityService,
        communityEventService: mockCommunityEventService,
      );
      host = ModelFactories.createTestUser(
        id: 'host-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
      spots = [
        ModelFactories.createTestSpot(name: 'Spot 1'),
        ModelFactories.createTestSpot(name: 'Spot 2'),
      ];
    });

    // Removed: Property assignment tests
    // Expertise event tests focus on business logic (event creation, registration, search), not property assignment

    group('createEvent', () {
      test(
          'should create event when host has local level expertise, set isPaid when price provided, include spots when provided, or throw exception when host lacks expertise or expertise in category',
          () async {
        // Test business logic: event creation with validation
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );
        expect(event, isA<ExpertiseEvent>());
        expect(event.title, equals('Food Tour'));
        expect(event.category, equals('food'));
        expect(event.host.id, equals(host.id));
        expect(event.status, equals(EventStatus.upcoming));

        final paidEvent = await service.createEvent(
          host: host,
          title: 'Paid Workshop',
          description: 'A paid workshop',
          category: 'food',
          eventType: ExpertiseEventType.workshop,
          startTime: startTime,
          endTime: endTime,
          price: 50.0,
        );
        expect(paidEvent.isPaid, isTrue);
        expect(paidEvent.price, equals(50.0));

        final spotEvent = await service.createEvent(
          host: host,
          title: 'Spot Tour',
          description: 'Tour of spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
          spots: spots,
        );
        expect(spotEvent.spots.length, equals(spots.length));

        final userWithoutExpertise =
            ModelFactories.createTestUser(id: 'host-456');
        expect(
          () => service.createEvent(
            host: userWithoutExpertise,
            title: 'Food Tour',
            description: 'A guided food tour',
            category: 'food',
            eventType: ExpertiseEventType.tour,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<Exception>()),
        );

        final hostWithoutCategory =
            ModelFactories.createTestUser(id: 'host-789')
                .copyWith(expertiseMap: {'coffee': 'city'});
        expect(
          () => service.createEvent(
            host: hostWithoutCategory,
            title: 'Food Tour',
            description: 'A guided food tour',
            category: 'food',
            eventType: ExpertiseEventType.tour,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsException,
        );
      });
    });

    group('registerForEvent', () {
      test(
          'should register user for event, or throw exception when event is full',
          () async {
        // Test business logic: event registration with capacity checking
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );
        final attendee = ModelFactories.createTestUser(id: 'attendee-123');
        await service.registerForEvent(event, attendee);
        expect(event.canUserAttend(attendee.id), isTrue);

        final fullEvent = await service.createEvent(
          host: host,
          title: 'Full Event',
          description: 'Event at capacity',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
          maxAttendees: 1,
        );
        final attendee1 = ModelFactories.createTestUser(id: 'attendee-1');
        final attendee2 = ModelFactories.createTestUser(id: 'attendee-2');
        await service.registerForEvent(fullEvent, attendee1);
        final updatedEvent = await service.getEventById(fullEvent.id);
        expect(
          () => service.registerForEvent(updatedEvent!, attendee2),
          throwsException,
        );
      });
    });

    group('cancelRegistration', () {
      test(
          'should cancel user registration, or throw exception when user is not registered',
          () async {
        // Test business logic: registration cancellation with validation
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );
        final attendee = ModelFactories.createTestUser(id: 'attendee-123');
        await service.registerForEvent(event, attendee);
        final registeredEvent = await service.getEventById(event.id);
        await service.cancelRegistration(registeredEvent!, attendee);
        final cancelledEvent = await service.getEventById(event.id);
        expect(cancelledEvent!.canUserAttend(attendee.id), isTrue);

        final nonAttendee = ModelFactories.createTestUser(id: 'non-attendee');
        expect(
          () => service.cancelRegistration(event, nonAttendee),
          throwsException,
        );
      });
    });

    group('getEventsByHost', () {
      test('should return events hosted by expert', () async {
        // Test business logic: event retrieval by host
        final events = await service.getEventsByHost(host);
        expect(events, isA<List<ExpertiseEvent>>());
      });
    });

    group('getEventsByAttendee', () {
      test('should return events user is attending', () async {
        // Test business logic: event retrieval by attendee
        final user = ModelFactories.createTestUser(id: 'user-123');
        final events = await service.getEventsByAttendee(user);
        expect(events, isA<List<ExpertiseEvent>>());
      });
    });

    group('searchEvents', () {
      test(
          'should search events by category, filter by location and event type, and respect maxResults parameter',
          () async {
        // Test business logic: event search with various filters
        final categoryEvents = await service.searchEvents(category: 'food');
        expect(categoryEvents, isA<List<ExpertiseEvent>>());

        final locationEvents =
            await service.searchEvents(location: 'San Francisco');
        expect(locationEvents, isA<List<ExpertiseEvent>>());

        final typeEvents =
            await service.searchEvents(eventType: ExpertiseEventType.tour);
        expect(typeEvents, isA<List<ExpertiseEvent>>());

        final limitedEvents =
            await service.searchEvents(category: 'food', maxResults: 10);
        expect(limitedEvents.length, lessThanOrEqualTo(10));
      });
    });

    group('getUpcomingEventsInCategory', () {
      test('should return upcoming events in category', () async {
        // Test business logic: upcoming events retrieval
        final events = await service.getUpcomingEventsInCategory(
          'food',
          maxResults: 10,
        );
        expect(events, isA<List<ExpertiseEvent>>());
        expect(events.length, lessThanOrEqualTo(10));
      });
    });

    group('updateEventStatus', () {
      test('should update event status', () async {
        // Test business logic: event status update
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));
        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );
        await service.updateEventStatus(event, EventStatus.completed);
        final updatedEvent = await service.getEventById(event.id);
        expect(updatedEvent!.status, equals(EventStatus.completed));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

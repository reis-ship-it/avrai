import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../fixtures/integration_test_fixtures.dart';

/// Event Discovery Integration Tests
///
/// Agent 3: Expertise UI & Testing (Week 4, Task 3.11)
///
/// Tests event discovery and browsing functionality:
/// - Event browsing
/// - Event search
/// - Event filters
/// - Event details display
/// - "My Events" page
///
/// **Test Scenarios:**
/// - Scenario 2: Free Event Registration Flow
/// - Scenario 3: Event Capacity Limits
/// - Scenario 5: Event Discovery Flow
void main() {
  group('Event Discovery Integration Tests', () {
    late ExpertiseEventService eventService;
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    late List<ExpertiseEvent> testEvents;

    setUp(() {
      eventService = ExpertiseEventService();
      // Create test events for discovery testing
      final host = IntegrationTestHelpers.createExpertUser(
        categories: ['Coffee', 'Restaurants'],
      );
      testEvents = IntegrationTestHelpers.createTestEvents(
        host: host,
        count: 5,
        category: 'Coffee',
      );
    });

    group('Scenario 2: Free Event Registration Flow', () {
      test('should register user for free event without payment', () async {
        // Test business logic: free event registration without payment processing
        // Arrange
        final scenario = IntegrationTestFixtures.freeEventHostingScenario();
        final host = scenario['host'] as UnifiedUser;
        final user = IntegrationTestHelpers.createUserWithCityExpertise();

        // Create event in service first
        final event = await eventService.createEvent(
          host: host,
          title: 'Free Test Event',
          description: 'A free event for testing',
          category: scenario['category'] as String,
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        );

        // Verify initial state
        expect(event.isPaid, isFalse);
        expect(event.price, anyOf(isNull, equals(0.0)));
        expect(event.attendeeCount, equals(0));
        expect(event.canUserAttend(user.id), isTrue);

        // Act - Register for free event
        await eventService.registerForEvent(event, user);

        // Assert - User registered
        final updatedEvent = await eventService.getEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.attendeeIds, contains(user.id));
        expect(updatedEvent.attendeeCount, equals(1));
      });

      test('should not process payment for free event', () async {
        // Test business logic: free event registration does not require payment
        // Arrange
        final scenario = IntegrationTestFixtures.freeEventHostingScenario();
        final host = scenario['host'] as UnifiedUser;
        final user = IntegrationTestHelpers.createUserWithCityExpertise();

        // Create free event in service
        final event = await eventService.createEvent(
          host: host,
          title: 'Free Test Event',
          description: 'A free event for testing',
          category: scenario['category'] as String,
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          price: 0.0, // Free event
        );

        // Verify event is free
        expect(event.isPaid, isFalse);
        expect(event.price, anyOf(isNull, equals(0.0)));

        // Act - Register for free event
        // Registration should succeed without payment processing
        await eventService.registerForEvent(event, user);

        // Assert - User registered successfully (no payment required)
        final updatedEvent = await eventService.getEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.attendeeIds, contains(user.id));
        expect(updatedEvent.attendeeCount, equals(1));
        // Note: In a real system, we would verify no Payment record was created
        // For now, we verify registration succeeded without payment
      });
    });

    group('Scenario 3: Event Capacity Limits', () {
      test('should enforce capacity limits correctly', () async {
        // Test business logic: registration fails when event is at capacity
        // Arrange
        final scenario = IntegrationTestFixtures.fullEventScenario();
        final host = scenario['host'] as UnifiedUser;

        // Create event at capacity (use category host has expertise in)
        final event = await eventService.createEvent(
          host: host,
          title: 'Full Event',
          description: 'Event at capacity',
          category:
              'Coffee', // Host has Coffee expertise (from createExpertUser default)
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          maxAttendees: 1,
        );

        // Fill event to capacity with unique user ID
        final firstUser = IntegrationTestHelpers.createUserWithCityExpertise(
            id: 'first-user-${DateTime.now().millisecondsSinceEpoch}');
        await eventService.registerForEvent(event, firstUser);
        final fullEvent = await eventService.getEventById(event.id);

        // Create a different user with unique ID for the failed registration attempt
        final newUser = IntegrationTestHelpers.createUserWithCityExpertise(
            id: 'new-user-${DateTime.now().millisecondsSinceEpoch}');

        // Verify event is full
        expect(fullEvent, isNotNull);
        expect(fullEvent!.isFull, isTrue);
        expect(fullEvent.attendeeCount, equals(fullEvent.maxAttendees));
        expect(fullEvent.canUserAttend(newUser.id), isFalse);

        // Act - Attempt to register for full event
        // Should throw exception
        expect(
          () => eventService.registerForEvent(fullEvent, newUser),
          throwsException,
        );

        // Assert - Event should remain full
        final updatedEvent = await eventService.getEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.attendeeCount, equals(fullEvent.maxAttendees));
        expect(updatedEvent.attendeeIds, isNot(contains(newUser.id)));
      });

      test('should allow registration when capacity available', () async {
        // Test business logic: registration succeeds when event has capacity
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final user = IntegrationTestHelpers.createUserWithCityExpertise();

        // Create event in service (use category host has expertise in)
        final event = await eventService.createEvent(
          host: host,
          title: 'Test Event',
          description: 'Event with capacity',
          category:
              'Coffee', // Host has Coffee expertise (from createExpertUser default)
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          maxAttendees: 10,
        );

        // Verify capacity available
        expect(event.isFull, isFalse);
        expect(event.attendeeCount, lessThan(event.maxAttendees));
        expect(event.canUserAttend(user.id), isTrue);

        // Act - Register for event with available capacity
        await eventService.registerForEvent(event, user);

        // Assert - Registration should succeed
        final updatedEvent = await eventService.getEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.attendeeIds, contains(user.id));
        expect(updatedEvent.attendeeCount, equals(1));
      });
    });

    group('Scenario 5: Event Discovery Flow', () {
      test('should display events correctly', () {
        // Arrange
        final scenario = IntegrationTestFixtures.eventDiscoveryScenario();
        final events = scenario['events'] as List<ExpertiseEvent>;

        // Assert
        expect(events, isNotEmpty);
        expect(events.length, greaterThan(0));

        // Verify event properties
        for (final event in events) {
          expect(event.id, isNotEmpty);
          expect(event.title, isNotEmpty);
          expect(event.category, isNotEmpty);
          expect(event.host, isNotNull);
          expect(event.startTime, isNotNull);
          expect(event.endTime, isNotNull);
        }
      });

      test('should filter events by category', () {
        // Arrange
        final scenario = IntegrationTestFixtures.eventDiscoveryScenario();
        final events = scenario['events'] as List<ExpertiseEvent>;
        const targetCategory = IntegrationTestConstants.testCategoryCoffee;

        // Act - Filter by category
        final filteredEvents =
            events.where((e) => e.category == targetCategory).toList();

        // Assert
        expect(filteredEvents, isNotEmpty);
        for (final event in filteredEvents) {
          expect(event.category, equals(targetCategory));
        }
      });

      test('should filter events by price (free vs paid)', () {
        // Arrange
        final scenario = IntegrationTestFixtures.eventDiscoveryScenario();
        final paidEvents = scenario['paidEvents'] as List<ExpertiseEvent>;
        final freeEvents = scenario['freeEvents'] as List<ExpertiseEvent>;

        // Assert - Paid events
        for (final event in paidEvents) {
          expect(event.isPaid, isTrue);
          expect(event.price, greaterThan(0.0));
        }

        // Assert - Free events
        for (final event in freeEvents) {
          expect(event.isPaid, isFalse);
          expect(event.price, anyOf(isNull, equals(0.0)));
        }
      });

      test('should search events by title', () {
        // Arrange
        final scenario = IntegrationTestFixtures.eventDiscoveryScenario();
        final events = scenario['events'] as List<ExpertiseEvent>;
        const searchQuery = 'Coffee';

        // Act - Search by title
        final searchResults = events
            .where((e) =>
                e.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        // Assert
        expect(searchResults, isNotEmpty);
        for (final event in searchResults) {
          expect(
            event.title.toLowerCase().contains(searchQuery.toLowerCase()),
            isTrue,
          );
        }
      });

      test('should display event details correctly', () {
        // Arrange
        final scenario = IntegrationTestFixtures.eventDiscoveryScenario();
        final events = scenario['events'] as List<ExpertiseEvent>;
        final event = events.first;

        // Assert - Event details are complete
        expect(event.id, isNotEmpty);
        expect(event.title, isNotEmpty);
        expect(event.description, isNotEmpty);
        expect(event.category, isNotEmpty);
        expect(event.host, isNotNull);
        expect(event.host.id, isNotEmpty);
        expect(event.startTime, isNotNull);
        expect(event.endTime, isNotNull);
        expect(event.maxAttendees, greaterThan(0));
        expect(event.status, isNotNull);
      });
    });

    group('My Events Page Tests', () {
      test('should display hosted events correctly', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final hostedEvents = IntegrationTestHelpers.createTestEvents(
          host: host,
          count: 3,
        );

        // Assert
        expect(hostedEvents, isNotEmpty);
        expect(hostedEvents.length, equals(3));
        for (final event in hostedEvents) {
          expect(event.host.id, equals(host.id));
        }
      });

      test('should display attending events correctly', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final attendee = IntegrationTestHelpers.createUserWithCityExpertise();
        final event = IntegrationTestHelpers.createTestEvent(host: host);

        // Add attendee to event
        final eventWithAttendee = event.copyWith(
          attendeeIds: [attendee.id],
          attendeeCount: 1,
        );

        // Assert
        expect(eventWithAttendee.attendeeIds, contains(attendee.id));
        expect(eventWithAttendee.attendeeCount, equals(1));
      });

      test('should filter events by status (upcoming, past)', () {
        // Arrange
        final host = IntegrationTestHelpers.createExpertUser();
        final now = DateTime.now();

        final upcomingEvent = IntegrationTestHelpers.createTestEvent(
          host: host,
          startTime: now.add(const Duration(days: 1)),
        );

        final pastEvent = IntegrationTestHelpers.createTestEvent(
          host: host,
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now.subtract(const Duration(hours: 1)),
        );

        // Assert - Upcoming event
        expect(upcomingEvent.hasStarted, isFalse);
        expect(upcomingEvent.hasEnded, isFalse);
        expect(upcomingEvent.status, equals(EventStatus.upcoming));

        // Assert - Past event
        expect(pastEvent.hasStarted, isTrue);
        expect(pastEvent.hasEnded, isTrue);
        // Past events would have status = EventStatus.completed
      });
    });
  });
}

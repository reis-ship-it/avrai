import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:avrai/core/services/community/community_event_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/models/community/community_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Manual mock for ExpertiseEventService
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Comprehensive tests for CommunityEventService
/// Tests non-expert event creation, validation, metrics tracking, and event management
///
/// **Philosophy Alignment:**
/// - Opens doors for non-experts to host community events
/// - Enables organic community building
/// - Creates path from community events to expert events
void main() {
  group('CommunityEventService Tests', () {
    late CommunityEventService service;
    late UnifiedUser nonExpertHost;
    late UnifiedUser expertHost;

    setUp(() {
      TestHelpers.setupTestEnvironment();

      service = CommunityEventService();

      // Create non-expert host (no expertise)
      nonExpertHost = ModelFactories.createTestUser(
        id: 'non-expert-1',
      ).copyWith();

      // Create expert host (has Local level expertise)
      expertHost = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'Coffee',
        location: 'Mission District, San Francisco',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Community event creation tests focus on business logic (validation, payment enforcement, date validation), not property assignment

    group('createCommunityEvent', () {
      test(
          'should allow non-experts and experts to create events, enforce no payment and public events, and validate required fields and dates',
          () async {
        // Test business logic: event creation with validation and constraints
        // Test non-expert creation
        final nonExpertEvent = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Community Coffee Meetup',
          description: 'A casual meetup for coffee lovers',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        expect(nonExpertEvent.isCommunityEvent, isTrue);
        expect(nonExpertEvent.hostExpertiseLevel, isNull);

        // Test expert creation
        final expertEvent = await service.createCommunityEvent(
          host: expertHost,
          title: 'Expert Community Event',
          description: 'An expert hosting a community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        expect(expertEvent.isCommunityEvent, isTrue);

        // Test payment enforcement (must be free)
        final freeEvent = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Free Community Event',
          description: 'Free event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
        expect(freeEvent.price, isNull);
        expect(freeEvent.isPaid, isFalse);

        // Test public events only
        final publicEvent = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Public Community Event',
          description: 'Public event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          isPublic: true,
        );
        expect(publicEvent.isPublic, isTrue);

        // Test validation - required fields
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: '',
            description: 'Test event',
            category: 'Coffee',
            eventType: ExpertiseEventType.meetup,
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
          throwsA(isA<Exception>()),
        );
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: 'Test Event',
            description: '',
            category: 'Coffee',
            eventType: ExpertiseEventType.meetup,
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
          throwsA(isA<Exception>()),
        );
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: 'Test Event',
            description: 'Test description',
            category: '',
            eventType: ExpertiseEventType.meetup,
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
          throwsA(isA<Exception>()),
        );

        // Test date validation
        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 2));
        final validEvent = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Test Event',
          description: 'Test description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: startTime,
          endTime: endTime,
        );
        expect(validEvent.startTime.isBefore(validEvent.endTime), isTrue);

        final pastStartTime = DateTime.now().subtract(const Duration(days: 1));
        final pastEndTime = pastStartTime.add(const Duration(hours: 2));
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: 'Test Event',
            description: 'Test description',
            category: 'Coffee',
            eventType: ExpertiseEventType.meetup,
            startTime: pastStartTime,
            endTime: pastEndTime,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Event Metrics Tracking', () {
      test(
          'should track attendance, engagement score, growth metrics, and diversity metrics',
          () async {
        // Test business logic: metrics tracking for community events
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Test Event',
          description: 'Test description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        await service.trackAttendance(event, 15);
        final event1 = await service.getCommunityEventById(event.id);
        expect(event1!.attendeeCount, equals(15));

        await service.trackEngagement(event,
            viewCount: 100, saveCount: 25, shareCount: 10);
        final event2 = await service.getCommunityEventById(event.id);
        expect(event2!.engagementScore, greaterThanOrEqualTo(0.0));
        expect(event2.engagementScore, lessThanOrEqualTo(1.0));

        await service.trackGrowth(event, [10, 15]);
        final event3 = await service.getCommunityEventById(event.id);
        expect(event3!.growthMetrics, greaterThanOrEqualTo(0.0));

        await service.trackDiversity(event, 0.75);
        final event4 = await service.getCommunityEventById(event.id);
        expect(event4!.diversityMetrics, greaterThanOrEqualTo(0.0));
        expect(event4.diversityMetrics, lessThanOrEqualTo(1.0));
      });
    });

    group('Event Management', () {
      test(
          'should get all community events, filter by host and category, update event details, and cancel events',
          () async {
        // Test business logic: event management operations
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Test Event',
          description: 'Test description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        final allEvents = await service.getCommunityEvents();
        expect(allEvents, isA<List<CommunityEvent>>());
        expect(allEvents, contains(event));

        final hostEvents =
            await service.getCommunityEventsByHost(nonExpertHost);
        expect(hostEvents.every((e) => e.host.id == nonExpertHost.id), isTrue);

        final categoryEvents =
            await service.getCommunityEventsByCategory('Coffee');
        expect(categoryEvents.every((e) => e.category == 'Coffee'), isTrue);

        final updatedEvent = await service.updateCommunityEvent(
          event: event,
          title: 'Updated Title',
          description: 'Updated description',
        );
        expect(updatedEvent.title, equals('Updated Title'));
        expect(updatedEvent.id, equals(event.id));

        final cancelledEvent = await service.cancelCommunityEvent(event);
        expect(cancelledEvent.status, equals(EventStatus.cancelled));
      });
    });

    group('Integration with ExpertiseEventService', () {
      test(
          'should make community events accessible through event service and allow filtering',
          () async {
        // Test business logic: integration with event service
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Searchable Event',
          description: 'This should appear in search',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        final retrievedEvent = await service.getCommunityEventById(event.id);
        expect(retrievedEvent, isNotNull);
        expect(retrievedEvent!.id, equals(event.id));
        expect(event.isCommunityEvent, isTrue);

        final communityEvents = await service.getCommunityEvents();
        expect(communityEvents, isA<List<CommunityEvent>>());
        expect(communityEvents.every((e) => e.isCommunityEvent), isTrue);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

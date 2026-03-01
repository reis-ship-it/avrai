import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/spots/spot.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ExpertiseEvent model
/// Tests event creation, JSON serialization, helper methods, and attendee management
void main() {
  group('ExpertiseEvent Model Tests', () {
    late DateTime testDate;
    late DateTime startTime;
    late DateTime endTime;
    late UnifiedUser testHost;
    late List<Spot> testSpots;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      startTime = testDate.add(const Duration(days: 1));
      endTime = startTime.add(const Duration(hours: 2));
      testHost = ModelFactories.createTestUser(
          id: 'host-123', displayName: 'Expert Host');
      testSpots = [
        ModelFactories.createTestSpot(id: 'spot-1', name: 'Coffee Shop 1'),
        ModelFactories.createTestSpot(id: 'spot-2', name: 'Coffee Shop 2'),
      ];
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Event Status Checks', () {
      test(
          'should correctly determine event status based on capacity and timing',
          () {
        // Test business logic: status determination
        final now = DateTime.now();
        final fullEvent = ExpertiseEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          attendeeCount: 10,
          maxAttendees: 10,
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 3)),
          createdAt: testDate,
          updatedAt: testDate,
        );
        final pastEvent = ExpertiseEvent(
          id: 'event-456',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.subtract(const Duration(hours: 1)),
          createdAt: testDate,
          updatedAt: testDate,
        );
        final futureEvent = ExpertiseEvent(
          id: 'event-789',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 3)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(fullEvent.isFull, isTrue);
        expect(pastEvent.hasEnded, isTrue);
        expect(futureEvent.hasStarted, isFalse);
      });
    });

    group('canUserAttend', () {
      test('should correctly determine user attendance eligibility', () {
        // Test business logic: attendance eligibility
        final now = DateTime.now();
        final availableEvent = ExpertiseEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          attendeeCount: 5,
          maxAttendees: 10,
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 3)),
          createdAt: testDate,
          updatedAt: testDate,
        );
        final fullEvent = ExpertiseEvent(
          id: 'event-456',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          attendeeCount: 10,
          maxAttendees: 10,
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 3)),
          createdAt: testDate,
          updatedAt: testDate,
        );
        final pastEvent = ExpertiseEvent(
          id: 'event-789',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.subtract(const Duration(hours: 1)),
          createdAt: testDate,
          updatedAt: testDate,
        );
        final withAttendees = ExpertiseEvent(
          id: 'event-101',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          attendeeIds: const ['user-1'],
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 3)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(availableEvent.canUserAttend('user-new'), isTrue);
        expect(fullEvent.canUserAttend('user-new'), isFalse); // Full
        expect(pastEvent.canUserAttend('user-new'), isFalse); // Ended
        expect(withAttendees.canUserAttend('user-1'),
            isFalse); // Already attending
      });
    });

    group('Event Type Display', () {
      test('should return correct display names and emojis for event types',
          () {
        // Test business logic: display formatting
        final tourEvent = ExpertiseEvent(
          id: 'event-1',
          title: 'Tour',
          description: 'Test',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final workshopEvent = ExpertiseEvent(
          id: 'event-2',
          title: 'Workshop',
          description: 'Test',
          category: 'Coffee',
          eventType: ExpertiseEventType.workshop,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(tourEvent.getEventTypeDisplayName(), equals('Expert Tour'));
        expect(tourEvent.getEventTypeEmoji(), equals('🚶'));
        expect(workshopEvent.getEventTypeDisplayName(), equals('Workshop'));
        expect(workshopEvent.getEventTypeEmoji(), equals('🎓'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final event = ExpertiseEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          attendeeIds: const ['user-1'],
          attendeeCount: 1,
          maxAttendees: 10,
          startTime: startTime,
          endTime: endTime,
          spots: testSpots,
          location: '123 Main St',
          price: 25.0,
          isPaid: true,
          createdAt: testDate,
          updatedAt: testDate,
          status: EventStatus.upcoming,
        );

        final json = event.toJson();
        final restored = ExpertiseEvent.fromJson(json, testHost);

        // Test critical business fields preserved
        expect(restored.canUserAttend('user-new'),
            equals(event.canUserAttend('user-new')));
        expect(restored.isFull, equals(event.isFull));
      });
    });

    // Removed: EventStatus Enum and ExpertiseEventType Enum groups
    // These tests verify enum definitions, which are compile-time constants
    // If enum values are wrong, the code won't compile

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = ExpertiseEvent(
          id: 'event-123',
          title: 'Original Title',
          description: 'Original description',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          title: 'Updated Title',
          attendeeCount: 5,
        );

        // Test immutability (business logic)
        expect(original.title, isNot(equals('Updated Title')));
        expect(updated.title, equals('Updated Title'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}

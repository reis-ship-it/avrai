import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/controllers/event_attendance_controller.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'event_attendance_controller_test.mocks.dart';

void main() {
  group('EventAttendanceController phase 1 outcomes', () {
    late MockExpertiseEventService mockEventService;
    late MockPaymentProcessingController mockPaymentController;
    late MockPreferencesProfileService mockPreferencesService;
    late MockAgentIdService mockAgentIdService;
    late EpisodicMemoryStore episodicStore;
    late EventAttendanceController controller;

    final now = DateTime.now().toUtc();
    final futureTime = now.add(const Duration(days: 7));

    late ExpertiseEvent testEvent;
    late UnifiedUser attendee;

    setUp(() async {
      mockEventService = MockExpertiseEventService();
      mockPaymentController = MockPaymentProcessingController();
      mockPreferencesService = MockPreferencesProfileService();
      mockAgentIdService = MockAgentIdService();
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();

      controller = EventAttendanceController(
        eventService: mockEventService,
        paymentController: mockPaymentController,
        preferencesService: mockPreferencesService,
        agentIdService: mockAgentIdService,
        atomicClock: AtomicClockService(),
        episodicMemoryStore: episodicStore,
      );

      attendee = UnifiedUser(
        id: 'user_123',
        email: 'user@test.com',
        displayName: 'Test User',
        createdAt: now,
        updatedAt: now,
      );

      testEvent = ExpertiseEvent(
        id: 'event_123',
        title: 'Test Event',
        description: 'Test Description',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        host: UnifiedUser(
          id: 'host_123',
          email: 'host@test.com',
          displayName: 'Host User',
          createdAt: now,
          updatedAt: now,
        ),
        startTime: futureTime,
        endTime: futureTime.add(const Duration(hours: 2)),
        location: 'Test Location',
        maxAttendees: 10,
        price: 0.0,
        isPaid: false,
        status: EventStatus.upcoming,
        createdAt: now,
        updatedAt: now,
        attendeeIds: const [],
        attendeeCount: 0,
      );
    });

    test('records attend_event tuple with checkin_confirmed outcome', () async {
      final updatedEvent = testEvent.copyWith(
        attendeeIds: [attendee.id],
        attendeeCount: 1,
      );
      when(mockEventService.registerForEvent(testEvent, attendee))
          .thenAnswer((_) async {});
      when(mockEventService.getEventById('event_123'))
          .thenAnswer((_) async => updatedEvent);
      when(mockAgentIdService.getUserAgentId('user_123'))
          .thenAnswer((_) async => 'agent_user_123');
      when(mockPreferencesService.getPreferencesProfile('agent_user_123'))
          .thenAnswer((_) async => null);

      final result = await controller.registerForEvent(
        event: testEvent,
        attendee: attendee,
        quantity: 1,
      );

      expect(result.success, true);
      final tuples = await episodicStore.replay(agentId: 'agent_user_123');
      expect(tuples.length, 1);
      expect(tuples.first.actionType, 'attend_event');
      expect(tuples.first.outcome.type, 'checkin_confirmed');
      expect(tuples.first.outcome.value, 1.0);
    });
  });
}

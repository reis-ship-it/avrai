import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../fixtures/model_factories.dart';
import 'post_event_feedback_service_test.mocks.dart';

void main() {
  group('PostEventFeedbackService 1.2.3 quality outcomes', () {
    late MockExpertiseEventService mockEventService;
    late PostEventFeedbackService service;
    late EpisodicMemoryStore episodicMemoryStore;
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      episodicMemoryStore = EpisodicMemoryStore();
      service = PostEventFeedbackService(
        eventService: mockEventService,
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
        endTime: DateTime.now().subtract(const Duration(hours: 22)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendeeIds: const ['user-456'],
      );
      when(mockEventService.getEventById('event-123'))
          .thenAnswer((_) async => testEvent);
    });

    test('records quality outcome tuple for standard feedback submissions',
        () async {
      await service.submitFeedback(
        eventId: 'event-123',
        userId: 'user-456',
        overallRating: 4.0,
        categoryRatings: const {'organization': 4.0},
        wouldAttendAgain: true,
        wouldRecommend: true,
      );

      final tuples = await episodicMemoryStore.getRecent(agentId: 'user-456');
      final tuple =
          tuples.firstWhere((t) => t.metadata['phase_ref'] == '1.2.3');
      expect(tuple.actionType, 'feedback_rating');
      expect(tuple.outcome.category.name, 'quality');
      expect(tuple.outcome.value, 4.0);
    });
  });
}

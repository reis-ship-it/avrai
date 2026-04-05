import 'package:avrai/presentation/pages/events/my_events_page.dart';
import 'package:avrai_core/models/events/event_feedback.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/platform_channel_helper.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

final _testPromptPolicyService = BoundedFollowUpPromptPolicyService(
  policy: BoundedFollowUpPromptPolicy(
    maxPromptPlansPerDay: 10,
    quietHoursStartHour: 0,
    quietHoursEndHour: 0,
    suggestionFamilyCooldown: Duration(seconds: 1),
    eventFamilyCooldown: Duration(seconds: 1),
  ),
);

class _FakeExpertiseEventService extends ExpertiseEventService {
  _FakeExpertiseEventService({
    required this.hostedEvents,
    required this.attendingEvents,
  });

  final List<ExpertiseEvent> hostedEvents;
  final List<ExpertiseEvent> attendingEvents;

  @override
  Future<List<ExpertiseEvent>> getEventsByHost(UnifiedUser host) async {
    return hostedEvents;
  }

  @override
  Future<List<ExpertiseEvent>> getEventsByAttendee(UnifiedUser user) async {
    return attendingEvents;
  }
}

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  testWidgets('shows event follow-up queue and completes a plan',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'my_events_follow_up_queue_prefs'),
    );
    final planner = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );
    final host = UnifiedUser(
      id: 'host_123',
      email: 'host@example.com',
      displayName: 'Host User',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
    );
    final event = ExpertiseEvent(
      id: 'event_123',
      title: 'Rooftop Jazz Night',
      description: 'Live music and conversation.',
      category: 'Music',
      eventType: ExpertiseEventType.meetup,
      host: host,
      startTime: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      endTime: DateTime.now().toUtc().subtract(const Duration(days: 2)).add(
            const Duration(hours: 3),
          ),
      createdAt: DateTime.utc(2026, 4, 1, 12),
      updatedAt: DateTime.utc(2026, 4, 1, 12),
      status: EventStatus.completed,
      attendeeIds: const <String>['test-user-id'],
      cityCode: 'austin',
      localityCode: 'austin_east',
    );

    await planner.createPlan(
      feedback: EventFeedback(
        id: 'feedback_123',
        eventId: event.id,
        userId: 'test-user-id',
        userRole: 'attendee',
        overallRating: 2.9,
        categoryRatings: const <String, double>{'venue': 2.5},
        comments: 'It felt too packed.',
        submittedAt: DateTime.utc(2026, 4, 5, 3),
        wouldAttendAgain: false,
        wouldRecommend: false,
      ),
      event: event,
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: MyEventsPage(
          eventService: _FakeExpertiseEventService(
            hostedEvents: const <ExpertiseEvent>[],
            attendingEvents: <ExpertiseEvent>[event],
          ),
          eventFeedbackPromptPlannerService: planner,
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);
    await tester.tap(find.text('Past'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Follow-up queue'), findsOneWidget);
    expect(
      find.textContaining(
        'What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Answer now'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Event follow-up'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'The room filled up too quickly and it became hard to stay.',
    );
    await WidgetTestHelpers.safePumpAndSettle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Follow-up queue'), findsNothing);
    final pendingPlans = await planner.listPendingPlans('test-user-id');
    final responses = await planner.listResponses('test-user-id');
    expect(pendingPlans, isEmpty);
    expect(responses, hasLength(1));
    expect(
      responses.single.responseText,
      'The room filled up too quickly and it became hard to stay.',
    );
  });

  testWidgets('supports dont-ask-again on the event follow-up queue',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'my_events_follow_up_dont_ask_again_prefs',
      ),
    );
    final planner = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );
    final host = UnifiedUser(
      id: 'host_123',
      email: 'host@example.com',
      displayName: 'Host User',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
    );
    final event = ExpertiseEvent(
      id: 'event_ask_again',
      title: 'Rooftop Jazz Night',
      description: 'Live music and conversation.',
      category: 'Music',
      eventType: ExpertiseEventType.meetup,
      host: host,
      startTime: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      endTime: DateTime.now().toUtc().subtract(const Duration(days: 2)).add(
            const Duration(hours: 3),
          ),
      createdAt: DateTime.utc(2026, 4, 1, 12),
      updatedAt: DateTime.utc(2026, 4, 1, 12),
      status: EventStatus.completed,
      attendeeIds: const <String>['test-user-id'],
      cityCode: 'austin',
      localityCode: 'austin_east',
    );

    final plan = await planner.createPlan(
      feedback: EventFeedback(
        id: 'feedback_block',
        eventId: event.id,
        userId: 'test-user-id',
        userRole: 'attendee',
        overallRating: 2.9,
        categoryRatings: const <String, double>{'venue': 2.5},
        comments: 'It felt too packed.',
        submittedAt: DateTime.utc(2026, 4, 5, 3),
        wouldAttendAgain: false,
        wouldRecommend: false,
      ),
      event: event,
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: MyEventsPage(
          eventService: _FakeExpertiseEventService(
            hostedEvents: const <ExpertiseEvent>[],
            attendingEvents: <ExpertiseEvent>[event],
          ),
          eventFeedbackPromptPlannerService: planner,
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);
    await tester.tap(find.text('Past'));
    await WidgetTestHelpers.safePumpAndSettle(tester);
    expect(find.text('Follow-up queue'), findsOneWidget);

    await tester.tap(find.text("Don't ask again"));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Follow-up queue'), findsNothing);
    final updatedPlan = (await planner.listPlans('test-user-id'))
        .firstWhere((candidate) => candidate.planId == plan.planId);
    expect(updatedPlan.status, 'dont_ask_again_local_bounded_follow_up');
  });
}

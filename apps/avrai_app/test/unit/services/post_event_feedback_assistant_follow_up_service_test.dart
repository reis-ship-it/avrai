import 'package:avrai_core/models/events/event_feedback.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _testPromptPolicyService = BoundedFollowUpPromptPolicyService(
  policy: BoundedFollowUpPromptPolicy(
    maxPromptPlansPerDay: 10,
    quietHoursStartHour: 0,
    quietHoursEndHour: 0,
    suggestionFamilyCooldown: Duration(seconds: 1),
    eventFamilyCooldown: Duration(seconds: 1),
  ),
);

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  test('assistant follow-up service offers and captures bounded event plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'post_event_feedback_assistant_follow_up_prefs',
      ),
    );
    final planner = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );
    final service = PostEventFeedbackAssistantFollowUpService(
      plannerService: planner,
    );

    await planner.createPlan(
      feedback: EventFeedback(
        id: 'feedback_123',
        eventId: 'event_123',
        userId: 'user_event',
        userRole: 'attendee',
        overallRating: 2.8,
        categoryRatings: const <String, double>{'venue': 2.5},
        comments: 'The room felt too packed.',
        submittedAt: DateTime.utc(2026, 4, 5, 3),
        wouldAttendAgain: false,
        wouldRecommend: false,
      ),
      event: ExpertiseEvent(
        id: 'event_123',
        title: 'Rooftop Jazz Night',
        description: 'Live music and conversation.',
        category: 'Music',
        eventType: ExpertiseEventType.meetup,
        host: UnifiedUser(
          id: 'host_123',
          email: 'host@example.com',
          displayName: 'Host User',
          createdAt: DateTime.utc(2026, 4, 1),
          updatedAt: DateTime.utc(2026, 4, 1),
        ),
        startTime: DateTime.utc(2026, 4, 4, 22),
        endTime: DateTime.utc(2026, 4, 5, 1),
        createdAt: DateTime.utc(2026, 4, 1, 12),
        updatedAt: DateTime.utc(2026, 4, 1, 12),
        cityCode: 'austin',
        localityCode: 'austin_east',
      ),
    );

    final offer = await service.maybeOfferFollowUp(
      ownerUserId: 'user_event',
    );

    expect(offer, isNotNull);
    expect(
      offer!.assistantPrompt,
      contains(
        'Quick event follow-up: What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
      ),
    );
    expect(
      (await planner.listPlans('user_event')).single.status,
      'assistant_follow_up_offered',
    );

    final response = await service.captureActiveAssistantFollowUpResponse(
      ownerUserId: 'user_event',
      responseText: 'The crowding made it hard to stay through the full set.',
    );

    expect(response, isNotNull);
    expect(
      response!.responseText,
      'The crowding made it hard to stay through the full set.',
    );
    expect(await planner.activeAssistantFollowUpPlan('user_event'), isNull);
    expect(await planner.listPendingPlans('user_event'), isEmpty);
  });
}

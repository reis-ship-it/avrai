import 'package:avrai_core/models/events/event_feedback.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_prompt_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/model_factories.dart';
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
  late UnifiedUser hostUser;
  late ExpertiseEvent testEvent;
  late EventFeedback testFeedback;

  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  setUp(() {
    hostUser = ModelFactories.createTestUser(
      id: 'host_123',
      displayName: 'Host User',
    );
    testEvent = ExpertiseEvent(
      id: 'event_123',
      title: 'Rooftop Jazz Night',
      description: 'Live music and conversation.',
      category: 'Music',
      eventType: ExpertiseEventType.meetup,
      host: hostUser,
      startTime: DateTime.utc(2026, 4, 4, 22, 0),
      endTime: DateTime.utc(2026, 4, 5, 1, 0),
      createdAt: DateTime.utc(2026, 4, 1, 12, 0),
      updatedAt: DateTime.utc(2026, 4, 1, 12, 0),
      cityCode: 'austin',
      localityCode: 'austin_east',
      attendeeIds: const <String>['user_event'],
    );
    testFeedback = EventFeedback(
      id: 'feedback_123',
      eventId: testEvent.id,
      userId: 'user_event',
      userRole: 'attendee',
      overallRating: 2.9,
      categoryRatings: const <String, double>{
        'venue': 2.5,
        'organization': 3.0,
      },
      comments: 'The music was great but the room felt packed.',
      improvements: const <String>['Better spacing'],
      submittedAt: DateTime.utc(2026, 4, 5, 3, 0),
      wouldAttendAgain: false,
      wouldRecommend: false,
    );
  });

  test('planner persists bounded post-event follow-up grounded in feedback',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'event_feedback_prompt_planner_prefs',
      ),
    );
    final service = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      feedback: testFeedback,
      event: testEvent,
    );

    final plans = await service.listPlans(testFeedback.userId);
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.priority, 'high');
    expect(plans.single.channelHint, 'event_reflection_follow_up');
    expect(
      plans.single.promptQuestion,
      'What about "Rooftop Jazz Night" should AVRAI change or avoid repeating next time?',
    );
    expect(
      plans.single.boundedContext['what'],
      'event_feedback on event_123:Rooftop Jazz Night',
    );
    expect(plans.single.boundedContext['where'], 'austin_east');
    expect(plans.single.boundedContext['feedbackRole'], 'attendee');
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:event_feedback_follow_up_plan',
        'surface:post_event_feedback',
        'feedback_role:attendee',
        'rating_category:venue',
      ]),
    );
  });

  test(
      'planner stages completed event follow-up responses into governed upward intake',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'event_feedback_prompt_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      feedback: testFeedback,
      event: testEvent,
    );
    final response = await service.completePlanWithResponse(
      ownerUserId: testFeedback.userId,
      planId: plan.planId,
      responseText:
          'The crowding made it hard to stay and settle into the music.',
      sourceSurface: 'assistant_follow_up_chat',
    );

    final reviews = await repository.getAllReviewItems();
    final sources = await repository.getAllSources();

    expect(response.completionMode, 'assistant_follow_up_chat');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'event_feedback_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['convictionTier'],
      'event_feedback_follow_up_correction_signal',
    );
    expect(
      reviews.single.payload['completionMode'],
      'assistant_follow_up_chat',
    );
    expect(
      reviews.single.payload['responseText'],
      'The crowding made it hard to stay and settle into the music.',
    );
    expect(
      reviews.single.payload['upwardSignalTags'],
      containsAll(const <String>[
        'source:event_feedback_follow_up_response',
        'completion_mode:assistant_follow_up_chat',
        'role:attendee',
      ]),
    );
    expect(
      sources.single.metadata['upwardDomainHints'],
      containsAll(const <String>['community', 'event', 'locality', 'venue']),
    );
  });

  test('planner defers event follow-up plans behind cooldown policy', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'event_feedback_prompt_defer_policy_prefs',
      ),
    );
    final service = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      feedback: testFeedback,
      event: testEvent,
    );

    expect(await service.listPendingPlans(testFeedback.userId), hasLength(1));

    await service.deferPlan(
      ownerUserId: testFeedback.userId,
      planId: plan.planId,
    );

    expect(await service.listPendingPlans(testFeedback.userId), isEmpty);
    final deferredPlan = (await service.listPlans(testFeedback.userId)).single;
    expect(deferredPlan.status, 'deferred_in_app_follow_up');
    expect(deferredPlan.boundedContext['nextEligibleAtUtc'], isNotNull);
  });

  test('dont-ask-again suppresses the same event follow-up permanently',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'event_feedback_prompt_dont_ask_again_prefs',
      ),
    );
    final service = PostEventFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final original = await service.createPlan(
      feedback: testFeedback,
      event: testEvent,
    );

    await service.dontAskAgainForPlan(
      ownerUserId: testFeedback.userId,
      planId: original.planId,
    );

    final replanned = await service.createPlan(
      feedback: testFeedback.copyWith(
        id: 'feedback_456',
        submittedAt: DateTime.utc(2026, 4, 5, 4, 0),
      ),
      event: testEvent,
    );

    final plans = await service.listPlans(testFeedback.userId);
    final originalUpdated = plans.firstWhere(
      (candidate) => candidate.planId == original.planId,
    );

    expect(originalUpdated.status, 'dont_ask_again_local_bounded_follow_up');
    expect(replanned.status, 'suppressed_local_bounded_follow_up');
    expect(await service.listPendingPlans(testFeedback.userId), isEmpty);
  });
}

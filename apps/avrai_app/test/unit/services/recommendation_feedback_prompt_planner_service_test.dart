import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_prompt_planner_service.dart';
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

  test('planner persists bounded follow-up grounded in structured feedback',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'recommendation_feedback_prompt_planner_prefs',
      ),
    );
    final service = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_456',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_456',
        title: 'Late Night Ramen',
        localityLabel: 'birmingham_southside',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 4, 4, 0),
      sourceSurface: 'explore_discovery',
      attribution: const RecommendationAttribution(
        why: 'Matches your late-night food preferences',
        whyDetails: 'We saw recent saves around casual Southside dinner spots',
        projectedEnjoyabilityPercent: 74,
        recommendationSource: 'place_intelligence_lane',
        confidence: 0.71,
      ),
      metadata: const <String, dynamic>{
        'domains': <String>['place', 'food'],
        'interaction_context': 'late_night_discovery',
      },
    );

    final plans = await service.listPlans('user_456');

    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.priority, 'high');
    expect(plans.single.channelHint, 'next_contextual_session');
    expect(
      plans.single.promptQuestion,
      'What felt off about "Late Night Ramen" for you right then?',
    );
    expect(
      plans.single.promptRationale,
      contains('lessLikeThis signal on explore_discovery'),
    );
    expect(
      plans.single.boundedContext['what'],
      'lessLikeThis on spot:spot_456:Late Night Ramen',
    );
    expect(
      plans.single.boundedContext['why'],
      'We saw recent saves around casual Southside dinner spots',
    );
    expect(
      plans.single.boundedContext['how'],
      'place_intelligence_lane via explore_discovery',
    );
    expect(plans.single.boundedContext['whenUtc'], '2026-04-04T04:00:00.000Z');
    expect(plans.single.boundedContext['where'], 'birmingham_southside');
    expect(plans.single.boundedContext['who'], 'owner_user_feedback_actor');
    expect(
      plans.single.signalTags,
      containsAll(
        const <String>[
          'feedback_action:lessLikeThis',
          'entity_type:spot',
          'source_surface:explore_discovery',
          'locality:birmingham_southside',
          'recommendation_source:place_intelligence_lane',
          'domain:place',
          'domain:food',
        ],
      ),
    );
  });

  test('planner supports bounded in-app queue lifecycle and local responses',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'recommendation_feedback_prompt_queue_prefs',
      ),
    );
    final service = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_queue',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.event,
        id: 'event_123',
        title: 'Sunset DJ Set',
        localityLabel: 'austin_east',
      ),
      action: RecommendationFeedbackAction.fun,
      occurredAtUtc: DateTime.utc(2026, 4, 4, 5, 0),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why: 'Matches your social-energy preferences',
        whyDetails:
            'It ranked high because you keep opening early-evening sets',
        projectedEnjoyabilityPercent: 81,
        recommendationSource: 'event_recommendation',
        confidence: 0.76,
      ),
    );

    expect(await service.listPendingPlans('user_queue'), hasLength(1));

    await service.deferPlan(
      ownerUserId: 'user_queue',
      planId: plan.planId,
    );
    final deferred = await service.listPendingPlans('user_queue');
    expect(deferred, isEmpty);
    final deferredPlan = (await service.listPlans('user_queue')).single;
    expect(deferredPlan.status, 'deferred_in_app_follow_up');
    expect(
      deferredPlan.boundedContext['nextEligibleAtUtc'],
      isNotNull,
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_queue',
      planId: plan.planId,
      responseText:
          'It looked good, but I wanted something smaller and quieter.',
      sourceSurface: 'explore_in_app_follow_up',
    );

    expect(response.planId, plan.planId);
    expect(response.completionMode, 'in_app_follow_up_queue');
    expect(
      response.boundedContext['promptQuestion'],
      plan.promptQuestion,
    );
    expect(await service.listPendingPlans('user_queue'), isEmpty);
    final responses = await service.listResponses('user_queue');
    expect(responses, hasLength(1));
    expect(
      responses.single.responseText,
      'It looked good, but I wanted something smaller and quieter.',
    );
    expect(
      (await service.listPlans('user_queue')).single.status,
      'completed_in_app_follow_up',
    );
  });

  test(
      'planner preserves surfaced explanation wording for why-did-you-show-this feedback',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'recommendation_feedback_prompt_explanation_prefs',
      ),
    );
    final service = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_explanation',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.event,
        id: 'event_explanation',
        title: 'Austin After Dark',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.whyDidYouShowThis,
      occurredAtUtc: DateTime.utc(2026, 4, 5, 2, 0),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why:
            'A recent signal that you wanted louder nightlife scenes also boosted this recommendation.',
        whyDetails:
            'Event recommendations come from your current knot and live event timing.',
        projectedEnjoyabilityPercent: 83,
        recommendationSource: 'event_recommendation',
        confidence: 0.81,
      ),
    );

    expect(
      plan.promptQuestion,
      contains(
        'because "A recent signal that you wanted louder nightlife scenes also boosted this recommendation."',
      ),
    );
    expect(
      plan.promptRationale,
      contains(
        'The runtime already recorded the explanation as "A recent signal that you wanted louder nightlife scenes also boosted this recommendation."',
      ),
    );
    expect(
      plan.boundedContext['why'],
      'A recent signal that you wanted louder nightlife scenes also boosted this recommendation.',
    );
    expect(
      plan.boundedContext['whyDetails'],
      'Event recommendations come from your current knot and live event timing.',
    );
  });

  test(
      'planner stages completed follow-up responses into governed upward intake',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'recommendation_feedback_prompt_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_upward',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_upward',
        title: 'Heatwave Cafe',
        localityLabel: 'brooklyn_williamsburg',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 4, 18, 0),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why: 'Matches your indoor coffee pattern',
        whyDetails: 'It ranked because you kept saving indoor daytime places',
        projectedEnjoyabilityPercent: 75,
        recommendationSource: 'place_intelligence_lane',
        confidence: 0.78,
      ),
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_upward',
      planId: plan.planId,
      responseText: 'It felt too loud and crowded for what I wanted.',
      sourceSurface: 'assistant_follow_up_chat',
    );

    final reviews = await repository.getAllReviewItems();
    final sources = await repository.getAllSources();

    expect(response.completionMode, 'assistant_follow_up_chat');
    expect(reviews, hasLength(1));
    expect(sources, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'recommendation_feedback_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['convictionTier'],
      'recommendation_feedback_follow_up_correction_signal',
    );
    expect(
      reviews.single.payload['responseText'],
      'It felt too loud and crowded for what I wanted.',
    );
    expect(
      reviews.single.payload['completionMode'],
      'assistant_follow_up_chat',
    );
    expect(
      reviews.single.payload['upwardSignalTags'],
      containsAll(
        const <String>[
          'source:recommendation_feedback_follow_up_response',
          'completion_mode:assistant_follow_up_chat',
          'entity_type:spot',
        ],
      ),
    );
    expect(
      sources.single.metadata['upwardDomainHints'],
      containsAll(const <String>['locality', 'place', 'venue']),
    );
  });

  test('dont-ask-again suppresses the same recommendation target permanently',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'recommendation_feedback_prompt_dont_ask_again_prefs',
      ),
    );
    final service = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final original = await service.createPlan(
      ownerUserId: 'user_blocked',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_blocked',
        title: 'Crowded Cafe',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 5, 1, 0),
      sourceSurface: 'explore',
    );

    await service.dontAskAgainForPlan(
      ownerUserId: 'user_blocked',
      planId: original.planId,
    );

    final replanned = await service.createPlan(
      ownerUserId: 'user_blocked',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_blocked',
        title: 'Crowded Cafe',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 5, 2, 0),
      sourceSurface: 'explore',
    );

    final plans = await service.listPlans('user_blocked');
    final originalUpdated = plans.firstWhere(
      (candidate) => candidate.planId == original.planId,
    );

    expect(originalUpdated.status, 'dont_ask_again_local_bounded_follow_up');
    expect(replanned.status, 'suppressed_local_bounded_follow_up');
    expect(await service.listPendingPlans('user_blocked'), isEmpty);
  });
}

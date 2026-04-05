import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_follow_up_planner_service.dart';
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

  test('planner persists bounded saved-discovery follow-up prompts', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'saved_discovery_follow_up_planner_prefs',
      ),
    );
    final service = SavedDiscoveryFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_saved',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_saved',
        title: 'Night Owl Cafe',
        localityLabel: 'birmingham_downtown',
      ),
      action: 'save',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 2, 0),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why: 'Matches your quieter late-night coffee pattern',
        whyDetails: 'It ranked because you keep saving calmer indoor places',
        projectedEnjoyabilityPercent: 82,
        recommendationSource: 'place_intelligence_lane',
        confidence: 0.8,
      ),
    );

    final plans = await service.listPlans('user_saved');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.priority, 'medium');
    expect(
      plans.single.promptQuestion,
      'What made "Night Owl Cafe" worth keeping after AVRAI framed it as "Matches your quieter late-night coffee pattern"?',
    );
    expect(plans.single.boundedContext['nextEligibleAtUtc'], isNotNull);
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:saved_discovery_follow_up_plan',
        'action:save',
        'entity_type:spot',
        'domain:place',
      ]),
    );
  });

  test(
      'planner preserves evidence-backed saved-discovery explanations in rationale and context',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'saved_discovery_follow_up_explanation_prefs',
      ),
    );
    final service = SavedDiscoveryFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_saved_explanation',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_saved_explanation',
        title: 'Quiet Coffee House',
        localityLabel: 'mission_sf',
      ),
      action: 'save',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 5, 0),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why:
            'A recent signal that you liked coffee shops with espresso and natural light helped boost this spot.',
        whyDetails:
            'This spot still matches your knot and locality context, and the bounded coffee learning signal added extra lift.',
        projectedEnjoyabilityPercent: 84,
        recommendationSource: 'spot_matching',
        confidence: 0.82,
      ),
    );

    expect(
      plan.promptQuestion,
      contains(
        'A recent signal that you liked coffee shops with espresso and natural light helped boost this spot.',
      ),
    );
    expect(
      plan.promptRationale,
      contains(
        'The runtime already recorded the explanation as "A recent signal that you liked coffee shops with espresso and natural light helped boost this spot."',
      ),
    );
    expect(
      plan.boundedContext['why'],
      'A recent signal that you liked coffee shops with espresso and natural light helped boost this spot.',
    );
    expect(
      plan.boundedContext['whyDetails'],
      'This spot still matches your knot and locality context, and the bounded coffee learning signal added extra lift.',
    );
  });

  test('planner stages completed saved-discovery follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'saved_discovery_follow_up_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = SavedDiscoveryFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_saved_upward',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: 'list_upward',
        title: 'Late Night Food',
        localityLabel: 'southside',
      ),
      action: 'unsave',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 3, 0),
      sourceSurface: 'explore',
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_saved_upward',
      planId: plan.planId,
      responseText:
          'It stopped matching what I actually wanted to keep around.',
      sourceSurface: 'assistant_follow_up_chat',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'assistant_follow_up_chat');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'saved_discovery_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['convictionTier'],
      'saved_discovery_follow_up_correction_signal',
    );
    expect(
      reviews.single.payload['completionMode'],
      'assistant_follow_up_chat',
    );
  });

  test('dont-ask-again suppresses the same saved-discovery target permanently',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'saved_discovery_follow_up_dont_ask_again_prefs',
      ),
    );
    final service = SavedDiscoveryFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final original = await service.createPlan(
      ownerUserId: 'user_saved_blocked',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: 'list_blocked',
        title: 'Quiet Bars',
        localityLabel: 'southside',
      ),
      action: 'save',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 3, 0),
      sourceSurface: 'explore',
    );

    await service.dontAskAgainForPlan(
      ownerUserId: 'user_saved_blocked',
      planId: original.planId,
    );

    final replanned = await service.createPlan(
      ownerUserId: 'user_saved_blocked',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.list,
        id: 'list_blocked',
        title: 'Quiet Bars',
        localityLabel: 'southside',
      ),
      action: 'save',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 4, 0),
      sourceSurface: 'explore',
    );

    final plans = await service.listPlans('user_saved_blocked');
    final originalUpdated = plans.firstWhere(
      (candidate) => candidate.planId == original.planId,
    );

    expect(originalUpdated.status, 'dont_ask_again_local_bounded_follow_up');
    expect(replanned.status, 'suppressed_local_bounded_follow_up');
    expect(await service.listPendingPlans('user_saved_blocked'), isEmpty);
  });
}

import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _onboardingPlannerPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('planner persists bounded onboarding follow-up plans', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'onboarding_follow_up_planner_prefs'),
    );
    final service = OnboardingFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _onboardingPlannerPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_onboarding',
      onboardingData: OnboardingData(
        agentId: 'agent_onboarding',
        homebase: 'Austin, TX',
        favoritePlaces: const <String>['Quiet cafe'],
        preferences: const <String, List<String>>{
          'Food & Drink': <String>['Coffee'],
        },
        completedAt: DateTime.utc(2026, 4, 5, 12),
        dimensionValues: const <String, double>{'openness': 0.84},
        questionnaireVersion: 'v3',
      ),
      suggestionSurfaces: const <String>['favorite_places', 'baseline_lists'],
    );

    final plans = await service.listPlans('user_onboarding');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.homebase, 'Austin, TX');
    expect(plans.single.signalTags, contains('source:onboarding_follow_up_plan'));
  });

  test('planner stages completed onboarding follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'onboarding_follow_up_upward_prefs'),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = OnboardingFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _onboardingPlannerPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_onboarding',
      onboardingData: OnboardingData(
        agentId: 'agent_onboarding',
        homebase: 'Austin, TX',
        favoritePlaces: const <String>['Quiet cafe'],
        preferences: const <String, List<String>>{
          'Food & Drink': <String>['Coffee'],
        },
        completedAt: DateTime.utc(2026, 4, 5, 12),
        dimensionValues: const <String, double>{'openness': 0.84},
        questionnaireVersion: 'v3',
      ),
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_onboarding',
      planId: plan.planId,
      responseText:
          'Keep coffee and my Austin homebase durable, but treat nightlife preferences as exploratory.',
      sourceSurface: 'data_center_follow_up_queue',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'onboarding_in_app_follow_up_queue');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'onboarding_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['upwardDomainHints'],
      containsAll(const <String>['identity', 'preference']),
    );
  });
}

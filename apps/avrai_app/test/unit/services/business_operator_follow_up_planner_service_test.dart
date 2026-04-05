import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _businessPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('planner persists bounded business/operator follow-up plans', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'business_operator_follow_up_planner_prefs',
      ),
    );
    final service = BusinessOperatorFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _businessPromptPolicyService,
    );

    final plan = await service.createPlan(
      account: BusinessAccount(
        id: 'business_123',
        name: 'Night Owl Cafe',
        email: 'owner@nightowl.com',
        businessType: 'Restaurant',
        categories: const <String>['Coffee', 'Nightlife'],
        preferredCommunities: const <String>['community-nightlife'],
        location: 'downtown',
        createdAt: DateTime.utc(2026, 4, 5, 4, 0),
        updatedAt: DateTime.utc(2026, 4, 5, 4, 30),
        createdBy: 'owner_123',
      ),
      action: 'update',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 4, 30),
      changedFields: const <String>['location', 'categories'],
    );

    final plans = await service.listPlans('owner_123');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.businessName, 'Night Owl Cafe');
    expect(plans.single.priority, 'high');
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:business_operator_follow_up_plan',
        'action:update',
        'domain:business',
      ]),
    );
  });

  test('planner stages completed business/operator follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'business_operator_follow_up_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = BusinessOperatorFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _businessPromptPolicyService,
    );

    final plan = await service.createPlan(
      account: BusinessAccount(
        id: 'business_456',
        name: 'Southside Books',
        email: 'owner@southsidebooks.com',
        businessType: 'Bookstore',
        location: 'southside',
        createdAt: DateTime.utc(2026, 4, 5, 6, 0),
        updatedAt: DateTime.utc(2026, 4, 5, 6, 15),
        createdBy: 'owner_456',
      ),
      action: 'update',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 6, 15),
      changedFields: const <String>['location'],
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'owner_456',
      planId: plan.planId,
      responseText:
          'The new footprint matters because customers now stay longer and ask for quieter recommendation windows upstairs.',
      sourceSurface: 'business_dashboard_follow_up_queue',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'business_in_app_follow_up_queue');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'business_operator_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['completionMode'],
      'business_in_app_follow_up_queue',
    );
    expect(
      reviews.single.payload['upwardDomainHints'],
      containsAll(const <String>['business', 'locality', 'place']),
    );
  });

  test('dont-ask-again suppresses the same business follow-up target',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'business_operator_follow_up_dont_ask_again_prefs',
      ),
    );
    final service = BusinessOperatorFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _businessPromptPolicyService,
    );

    final account = BusinessAccount(
      id: 'business_blocked',
      name: 'Quiet Corner Books',
      email: 'owner@quietcorner.com',
      businessType: 'Bookstore',
      location: 'southside',
      createdAt: DateTime.utc(2026, 4, 5, 7, 0),
      updatedAt: DateTime.utc(2026, 4, 5, 7, 15),
      createdBy: 'owner_blocked',
    );
    final original = await service.createPlan(
      account: account,
      action: 'update',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 7, 15),
      changedFields: const <String>['location'],
    );

    await service.dontAskAgainForPlan(
      ownerUserId: 'owner_blocked',
      planId: original.planId,
    );

    final replanned = await service.createPlan(
      account: account.copyWith(updatedAt: DateTime.utc(2026, 4, 5, 8, 0)),
      action: 'update',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 8, 0),
      changedFields: const <String>['location'],
    );

    final plans = await service.listPlans('owner_blocked');
    final originalUpdated = plans.firstWhere(
      (candidate) => candidate.planId == original.planId,
    );

    expect(originalUpdated.status, 'dont_ask_again_local_bounded_follow_up');
    expect(replanned.status, 'suppressed_local_bounded_follow_up');
    expect(await service.listPendingPlans('owner_blocked'), isEmpty);
  });
}

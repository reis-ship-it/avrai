import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_correction_follow_up_planner_service.dart';
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

  test('planner persists bounded explicit-correction follow-up prompts',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'correction_follow_up_planner_prefs',
      ),
    );
    final service = UserGovernedLearningCorrectionFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_correction',
      targetEnvelopeId: 'env_123',
      targetSourceId: 'src_123',
      targetSummary: 'The user wants a quieter weeknight plan.',
      correctionText: 'Actually I want that to apply only on weekdays.',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 4, 0),
      sourceSurface: 'data_center_correction',
      domainHints: const <String>['place', 'list'],
      referencedEntities: const <String>['coffee shop list'],
      localityCode: 'birmingham_downtown',
      sourceProvider: 'explicit_correction_intake',
    );

    final plans = await service.listPlans('user_correction');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.priority, 'high');
    expect(
      plans.single.promptQuestion,
      'Should I treat your correction about "The user wants a quieter weeknight plan." as durable, or only for a specific situation?',
    );
    expect(plans.single.boundedContext['nextEligibleAtUtc'], isNotNull);
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:explicit_correction_follow_up_plan',
        'action:correct',
        'domain:place',
      ]),
    );
  });

  test(
      'planner stages completed explicit-correction follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'correction_follow_up_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = UserGovernedLearningCorrectionFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _testPromptPolicyService,
    );

    final plan = await service.createPlan(
      ownerUserId: 'user_correction_upward',
      targetEnvelopeId: 'env_upward',
      targetSourceId: 'src_upward',
      targetSummary: 'The user wants a quieter weeknight plan.',
      correctionText: 'Actually I want it only when I am working late.',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 5, 0),
      sourceSurface: 'data_center_correction',
      domainHints: const <String>['place'],
      localityCode: 'southside',
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_correction_upward',
      planId: plan.planId,
      responseText: 'Only when I am trying to stay somewhere quiet to focus.',
      sourceSurface: 'assistant_follow_up_chat',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'assistant_follow_up_chat');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'explicit_correction_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['convictionTier'],
      'explicit_correction_follow_up_signal',
    );
    expect(
      reviews.single.payload['completionMode'],
      'assistant_follow_up_chat',
    );
  });

  test('dismissed correction follow-up suppresses the same target briefly',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'correction_follow_up_suppression_prefs',
      ),
    );
    final service = UserGovernedLearningCorrectionFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );

    final firstPlan = await service.createPlan(
      ownerUserId: 'user_correction_suppressed',
      targetEnvelopeId: 'env_suppressed',
      targetSourceId: 'src_suppressed',
      targetSummary: 'Quiet weekday coffee preference.',
      correctionText: 'Only if I need to work, not when I am meeting people.',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 6, 0),
      sourceSurface: 'data_center_correction',
    );
    await service.dismissPlan(
      ownerUserId: 'user_correction_suppressed',
      planId: firstPlan.planId,
    );

    final suppressedPlan = await service.createPlan(
      ownerUserId: 'user_correction_suppressed',
      targetEnvelopeId: 'env_suppressed',
      targetSourceId: 'src_suppressed',
      targetSummary: 'Quiet weekday coffee preference.',
      correctionText: 'Still only if I need to work.',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 6, 5),
      sourceSurface: 'data_center_correction',
    );

    expect(suppressedPlan.status, 'suppressed_local_bounded_follow_up');
    final pending =
        await service.listPendingPlans('user_correction_suppressed');
    expect(pending, isEmpty);
  });
}

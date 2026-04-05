import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/passive_collection/visit_locality_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _behaviorPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('planner persists bounded visit/locality follow-up prompts', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'visit_locality_follow_up_planner_prefs',
      ),
    );
    final service = VisitLocalityFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _behaviorPromptPolicyService,
    );

    final plan = await service.createVisitPlan(
      visit: Visit(
        id: 'visit_123',
        userId: 'user_behavior',
        locationId: 'Night Owl Cafe',
        checkInTime: DateTime.utc(2026, 4, 5, 1, 0),
        checkOutTime: DateTime.utc(2026, 4, 5, 1, 45),
        dwellTime: const Duration(minutes: 45),
        qualityScore: 1.2,
        isAutomatic: true,
        isRepeatVisit: true,
        createdAt: DateTime.utc(2026, 4, 5, 1, 0),
        updatedAt: DateTime.utc(2026, 4, 5, 1, 45),
        metadata: const <String, dynamic>{'localityCode': 'downtown'},
      ),
      source: 'geofence',
    );

    final plans = await service.listPlans('user_behavior');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.observationKind, 'visit');
    expect(plans.single.priority, 'high');
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:visit_follow_up_plan',
        'observation:visit',
        'domain:place',
      ]),
    );
  });

  test('planner stages completed visit/locality follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'visit_locality_follow_up_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = VisitLocalityFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _behaviorPromptPolicyService,
    );

    final plan = await service.createLocalityPlan(
      ownerUserId: 'user_behavior_upward',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 2, 0),
      sourceKind: 'passive_dwell',
      localityStableKey: 'gh7:abc1234',
      structuredSignals: const <String, dynamic>{
        'dwellDurationMinutes': 64,
        'coPresenceDetected': true,
      },
      socialContext: 'social_cluster',
      activityContext: 'passive_dwell',
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_behavior_upward',
      planId: plan.planId,
      responseText:
          'That area matters when I want somewhere social enough to linger without planning an event.',
      sourceSurface: 'assistant_follow_up_chat',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'assistant_follow_up_chat');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'visit_locality_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['observationKind'],
      'locality',
    );
    expect(
      reviews.single.payload['completionMode'],
      'assistant_follow_up_chat',
    );
  });

  test('dismissed locality follow-up suppresses the same locality target',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'visit_locality_follow_up_suppression_prefs',
      ),
    );
    final service = VisitLocalityFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _behaviorPromptPolicyService,
    );

    final firstPlan = await service.createLocalityPlan(
      ownerUserId: 'user_behavior_suppressed',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 7, 0),
      sourceKind: 'passive_dwell',
      localityStableKey: 'gh7:suppressed',
      structuredSignals: const <String, dynamic>{
        'dwellDurationMinutes': 52,
      },
    );
    await service.dismissPlan(
      ownerUserId: 'user_behavior_suppressed',
      planId: firstPlan.planId,
    );

    final suppressedPlan = await service.createLocalityPlan(
      ownerUserId: 'user_behavior_suppressed',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 7, 5),
      sourceKind: 'passive_dwell',
      localityStableKey: 'gh7:suppressed',
      structuredSignals: const <String, dynamic>{
        'dwellDurationMinutes': 38,
      },
    );

    expect(suppressedPlan.status, 'suppressed_local_bounded_follow_up');
    final pending = await service.listPendingPlans('user_behavior_suppressed');
    expect(pending, isEmpty);
  });
}

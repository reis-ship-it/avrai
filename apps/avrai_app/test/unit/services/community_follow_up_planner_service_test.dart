import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/community/community_validation.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/community/community_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _communityPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('planner persists bounded community coordination follow-up plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'community_follow_up_planner_prefs'),
    );
    final service = CommunityFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _communityPromptPolicyService,
    );

    final plan = await service.createCoordinationPlan(
      community: Community(
        id: 'community_123',
        name: 'Night Owls',
        description: 'Late-night community',
        category: 'social',
        originatingEventId: 'event_123',
        originatingEventType: OriginatingEventType.communityEvent,
        memberIds: const <String>['user_community'],
        memberCount: 1,
        founderId: 'founder_1',
        eventIds: const <String>[],
        eventCount: 0,
        memberGrowthRate: 0,
        eventGrowthRate: 0,
        createdAt: DateTime.utc(2026, 4, 5, 4),
        lastEventAt: null,
        engagementScore: 0.4,
        diversityScore: 0.2,
        activityLevel: ActivityLevel.active,
        originalLocality: 'Downtown',
        currentLocalities: const <String>['Downtown'],
        localityCode: 'atx_downtown',
        updatedAt: DateTime.utc(2026, 4, 5, 4, 5),
      ),
      action: 'add_member',
      actorUserId: 'user_community',
      affectedRef: 'user_community',
    );

    final plans = await service.listPlans('user_community');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.followUpKind, 'community_coordination');
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:community_follow_up_plan',
        'kind:community_coordination',
        'domain:community',
      ]),
    );
  });

  test(
      'planner stages completed community validation follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'community_follow_up_upward_prefs'),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = CommunityFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _communityPromptPolicyService,
    );

    final plan = await service.createValidationPlan(
      validation: CommunityValidation.fromCommunityMember(
        spotId: 'spot_123',
        memberId: 'user_community_validation',
        status: ValidationStatus.needsReview,
        criteria: const <ValidationCriteria>[
          ValidationCriteria.locationAccuracy,
        ],
      ),
      spotName: 'Late Shift Cafe',
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_community_validation',
      planId: plan.planId,
      responseText:
          'It looked open, but the listing missed that the late-night kitchen closes much earlier than the spot itself.',
      sourceSurface: 'assistant_follow_up_chat',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'assistant_follow_up_chat');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'community_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['followUpKind'],
      'community_validation',
    );
  });

  test('dismissed community follow-up suppresses the same target', () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(boxName: 'community_follow_up_suppression_prefs'),
    );
    final service = CommunityFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _communityPromptPolicyService,
    );

    final firstPlan = await service.createCoordinationPlan(
      community: Community(
        id: 'community_suppressed',
        name: 'Night Owls',
        description: 'Late-night community',
        category: 'social',
        originatingEventId: 'event_123',
        originatingEventType: OriginatingEventType.communityEvent,
        memberIds: const <String>['user_community_suppressed'],
        memberCount: 1,
        founderId: 'founder_1',
        eventIds: const <String>[],
        eventCount: 0,
        memberGrowthRate: 0,
        eventGrowthRate: 0,
        createdAt: DateTime.utc(2026, 4, 5, 8),
        lastEventAt: null,
        engagementScore: 0.4,
        diversityScore: 0.2,
        activityLevel: ActivityLevel.active,
        originalLocality: 'Downtown',
        currentLocalities: const <String>['Downtown'],
        localityCode: 'atx_downtown',
        updatedAt: DateTime.utc(2026, 4, 5, 8, 5),
      ),
      action: 'add_member',
      actorUserId: 'user_community_suppressed',
    );
    await service.dismissPlan(
      ownerUserId: 'user_community_suppressed',
      planId: firstPlan.planId,
    );

    final suppressedPlan = await service.createCoordinationPlan(
      community: Community(
        id: 'community_suppressed',
        name: 'Night Owls',
        description: 'Late-night community',
        category: 'social',
        originatingEventId: 'event_123',
        originatingEventType: OriginatingEventType.communityEvent,
        memberIds: const <String>['user_community_suppressed'],
        memberCount: 1,
        founderId: 'founder_1',
        eventIds: const <String>[],
        eventCount: 0,
        memberGrowthRate: 0,
        eventGrowthRate: 0,
        createdAt: DateTime.utc(2026, 4, 5, 8),
        lastEventAt: null,
        engagementScore: 0.4,
        diversityScore: 0.2,
        activityLevel: ActivityLevel.active,
        originalLocality: 'Downtown',
        currentLocalities: const <String>['Downtown'],
        localityCode: 'atx_downtown',
        updatedAt: DateTime.utc(2026, 4, 5, 8, 10),
      ),
      action: 'add_member',
      actorUserId: 'user_community_suppressed',
    );

    expect(suppressedPlan.status, 'suppressed_local_bounded_follow_up');
    final pending = await service.listPendingPlans('user_community_suppressed');
    expect(pending, isEmpty);
  });
}

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_feedback_assistant_follow_up_service.dart';
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

  test('assistant follow-up service offers and captures bounded prompt plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'recommendation_feedback_assistant_follow_up_prefs',
      ),
    );
    final planner = RecommendationFeedbackPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );
    final service = RecommendationFeedbackAssistantFollowUpService(
      plannerService: planner,
    );

    await planner.createPlan(
      ownerUserId: 'user_assistant',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_assistant',
        title: 'Heatwave Cafe',
        localityLabel: 'austin_downtown',
      ),
      action: RecommendationFeedbackAction.lessLikeThis,
      occurredAtUtc: DateTime.utc(2026, 4, 4, 18),
      sourceSurface: 'explore',
      attribution: const RecommendationAttribution(
        why: 'Matches your indoor coffee pattern',
        whyDetails: 'It ranked because you kept saving indoor daytime places',
        projectedEnjoyabilityPercent: 75,
        recommendationSource: 'place_intelligence_lane',
        confidence: 0.78,
      ),
    );

    final offer = await service.maybeOfferFollowUp(
      ownerUserId: 'user_assistant',
    );

    expect(offer, isNotNull);
    expect(
      offer!.assistantPrompt,
      contains('Quick follow-up: What felt off about "Heatwave Cafe"'),
    );
    expect(
      (await planner.listPlans('user_assistant')).single.status,
      'assistant_follow_up_offered',
    );

    final response = await service.captureActiveAssistantFollowUpResponse(
      ownerUserId: 'user_assistant',
      responseText: 'It felt too crowded and louder than I wanted.',
    );

    expect(response, isNotNull);
    expect(
      response!.responseText,
      'It felt too crowded and louder than I wanted.',
    );
    expect(await planner.activeAssistantFollowUpPlan('user_assistant'), isNull);
    expect(await planner.listPendingPlans('user_assistant'), isEmpty);
  });
}

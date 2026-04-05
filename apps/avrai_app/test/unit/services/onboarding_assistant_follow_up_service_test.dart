import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/onboarding/onboarding_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _onboardingAssistantPromptPolicyService =
    BoundedFollowUpPromptPolicyService(
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

  test('assistant follow-up service offers and captures onboarding plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'onboarding_assistant_follow_up_prefs',
      ),
    );
    final planner = OnboardingFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _onboardingAssistantPromptPolicyService,
    );
    final service = OnboardingAssistantFollowUpService(
      plannerService: planner,
    );

    await planner.createPlan(
      ownerUserId: 'user_onboarding_assistant',
      onboardingData: OnboardingData(
        agentId: 'agent_onboarding_assistant',
        homebase: 'Austin, TX',
        completedAt: DateTime.utc(2026, 4, 5, 12),
        preferences: const <String, List<String>>{
          'Food & Drink': <String>['Coffee'],
        },
        questionnaireVersion: 'v3',
      ),
    );

    final offer = await service.maybeOfferFollowUp(
      ownerUserId: 'user_onboarding_assistant',
    );
    expect(offer, isNotNull);
    expect(offer!.assistantPrompt, contains('Quick onboarding follow-up:'));

    final response = await service.captureActiveAssistantFollowUpResponse(
      ownerUserId: 'user_onboarding_assistant',
      responseText:
          'Treat my homebase as durable, but keep the rest provisional until I have more activity.',
    );

    expect(response, isNotNull);
    expect(response!.completionMode, 'onboarding_assistant_follow_up_chat');
    expect(
      await planner.activeAssistantFollowUpPlan('user_onboarding_assistant'),
      isNull,
    );
  });
}

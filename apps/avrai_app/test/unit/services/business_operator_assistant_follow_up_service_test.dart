import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_runtime_os/services/business/business_operator_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/business/business_operator_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _businessAssistantPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('assistant follow-up service offers and captures business plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'business_operator_assistant_follow_up_prefs',
      ),
    );
    final planner = BusinessOperatorFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _businessAssistantPromptPolicyService,
    );
    final service = BusinessOperatorAssistantFollowUpService(
      plannerService: planner,
    );

    await planner.createPlan(
      account: BusinessAccount(
        id: 'business_assistant',
        name: 'Night Owl Cafe',
        email: 'owner@nightowl.com',
        businessType: 'Restaurant',
        location: 'downtown',
        createdAt: DateTime.utc(2026, 4, 5, 10),
        updatedAt: DateTime.utc(2026, 4, 5, 11),
        createdBy: 'owner_business_assistant',
      ),
      action: 'update',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 11),
      changedFields: const <String>['location'],
    );

    final offer = await service.maybeOfferFollowUp(
      ownerUserId: 'owner_business_assistant',
    );
    expect(offer, isNotNull);
    expect(offer!.assistantPrompt, contains('Quick business follow-up:'));

    final response = await service.captureActiveAssistantFollowUpResponse(
      ownerUserId: 'owner_business_assistant',
      responseText:
          'Treat the new downtown footprint as durable because it changes who we serve at night.',
    );

    expect(response, isNotNull);
    expect(response!.completionMode, 'business_assistant_follow_up_chat');
    expect(
      await planner.activeAssistantFollowUpPlan('owner_business_assistant'),
      isNull,
    );
  });
}

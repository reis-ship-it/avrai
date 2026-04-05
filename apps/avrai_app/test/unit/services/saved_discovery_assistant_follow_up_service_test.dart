import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/recommendations/saved_discovery_assistant_follow_up_service.dart';
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

  test('assistant follow-up service offers and captures saved-item plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'saved_discovery_assistant_follow_up_prefs',
      ),
    );
    final planner = SavedDiscoveryFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _testPromptPolicyService,
    );
    final service = SavedDiscoveryAssistantFollowUpService(
      plannerService: planner,
    );

    await planner.createPlan(
      ownerUserId: 'user_saved_assistant',
      entity: const DiscoveryEntityReference(
        type: DiscoveryEntityType.spot,
        id: 'spot_saved_assistant',
        title: 'Heatwave Cafe',
        localityLabel: 'austin_downtown',
      ),
      action: 'save',
      occurredAtUtc: DateTime.utc(2026, 4, 4, 18),
      sourceSurface: 'explore',
    );

    final offer = await service.maybeOfferFollowUp(
      ownerUserId: 'user_saved_assistant',
    );

    expect(offer, isNotNull);
    expect(
      offer!.assistantPrompt,
      contains(
          'Quick saved-item follow-up: What made "Heatwave Cafe" worth saving for later?'),
    );

    final response = await service.captureActiveAssistantFollowUpResponse(
      ownerUserId: 'user_saved_assistant',
      responseText:
          'It felt like the kind of backup place I would actually use.',
    );

    expect(response, isNotNull);
    expect(
      response!.responseText,
      'It felt like the kind of backup place I would actually use.',
    );
    expect(await planner.activeAssistantFollowUpPlan('user_saved_assistant'),
        isNull);
    expect(await planner.listPendingPlans('user_saved_assistant'), isEmpty);
  });
}

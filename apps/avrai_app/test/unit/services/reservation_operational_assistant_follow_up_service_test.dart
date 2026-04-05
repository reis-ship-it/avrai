import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_assistant_follow_up_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _assistantPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('assistant follow-up service offers and captures reservation plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'reservation_operational_assistant_follow_up_prefs',
      ),
    );
    final planner = ReservationOperationalFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _assistantPromptPolicyService,
    );
    final service = ReservationOperationalAssistantFollowUpService(
      plannerService: planner,
    );

    await planner.createRecurrencePlan(
      ownerUserId: 'user_reservation_assistant',
      reservation: _buildReservation(),
      occurredAtUtc: DateTime.utc(2026, 4, 5, 18),
      recurrencePattern: 'weekly',
      createdInstanceCount: 3,
    );

    final offer = await service.maybeOfferFollowUp(
      ownerUserId: 'user_reservation_assistant',
    );

    expect(offer, isNotNull);
    expect(
      offer!.assistantPrompt,
      contains('Quick reservation follow-up about event:event_123:'),
    );

    final response = await service.captureActiveAssistantFollowUpResponse(
      ownerUserId: 'user_reservation_assistant',
      responseText:
          'It should only repeat when the timing stays aligned with my normal weekly schedule.',
    );

    expect(response, isNotNull);
    expect(
      response!.responseText,
      'It should only repeat when the timing stays aligned with my normal weekly schedule.',
    );
    expect(
      await planner.activeAssistantFollowUpPlan('user_reservation_assistant'),
      isNull,
    );
    expect(
        await planner.listPendingPlans('user_reservation_assistant'), isEmpty);
  });
}

Reservation _buildReservation() {
  return Reservation(
    id: 'reservation_assistant',
    agentId: 'agent_owner',
    type: ReservationType.event,
    targetId: 'event_123',
    reservationTime: DateTime.utc(2026, 4, 20, 19),
    partySize: 2,
    ticketCount: 1,
    metadata: const <String, dynamic>{
      'userId': 'user_reservation_assistant',
      'cityCode': 'austin',
      'localityCode': 'downtown',
    },
    createdAt: DateTime.utc(2026, 4, 5, 12),
    updatedAt: DateTime.utc(2026, 4, 5, 12),
  );
}

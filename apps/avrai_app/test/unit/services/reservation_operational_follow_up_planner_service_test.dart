import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';

final _reservationPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  test('planner persists bounded reservation operational follow-up plans',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'reservation_operational_follow_up_planner_prefs',
      ),
    );
    final service = ReservationOperationalFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _reservationPromptPolicyService,
    );

    final plan = await service.createSharingPlan(
      ownerUserId: 'user_reservation',
      reservation: _buildReservation(
        id: 'reservation_123',
        type: ReservationType.event,
        targetId: 'event_123',
      ),
      action: 'share',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 18),
      counterpartUserId: 'user_friend',
      permission: 'fullAccess',
    );

    final plans = await service.listPlans('user_reservation');
    expect(plans, hasLength(1));
    expect(plans.single.planId, plan.planId);
    expect(plans.single.operationKind, 'reservation_share');
    expect(
      plans.single.signalTags,
      containsAll(const <String>[
        'source:reservation_operational_follow_up_plan',
        'operation:reservation_share',
        'domain:reservation',
      ]),
    );
  });

  test('planner stages completed reservation follow-up responses upward',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'reservation_operational_follow_up_upward_prefs',
      ),
    );
    final repository = UniversalIntakeRepository();
    final governedService = GovernedUpwardLearningIntakeService(
      intakeRepository: repository,
      atomicClockService: AtomicClockService(),
    );
    final service = ReservationOperationalFollowUpPromptPlannerService(
      prefs: prefs,
      governedUpwardLearningIntakeService: governedService,
      promptPolicyService: _reservationPromptPolicyService,
    );

    final plan = await service.createCalendarSyncPlan(
      ownerUserId: 'user_reservation',
      reservation: _buildReservation(
        id: 'reservation_calendar',
        type: ReservationType.business,
        targetId: 'business_456',
      ),
      occurredAtUtc: DateTime.utc(2026, 4, 5, 19),
      calendarEventId: 'calendar_event_123',
    );

    final response = await service.completePlanWithResponse(
      ownerUserId: 'user_reservation',
      planId: plan.planId,
      responseText:
          'It matters because I only want calendar sync for reservations that should block real time on my schedule.',
      sourceSurface: 'reservation_in_app_follow_up_queue',
    );

    final reviews = await repository.getAllReviewItems();
    expect(response.completionMode, 'reservation_in_app_follow_up_queue');
    expect(reviews, hasLength(1));
    expect(
      reviews.single.payload['sourceKind'],
      'reservation_operational_follow_up_response_intake',
    );
    expect(
      reviews.single.payload['completionMode'],
      'reservation_in_app_follow_up_queue',
    );
    expect(
      reviews.single.payload['upwardDomainHints'],
      containsAll(const <String>['reservation', 'timing']),
    );
  });

  test('dont-ask-again suppresses the same reservation follow-up target',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'reservation_operational_follow_up_dont_ask_again_prefs',
      ),
    );
    final service = ReservationOperationalFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _reservationPromptPolicyService,
    );

    final reservation = _buildReservation(
      id: 'reservation_blocked',
      type: ReservationType.spot,
      targetId: 'spot_789',
    );
    final original = await service.createSharingPlan(
      ownerUserId: 'user_reservation',
      reservation: reservation,
      action: 'share',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 20),
    );

    await service.dontAskAgainForPlan(
      ownerUserId: 'user_reservation',
      planId: original.planId,
    );

    final replanned = await service.createSharingPlan(
      ownerUserId: 'user_reservation',
      reservation: reservation,
      action: 'share',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 21),
    );

    final plans = await service.listPlans('user_reservation');
    final originalUpdated = plans.firstWhere(
      (candidate) => candidate.planId == original.planId,
    );

    expect(originalUpdated.status, 'dont_ask_again_local_bounded_follow_up');
    expect(replanned.status, 'suppressed_local_bounded_follow_up');
    expect(await service.listPendingPlans('user_reservation'), isEmpty);
  });
}

Reservation _buildReservation({
  required String id,
  required ReservationType type,
  required String targetId,
}) {
  return Reservation(
    id: id,
    agentId: 'agent_owner',
    type: type,
    targetId: targetId,
    reservationTime: DateTime.utc(2026, 4, 20, 19),
    partySize: 2,
    ticketCount: 1,
    metadata: const <String, dynamic>{
      'userId': 'user_reservation',
      'cityCode': 'austin',
      'localityCode': 'downtown',
    },
    createdAt: DateTime.utc(2026, 4, 5, 12),
    updatedAt: DateTime.utc(2026, 4, 5, 12),
  );
}

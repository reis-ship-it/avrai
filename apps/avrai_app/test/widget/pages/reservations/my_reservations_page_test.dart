import 'package:avrai/presentation/pages/reservations/my_reservations_page.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/platform_channel_helper.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

class _MockReservationService extends Mock implements ReservationService {}

final _widgetPromptPolicyService = BoundedFollowUpPromptPolicyService(
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

  testWidgets('shows reservation follow-up queue and completes a plan',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'my_reservations_follow_up_queue_prefs',
      ),
    );
    final planner = ReservationOperationalFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _widgetPromptPolicyService,
    );
    final reservationService = _MockReservationService();
    final reservation = _buildReservation();

    when(() => reservationService.getUserReservations(userId: 'test-user-id'))
        .thenAnswer((_) async => <Reservation>[reservation]);

    await planner.createCalendarSyncPlan(
      ownerUserId: 'test-user-id',
      reservation: reservation,
      occurredAtUtc: DateTime.utc(2026, 4, 5, 18),
      calendarEventId: 'calendar_event_123',
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: MyReservationsPage(
          reservationService: reservationService,
          reservationFollowUpPlannerService: planner,
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);

    expect(find.text('Reservation follow-up queue'), findsOneWidget);
    expect(find.text('Answer now'), findsOneWidget);

    await tester.tap(find.text('Answer now'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Reservation follow-up'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'I only want the calendar sync when the reservation should block real time on my schedule.',
    );
    await WidgetTestHelpers.safePumpAndSettle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Reservation follow-up queue'), findsNothing);
    final responses = await planner.listResponses('test-user-id');
    expect(responses, hasLength(1));
    expect(
      responses.single.responseText,
      'I only want the calendar sync when the reservation should block real time on my schedule.',
    );
  });

  testWidgets('supports dont-ask-again on the reservation follow-up queue',
      (WidgetTester tester) async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'my_reservations_follow_up_dont_ask_again_prefs',
      ),
    );
    final planner = ReservationOperationalFollowUpPromptPlannerService(
      prefs: prefs,
      promptPolicyService: _widgetPromptPolicyService,
    );
    final reservationService = _MockReservationService();
    final reservation = _buildReservation();

    when(() => reservationService.getUserReservations(userId: 'test-user-id'))
        .thenAnswer((_) async => <Reservation>[reservation]);

    final plan = await planner.createSharingPlan(
      ownerUserId: 'test-user-id',
      reservation: reservation,
      action: 'share',
      occurredAtUtc: DateTime.utc(2026, 4, 5, 17),
    );

    final widget = WidgetTestHelpers.createTestableWidget(
      authBloc: MockBlocFactory.createAuthenticatedAuthBloc(),
      child: Scaffold(
        body: MyReservationsPage(
          reservationService: reservationService,
          reservationFollowUpPlannerService: planner,
        ),
      ),
    );

    await WidgetTestHelpers.pumpAndSettle(tester, widget);
    expect(find.text('Reservation follow-up queue'), findsOneWidget);

    await tester.tap(find.text("Don't ask again"));
    await WidgetTestHelpers.safePumpAndSettle(tester);

    expect(find.text('Reservation follow-up queue'), findsNothing);
    final updatedPlan = (await planner.listPlans('test-user-id'))
        .firstWhere((candidate) => candidate.planId == plan.planId);
    expect(updatedPlan.status, 'dont_ask_again_local_bounded_follow_up');
  });
}

Reservation _buildReservation() {
  return Reservation(
    id: 'reservation_123',
    agentId: 'agent_owner',
    type: ReservationType.business,
    targetId: 'business_123',
    reservationTime: DateTime.now().toUtc().add(const Duration(days: 2)),
    partySize: 2,
    ticketCount: 1,
    metadata: const <String, dynamic>{
      'userId': 'test-user-id',
      'cityCode': 'austin',
      'localityCode': 'downtown',
    },
    createdAt: DateTime.utc(2026, 4, 5, 12),
    updatedAt: DateTime.utc(2026, 4, 5, 12),
  );
}

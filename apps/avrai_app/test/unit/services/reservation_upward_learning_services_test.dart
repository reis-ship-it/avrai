import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/recommendations/bounded_follow_up_prompt_policy_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_calendar_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_operational_follow_up_planner_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_quantum_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_recurrence_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_sharing_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/platform_channel_helper.dart';

class _MockReservationService extends Mock implements ReservationService {}

class _MockReservationQuantumService extends Mock
    implements ReservationQuantumService {}

class _MockAgentIdService extends Mock implements AgentIdService {}

class _MockPersonalityLearning extends Mock implements PersonalityLearning {}

class _MockAtomicClockService extends Mock implements AtomicClockService {}

void main() {
  final promptPolicyService = BoundedFollowUpPromptPolicyService(
    policy: BoundedFollowUpPromptPolicy(
      maxPromptPlansPerDay: 10,
      quietHoursStartHour: 0,
      quietHoursEndHour: 0,
      suggestionFamilyCooldown: const Duration(seconds: 1),
      eventFamilyCooldown: const Duration(seconds: 1),
    ),
  );

  setUpAll(() {
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(DateTime.utc(2026, 1, 1));
  });

  group('Reservation upward learning widening', () {
    late UniversalIntakeRepository intakeRepository;
    late GovernedUpwardLearningIntakeService upwardService;
    late _MockReservationService reservationService;
    late _MockReservationQuantumService quantumService;
    late _MockAgentIdService agentIdService;
    late _MockPersonalityLearning personalityLearning;
    late _MockAtomicClockService atomicClockService;

    setUpAll(() async {
      await setupTestStorage();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() async {
      intakeRepository = UniversalIntakeRepository();
      upwardService = GovernedUpwardLearningIntakeService(
        intakeRepository: intakeRepository,
        atomicClockService: AtomicClockService(),
      );
      reservationService = _MockReservationService();
      quantumService = _MockReservationQuantumService();
      agentIdService = _MockAgentIdService();
      personalityLearning = _MockPersonalityLearning();
      atomicClockService = _MockAtomicClockService();

      when(() => atomicClockService.getAtomicTimestamp()).thenAnswer(
        (_) async => AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
        ),
      );
    });

    test('shareReservation stages reservation sharing upward intake', () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'reservation_sharing_follow_up_prefs'),
      );
      final planner = ReservationOperationalFollowUpPromptPlannerService(
        prefs: prefs,
        promptPolicyService: promptPolicyService,
      );
      final reservation = _buildReservation(
        id: 'reservation_share',
        agentId: 'agent_owner',
        type: ReservationType.spot,
        targetId: 'spot_123',
      );

      when(() => reservationService.getReservationById('reservation_share'))
          .thenAnswer((_) async => reservation);
      when(() => agentIdService.getUserAgentId('user_owner'))
          .thenAnswer((_) async => 'agent_owner');
      when(() => agentIdService.getUserAgentId('user_friend'))
          .thenAnswer((_) async => 'agent_friend');

      final service = ReservationSharingService(
        reservationService: reservationService,
        quantumService: quantumService,
        agentIdService: agentIdService,
        personalityLearning: personalityLearning,
        atomicClock: atomicClockService,
        governedUpwardLearningIntakeService: upwardService,
        reservationFollowUpPlannerService: planner,
      );

      final result = await service.shareReservation(
        reservationId: 'reservation_share',
        ownerUserId: 'user_owner',
        sharedWithUserId: 'user_friend',
        permission: SharingPermission.fullAccess,
      );

      expect(result.success, isTrue);
      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
          reviews.single.payload['sourceKind'], 'reservation_sharing_intake');
      expect(reviews.single.payload['action'], 'share');
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_sharing_full_access_signal',
      );
      final plans = await planner.listPendingPlans('user_owner');
      expect(plans, hasLength(1));
      expect(plans.single.operationKind, 'reservation_share');
    });

    test('transferReservation stages reservation transfer upward intake',
        () async {
      final reservation = _buildReservation(
        id: 'reservation_transfer',
        agentId: 'agent_owner',
        type: ReservationType.event,
        targetId: 'event_123',
      );

      when(() => reservationService.getReservationById('reservation_transfer'))
          .thenAnswer((_) async => reservation);
      when(() => agentIdService.getUserAgentId('user_owner'))
          .thenAnswer((_) async => 'agent_owner');
      when(() => agentIdService.getUserAgentId('user_new_owner'))
          .thenAnswer((_) async => 'agent_new_owner');

      final service = ReservationSharingService(
        reservationService: reservationService,
        quantumService: quantumService,
        agentIdService: agentIdService,
        personalityLearning: personalityLearning,
        atomicClock: atomicClockService,
        governedUpwardLearningIntakeService: upwardService,
      );

      final result = await service.transferReservation(
        reservationId: 'reservation_transfer',
        fromUserId: 'user_owner',
        toUserId: 'user_new_owner',
      );

      expect(result.success, isTrue);
      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
          reviews.single.payload['sourceKind'], 'reservation_sharing_intake');
      expect(reviews.single.payload['action'], 'transfer');
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_transfer_signal',
      );
    });

    test('createRecurringSeries stages reservation recurrence upward intake',
        () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage:
            getTestStorage(boxName: 'reservation_recurrence_follow_up_prefs'),
      );
      final planner = ReservationOperationalFollowUpPromptPlannerService(
        prefs: prefs,
        promptPolicyService: promptPolicyService,
      );
      final baseReservation = _buildReservation(
        id: 'reservation_base',
        agentId: 'agent_owner',
        type: ReservationType.event,
        targetId: 'event_123',
      );

      when(() => agentIdService.getUserAgentId('user_owner'))
          .thenAnswer((_) async => 'agent_owner');

      var createdCount = 0;
      when(
        () => reservationService.createReservation(
          userId: 'user_owner',
          type: ReservationType.event,
          targetId: 'event_123',
          reservationTime: any(named: 'reservationTime'),
          partySize: 2,
          ticketCount: 1,
          specialRequests: null,
          ticketPrice: null,
          depositAmount: null,
          seatId: null,
          cancellationPolicy: null,
          userData: null,
        ),
      ).thenAnswer((invocation) async {
        createdCount += 1;
        return _buildReservation(
          id: 'instance_$createdCount',
          agentId: 'agent_owner',
          type: ReservationType.event,
          targetId: 'event_123',
          reservationTime:
              invocation.namedArguments[#reservationTime] as DateTime,
        );
      });

      final service = ReservationRecurrenceService(
        reservationService: reservationService,
        quantumService: quantumService,
        agentIdService: agentIdService,
        personalityLearning: personalityLearning,
        atomicClock: atomicClockService,
        governedUpwardLearningIntakeService: upwardService,
        reservationFollowUpPlannerService: planner,
      );

      final result = await service.createRecurringSeries(
        userId: 'user_owner',
        baseReservation: baseReservation,
        pattern: const RecurrencePattern(
          type: RecurrencePatternType.weekly,
          interval: 1,
          maxOccurrences: 2,
        ),
      );

      expect(result.success, isTrue);
      expect(result.createdReservationIds, hasLength(2));
      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'reservation_recurrence_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_recurrence_pattern_signal',
      );
      final plans = await planner.listPendingPlans('user_owner');
      expect(plans, hasLength(1));
      expect(plans.single.operationKind, 'reservation_recurrence');
    });

    test('syncReservationToCalendar stages reservation calendar upward intake',
        () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage:
            getTestStorage(boxName: 'reservation_calendar_follow_up_prefs'),
      );
      final planner = ReservationOperationalFollowUpPromptPlannerService(
        prefs: prefs,
        promptPolicyService: promptPolicyService,
      );
      final reservation = _buildReservation(
        id: 'reservation_calendar',
        agentId: 'agent_owner',
        type: ReservationType.business,
        targetId: 'business_123',
      );
      final updatedReservation = reservation.copyWith(
        calendarEventId:
            'reservation_calendar_${reservation.reservationTime.toIso8601String()}',
      );

      when(() => reservationService.getReservationById('reservation_calendar'))
          .thenAnswer((_) async => reservation);
      when(
        () => reservationService.updateReservation(
          reservationId: 'reservation_calendar',
          calendarEventId: any(named: 'calendarEventId'),
        ),
      ).thenAnswer((_) async => updatedReservation);

      final service = ReservationCalendarService(
        reservationService: reservationService,
        quantumService: quantumService,
        agentIdService: agentIdService,
        personalityLearning: personalityLearning,
        atomicClock: atomicClockService,
        governedUpwardLearningIntakeService: upwardService,
        reservationFollowUpPlannerService: planner,
        addEventToCalendar: (_) async => true,
      );

      final result = await service.syncReservationToCalendar(
        reservationId: 'reservation_calendar',
        ownerUserId: 'user_owner',
      );

      expect(result.success, isTrue);
      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(
        reviews.single.payload['sourceKind'],
        'reservation_calendar_sync_intake',
      );
      expect(
        reviews.single.payload['convictionTier'],
        'reservation_calendar_sync_signal',
      );
      final plans = await planner.listPendingPlans('user_owner');
      expect(plans, hasLength(1));
      expect(plans.single.operationKind, 'reservation_calendar_sync');
    });
  });
}

Reservation _buildReservation({
  required String id,
  required String agentId,
  required ReservationType type,
  required String targetId,
  DateTime? reservationTime,
}) {
  final time = reservationTime ?? DateTime.utc(2026, 4, 20, 19, 0);
  return Reservation(
    id: id,
    agentId: agentId,
    type: type,
    targetId: targetId,
    reservationTime: time,
    partySize: 2,
    ticketCount: 1,
    metadata: const <String, dynamic>{
      'userId': 'user_owner',
      'cityCode': 'bham',
      'localityCode': 'downtown',
    },
    createdAt: DateTime.utc(2026, 4, 1, 12, 0),
    updatedAt: DateTime.utc(2026, 4, 1, 12, 0),
  );
}

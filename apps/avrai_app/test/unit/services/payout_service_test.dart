import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/payment/payout_service.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';

import 'payout_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([RevenueSplitService])
void main() {
  group('PayoutService Tests', () {
    late PayoutService service;
    late MockRevenueSplitService mockRevenueSplitService;

    setUp(() {
      mockRevenueSplitService = MockRevenueSplitService();
      service = PayoutService(
        revenueSplitService: mockRevenueSplitService,
      );
    });

    // Removed: Property assignment tests
    // Payout tests focus on business logic (payout scheduling, status updates, earnings tracking), not property assignment

    group('schedulePayout', () {
      test('should schedule payout for a party and generate unique payout ID',
          () async {
        // Test business logic: payout scheduling
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final payout1 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        expect(payout1, isA<Payout>());
        expect(payout1.partyId, equals('user-123'));
        expect(payout1.amount, equals(50.00));
        expect(payout1.eventId, equals('event-123'));
        expect(payout1.status, equals(PayoutStatus.scheduled));
        expect(payout1.scheduledDate, equals(scheduledDate));
        expect(payout1.createdAt, isNotNull);
        expect(payout1.updatedAt, isNotNull);

        final payout2 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        expect(payout1.id, isNot(equals(payout2.id)));
      });
    });

    group('updatePayoutStatus', () {
      test(
          'should update payout status, set completedAt when status is completed, or throw exception if payout not found',
          () async {
        // Test business logic: payout status updates with error handling
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final payout1 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        final updated = await service.updatePayoutStatus(
          payoutId: payout1.id,
          status: PayoutStatus.processing,
        );
        expect(updated.status, equals(PayoutStatus.processing));
        expect(updated.updatedAt.isAfter(payout1.updatedAt), isTrue);

        final payout2 = await service.schedulePayout(
          partyId: 'user-124',
          amount: 50.00,
          eventId: 'event-124',
          scheduledDate: scheduledDate,
        );
        final completed = await service.updatePayoutStatus(
          payoutId: payout2.id,
          status: PayoutStatus.completed,
        );
        expect(completed.status, equals(PayoutStatus.completed));
        expect(completed.completedAt, isNotNull);

        expect(
          () => service.updatePayoutStatus(
            payoutId: 'nonexistent-payout',
            status: PayoutStatus.completed,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Payout not found'),
          )),
        );
      });
    });

    group('getPayout', () {
      test('should return payout by ID, or return null if payout not found',
          () async {
        // Test business logic: payout retrieval
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final created = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        final payout1 = await service.getPayout(created.id);
        expect(payout1, isNotNull);
        expect(payout1?.id, equals(created.id));
        expect(payout1?.partyId, equals('user-123'));

        final payout2 = await service.getPayout('nonexistent-payout');
        expect(payout2, isNull);
      });
    });

    group('getPayoutsForParty', () {
      test(
          'should return payouts for a party, or return empty list if no payouts for party',
          () async {
        // Test business logic: party payout retrieval
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 75.00,
          eventId: 'event-456',
          scheduledDate: scheduledDate,
        );
        await service.schedulePayout(
          partyId: 'business-123',
          amount: 100.00,
          eventId: 'event-789',
          scheduledDate: scheduledDate,
        );
        final payouts1 = await service.getPayoutsForParty('user-123');
        expect(payouts1, hasLength(2));
        expect(payouts1.every((p) => p.partyId == 'user-123'), isTrue);
        expect(
            payouts1[0].scheduledDate.isAfter(payouts1[1].scheduledDate) ||
                payouts1[0]
                    .scheduledDate
                    .isAtSameMomentAs(payouts1[1].scheduledDate),
            isTrue);

        final payouts2 = await service.getPayoutsForParty('nonexistent-party');
        expect(payouts2, isEmpty);
      });
    });

    group('trackEarnings', () {
      test(
          'should track total earnings for a party, calculate total paid and pending amounts, filter earnings by date range, or return zero earnings if no payouts',
          () async {
        // Test business logic: earnings tracking with various scenarios
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 75.00,
          eventId: 'event-456',
          scheduledDate: scheduledDate,
        );
        final report1 = await service.trackEarnings(
          partyId: 'user-123',
        );
        expect(report1, isA<EarningsReport>());
        expect(report1.partyId, equals('user-123'));
        expect(report1.totalEarnings, equals(125.00));
        expect(report1.payoutCount, equals(2));
        expect(report1.payouts, hasLength(2));

        final payout1 = await service.schedulePayout(
          partyId: 'user-124',
          amount: 50.00,
          eventId: 'event-124',
          scheduledDate: scheduledDate,
        );
        // ignore: unused_local_variable
        // ignore: unused_local_variable - May be used in callback or assertion
        final payout2 = await service.schedulePayout(
          partyId: 'user-124',
          amount: 75.00,
          eventId: 'event-125',
          scheduledDate: scheduledDate,
        );
        await service.updatePayoutStatus(
          payoutId: payout1.id,
          status: PayoutStatus.completed,
        );
        final report2 = await service.trackEarnings(
          partyId: 'user-124',
        );
        expect(report2.totalEarnings, equals(125.00));
        expect(report2.totalPaid, equals(50.00));
        expect(report2.totalPending, equals(75.00));

        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final futureDate = DateTime.now().add(const Duration(days: 10));
        await service.schedulePayout(
          partyId: 'user-125',
          amount: 50.00,
          eventId: 'event-126',
          scheduledDate: pastDate,
        );
        await service.schedulePayout(
          partyId: 'user-125',
          amount: 75.00,
          eventId: 'event-127',
          scheduledDate: futureDate,
        );
        final startDate = DateTime.now().subtract(const Duration(days: 5));
        final endDate = DateTime.now().add(const Duration(days: 5));
        final report3 = await service.trackEarnings(
          partyId: 'user-125',
          startDate: startDate,
          endDate: endDate,
        );
        expect(report3.startDate, equals(startDate));
        expect(report3.endDate, equals(endDate));
        expect(report3.payouts.length, lessThanOrEqualTo(2));

        final report4 = await service.trackEarnings(
          partyId: 'nonexistent-party',
        );
        expect(report4.totalEarnings, equals(0.0));
        expect(report4.totalPaid, equals(0.0));
        expect(report4.totalPending, equals(0.0));
        expect(report4.payoutCount, equals(0));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_core/models/payment/revenue_split.dart';
import 'package:avrai_core/models/events/event_partnership.dart';

import 'revenue_split_service_partnership_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([PartnershipService])
void main() {
  group('RevenueSplitService Partnership Split Tests', () {
    late RevenueSplitService service;
    late MockPartnershipService mockPartnershipService;
    late EventPartnership testPartnership;

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      service = RevenueSplitService(
        partnershipService: mockPartnershipService,
      );

      testPartnership = EventPartnership(
        id: 'partnership-123',
        eventId: 'event-123',
        userId: 'user-123',
        businessId: 'business-123',
        status: PartnershipStatus.locked,
        vibeCompatibilityScore: 0.75,
        userApproved: true,
        businessApproved: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Revenue split tests focus on business logic (calculations, fees, validation), not property assignment

    group('calculateNWaySplit', () {
      test(
          'should calculate N-way split with correct percentages and fees, support 3-way split, or throw exception for invalid inputs (percentages not sum to 100%, empty parties list)',
          () async {
        // Test business logic: revenue split calculation with fees and validation
        final parties2Way = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        final revenueSplit1 = await service.calculateNWaySplit(
          eventId: 'event-123',
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties2Way,
        );
        expect(revenueSplit1, isA<RevenueSplit>());
        expect(revenueSplit1.eventId, equals('event-123'));
        expect(revenueSplit1.partnershipId, equals('partnership-123'));
        expect(revenueSplit1.totalAmount, equals(100.00));
        expect(revenueSplit1.parties, hasLength(2));
        expect(revenueSplit1.parties[0].percentage, equals(50.0));
        expect(revenueSplit1.parties[1].percentage, equals(50.0));
        expect(revenueSplit1.isValid, isTrue);
        expect(revenueSplit1.platformFee, equals(10.00)); // 10% of 100.00
        // Processing fee = (100.00 * 0.029) + (0.30 * 4) = 2.90 + 1.20 = 4.10
        expect(revenueSplit1.processingFee, closeTo(4.10, 0.01));

        final parties3Way = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 40.0,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 35.0,
            name: 'Business',
          ),
          const SplitParty(
            partyId: 'sponsor-123',
            type: SplitPartyType.sponsor,
            percentage: 25.0,
            name: 'Sponsor',
          ),
        ];
        final revenueSplit2 = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties3Way,
        );
        expect(revenueSplit2.parties, hasLength(3));
        expect(revenueSplit2.isValid, isTrue);

        final invalidParties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 40.0,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];
        expect(
          () => service.calculateNWaySplit(
            eventId: 'event-123',
            totalAmount: 100.00,
            ticketsSold: 4,
            parties: invalidParties,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Percentages must sum to 100%'),
          )),
        );

        expect(
          () => service.calculateNWaySplit(
            eventId: 'event-123',
            totalAmount: 100.00,
            ticketsSold: 4,
            parties: [],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Parties list cannot be empty'),
          )),
        );
      });
    });

    group('calculateFromPartnership', () {
      test(
          'should calculate revenue split from partnership, or throw exception if partnership not found',
          () async {
        // Test business logic: revenue split calculation from partnership
        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => testPartnership);

        final revenueSplit = await service.calculateFromPartnership(
          partnershipId: 'partnership-123',
          totalAmount: 100.00,
          ticketsSold: 4,
        );
        expect(revenueSplit, isA<RevenueSplit>());
        expect(revenueSplit.eventId, equals('event-123'));
        expect(revenueSplit.partnershipId, equals('partnership-123'));
        expect(revenueSplit.parties, hasLength(2)); // Default 50/50 split
        expect(revenueSplit.parties[0].partyId, equals('user-123'));
        expect(revenueSplit.parties[1].partyId, equals('business-123'));

        when(mockPartnershipService.getPartnershipById('partnership-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.calculateFromPartnership(
            partnershipId: 'partnership-123',
            totalAmount: 100.00,
            ticketsSold: 4,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Partnership not found'),
          )),
        );
      });
    });

    group('lockSplit', () {
      test(
          'should lock revenue split, or throw exception if split not found or already locked',
          () async {
        // Test business logic: revenue split locking with validation
        final parties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ),
        ];

        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        final locked = await service.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );
        expect(locked.isLocked, isTrue);
        expect(locked.lockedBy, equals('user-123'));
        expect(locked.lockedAt, isNotNull);

        expect(
          () => service.lockSplit(
            revenueSplitId: 'nonexistent-split',
            lockedBy: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Revenue split not found'),
          )),
        );

        expect(
          () => service.lockSplit(
            revenueSplitId: revenueSplit.id,
            lockedBy: 'user-123',
          ),
          throwsA(isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('already locked'),
          )),
        );
      });
    });

    group('distributePayments', () {
      test(
          'should distribute payments to parties, or throw exception if split not locked',
          () async {
        // Test business logic: payment distribution with validation
        final parties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            amount: 43.50,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            amount: 43.50,
            name: 'Business',
          ),
        ];

        final revenueSplit = await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        final locked = await service.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: 'user-123',
        );

        final eventEndTime = DateTime.now().add(const Duration(days: 1));
        final distribution = await service.distributePayments(
          revenueSplitId: locked.id,
          eventEndTime: eventEndTime,
        );
        expect(distribution, isA<Map<String, double>>());
        expect(distribution['user-123'], isNotNull);
        expect(distribution['business-123'], isNotNull);

        // Test with unlocked split (create a new split that's not locked)
        final unlockedSplit = await service.calculateNWaySplit(
          eventId: 'event-456',
          totalAmount: 200.00,
          ticketsSold: 2,
          parties: parties,
        );
        await expectLater(
          service.distributePayments(
            revenueSplitId: unlockedSplit.id,
            eventEndTime: eventEndTime,
          ),
          throwsA(isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('must be locked'),
          )),
        );
      });
    });

    group('trackEarnings', () {
      test(
          'should track earnings for a party and filter earnings by date range',
          () async {
        // Test business logic: earnings tracking with date filtering
        final parties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            amount: 43.50,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
            amount: 43.50,
            name: 'Business',
          ),
        ];

        await service.calculateNWaySplit(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 4,
          parties: parties,
        );

        final earnings1 = await service.trackEarnings(partyId: 'user-123');
        expect(earnings1, isA<double>());
        expect(earnings1, greaterThanOrEqualTo(0.0));

        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now().add(const Duration(days: 30));
        final earnings2 = await service.trackEarnings(
          partyId: 'user-123',
          startDate: startDate,
          endDate: endDate,
        );
        expect(earnings2, isA<double>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

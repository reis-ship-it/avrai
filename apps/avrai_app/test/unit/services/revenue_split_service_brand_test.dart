import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/payment/product_tracking_service.dart';
import 'package:avrai_core/models/payment/revenue_split.dart';
import 'package:avrai_core/models/events/event_partnership.dart';
import 'package:avrai_core/models/sponsorship/sponsorship.dart';
import 'package:avrai_core/models/payment/product_tracking.dart';

import 'revenue_split_service_brand_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  PartnershipService,
  SponsorshipService,
  ProductTrackingService,
])
void main() {
  group('RevenueSplitService Brand Sponsorship Tests', () {
    late RevenueSplitService service;
    late MockPartnershipService mockPartnershipService;
    late MockSponsorshipService mockSponsorshipService;
    late MockProductTrackingService mockProductTrackingService;
    late EventPartnership testPartnership;
    late Sponsorship testSponsorship1;
    late Sponsorship testSponsorship2;

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      mockSponsorshipService = MockSponsorshipService();
      mockProductTrackingService = MockProductTrackingService();

      service = RevenueSplitService(
        partnershipService: mockPartnershipService,
        sponsorshipService: mockSponsorshipService,
        productTrackingService: mockProductTrackingService,
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

      testSponsorship1 = Sponsorship(
        id: 'sponsorship-1',
        eventId: 'event-123',
        brandId: 'brand-1',
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        status: SponsorshipStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testSponsorship2 = Sponsorship(
        id: 'sponsorship-2',
        eventId: 'event-123',
        brandId: 'brand-2',
        type: SponsorshipType.product,
        productValue: 300.00,
        status: SponsorshipStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Revenue split brand tests focus on business logic (brand split calculation, product sales, hybrid splits), not property assignment

    group('calculateNWayBrandSplit', () {
      test(
          'should calculate N-way brand split with partnership and brands, use provided brand percentages, throw exception if SponsorshipService not available, or calculate equal split among brands if percentages not provided',
          () async {
        // Test business logic: N-way brand split calculation
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockSponsorshipService.getSponsorshipsForEvent('event-123'))
            .thenAnswer((_) async => [testSponsorship1, testSponsorship2]);

        final revenueSplit1 = await service.calculateNWayBrandSplit(
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
        );
        expect(revenueSplit1, isA<RevenueSplit>());
        expect(revenueSplit1.eventId, equals('event-123'));
        expect(revenueSplit1.parties.length, greaterThanOrEqualTo(4));
        expect(
            revenueSplit1.parties.any((p) => p.partyId == 'user-123'), isTrue);
        expect(revenueSplit1.parties.any((p) => p.partyId == 'business-123'),
            isTrue);
        expect(
            revenueSplit1.parties.any((p) => p.partyId == 'brand-1'), isTrue);
        expect(
            revenueSplit1.parties.any((p) => p.partyId == 'brand-2'), isTrue);

        final revenueSplit2 = await service.calculateNWayBrandSplit(
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
          brandPercentages: {
            'brand-1': 15.0,
            'brand-2': 10.0,
          },
        );
        final brand1Party =
            revenueSplit2.parties.firstWhere((p) => p.partyId == 'brand-1');
        final brand2Party =
            revenueSplit2.parties.firstWhere((p) => p.partyId == 'brand-2');
        expect(brand1Party.percentage, equals(15.0));
        expect(brand2Party.percentage, equals(10.0));

        final serviceWithoutSponsorship = RevenueSplitService(
          partnershipService: mockPartnershipService,
        );
        expect(
          () => serviceWithoutSponsorship.calculateNWayBrandSplit(
            eventId: 'event-123',
            totalAmount: 1000.00,
            ticketsSold: 20,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('SponsorshipService not available'),
          )),
        );

        final revenueSplit3 = await service.calculateNWayBrandSplit(
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
        );
        final brandParties = revenueSplit3.parties
            .where((p) => p.type == SplitPartyType.sponsor)
            .toList();
        expect(brandParties.length, equals(2));
        expect(brandParties[0].percentage,
            closeTo(brandParties[1].percentage, 0.01));
      });
    });

    group('calculateProductSalesSplit', () {
      test(
          'should calculate product sales revenue split, throw exception if product tracking not found, or calculate platform and processing fees correctly',
          () async {
        // Test business logic: product sales split calculation
        final productTracking = ProductTracking(
          id: 'tracking-123',
          sponsorshipId: 'sponsorship-1',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          quantitySold: 50,
          unitPrice: 15.00,
          totalSales: 750.00,
          platformFee: 75.00,
          sales: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => productTracking);
        when(mockSponsorshipService.getSponsorshipById('sponsorship-1'))
            .thenAnswer((_) async => testSponsorship1);

        final revenueSplit1 = await service.calculateProductSalesSplit(
          productTrackingId: 'tracking-123',
          totalSales: 750.00,
        );
        expect(revenueSplit1, isA<RevenueSplit>());
        expect(revenueSplit1.totalAmount, equals(750.00));
        expect(revenueSplit1.parties, hasLength(1));
        expect(revenueSplit1.parties[0].partyId, equals('brand-1'));
        expect(revenueSplit1.parties[0].type, equals(SplitPartyType.sponsor));
        expect(revenueSplit1.platformFee, equals(75.00));
        expect(revenueSplit1.processingFee, closeTo(22.05, 0.01));

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.calculateProductSalesSplit(
            productTrackingId: 'tracking-123',
            totalSales: 750.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Product tracking not found'),
          )),
        );
      });
    });

    group('calculateHybridSplit', () {
      test(
          'should calculate hybrid split (cash + product) or distribute product sales to sponsor parties',
          () async {
        // Test business logic: hybrid split calculation
        final parties1 = [
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
            partyId: 'brand-1',
            type: SplitPartyType.sponsor,
            percentage: 25.0,
            name: 'Brand',
          ),
        ];
        final splits1 = await service.calculateHybridSplit(
          eventId: 'event-123',
          cashAmount: 1000.00,
          productSalesAmount: 500.00,
          ticketsSold: 20,
          parties: parties1,
        );
        expect(splits1, isA<Map<String, RevenueSplit>>());
        expect(splits1['cash'], isNotNull);
        expect(splits1['product'], isNotNull);
        expect(splits1['cash']?.totalAmount, equals(1000.00));
        expect(splits1['product']?.totalAmount, equals(500.00));

        final parties2 = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 40.0,
            name: 'User',
          ),
          const SplitParty(
            partyId: 'brand-1',
            type: SplitPartyType.sponsor,
            percentage: 60.0,
            name: 'Brand',
          ),
        ];
        final splits2 = await service.calculateHybridSplit(
          eventId: 'event-123',
          cashAmount: 1000.00,
          productSalesAmount: 500.00,
          ticketsSold: 20,
          parties: parties2,
        );
        final productSplit = splits2['product'];
        expect(productSplit, isNotNull);
        final sponsorParties = productSplit!.parties
            .where((p) => p.type == SplitPartyType.sponsor)
            .toList();
        expect(sponsorParties, isNotEmpty);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

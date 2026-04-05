import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/payment/product_tracking_service.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';
import 'package:avrai_core/models/payment/product_tracking.dart';
import 'package:avrai_core/models/sponsorship/sponsorship.dart';

import 'product_tracking_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([SponsorshipService, RevenueSplitService])
void main() {
  group('ProductTrackingService Tests', () {
    late ProductTrackingService service;
    late MockSponsorshipService mockSponsorshipService;
    late MockRevenueSplitService mockRevenueSplitService;
    late Sponsorship testSponsorship;

    setUp(() {
      mockSponsorshipService = MockSponsorshipService();
      mockRevenueSplitService = MockRevenueSplitService();

      service = ProductTrackingService(
        sponsorshipService: mockSponsorshipService,
        revenueSplitService: mockRevenueSplitService,
      );

      testSponsorship = Sponsorship(
        id: 'sponsorship-123',
        eventId: 'event-123',
        brandId: 'brand-123',
        type: SponsorshipType.product,
        productValue: 300.00,
        status: SponsorshipStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Product tracking tests focus on business logic (product contribution, sales, revenue attribution), not property assignment

    group('recordProductContribution', () {
      test(
          'should record product contribution for product sponsorship, throw exception if sponsorship not found, or throw exception if sponsorship type does not support products',
          () async {
        // Test business logic: product contribution recording
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking1 = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
          description: 'Premium coffee beans',
        );
        expect(tracking1, isA<ProductTracking>());
        expect(tracking1.sponsorshipId, equals('sponsorship-123'));
        expect(tracking1.productName, equals('Coffee Beans'));
        expect(tracking1.quantityProvided, equals(100));
        expect(tracking1.unitPrice, equals(15.00));
        expect(tracking1.quantityRemaining, equals(100));

        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.recordProductContribution(
            sponsorshipId: 'sponsorship-123',
            productName: 'Coffee Beans',
            quantityProvided: 100,
            unitPrice: 15.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sponsorship not found'),
          )),
        );

        final financialSponsorship = testSponsorship.copyWith(
          type: SponsorshipType.financial,
          productValue: null,
        );
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => financialSponsorship);
        expect(
          () => service.recordProductContribution(
            sponsorshipId: 'sponsorship-123',
            productName: 'Coffee Beans',
            quantityProvided: 100,
            unitPrice: 15.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('does not support products'),
          )),
        );
      });
    });

    group('recordProductSale', () {
      test(
          'should record product sale and update quantity or throw exception if insufficient quantity available',
          () async {
        // Test business logic: product sale recording
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking1 = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );
        final updated1 = await service.recordProductSale(
          productTrackingId: tracking1.id,
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );
        expect(updated1.quantitySold, equals(10));
        expect(updated1.quantityRemaining, equals(90));
        expect(updated1.sales, hasLength(1));
        expect(updated1.sales[0].quantity, equals(10));
        expect(updated1.sales[0].buyerId, equals('user-456'));

        final tracking2 = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 10,
          unitPrice: 15.00,
        );
        expect(
          () => service.recordProductSale(
            productTrackingId: tracking2.id,
            quantity: 20,
            buyerId: 'user-456',
            salePrice: 15.00,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient quantity'),
          )),
        );
      });
    });

    group('calculateRevenueAttribution', () {
      test('should calculate revenue attribution for product sales', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );

        await service.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );

        // Act
        final revenueDistribution = await service.calculateRevenueAttribution(
          productTrackingId: tracking.id,
        );

        // Get updated tracking to verify
        final updatedTracking =
            await service.getProductTrackingById(tracking.id);

        // Assert
        expect(revenueDistribution, isA<Map<String, double>>());
        expect(revenueDistribution, isNotEmpty);
        expect(updatedTracking, isNotNull);
        expect(updatedTracking!.totalSales, equals(150.00)); // 10 * 15.00
        expect(updatedTracking.revenueDistribution, isNotEmpty);
      });
    });

    group('generateSalesReport', () {
      test('should generate sales report for product tracking', () async {
        // Arrange
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final tracking = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );

        await service.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );

        // Act
        final report = await service.generateSalesReport(
          sponsorshipId: 'sponsorship-123',
        );

        // Assert
        expect(report, isA<ProductSalesReport>());
        expect(report.sponsorshipId, equals('sponsorship-123'));
        expect(report.totalQuantitySold, greaterThanOrEqualTo(10));
        expect(report.totalSales, greaterThanOrEqualTo(150.00));
      });
    });

    group('getProductTrackingById', () {
      test(
          'should return product tracking by ID or return null if product tracking not found',
          () async {
        // Test business logic: product tracking retrieval
        when(mockSponsorshipService.getSponsorshipById('sponsorship-123'))
            .thenAnswer((_) async => testSponsorship);

        final created = await service.recordProductContribution(
          sponsorshipId: 'sponsorship-123',
          productName: 'Coffee Beans',
          quantityProvided: 100,
          unitPrice: 15.00,
        );
        final tracking1 = await service.getProductTrackingById(created.id);
        expect(tracking1, isNotNull);
        expect(tracking1?.id, equals(created.id));

        final tracking2 =
            await service.getProductTrackingById('nonexistent-id');
        expect(tracking2, isNull);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

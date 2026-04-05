import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/payment/product_sales_service.dart';
import 'package:avrai_runtime_os/services/payment/product_tracking_service.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_service.dart';
import 'package:avrai_core/models/payment/product_tracking.dart';
import 'package:avrai_core/models/payment/revenue_split.dart';
import 'package:avrai_core/models/payment/payment_status.dart';

import 'product_sales_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  ProductTrackingService,
  RevenueSplitService,
  PaymentService,
])
void main() {
  group('ProductSalesService Tests', () {
    late ProductSalesService service;
    late MockProductTrackingService mockProductTrackingService;
    late MockRevenueSplitService mockRevenueSplitService;
    late MockPaymentService mockPaymentService;
    late ProductTracking testProductTracking;

    setUp(() {
      mockProductTrackingService = MockProductTrackingService();
      mockRevenueSplitService = MockRevenueSplitService();
      mockPaymentService = MockPaymentService();

      service = ProductSalesService(
        productTrackingService: mockProductTrackingService,
        revenueSplitService: mockRevenueSplitService,
        paymentService: mockPaymentService,
      );

      testProductTracking = ProductTracking(
        id: 'tracking-123',
        sponsorshipId: 'sponsorship-123',
        productName: 'Coffee Beans',
        quantityProvided: 100,
        quantitySold: 0,
        unitPrice: 15.00,
        totalSales: 0.0,
        platformFee: 0.0,
        sales: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Product sales tests focus on business logic (product sale processing, revenue calculation, revenue split), not property assignment

    group('processProductSale', () {
      test(
          'should process product sale successfully, throw exception if product tracking not found, throw exception if insufficient quantity available, or use unitPrice if salePrice not provided',
          () async {
        // Test business logic: product sale processing
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => testProductTracking);
        when(mockProductTrackingService.recordProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
          paymentMethod: anyNamed('paymentMethod'),
        )).thenAnswer((_) async => testProductTracking.copyWith(
              quantitySold: 10,
              totalSales: 150.00,
              sales: [
                ProductSale(
                  id: 'sale-1',
                  productTrackingId: 'tracking-123',
                  buyerId: 'user-456',
                  quantity: 10,
                  unitPrice: 15.00,
                  totalAmount: 150.00,
                  soldAt: DateTime.now(),
                  paymentStatus: PaymentStatus.completed,
                ),
              ],
            ));
        when(mockProductTrackingService.calculateRevenueAttribution(
          productTrackingId: 'tracking-123',
        )).thenAnswer((_) async => {'brand-123': 135.00});
        final sale1 = await service.processProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
        );
        expect(sale1, isA<ProductSale>());
        expect(sale1.quantity, equals(10));
        expect(sale1.buyerId, equals('user-456'));
        expect(sale1.totalAmount, equals(150.00));

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.processProductSale(
            productTrackingId: 'tracking-123',
            quantity: 10,
            buyerId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Product tracking not found'),
          )),
        );

        final lowStockTracking = testProductTracking.copyWith(
          quantityProvided: 5,
        );
        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => lowStockTracking);
        expect(
          () => service.processProductSale(
            productTrackingId: 'tracking-123',
            quantity: 10,
            buyerId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient quantity available'),
          )),
        );

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => testProductTracking);
        when(mockProductTrackingService.recordProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
          salePrice: 15.00,
          paymentMethod: anyNamed('paymentMethod'),
        )).thenAnswer((_) async => testProductTracking.copyWith(
              quantitySold: 10,
              totalSales: 150.00,
              sales: [
                ProductSale(
                  id: 'sale-1',
                  productTrackingId: 'tracking-123',
                  buyerId: 'user-456',
                  quantity: 10,
                  unitPrice: 15.00,
                  totalAmount: 150.00,
                  soldAt: DateTime.now(),
                  paymentStatus: PaymentStatus.completed,
                ),
              ],
            ));
        when(mockProductTrackingService.calculateRevenueAttribution(
          productTrackingId: 'tracking-123',
        )).thenAnswer((_) async => {'brand-123': 135.00});
        final sale2 = await service.processProductSale(
          productTrackingId: 'tracking-123',
          quantity: 10,
          buyerId: 'user-456',
        );
        expect(sale2.unitPrice, equals(15.00));
      });
    });

    group('calculateProductRevenue', () {
      test(
          'should calculate total product revenue for sponsorship or filter revenue by date range',
          () async {
        // Test business logic: product revenue calculation
        final tracking1 = testProductTracking.copyWith(
          id: 'tracking-1',
          totalSales: 150.00,
        );
        final tracking2 = testProductTracking.copyWith(
          id: 'tracking-2',
          totalSales: 200.00,
        );
        when(mockProductTrackingService
                .getProductTrackingForSponsorship('sponsorship-123'))
            .thenAnswer((_) async => [tracking1, tracking2]);
        final revenue1 = await service.calculateProductRevenue(
          sponsorshipId: 'sponsorship-123',
        );
        expect(revenue1, equals(350.00));

        final tracking3 = testProductTracking.copyWith(
          id: 'tracking-1',
          totalSales: 150.00,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        );
        final tracking4 = testProductTracking.copyWith(
          id: 'tracking-2',
          totalSales: 200.00,
          createdAt: DateTime.now().add(const Duration(days: 5)),
        );
        when(mockProductTrackingService
                .getProductTrackingForSponsorship('sponsorship-123'))
            .thenAnswer((_) async => [tracking3, tracking4]);
        final startDate = DateTime.now().subtract(const Duration(days: 10));
        final endDate = DateTime.now();
        final revenue2 = await service.calculateProductRevenue(
          sponsorshipId: 'sponsorship-123',
          startDate: startDate,
          endDate: endDate,
        );
        expect(revenue2, equals(150.00));
      });
    });

    group('calculateProductRevenueSplit', () {
      test('should calculate product revenue split', () async {
        // Arrange
        final tracking = testProductTracking.copyWith(
          totalSales: 150.00,
        );
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          totalAmount: 150.00,
          ticketsSold: 10,
          parties: const [
            SplitParty(
              partyId: 'brand-123',
              type: SplitPartyType.sponsor,
              percentage: 100.0,
              amount: 135.00,
              name: 'Brand',
            ),
          ],
        );

        when(mockProductTrackingService.getProductTrackingById('tracking-123'))
            .thenAnswer((_) async => tracking);
        when(mockRevenueSplitService.calculateProductSalesSplit(
          productTrackingId: 'tracking-123',
          totalSales: 150.00,
        )).thenAnswer((_) async => revenueSplit);

        // Act
        final split = await service.calculateProductRevenueSplit(
          productTrackingId: 'tracking-123',
        );

        // Assert
        expect(split, isA<RevenueSplit>());
        expect(split.totalAmount, equals(150.00));
        expect(split.parties, hasLength(1));
        expect(split.parties[0].partyId, equals('brand-123'));
      });
    });

    group('generateEventSalesReport', () {
      test('should generate event sales report', () async {
        // Act
        final report = await service.generateEventSalesReport(
          eventId: 'event-123',
        );

        // Assert
        expect(report, isA<EventProductSalesReport>());
        expect(report.eventId, equals('event-123'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

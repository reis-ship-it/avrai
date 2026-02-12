import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/business/brand_analytics_service.dart';
import 'package:avrai/core/services/business/sponsorship_service.dart';
import 'package:avrai/core/services/payment/product_tracking_service.dart';
import 'package:avrai/core/services/payment/product_sales_service.dart';
import 'package:avrai/core/services/payment/revenue_split_service.dart';
import 'package:avrai/core/models/sponsorship/sponsorship.dart';

import 'brand_analytics_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  SponsorshipService,
  ProductTrackingService,
  ProductSalesService,
  RevenueSplitService,
])
void main() {
  group('BrandAnalyticsService Tests', () {
    late BrandAnalyticsService service;
    late MockSponsorshipService mockSponsorshipService;
    late MockProductTrackingService mockProductTrackingService;
    late MockProductSalesService mockProductSalesService;
    late MockRevenueSplitService mockRevenueSplitService;
    late Sponsorship testSponsorship;

    setUp(() {
      // Create fresh mocks for each test to avoid conflicts
      mockSponsorshipService = MockSponsorshipService();
      mockProductTrackingService = MockProductTrackingService();
      mockProductSalesService = MockProductSalesService();
      mockRevenueSplitService = MockRevenueSplitService();

      // Mock getSponsorshipsForBrand and getSponsorshipsForEvent to return empty list by default
      // Tests can override this if they need specific sponsorships
      when(mockSponsorshipService.getSponsorshipsForBrand(any))
          .thenAnswer((_) async => <Sponsorship>[]);
      when(mockSponsorshipService.getSponsorshipsForEvent(any))
          .thenAnswer((_) async => <Sponsorship>[]);
      
      // Mock trackEarnings to return 0.0 by default
      // Tests can override this if they need specific earnings
      when(mockRevenueSplitService.trackEarnings(
        partyId: anyNamed('partyId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => 0.0);

      service = BrandAnalyticsService(
        sponsorshipService: mockSponsorshipService,
        productTrackingService: mockProductTrackingService,
        productSalesService: mockProductSalesService,
        revenueSplitService: mockRevenueSplitService,
      );

      testSponsorship = Sponsorship(
        id: 'sponsorship-123',
        eventId: 'event-123',
        brandId: 'brand-123',
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        status: SponsorshipStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('calculateBrandROI', () {
      test('should calculate brand ROI', () async {
        // Arrange - Set up all mocks BEFORE any service calls
        when(mockSponsorshipService.getSponsorshipsForBrand('brand-123'))
            .thenAnswer((_) async => <Sponsorship>[]);
        when(mockRevenueSplitService.trackEarnings(
          partyId: 'brand-123',
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        )).thenAnswer((_) async => 600.00); // Revenue from splits

        // Act
        final roi = await service.calculateBrandROI(
          brandId: 'brand-123',
        );

        // Assert
        expect(roi, isA<BrandROI>());
        expect(roi.brandId, equals('brand-123'));
        expect(roi.totalRevenue, equals(600.00));
        expect(roi.roiPercentage, isA<double>());
      });

      test('should calculate ROI percentage correctly', () async {
        // Arrange - Set up all mocks BEFORE any service calls
        // Investment: 500.00 (from sponsorship contributionAmount)
        // Revenue: 600.00
        // ROI = ((600 - 500) / 500) * 100 = 20%
        when(mockSponsorshipService.getSponsorshipsForBrand('brand-123'))
            .thenAnswer((_) async => <Sponsorship>[testSponsorship]);
        when(mockRevenueSplitService.trackEarnings(
          partyId: 'brand-123',
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        )).thenAnswer((_) async => 600.00);

        // Act
        final roi = await service.calculateBrandROI(
          brandId: 'brand-123',
        );

        // Assert
        expect(roi.totalInvestment, equals(500.00));
        expect(roi.totalRevenue, equals(600.00));
        expect(roi.netProfit, equals(100.00)); // 600 - 500
        expect(roi.roiPercentage, equals(20.0)); // ((600 - 500) / 500) * 100
      });

      test('should filter ROI by date range', () async {
        // Arrange - Set up all mocks BEFORE any service calls
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        when(mockSponsorshipService.getSponsorshipsForBrand('brand-123'))
            .thenAnswer((_) async => <Sponsorship>[]);
        when(mockRevenueSplitService.trackEarnings(
          partyId: 'brand-123',
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => 600.00);

        // Act
        final roi = await service.calculateBrandROI(
          brandId: 'brand-123',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(roi.startDate, equals(startDate));
        expect(roi.endDate, equals(endDate));
      });
    });

    group('getBrandPerformance', () {
      test('should return brand performance metrics', () async {
        // Act
        final performance = await service.getBrandPerformance(
          brandId: 'brand-123',
        );

        // Assert
        expect(performance, isA<BrandPerformance>());
        expect(performance.brandId, equals('brand-123'));
        expect(performance.calculatedAt, isNotNull);
      });
    });

    group('analyzeBrandExposure', () {
      test('should return brand exposure analytics', () async {
        // Act
        final exposure = await service.analyzeBrandExposure(
          brandId: 'brand-123',
          eventId: 'event-123',
        );

        // Assert
        expect(exposure, isA<BrandExposure>());
        expect(exposure.brandId, equals('brand-123'));
        expect(exposure.eventId, equals('event-123'));
        expect(exposure.calculatedAt, isNotNull);
      });
    });

    group('getEventPerformance', () {
      test('should return event performance metrics', () async {
        // Arrange - Set up all mocks BEFORE any service calls
        when(mockSponsorshipService.getSponsorshipsForEvent('event-123'))
            .thenAnswer((_) async => <Sponsorship>[testSponsorship]);

        // Act
        final performance = await service.getEventPerformance(
          eventId: 'event-123',
        );

        // Assert
        expect(performance, isA<EventPerformance>());
        expect(performance.eventId, equals('event-123'));
        expect(performance.totalSponsorships, equals(1));
        expect(performance.totalSponsorshipValue, equals(500.00));
      });
    });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/business/brand_analytics_service.dart';
import 'package:avrai/core/services/business/sponsorship_service.dart';
import 'package:avrai/core/services/payment/product_tracking_service.dart';
import 'package:avrai/core/services/payment/product_sales_service.dart';
import 'package:avrai/core/services/payment/revenue_split_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/services/matching/vibe_compatibility_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/models/sponsorship/sponsorship.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/business/brand_account.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for brand-analytics flow
/// 
/// Tests the integration between brand sponsorships and analytics:
/// 1. ROI tracking for brands
/// 2. Performance metrics
/// 3. Brand exposure analytics
/// 4. Event performance tracking
void main() {
  group('Brand-Analytics Integration Tests', () {
    late BrandAnalyticsService analyticsService;
    late SponsorshipService sponsorshipService;
    late ProductTrackingService productTrackingService;
    late ProductSalesService productSalesService;
    late RevenueSplitService revenueSplitService;
    late ExpertiseEventService eventService;
    late PartnershipService partnershipService;
    late BusinessService businessService;
    late UnifiedUser testUser;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand;

    setUp(() {
      if (!di.sl.isRegistered<AgentIdService>()) {
        di.sl.registerLazySingleton<AgentIdService>(() => AgentIdService());
      }

      final VibeCompatibilityService vibeCompatibilityService =
          QuantumKnotVibeCompatibilityService(
        personalityLearning: PersonalityLearning(),
        personalityKnotService: PersonalityKnotService(),
        entityKnotService: EntityKnotService(),
      );

      eventService = ExpertiseEventService();
      final businessAccountService = BusinessAccountService();
      businessService = BusinessService(accountService: businessAccountService);
      partnershipService = PartnershipService(
        eventService: eventService,
        businessService: businessService,
        vibeCompatibilityService: vibeCompatibilityService,
      );
      sponsorshipService = SponsorshipService(
        eventService: eventService,
        partnershipService: partnershipService,
        vibeCompatibilityService: vibeCompatibilityService,
      );
      revenueSplitService = RevenueSplitService(
        partnershipService: partnershipService,
        sponsorshipService: sponsorshipService,
      );
      productTrackingService = ProductTrackingService(
        sponsorshipService: sponsorshipService,
        revenueSplitService: revenueSplitService,
      );
      productSalesService = ProductSalesService(
        productTrackingService: productTrackingService,
        revenueSplitService: revenueSplitService,
      );
      analyticsService = BrandAnalyticsService(
        sponsorshipService: sponsorshipService,
        productTrackingService: productTrackingService,
        productSalesService: productSalesService,
        revenueSplitService: revenueSplitService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      testUser = testUser.copyWith(
        expertiseMap: {
          'Coffee': 'city',
        },
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Brand Event',
        description: 'An event with brand sponsorship',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Test Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'test@brand.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('brand ROI calculation flow', () async {
      // Step 1: Create event in service
      final createdEvent = await eventService.createEvent(
        host: testEvent.host,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
        maxAttendees: testEvent.maxAttendees,
        price: testEvent.price,
      );
      
      // Step 2: Register brand and create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Calculate brand ROI
      final roi = await analyticsService.calculateBrandROI(
        brandId: testBrand.id,
      );

      // Assert
      expect(roi, isA<BrandROI>());
      expect(roi.brandId, equals(testBrand.id));
      expect(roi.totalInvestment, greaterThanOrEqualTo(0.0));
      expect(roi.totalRevenue, greaterThanOrEqualTo(0.0));
    });

    test('brand performance metrics flow', () async {
      // Step 1: Create event in service
      final createdEvent = await eventService.createEvent(
        host: testEvent.host,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
        maxAttendees: testEvent.maxAttendees,
        price: testEvent.price,
      );
      
      // Step 2: Register brand and create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Get brand performance
      final performance = await analyticsService.getBrandPerformance(
        brandId: testBrand.id,
      );

      // Assert
      expect(performance, isA<BrandPerformance>());
      expect(performance.brandId, equals(testBrand.id));
      expect(performance.totalSponsorships, greaterThanOrEqualTo(0));
    });

    test('brand exposure analytics flow', () async {
      // Step 1: Create event in service
      final createdEvent = await eventService.createEvent(
        host: testEvent.host,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
        maxAttendees: testEvent.maxAttendees,
        price: testEvent.price,
      );
      
      // Step 2: Register brand and create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Analyze brand exposure
      final exposure = await analyticsService.analyzeBrandExposure(
        brandId: testBrand.id,
        eventId: createdEvent.id,
      );

      // Assert
      expect(exposure, isA<BrandExposure>());
      expect(exposure.brandId, equals(testBrand.id));
      expect(exposure.eventId, equals(createdEvent.id));
    });

    test('event performance tracking flow', () async {
      // Step 1: Create event in service
      final createdEvent = await eventService.createEvent(
        host: testEvent.host,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
        maxAttendees: testEvent.maxAttendees,
        price: testEvent.price,
      );
      
      // Step 2: Register brand and create sponsorship
      await sponsorshipService.registerBrand(testBrand);

      await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      // Step 2: Get event performance
      final performance = await analyticsService.getEventPerformance(
        eventId: createdEvent.id,
      );

      // Assert
      expect(performance, isA<EventPerformance>());
      expect(performance.eventId, equals(createdEvent.id));
      expect(performance.totalSponsorships, greaterThanOrEqualTo(1));
      expect(performance.totalSponsorshipValue, greaterThanOrEqualTo(500.00));
    });
  });
}


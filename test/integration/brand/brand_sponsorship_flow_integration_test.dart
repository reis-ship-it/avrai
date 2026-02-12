import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/business/sponsorship_service.dart';
import 'package:avrai/core/services/business/brand_discovery_service.dart';
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

/// Integration tests for end-to-end brand sponsorship flow
/// 
/// Tests the complete brand sponsorship lifecycle:
/// 1. Brand discovery
/// 2. Sponsorship proposal
/// 3. Sponsorship acceptance
/// 4. Product tracking (if applicable)
/// 5. Revenue attribution
void main() {
  group('Brand Sponsorship Flow Integration Tests', () {
    late SponsorshipService sponsorshipService;
    late BrandDiscoveryService brandDiscoveryService;
    late ExpertiseEventService eventService;
    late PartnershipService partnershipService;
    late BusinessService businessService;
    late BusinessAccountService businessAccountService;
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
      businessAccountService = BusinessAccountService();
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
      brandDiscoveryService = BrandDiscoveryService(
        eventService: eventService,
        sponsorshipService: sponsorshipService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      testUser = testUser.copyWith(
        expertiseMap: {
          'Coffee': 'city',
        },
        location: 'San Francisco', // Set location to match event location for city expert
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Event',
        description: 'A coffee event with brand sponsorship',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'San Francisco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Test Coffee Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'test@brand.com',
        verificationStatus: BrandVerificationStatus.verified,
        categories: const ['Coffee'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('complete brand sponsorship flow: discovery → proposal → acceptance', () async {
      // Step 0: Create event in service so it can be found
      final createdEvent = await eventService.createEvent(
        host: testUser,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
      );
      
      // Step 1: Register brand in both services
      await sponsorshipService.registerBrand(testBrand);
      // Also register in BrandDiscoveryService so it can find the brand
      await brandDiscoveryService.registerBrand(testBrand);

      // Step 2: Get sponsorship suggestions
      final discovery = await brandDiscoveryService.getSponsorshipSuggestions(
        eventId: createdEvent.id,
      );

      expect(discovery.matchingResults, isNotEmpty);

      // Step 3: Create sponsorship proposal
      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.financial,
        contributionAmount: 500.00,
        vibeCompatibilityScore: 0.75,
      );

      expect(sponsorship.status, equals(SponsorshipStatus.proposed));
      expect(sponsorship.type, equals(SponsorshipType.financial));
      expect(sponsorship.contributionAmount, equals(500.00));

      // Step 4: Update sponsorship status to approved
      final approved = await sponsorshipService.updateSponsorshipStatus(
        sponsorshipId: sponsorship.id,
        status: SponsorshipStatus.approved,
      );

      expect(approved.status, equals(SponsorshipStatus.approved));

      // Step 5: Lock sponsorship
      final locked = await sponsorshipService.updateSponsorshipStatus(
        sponsorshipId: sponsorship.id,
        status: SponsorshipStatus.locked,
      );

      expect(locked.status, equals(SponsorshipStatus.locked));
      expect(locked.isLocked, isTrue);
    });

    test('multi-party sponsorship flow with partnership', () async {
      // Step 0: Create event in service so it can be found
      final createdEvent = await eventService.createEvent(
        host: testUser,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
      );
      
      // Step 1: Create business and partnership
      final business = await businessService.createBusinessAccount(
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdBy: 'user-123',
      );
      // Update business to be verified and active in the service
      // Use the same BusinessAccountService instance that BusinessService uses
      final verifiedBusiness = await businessAccountService.updateBusinessAccount(
        business,
        name: business.name,
        isVerified: true,
        isActive: true,
      );

      await partnershipService.createPartnership(
        eventId: createdEvent.id,
        userId: testUser.id,
        businessId: verifiedBusiness.id,
        vibeCompatibilityScore: 0.75,
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

      // Step 3: Verify both partnership and sponsorship exist for event
      final partnerships = await partnershipService.getPartnershipsForEvent(createdEvent.id);
      final sponsorships = await sponsorshipService.getSponsorshipsForEvent(createdEvent.id);

      expect(partnerships, isNotEmpty);
      expect(sponsorships, isNotEmpty);
      expect(partnerships.first.eventId, equals(createdEvent.id));
      expect(sponsorships.first.eventId, equals(createdEvent.id));
    });

    test('product sponsorship flow with product tracking', () async {
      // Step 0: Create event in service so it can be found
      final createdEvent = await eventService.createEvent(
        host: testUser,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
      );
      
      // Step 1: Register brand
      await sponsorshipService.registerBrand(testBrand);

      // Step 2: Create product sponsorship
      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.product,
        productValue: 300.00,
        vibeCompatibilityScore: 0.75,
      );

      expect(sponsorship.type, equals(SponsorshipType.product));
      expect(sponsorship.productValue, equals(300.00));

      // Step 3: Product tracking would be done separately
      // This test verifies sponsorship can be created for product type
    });

    test('hybrid sponsorship flow (cash + product)', () async {
      // Step 0: Create event in service so it can be found
      final createdEvent = await eventService.createEvent(
        host: testUser,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
      );
      
      // Step 1: Register brand
      await sponsorshipService.registerBrand(testBrand);

      // Step 2: Create hybrid sponsorship
      final sponsorship = await sponsorshipService.createSponsorship(
        eventId: createdEvent.id,
        brandId: testBrand.id,
        type: SponsorshipType.hybrid,
        contributionAmount: 500.00,
        productValue: 300.00,
        vibeCompatibilityScore: 0.75,
      );

      expect(sponsorship.type, equals(SponsorshipType.hybrid));
      expect(sponsorship.contributionAmount, equals(500.00));
      expect(sponsorship.productValue, equals(300.00));
      expect(sponsorship.totalContributionValue, equals(800.00));
    });

    test('sponsorship eligibility checks', () async {
      // Step 0: Create event in service so it can be found
      final createdEvent = await eventService.createEvent(
        host: testUser,
        title: testEvent.title,
        description: testEvent.description,
        category: testEvent.category,
        eventType: testEvent.eventType,
        startTime: testEvent.startTime,
        endTime: testEvent.endTime,
        location: testEvent.location,
      );
      
      // Step 1: Create unverified brand
      final unverifiedBrand = BrandAccount(
        id: 'brand-unverified',
        name: 'Unverified Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'unverified@brand.com',
        verificationStatus: BrandVerificationStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await sponsorshipService.registerBrand(unverifiedBrand);

      // Step 2: Try to create sponsorship (should fail eligibility check)
      final isEligible = await sponsorshipService.checkSponsorshipEligibility(
        eventId: createdEvent.id,
        brandId: unverifiedBrand.id,
      );

      expect(isEligible, isFalse); // Brand not verified

      // Step 3: Verify brand and check again
      final verifiedBrand = unverifiedBrand.copyWith(
        verificationStatus: BrandVerificationStatus.verified,
      );
      await sponsorshipService.registerBrand(verifiedBrand);

      final isEligibleAfterVerification = await sponsorshipService.checkSponsorshipEligibility(
        eventId: createdEvent.id,
        brandId: verifiedBrand.id,
      );

      // Should be eligible if compatibility is 70%+
      expect(isEligibleAfterVerification, isTrue);
    });
  });
}


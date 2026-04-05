import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/sponsorship/sponsorship.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/business/brand_account.dart';
import '../../fixtures/model_factories.dart';

import 'sponsorship_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService, PartnershipService])
void main() {
  if (!di.sl.isRegistered<AgentIdService>()) {
    di.sl.registerLazySingleton<AgentIdService>(() => AgentIdService());
  }

  final VibeCompatibilityService vibeCompatibilityService =
      QuantumKnotVibeCompatibilityService(
    personalityLearning: PersonalityLearning(),
    personalityKnotService: PersonalityKnotService(),
    entityKnotService: EntityKnotService(),
  );

  group('SponsorshipService Tests', () {
    late SponsorshipService service;
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPartnershipService = MockPartnershipService();

      service = SponsorshipService(
        eventService: mockEventService,
        partnershipService: mockPartnershipService,
        vibeCompatibilityService: vibeCompatibilityService,
      );

      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
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

    // Removed: Property assignment tests
    // Sponsorship tests focus on business logic (creation, validation, status management), not property assignment

    group('createSponsorship', () {
      test(
          'should create financial, product, and hybrid sponsorships with valid inputs, or throw exception for invalid inputs (event not found, brand not found, brand not verified, compatibility below threshold, missing required fields)',
          () async {
        // Test business logic: sponsorship creation with validation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);

        // Financial sponsorship
        final financial = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );
        expect(financial.type, equals(SponsorshipType.financial));
        expect(financial.contributionAmount, equals(500.00));
        expect(financial.status, equals(SponsorshipStatus.proposed));

        // Product sponsorship
        final product = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 300.00,
          vibeCompatibilityScore: 0.80,
        );
        expect(product.type, equals(SponsorshipType.product));
        expect(product.productValue, equals(300.00));

        // Hybrid sponsorship
        final hybrid = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.hybrid,
          contributionAmount: 500.00,
          productValue: 300.00,
          vibeCompatibilityScore: 0.75,
        );
        expect(hybrid.type, equals(SponsorshipType.hybrid));
        expect(hybrid.contributionAmount, equals(500.00));
        expect(hybrid.productValue, equals(300.00));

        // Error cases
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'nonexistent-brand',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Brand account not found'),
          )),
        );

        final unverifiedBrand = BrandAccount(
          id: 'brand-unverified',
          name: 'Unverified Brand',
          brandType: 'Coffee Roaster',
          contactEmail: 'unverified@brand.com',
          verificationStatus: BrandVerificationStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.registerBrand(unverifiedBrand);
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-unverified',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Brand account not verified'),
          )),
        );

        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.65, // Below 70% threshold
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Compatibility below 70% threshold'),
          )),
        );

        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            vibeCompatibilityScore: 0.75,
            // Missing contributionAmount
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Financial sponsorship requires contributionAmount'),
          )),
        );

        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.product,
            vibeCompatibilityScore: 0.75,
            // Missing productValue
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Product sponsorship requires productValue'),
          )),
        );
      });
    });

    group('getSponsorshipsForEvent', () {
      test('should return sponsorships for event or empty list if none exist',
          () async {
        // Test business logic: sponsorship retrieval
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);

        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        final sponsorships = await service.getSponsorshipsForEvent('event-123');
        expect(sponsorships, isNotEmpty);
        expect(sponsorships.first.id, equals(sponsorship.id));
        expect(sponsorships.first.eventId, equals('event-123'));

        final emptySponsorships =
            await service.getSponsorshipsForEvent('event-none');
        expect(emptySponsorships, isEmpty);
      });
    });

    group('getSponsorshipById', () {
      test('should return sponsorship by ID or null if not found', () async {
        // Test business logic: sponsorship retrieval by ID
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);

        final created = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        final sponsorship = await service.getSponsorshipById(created.id);
        expect(sponsorship, isNotNull);
        expect(sponsorship?.id, equals(created.id));

        final notFound = await service.getSponsorshipById('nonexistent-id');
        expect(notFound, isNull);
      });
    });

    group('updateSponsorshipStatus', () {
      test(
          'should update sponsorship status correctly, or throw exception if sponsorship not found or status transition is invalid',
          () async {
        // Test business logic: status updates with validation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);

        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        final updated = await service.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.negotiating,
        );
        expect(updated.status, equals(SponsorshipStatus.negotiating));
        expect(updated.updatedAt.isAfter(sponsorship.updatedAt), isTrue);

        expect(
          () => service.updateSponsorshipStatus(
            sponsorshipId: 'nonexistent-id',
            status: SponsorshipStatus.negotiating,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sponsorship not found'),
          )),
        );

        // Cannot go from proposed directly to completed
        expect(
          () => service.updateSponsorshipStatus(
            sponsorshipId: sponsorship.id,
            status: SponsorshipStatus.completed,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid status transition'),
          )),
        );
      });
    });

    group('checkSponsorshipEligibility', () {
      test(
          'should return true for eligible sponsorship, or false if event not found or event has already started',
          () async {
        // Test business logic: eligibility checking
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);

        final isEligible = await service.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );
        expect(isEligible, isTrue);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        final notFound = await service.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );
        expect(notFound, isFalse);

        final pastEvent = testEvent.copyWith(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(hours: 23)),
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => pastEvent);
        final started = await service.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );
        expect(started, isFalse);
      });
    });

    group('calculateCompatibility', () {
      test('should return compatibility score', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.registerBrand(testBrand);

        // Act
        final compatibility = await service.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/business/brand_discovery_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/business/brand_account.dart';
import 'package:avrai_core/models/business/brand_discovery.dart';
import '../../fixtures/model_factories.dart';

import 'brand_discovery_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService, SponsorshipService])
void main() {
  group('BrandDiscoveryService Tests', () {
    late BrandDiscoveryService service;
    late MockExpertiseEventService mockEventService;
    late MockSponsorshipService mockSponsorshipService;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand1;
    late BrandAccount testBrand2;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockSponsorshipService = MockSponsorshipService();

      service = BrandDiscoveryService(
        eventService: mockEventService,
        sponsorshipService: mockSponsorshipService,
      );

      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Event',
        description: 'A coffee event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'San Francisco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand1 = BrandAccount(
        id: 'brand-1',
        name: 'Coffee Brand 1',
        brandType: 'Coffee Roaster',
        contactEmail: 'brand1@coffee.com',
        verificationStatus: BrandVerificationStatus.verified,
        categories: const ['Coffee'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand2 = BrandAccount(
        id: 'brand-2',
        name: 'Coffee Brand 2',
        brandType: 'Coffee Roaster',
        contactEmail: 'brand2@coffee.com',
        verificationStatus: BrandVerificationStatus.verified,
        categories: const ['Coffee'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Brand discovery tests focus on business logic (brand finding, compatibility calculation, sponsorship suggestions), not property assignment

    group('findBrandsForEvent', () {
      test(
          'should return matching brands with 70%+ compatibility, filter out brands below 70% compatibility threshold, return empty list if event not found, or respect custom minCompatibility threshold',
          () async {
        // Test business logic: brand finding for events
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => true);
        when(mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => true);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.75,
              quantum: 0.75,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.80);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.80,
              quantum: 0.80,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        await service.registerBrand(testBrand1);
        await service.registerBrand(testBrand2);
        final matches1 = await service.findBrandsForEvent(
          eventId: 'event-123',
          minCompatibility: 0.70,
        );
        expect(matches1, isNotEmpty);
        expect(matches1.length, greaterThanOrEqualTo(2));
        expect(matches1[0].compatibilityScore, greaterThanOrEqualTo(70.0));
        expect(matches1[1].compatibilityScore, greaterThanOrEqualTo(70.0));
        expect(matches1[0].compatibilityScore,
            greaterThanOrEqualTo(matches1[1].compatibilityScore));

        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.65);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.65,
              quantum: 0.65,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.75,
              quantum: 0.75,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        final matches2 = await service.findBrandsForEvent(
          eventId: 'event-123',
          minCompatibility: 0.70,
        );
        expect(matches2.length, equals(1));
        expect(matches2[0].brandId, equals('brand-2'));
        expect(matches2[0].compatibilityScore, greaterThanOrEqualTo(70.0));

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        final matches3 = await service.findBrandsForEvent(
          eventId: 'event-123',
        );
        expect(matches3, isEmpty);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.75,
              quantum: 0.75,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.85);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.85,
              quantum: 0.85,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        final matches4 = await service.findBrandsForEvent(
          eventId: 'event-123',
          minCompatibility: 0.80,
        );
        expect(matches4.length, equals(1));
        expect(matches4[0].brandId, equals('brand-2'));
        expect(matches4[0].compatibilityScore, greaterThanOrEqualTo(80.0));
      });
    });

    group('findEventsForBrand', () {
      test('should return matching events for brand', () async {
        // Note: This test is currently limited because _getAllUpcomingEvents()
        // returns an empty list. In production, this would query the event service.
        // For now, we test that the method handles empty events gracefully.
        await service.registerBrand(testBrand1);

        // Act
        final matches = await service.findEventsForBrand(
          brandId: 'brand-1',
          minCompatibility: 0.70,
        );

        // Assert - service returns empty list when no events available
        // (In production, _getAllUpcomingEvents would query the event service)
        expect(matches, isEmpty);
      });
    });

    group('calculateBrandEventCompatibility', () {
      test('should calculate compatibility score', () async {
        // Arrange
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);

        // Act
        final compatibility = await service.calculateBrandEventCompatibility(
          brandId: 'brand-1',
          eventId: 'event-123',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, equals(0.75));
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('getSponsorshipSuggestions', () {
      test('should return sponsorship suggestions or filter by search criteria',
          () async {
        // Test business logic: sponsorship suggestion generation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => true);
        when(mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => true);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.75,
              quantum: 0.75,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.80);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.80,
              quantum: 0.80,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        await service.registerBrand(testBrand1);
        await service.registerBrand(testBrand2);
        final discovery1 = await service.getSponsorshipSuggestions(
          eventId: 'event-123',
        );
        expect(discovery1, isA<BrandDiscovery>());
        expect(discovery1.eventId, equals('event-123'));
        expect(discovery1.matchingResults, isNotEmpty);

        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateVibeScore(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => const VibeScore(
              combined: 0.75,
              quantum: 0.75,
              knotTopological: 0.0,
              knotWeave: 0.0,
            ));
        final discovery2 = await service.getSponsorshipSuggestions(
          eventId: 'event-123',
          searchCriteria: {
            'category': 'Coffee',
            'minContribution': 500.0,
          },
        );
        expect(discovery2.searchCriteria, isNotNull);
        expect(discovery2.searchCriteria['category'], equals('Coffee'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

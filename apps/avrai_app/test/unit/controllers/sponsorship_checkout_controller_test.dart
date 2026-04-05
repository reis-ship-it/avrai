import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai_runtime_os/controllers/sponsorship_checkout_controller.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/payment/product_tracking_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/payment/product_tracking.dart';
import 'package:avrai_core/models/sponsorship/sponsorship.dart';
import 'package:avrai_core/models/user/unified_user.dart';

import 'sponsorship_checkout_controller_test.mocks.dart';

@GenerateMocks([
  SponsorshipService,
  ExpertiseEventService,
  ProductTrackingService,
])
void main() {
  group('SponsorshipCheckoutController', () {
    late SponsorshipCheckoutController controller;
    late MockSponsorshipService mockSponsorshipService;
    late MockExpertiseEventService mockEventService;
    late MockProductTrackingService mockProductTrackingService;
    final DateTime now = DateTime.now();

    setUp(() {
      mockSponsorshipService = MockSponsorshipService();
      mockEventService = MockExpertiseEventService();
      mockProductTrackingService = MockProductTrackingService();

      controller = SponsorshipCheckoutController(
        sponsorshipService: mockSponsorshipService,
        eventService: mockEventService,
        productTrackingService: mockProductTrackingService,
      );
    });

    final testUser = UnifiedUser(
      id: 'user_123',
      displayName: 'Test User',
      email: 'user@test.com',
      primaryRole: UserRole.follower,
      createdAt: now,
      updatedAt: now,
    );

    final testEvent = ExpertiseEvent(
      id: 'event_123',
      title: 'Sponsored Event',
      description: 'Test sponsored event',
      category: 'Coffee',
      host: UnifiedUser(
        id: 'host_123',
        displayName: 'Host',
        email: 'host@test.com',
        primaryRole: UserRole.follower,
        createdAt: now,
        updatedAt: now,
      ),
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 2)),
      location: 'Test Location',
      eventType: ExpertiseEventType.workshop,
      price: 0.0,
      isPaid: false,
      maxAttendees: 50,
      attendeeCount: 10,
      status: EventStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    final testFinancialSponsorship = Sponsorship(
      id: 'sponsorship_123',
      eventId: 'event_123',
      brandId: 'brand_456',
      type: SponsorshipType.financial,
      contributionAmount: 500.0,
      status: SponsorshipStatus.proposed,
      createdAt: now,
      updatedAt: now,
    );

    final testProductSponsorship = Sponsorship(
      id: 'sponsorship_456',
      eventId: 'event_123',
      brandId: 'brand_456',
      type: SponsorshipType.product,
      productValue: 300.0,
      status: SponsorshipStatus.proposed,
      createdAt: now,
      updatedAt: now,
    );

    final testHybridSponsorship = Sponsorship(
      id: 'sponsorship_789',
      eventId: 'event_123',
      brandId: 'brand_456',
      type: SponsorshipType.hybrid,
      contributionAmount: 300.0,
      productValue: 200.0,
      status: SponsorshipStatus.proposed,
      createdAt: now,
      updatedAt: now,
    );

    group('validate', () {
      test('should return valid result for valid financial sponsorship input',
          () {
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
        );

        final result = controller.validate(input);

        expect(result.isValid, isTrue);
      });

      test('should return valid result for valid product sponsorship input',
          () {
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.product,
          productValue: 300.0,
        );

        final result = controller.validate(input);

        expect(result.isValid, isTrue);
      });

      test('should return valid result for valid hybrid sponsorship input', () {
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.0,
          productValue: 200.0,
        );

        final result = controller.validate(input);

        expect(result.isValid, isTrue);
      });

      test(
          'should return invalid result for financial sponsorship without amount',
          () {
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: null,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['contributionAmount'], isNotNull);
      });

      test('should return invalid result for product sponsorship without value',
          () {
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.product,
          productValue: null,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['productValue'], isNotNull);
      });

      test(
          'should return invalid result for hybrid sponsorship missing both values',
          () {
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.hybrid,
          contributionAmount: null,
          productValue: null,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['contributionAmount'], isNotNull);
        expect(result.fieldErrors['productValue'], isNotNull);
      });

      test(
          'should return invalid result when existing sponsorship event ID does not match',
          () {
        final invalidSponsorship =
            testFinancialSponsorship.copyWith(eventId: 'different_event');
        final input = SponsorshipCheckoutInput(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          existingSponsorship: invalidSponsorship,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['existingSponsorship'], isNotNull);
      });
    });

    group('processSponsorshipCheckout', () {
      test('should successfully process checkout for financial sponsorship',
          () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.createSponsorship(
          eventId: 'event_123',
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          productValue: null,
        )).thenAnswer((_) async => testFinancialSponsorship);

        final result = await controller.processSponsorshipCheckout(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          user: testUser,
        );

        expect(result.success, isTrue);
        expect(result.sponsorship?.id, equals('sponsorship_123'));
        expect(result.sponsorship?.type, equals(SponsorshipType.financial));
        expect(result.sponsorship?.contributionAmount, equals(500.0));

        verify(mockEventService.getEventById('event_123')).called(1);
        verify(mockSponsorshipService.createSponsorship(
          eventId: 'event_123',
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          productValue: null,
        )).called(1);
      });

      test(
          'should successfully process checkout for product sponsorship with product tracking',
          () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.createSponsorship(
          eventId: 'event_123',
          brandId: 'brand_456',
          type: SponsorshipType.product,
          contributionAmount: null,
          productValue: 300.0,
        )).thenAnswer((_) async => testProductSponsorship);
        when(mockProductTrackingService.recordProductContribution(
          sponsorshipId: 'sponsorship_456',
          productName: 'Premium Coffee Beans',
          quantityProvided: 10,
          unitPrice: 30.0,
        )).thenAnswer((_) async => ProductTracking(
              id: 'tracking_456',
              sponsorshipId: 'sponsorship_456',
              productName: 'Premium Coffee Beans',
              quantityProvided: 10,
              quantitySold: 0,
              quantityGivenAway: 0,
              quantityUsedInEvent: 0,
              unitPrice: 30.0,
              totalSales: 0.0,
              platformFee: 0.0,
              revenueDistribution: const {},
              sales: const [],
              createdAt: now,
              updatedAt: now,
            ));

        final result = await controller.processSponsorshipCheckout(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.product,
          productValue: 300.0,
          productName: 'Premium Coffee Beans',
          productQuantity: 10,
        );

        expect(result.success, isTrue);
        expect(result.sponsorship?.id, equals('sponsorship_456'));
        expect(result.sponsorship?.type, equals(SponsorshipType.product));
        expect(result.sponsorship?.productValue, equals(300.0));

        verify(mockProductTrackingService.recordProductContribution(
          sponsorshipId: 'sponsorship_456',
          productName: 'Premium Coffee Beans',
          quantityProvided: 10,
          unitPrice: 30.0,
        )).called(1);
      });

      test('should successfully process checkout for hybrid sponsorship',
          () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.createSponsorship(
          eventId: 'event_123',
          brandId: 'brand_456',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.0,
          productValue: 200.0,
        )).thenAnswer((_) async => testHybridSponsorship);
        when(mockProductTrackingService.recordProductContribution(
          sponsorshipId: 'sponsorship_789',
          productName: 'Product Name',
          quantityProvided: 1,
          unitPrice: 200.0,
        )).thenAnswer((_) async => ProductTracking(
              id: 'tracking_456',
              sponsorshipId: 'sponsorship_456',
              productName: 'Premium Coffee Beans',
              quantityProvided: 10,
              quantitySold: 0,
              quantityGivenAway: 0,
              quantityUsedInEvent: 0,
              unitPrice: 30.0,
              totalSales: 0.0,
              platformFee: 0.0,
              revenueDistribution: const {},
              sales: const [],
              createdAt: now,
              updatedAt: now,
            ));

        final result = await controller.processSponsorshipCheckout(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.0,
          productValue: 200.0,
          productName: 'Product Name',
          user: testUser,
        );

        expect(result.success, isTrue);
        expect(result.sponsorship?.id, equals('sponsorship_789'));
        expect(result.sponsorship?.type, equals(SponsorshipType.hybrid));
        expect(result.sponsorship?.contributionAmount, equals(300.0));
        expect(result.sponsorship?.productValue, equals(200.0));

        verify(mockProductTrackingService.recordProductContribution(
          sponsorshipId: 'sponsorship_789',
          productName: 'Product Name',
          quantityProvided: 1,
          unitPrice: 200.0,
        )).called(1);
      });

      test('should return failure when event not found', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => null);

        final result = await controller.processSponsorshipCheckout(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          user: testUser,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('EVENT_NOT_FOUND'));
        verifyNever(mockSponsorshipService.createSponsorship(
          eventId: anyNamed('eventId'),
          brandId: anyNamed('brandId'),
          type: anyNamed('type'),
          contributionAmount: anyNamed('contributionAmount'),
          productValue: anyNamed('productValue'),
        ));
      });

      test('should return failure when sponsorship creation fails', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.createSponsorship(
          eventId: 'event_123',
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          productValue: null,
        )).thenThrow(Exception('Brand not verified'));

        final result = await controller.processSponsorshipCheckout(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          user: testUser,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('UNEXPECTED_ERROR'));
      });

      test('should return failure for financial sponsorship without user',
          () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.createSponsorship(
          eventId: 'event_123',
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          productValue: null,
        )).thenAnswer((_) async => testFinancialSponsorship);

        final result = await controller.processSponsorshipCheckout(
          event: testEvent,
          brandId: 'brand_456',
          type: SponsorshipType.financial,
          contributionAmount: 500.0,
          user: null, // User is null, but contributionAmount > 0 requires user
        );

        expect(result.success, isFalse);
        // Controller checks for user after creating sponsorship, so it returns USER_REQUIRED
        expect(result.errorCode, equals('USER_REQUIRED'));
      });
    });

    group('rollback', () {
      test('should log rollback when called with success result', () async {
        final result = SponsorshipCheckoutResult.success(
          sponsorship: testFinancialSponsorship,
        );

        await controller.rollback(result);

        // Rollback should not throw - sponsorship rollback would be handled by SponsorshipService
        expect(true, isTrue); // Test passes if no exception is thrown
      });

      test('should not throw when rollback is called with failure result',
          () async {
        final result = SponsorshipCheckoutResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        await controller.rollback(result);
        // Test passes if no exception is thrown
      });
    });
  });
}

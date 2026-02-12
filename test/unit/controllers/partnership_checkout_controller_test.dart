import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/partnership_checkout_controller.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/services/payment/revenue_split_service.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/payment/sales_tax_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/models/payment/payment_status.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';

import 'partnership_checkout_controller_test.mocks.dart';

@GenerateMocks([
  PaymentProcessingController,
  RevenueSplitService,
  PartnershipService,
  ExpertiseEventService,
  SalesTaxService,
])
void main() {
  group('PartnershipCheckoutController', () {
    late PartnershipCheckoutController controller;
    late MockPaymentProcessingController mockPaymentController;
    late MockRevenueSplitService mockRevenueSplitService;
    late MockPartnershipService mockPartnershipService;
    late MockExpertiseEventService mockEventService;
    late MockSalesTaxService mockSalesTaxService;
    final DateTime now = DateTime.now();

    setUp(() {
      mockPaymentController = MockPaymentProcessingController();
      mockRevenueSplitService = MockRevenueSplitService();
      mockPartnershipService = MockPartnershipService();
      mockEventService = MockExpertiseEventService();
      mockSalesTaxService = MockSalesTaxService();

      controller = PartnershipCheckoutController(
        paymentController: mockPaymentController,
        revenueSplitService: mockRevenueSplitService,
        partnershipService: mockPartnershipService,
        eventService: mockEventService,
        salesTaxService: mockSalesTaxService,
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
      title: 'Partnership Event',
      description: 'Test partnership event',
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
      price: 25.0,
      isPaid: true,
      maxAttendees: 50,
      attendeeCount: 10,
      status: EventStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    final testPartnership = EventPartnership(
      id: 'partnership_123',
      eventId: 'event_123',
      userId: 'host_123',
      businessId: 'business_456',
      status: PartnershipStatus.approved,
      vibeCompatibilityScore: 0.85,
      createdAt: now,
      updatedAt: now,
    );

    final testRevenueSplit = RevenueSplit.nWay(
      id: 'split_123',
      eventId: 'event_123',
      partnershipId: 'partnership_123',
      totalAmount: 50.0,
      ticketsSold: 2,
      parties: const [
        SplitParty(
          partyId: 'host_123',
          type: SplitPartyType.user,
          percentage: 50.0,
        ),
        SplitParty(
          partyId: 'business_456',
          type: SplitPartyType.business,
          percentage: 50.0,
        ),
      ],
    );

    final testPayment = Payment(
      id: 'payment_123',
      eventId: 'event_123',
      userId: 'user_123',
      amount: 25.0,
      status: PaymentStatus.completed,
      quantity: 2,
      createdAt: now,
      updatedAt: now,
    );

    const testTaxCalculation = SalesTaxCalculation(
      taxableAmount: 50.0,
      taxRate: 8.5,
      taxAmount: 4.25,
      totalAmount: 54.25,
    );

    group('validate', () {
      test('should return valid result for valid input', () {
        final input = PartnershipCheckoutInput(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: testPartnership,
        );

        final result = controller.validate(input);

        expect(result.isValid, isTrue);
      });

      test('should return invalid result for zero quantity', () {
        final input = PartnershipCheckoutInput(
          event: testEvent,
          buyer: testUser,
          quantity: 0,
          partnership: testPartnership,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['quantity'], isNotNull);
      });

      test('should return invalid result when partnership event ID does not match', () {
        final invalidPartnership = testPartnership.copyWith(eventId: 'different_event');
        final input = PartnershipCheckoutInput(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: invalidPartnership,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['partnership'], isNotNull);
      });
    });

    group('processCheckout', () {
      test('should successfully process checkout for partnership event', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership_123',
          totalAmount: 50.0,
          ticketsSold: 2,
        )).thenAnswer((_) async => testRevenueSplit);
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_123',
          ticketPrice: 25.0,
        )).thenAnswer((_) async => testTaxCalculation);
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.success(
          payment: testPayment,
          taxAmount: 4.25,
          subtotal: 50.0,
          totalAmount: 54.25,
          event: testEvent,
          quantity: 2,
          revenueSplit: testRevenueSplit,
        ));

        final result = await controller.processCheckout(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: null, // Will be looked up
        );

        expect(result.success, isTrue);
        expect(result.totalAmount, equals(58.5)); // 50.0 + (4.25 * 2)
        expect(result.payment?.id, equals('payment_123'));
        expect(result.partnership?.id, equals('partnership_123'));
        expect(result.revenueSplit?.id, equals('split_123'));

        verify(mockEventService.getEventById('event_123')).called(1);
        verify(mockPartnershipService.getPartnershipsForEvent('event_123')).called(1);
        verify(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership_123',
          totalAmount: 50.0,
          ticketsSold: 2,
        )).called(1);
      });

      test('should use provided partnership if available', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_123',
          ticketPrice: 25.0,
        )).thenAnswer((_) async => testTaxCalculation);
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.success(
          payment: testPayment,
          taxAmount: 4.25,
          subtotal: 50.0,
          totalAmount: 54.25,
          event: testEvent,
          quantity: 2,
          revenueSplit: testRevenueSplit,
        ));

        final result = await controller.processCheckout(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: testPartnership,
        );

        expect(result.success, isTrue);
        expect(result.partnership?.id, equals('partnership_123'));
        verifyNever(mockPartnershipService.getPartnershipsForEvent(any));
      });

      test('should return failure when partnership not found', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => []);

        final result = await controller.processCheckout(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: null,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('PARTNERSHIP_NOT_FOUND'));
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should return failure when partnership not active', () async {
        final inactivePartnership = testPartnership.copyWith(
          status: PartnershipStatus.cancelled,
        );
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => [inactivePartnership]);

        final result = await controller.processCheckout(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: null,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('PARTNERSHIP_NOT_ACTIVE'));
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should use existing revenue split from partnership if available', () async {
        final partnershipWithSplit = testPartnership.copyWith(
          revenueSplit: testRevenueSplit,
        );
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => [partnershipWithSplit]);
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_123',
          ticketPrice: 25.0,
        )).thenAnswer((_) async => testTaxCalculation);
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.success(
          payment: testPayment,
          taxAmount: 4.25,
          subtotal: 50.0,
          totalAmount: 54.25,
          event: testEvent,
          quantity: 2,
          revenueSplit: testRevenueSplit,
        ));

        final result = await controller.processCheckout(
          event: testEvent,
          buyer: testUser,
          quantity: 2,
          partnership: null,
        );

        expect(result.success, isTrue);
        // Should not calculate new revenue split if one already exists
        verifyNever(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: anyNamed('partnershipId'),
          totalAmount: anyNamed('totalAmount'),
          ticketsSold: anyNamed('ticketsSold'),
        ));
      });
    });

    group('calculateRevenueSplit', () {
      test('should calculate revenue split for partnership event', () async {
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => [testPartnership]);
        when(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: 'partnership_123',
          totalAmount: 50.0,
          ticketsSold: 2,
        )).thenAnswer((_) async => testRevenueSplit);

        final revenueSplit = await controller.calculateRevenueSplit(
          event: testEvent,
          quantity: 2,
          partnership: null,
        );

        expect(revenueSplit, isNotNull);
        expect(revenueSplit?.id, equals('split_123'));
      });

      test('should return existing revenue split if available', () async {
        final partnershipWithSplit = testPartnership.copyWith(
          revenueSplit: testRevenueSplit,
        );
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => [partnershipWithSplit]);

        final revenueSplit = await controller.calculateRevenueSplit(
          event: testEvent,
          quantity: 2,
          partnership: null,
        );

        expect(revenueSplit?.id, equals('split_123'));
        verifyNever(mockRevenueSplitService.calculateFromPartnership(
          partnershipId: anyNamed('partnershipId'),
          totalAmount: anyNamed('totalAmount'),
          ticketsSold: anyNamed('ticketsSold'),
        ));
      });

      test('should return null when partnership not found', () async {
        when(mockPartnershipService.getPartnershipsForEvent('event_123'))
            .thenAnswer((_) async => []);

        final revenueSplit = await controller.calculateRevenueSplit(
          event: testEvent,
          quantity: 2,
          partnership: null,
        );

        expect(revenueSplit, isNull);
      });
    });

    group('rollback', () {
      test('should log rollback when called with success result', () async {
        final result = PartnershipCheckoutResult.success(
          payment: testPayment,
          subtotal: 50.0,
          taxAmount: 4.25,
          totalAmount: 54.25,
          quantity: 2,
          event: testEvent,
          partnership: testPartnership,
          revenueSplit: testRevenueSplit,
        );

        await controller.rollback(result);

        // Rollback should not throw - payment rollback would be handled by PaymentProcessingController
        expect(true, isTrue); // Test passes if no exception is thrown
      });

      test('should not throw when rollback is called with failure result', () async {
        final result = PartnershipCheckoutResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        await controller.rollback(result);
        // Test passes if no exception is thrown
      });
    });
  });
}


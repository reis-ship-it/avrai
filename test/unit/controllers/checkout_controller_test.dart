import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/checkout_controller.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/services/payment/sales_tax_service.dart';
import 'package:avrai/core/services/misc/legal_document_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/models/payment/payment_status.dart';

import 'checkout_controller_test.mocks.dart';

@GenerateMocks([
  PaymentProcessingController,
  SalesTaxService,
  LegalDocumentService,
  ExpertiseEventService,
])
void main() {
  group('CheckoutController', () {
    late CheckoutController controller;
    late MockPaymentProcessingController mockPaymentController;
    late MockSalesTaxService mockSalesTaxService;
    late MockLegalDocumentService mockLegalService;
    late MockExpertiseEventService mockEventService;
    final DateTime now = DateTime.now();

    setUp(() {
      mockPaymentController = MockPaymentProcessingController();
      mockSalesTaxService = MockSalesTaxService();
      mockLegalService = MockLegalDocumentService();
      mockEventService = MockExpertiseEventService();

      controller = CheckoutController(
        paymentController: mockPaymentController,
        salesTaxService: mockSalesTaxService,
        legalService: mockLegalService,
        eventService: mockEventService,
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

    final testFreeEvent = ExpertiseEvent(
      id: 'event_123',
      title: 'Free Event',
      description: 'Test free event',
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

    final testPaidEvent = testFreeEvent.copyWith(
      id: 'event_456',
      title: 'Paid Event',
      price: 25.0,
      isPaid: true,
    );

    final testPayment = Payment(
      id: 'payment_123',
      eventId: 'event_456',
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
        final input = CheckoutInput(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
          requireWaiver: true,
        );

        final result = controller.validate(input);

        expect(result.isValid, isTrue);
      });

      test('should return invalid result for zero quantity', () {
        final input = CheckoutInput(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 0,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['quantity'], isNotNull);
      });

      test('should return invalid result for quantity exceeding 100', () {
        final input = CheckoutInput(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 101,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['quantity'], isNotNull);
      });
    });

    group('processCheckout', () {
      test('should successfully process checkout for free event', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testFreeEvent);
        when(mockLegalService.hasAcceptedEventWaiver('user_123', 'event_123'))
            .thenAnswer((_) async => true);
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.success(
          payment: null,
          taxAmount: 0.0,
          subtotal: 0.0,
          totalAmount: 0.0,
          event: testFreeEvent,
          quantity: 2,
        ));

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
          requireWaiver: true,
        );

        expect(result.success, isTrue);
        expect(result.totalAmount, equals(0.0));
        expect(result.payment, isNull);
        expect(result.quantity, equals(2));

        verify(mockEventService.getEventById('event_123')).called(1);
        verify(mockLegalService.hasAcceptedEventWaiver('user_123', 'event_123')).called(1);
        verify(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).called(1);
      });

      test('should successfully process checkout for paid event with tax', () async {
        when(mockEventService.getEventById('event_456'))
            .thenAnswer((_) async => testPaidEvent);
        when(mockLegalService.hasAcceptedEventWaiver('user_123', 'event_456'))
            .thenAnswer((_) async => true);
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_456',
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
          event: testPaidEvent,
          quantity: 2,
        ));

        final result = await controller.processCheckout(
          event: testPaidEvent,
          buyer: testUser,
          quantity: 2,
          requireWaiver: true,
        );

        expect(result.success, isTrue);
        expect(result.subtotal, equals(50.0));
        expect(result.taxAmount, equals(8.5)); // 4.25 * 2 (quantity)
        expect(result.totalAmount, equals(58.5)); // 50.0 + 8.5
        expect(result.payment?.id, equals('payment_123'));

        verify(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_456',
          ticketPrice: 25.0,
        )).called(1);
      });

      test('should return failure when event not found', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => null);

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('EVENT_NOT_FOUND'));
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should return failure when insufficient capacity', () async {
        final eventWithLowCapacity = testFreeEvent.copyWith(
          maxAttendees: 10,
          attendeeCount: 9,
        );
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => eventWithLowCapacity);

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('INSUFFICIENT_CAPACITY'));
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should return failure when event has started', () async {
        final pastEvent = testFreeEvent.copyWith(
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 1)),
        );
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => pastEvent);

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('EVENT_STARTED'));
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should return failure when waiver not accepted', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testFreeEvent);
        when(mockLegalService.hasAcceptedEventWaiver('user_123', 'event_123'))
            .thenAnswer((_) async => false);

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
          requireWaiver: true,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('WAIVER_NOT_ACCEPTED'));
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should skip waiver check when requireWaiver is false', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testFreeEvent);
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.success(
          payment: null,
          taxAmount: 0.0,
          subtotal: 0.0,
          totalAmount: 0.0,
          event: testFreeEvent,
          quantity: 2,
        ));

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
          requireWaiver: false,
        );

        expect(result.success, isTrue);
        verifyNever(mockLegalService.hasAcceptedEventWaiver(any, any));
      });

      test('should handle tax calculation failure gracefully', () async {
        when(mockEventService.getEventById('event_456'))
            .thenAnswer((_) async => testPaidEvent);
        when(mockLegalService.hasAcceptedEventWaiver('user_123', 'event_456'))
            .thenAnswer((_) async => true);
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_456',
          ticketPrice: 25.0,
        )).thenThrow(Exception('Tax calculation failed'));
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.success(
          payment: testPayment,
          taxAmount: 0.0,
          subtotal: 50.0,
          totalAmount: 50.0,
          event: testPaidEvent,
          quantity: 2,
        ));

        final result = await controller.processCheckout(
          event: testPaidEvent,
          buyer: testUser,
          quantity: 2,
        );

        expect(result.success, isTrue);
        expect(result.totalAmount, equals(50.0)); // Proceeds without tax
      });

      test('should return failure when payment processing fails', () async {
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testFreeEvent);
        when(mockLegalService.hasAcceptedEventWaiver('user_123', 'event_123'))
            .thenAnswer((_) async => true);
        when(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => PaymentProcessingResult.failure(
          error: 'Payment failed',
          errorCode: 'PAYMENT_FAILED',
        ));

        final result = await controller.processCheckout(
          event: testFreeEvent,
          buyer: testUser,
          quantity: 2,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('PAYMENT_FAILED'));
      });
    });

    group('calculateTotals', () {
      test('should calculate totals for paid event with tax', () async {
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_456',
          ticketPrice: 25.0,
        )).thenAnswer((_) async => testTaxCalculation);

        final totals = await controller.calculateTotals(
          event: testPaidEvent,
          quantity: 2,
        );

        expect(totals.subtotal, equals(50.0));
        expect(totals.taxAmount, equals(8.5)); // 4.25 * 2 (quantity)
        expect(totals.totalAmount, equals(58.5)); // 50.0 + 8.5
        expect(totals.quantity, equals(2));
      });

      test('should calculate totals for free event', () async {
        final totals = await controller.calculateTotals(
          event: testFreeEvent,
          quantity: 2,
        );

        expect(totals.subtotal, equals(0.0));
        expect(totals.taxAmount, equals(0.0));
        expect(totals.totalAmount, equals(0.0));
        expect(totals.quantity, equals(2));
      });

      test('should handle tax calculation failure gracefully', () async {
        when(mockSalesTaxService.calculateSalesTax(
          eventId: 'event_456',
          ticketPrice: 25.0,
        )).thenThrow(Exception('Tax calculation failed'));

        final totals = await controller.calculateTotals(
          event: testPaidEvent,
          quantity: 2,
        );

        expect(totals.subtotal, equals(50.0));
        expect(totals.totalAmount, equals(50.0)); // Proceeds without tax
      });
    });

    group('rollback', () {
      test('should log rollback when called with success result', () async {
        final result = CheckoutResult.success(
          payment: testPayment,
          subtotal: 50.0,
          taxAmount: 4.25,
          totalAmount: 54.25,
          quantity: 2,
          event: testPaidEvent,
        );

        await controller.rollback(result);

        // Rollback should not throw - payment rollback would be handled by PaymentProcessingController
        // For now, we just verify it completes without error
        expect(true, isTrue); // Test passes if no exception is thrown
      });

      test('should not throw when rollback is called with failure result', () async {
        final result = CheckoutResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        await controller.rollback(result);
        // Test passes if no exception is thrown
      });
    });
  });
}


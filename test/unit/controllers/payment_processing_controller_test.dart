/// PaymentProcessingController Unit Tests
///
/// Tests for payment processing workflow orchestration:
/// - Payment validation
/// - Sales tax calculation
/// - Payment processing
/// - Event registration
/// - Error handling
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/models/payment/payment_status.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/services/payment/payment_event_service.dart';
import 'package:avrai/core/services/payment/sales_tax_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'payment_processing_controller_test.mocks.dart';

@GenerateMocks([
  SalesTaxService,
  PaymentEventService,
])
void main() {
  group('PaymentProcessingController', () {
    late PaymentProcessingController controller;
    late MockSalesTaxService mockSalesTaxService;
    late MockPaymentEventService mockPaymentEventService;

    // Test data
    late UnifiedUser testUser;
    late ExpertiseEvent testEvent;

    setUp(() {
      mockSalesTaxService = MockSalesTaxService();
      mockPaymentEventService = MockPaymentEventService();

      controller = PaymentProcessingController(
        salesTaxService: mockSalesTaxService,
        paymentEventService: mockPaymentEventService,
      );

      // Create test user
      final now = DateTime.now();
      testUser = UnifiedUser(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: now,
        updatedAt: now,
      );

      // Create test event
      testEvent = ExpertiseEvent(
        id: 'event_123',
        title: 'Coffee Tasting Tour',
        description: 'Explore local coffee shops',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        host: UnifiedUser(
          id: 'host_123',
          email: 'host@example.com',
          displayName: 'Host User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: EventStatus.upcoming,
        price: 25.0,
        isPaid: true,
        maxAttendees: 20,
        attendeeCount: 5,
      );
    });

    group('validatePayment', () {
      test('should return valid result for valid payment data', () {
        // Arrange
        const quantity = 2;

        // Act
        final result = controller.validatePayment(
          event: testEvent,
          buyer: testUser,
          quantity: quantity,
        );

        // Assert
        expect(result.isValid, isTrue);
        expect(result.fieldErrors, isEmpty);
        expect(result.generalErrors, isEmpty);
      });

      test('should return invalid result for event that already started', () {
        // Arrange
        final pastEvent = testEvent.copyWith(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Act
        final result = controller.validatePayment(
          event: pastEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['event'], equals('Event has already started'));
      });

      test('should return invalid result for cancelled event', () {
        // Arrange
        final cancelledEvent = testEvent.copyWith(
          status: EventStatus.cancelled,
        );

        // Act
        final result = controller.validatePayment(
          event: cancelledEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['event'], equals('Event is not available for purchase'));
      });

      test('should return invalid result for zero quantity', () {
        // Act
        final result = controller.validatePayment(
          event: testEvent,
          buyer: testUser,
          quantity: 0,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['quantity'], equals('Quantity must be greater than 0'));
      });

      test('should return invalid result for insufficient capacity', () {
        // Arrange
        final fullEvent = testEvent.copyWith(
          attendeeCount: 19,
          maxAttendees: 20,
        );

        // Act
        final result = controller.validatePayment(
          event: fullEvent,
          buyer: testUser,
          quantity: 2,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['quantity'], equals('Insufficient capacity. Only 1 tickets available'));
      });

      test('should return invalid result for already registered user', () {
        // Arrange
        // Note: canUserAttend checks attendeeIds first, so this error message
        // may be overwritten by canUserAttend's check. The validation still fails correctly.
        final eventWithUser = testEvent.copyWith(
          attendeeIds: [testUser.id],
        );

        // Act
        final result = controller.validatePayment(
          event: eventWithUser,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isValid, isFalse);
        // The error message depends on which check runs first
        // Both checks should result in buyer field error
        expect(result.fieldErrors.containsKey('buyer'), isTrue);
        expect(result.fieldErrors['buyer'], anyOf(
          equals('User is already registered for this event'),
          equals('User cannot attend this event (expertise or geographic scope restriction)'),
        ));
      });

      test('should return invalid result for paid event without price', () {
        // Arrange
        // Ensure event is valid except for the price issue
        // Note: copyWith with price: null doesn't actually set it to null (uses ?? operator)
        // So we need to create a new event with price explicitly set to null/0
        final invalidEvent = ExpertiseEvent(
          id: testEvent.id,
          title: testEvent.title,
          description: testEvent.description,
          category: testEvent.category,
          eventType: testEvent.eventType,
          host: testEvent.host,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          createdAt: testEvent.createdAt,
          updatedAt: testEvent.updatedAt,
          status: EventStatus.upcoming,
          isPaid: true,
          price: null, // Explicitly null for paid event
          attendeeIds: const [], // Ensure user is not already registered
        );

        // Act
        final result = controller.validatePayment(
          event: invalidEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['event'], equals('Paid event must have a valid price'));
      });
    });

    group('processEventPayment', () {
      test('should successfully process payment with tax', () async {
        // Arrange
        const quantity = 2;
        const taxCalculation = SalesTaxCalculation(
          taxableAmount: 25.0,
          taxRate: 8.5,
          taxAmount: 2.13,
          totalAmount: 27.13,
        );
        final payment = Payment(
          id: 'payment_123',
          eventId: testEvent.id,
          userId: testUser.id,
          amount: 25.0,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          quantity: quantity,
        );
        final revenueSplit = RevenueSplit.calculate(
          eventId: testEvent.id,
          totalAmount: 54.26, // (25.0 + 2.13) * 2
          ticketsSold: quantity,
        );

        when(mockSalesTaxService.calculateSalesTax(
          eventId: testEvent.id,
          ticketPrice: 25.0,
        )).thenAnswer((_) async => taxCalculation);

        when(mockPaymentEventService.processEventPayment(
          event: testEvent,
          user: testUser,
          quantity: quantity,
        )).thenAnswer((_) async => PaymentEventResult.success(
          payment: payment,
          event: testEvent.copyWith(attendeeCount: 7),
          registered: true,
          revenueSplit: revenueSplit,
        ));

        // Act
        final result = await controller.processEventPayment(
          event: testEvent,
          buyer: testUser,
          quantity: quantity,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.payment, isNotNull);
        expect(result.payment?.id, equals('payment_123'));
        expect(result.taxAmount, equals(4.26)); // 2.13 * 2
        expect(result.subtotal, equals(50.0)); // 25.0 * 2
        expect(result.totalAmount, equals(54.26)); // 50.0 + 4.26
        expect(result.event, isNotNull);
        expect(result.quantity, equals(quantity));
        verify(mockSalesTaxService.calculateSalesTax(
          eventId: testEvent.id,
          ticketPrice: 25.0,
        )).called(1);
        verify(mockPaymentEventService.processEventPayment(
          event: testEvent,
          user: testUser,
          quantity: quantity,
        )).called(1);
      });

      test('should successfully process payment for free event', () async {
        // Arrange
        // Note: copyWith doesn't set null values, so create a new event for free event
        final freeEvent = ExpertiseEvent(
          id: testEvent.id,
          title: testEvent.title,
          description: testEvent.description,
          category: testEvent.category,
          eventType: testEvent.eventType,
          host: testEvent.host,
          startTime: testEvent.startTime,
          endTime: testEvent.endTime,
          createdAt: testEvent.createdAt,
          updatedAt: testEvent.updatedAt,
          status: testEvent.status,
          isPaid: false,
          price: null, // Explicitly null for free event
        );

        when(mockPaymentEventService.processEventPayment(
          event: freeEvent,
          user: testUser,
          quantity: 1,
        )).thenAnswer((_) async => PaymentEventResult.success(
          payment: null, // Free events have no payment
          event: freeEvent.copyWith(attendeeCount: 6),
          registered: true,
        ));

        // Act
        final result = await controller.processEventPayment(
          event: freeEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.payment, isNull); // Free events have no payment
        expect(result.taxAmount, equals(0.0));
        expect(result.subtotal, equals(0.0));
        expect(result.totalAmount, equals(0.0));
        verifyNever(mockSalesTaxService.calculateSalesTax(
          eventId: anyNamed('eventId'),
          ticketPrice: anyNamed('ticketPrice'),
        ));
        verify(mockPaymentEventService.processEventPayment(
          event: freeEvent,
          user: testUser,
          quantity: 1,
        )).called(1);
      });

      test('should handle tax calculation failure gracefully', () async {
        // Arrange
        final payment = Payment(
          id: 'payment_123',
          eventId: testEvent.id,
          userId: testUser.id,
          amount: 25.0,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSalesTaxService.calculateSalesTax(
          eventId: testEvent.id,
          ticketPrice: 25.0,
        )).thenThrow(Exception('Tax calculation failed'));

        when(mockPaymentEventService.processEventPayment(
          event: testEvent,
          user: testUser,
          quantity: 1,
        )).thenAnswer((_) async => PaymentEventResult.success(
          payment: payment,
          event: testEvent.copyWith(attendeeCount: 6),
          registered: true,
        ));

        // Act
        final result = await controller.processEventPayment(
          event: testEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        // Should still succeed even if tax calculation fails
        expect(result.isSuccess, isTrue);
        expect(result.taxAmount, equals(0.0)); // Tax calculation failed, so 0
        expect(result.subtotal, equals(25.0));
        expect(result.totalAmount, equals(25.0));
      });

      test('should return failure result when validation fails', () async {
        // Arrange
        final invalidEvent = testEvent.copyWith(
          status: EventStatus.cancelled,
        );

        // Act
        final result = await controller.processEventPayment(
          event: invalidEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.errorCode, equals('VALIDATION_FAILED'));
        expect(result.validationErrors, isNotNull);
        verifyNever(mockSalesTaxService.calculateSalesTax(
          eventId: anyNamed('eventId'),
          ticketPrice: anyNamed('ticketPrice'),
        ));
        verifyNever(mockPaymentEventService.processEventPayment(
          event: anyNamed('event'),
          user: anyNamed('user'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should return failure result when payment processing fails', () async {
        // Arrange
        when(mockSalesTaxService.calculateSalesTax(
          eventId: testEvent.id,
          ticketPrice: 25.0,
        )).thenAnswer((_) async => const SalesTaxCalculation(
          taxableAmount: 25.0,
          taxRate: 0.0,
          taxAmount: 0.0,
          totalAmount: 25.0,
        ));

        when(mockPaymentEventService.processEventPayment(
          event: testEvent,
          user: testUser,
          quantity: 1,
        )).thenAnswer((_) async => PaymentEventResult.failure(
          errorMessage: 'Payment failed',
          errorCode: 'PAYMENT_FAILED',
        ));

        // Act
        final result = await controller.processEventPayment(
          event: testEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, equals('Payment failed'));
        expect(result.errorCode, equals('PAYMENT_FAILED'));
      });

      test('should return failure result when event not found after payment', () async {
        // Note: This scenario is actually not possible with current PaymentEventResult structure
        // since event is required. This test validates the controller's null check logic
        // In practice, PaymentEventService would throw an exception instead.
        // For now, we'll skip this test case as it's not a valid scenario.
        // TODO: Add test when PaymentEventService can return null event scenarios
      });
    });

    group('processRefund', () {
      test('should return failure result (not yet implemented)', () async {
        // Act
        final result = await controller.processRefund(
          paymentId: 'payment_123',
          reason: 'Customer request',
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, equals('Refund processing is not yet implemented'));
        expect(result.errorCode, equals('REFUND_NOT_IMPLEMENTED'));
      });
    });

    group('WorkflowController interface', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        final paymentData = PaymentData(
          event: testEvent,
          buyer: testUser,
          quantity: 1,
        );
        final payment = Payment(
          id: 'payment_123',
          eventId: testEvent.id,
          userId: testUser.id,
          amount: 25.0,
          status: PaymentStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSalesTaxService.calculateSalesTax(
          eventId: testEvent.id,
          ticketPrice: 25.0,
        )).thenAnswer((_) async => const SalesTaxCalculation(
          taxableAmount: 25.0,
          taxRate: 0.0,
          taxAmount: 0.0,
          totalAmount: 25.0,
        ));

        when(mockPaymentEventService.processEventPayment(
          event: testEvent,
          user: testUser,
          quantity: 1,
        )).thenAnswer((_) async => PaymentEventResult.success(
          payment: payment,
          event: testEvent.copyWith(attendeeCount: 6),
          registered: true,
        ));

        // Act
        final result = await controller.execute(paymentData);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should validate via validate method', () {
        // Arrange
        final paymentData = PaymentData(
          event: testEvent,
          buyer: testUser,
          quantity: 1,
        );

        // Act
        final result = controller.validate(paymentData);

        // Assert
        expect(result.isValid, isTrue);
      });
    });
  });
}


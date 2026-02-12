import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/event_attendance_controller.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/matching/preferences_profile_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/models/payment/payment_status.dart';

import 'event_attendance_controller_test.mocks.dart';

@GenerateMocks([
  ExpertiseEventService,
  PaymentProcessingController,
  PreferencesProfileService,
  AgentIdService,
])
void main() {
  group('EventAttendanceController', () {
    late EventAttendanceController controller;
    late MockExpertiseEventService mockEventService;
    late MockPaymentProcessingController mockPaymentController;
    late MockPreferencesProfileService mockPreferencesService;
    late MockAgentIdService mockAgentIdService;

    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    final DateTime now = DateTime.now();
    final DateTime futureTime = now.add(const Duration(days: 7));

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPaymentController = MockPaymentProcessingController();
      mockPreferencesService = MockPreferencesProfileService();
      mockAgentIdService = MockAgentIdService();

      controller = EventAttendanceController(
        eventService: mockEventService,
        paymentController: mockPaymentController,
        preferencesService: mockPreferencesService,
        agentIdService: mockAgentIdService,
      );

      testEvent = ExpertiseEvent(
        id: 'event_123',
        title: 'Test Event',
        description: 'Test Description',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        host: UnifiedUser(
          id: 'host_123',
          email: 'host@test.com',
          displayName: 'Host User',
          createdAt: now,
          updatedAt: now,
        ),
        startTime: futureTime,
        endTime: futureTime.add(const Duration(hours: 2)),
        location: 'Test Location',
        maxAttendees: 10,
        price: 0.0,
        isPaid: false,
        status: EventStatus.upcoming,
        createdAt: now,
        updatedAt: now,
        attendeeIds: const [],
        attendeeCount: 0,
      );

      testUser = UnifiedUser(
        id: 'user_123',
        email: 'user@test.com',
        displayName: 'Test User',
        createdAt: now,
        updatedAt: now,
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        final data = AttendanceData(
          event: testEvent,
          attendee: testUser,
          quantity: 1,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty event ID', () {
        // Arrange
        final invalidEvent = testEvent.copyWith(id: '');
        final data = AttendanceData(
          event: invalidEvent,
          attendee: testUser,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['event'], isNotNull);
      });

      test('should return invalid result for zero quantity', () {
        // Arrange
        final data = AttendanceData(
          event: testEvent,
          attendee: testUser,
          quantity: 0,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['quantity'], isNotNull);
      });
    });

    group('registerForEvent', () {
      test('should successfully register for free event', () async {
        // Arrange
        final updatedEvent = testEvent.copyWith(
          attendeeIds: [testUser.id],
          attendeeCount: 1,
          updatedAt: now,
        );

        when(mockEventService.registerForEvent(testEvent, testUser))
            .thenAnswer((_) async => Future.value());
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => updatedEvent);
        when(mockAgentIdService.getUserAgentId('user_123'))
            .thenAnswer((_) async => 'agent_user_123');
        when(mockPreferencesService.getPreferencesProfile('agent_user_123'))
            .thenAnswer((_) async => null); // No preferences yet

        // Act
        final result = await controller.registerForEvent(
          event: testEvent,
          attendee: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.event, isNotNull);
        expect(result.event?.attendeeIds, contains(testUser.id));
        expect(result.payment, isNull); // Free event

        verify(mockEventService.registerForEvent(testEvent, testUser)).called(1);
        verify(mockEventService.getEventById('event_123')).called(1);
        verifyNever(mockPaymentController.processEventPayment(
          event: anyNamed('event'),
          buyer: anyNamed('buyer'),
          quantity: anyNamed('quantity'),
        ));
      });

      test('should successfully register for paid event via PaymentProcessingController', () async {
        // Arrange
        final paidEvent = testEvent.copyWith(
          price: 50.0,
          isPaid: true,
        );
        final updatedEvent = paidEvent.copyWith(
          attendeeIds: [testUser.id],
          attendeeCount: 1,
        );
        final testPayment = Payment(
          id: 'payment_123',
          userId: testUser.id,
          eventId: paidEvent.id,
          amount: 50.0,
          status: PaymentStatus.completed,
          createdAt: now,
          updatedAt: now,
        );

        when(mockPaymentController.processEventPayment(
          event: paidEvent,
          buyer: testUser,
          quantity: 1,
        )).thenAnswer((_) async => PaymentProcessingResult.success(
              payment: testPayment,
              event: updatedEvent,
              quantity: 1,
              subtotal: 50.0,
              taxAmount: 0.0,
              totalAmount: 50.0,
              paymentIntent: null,
              revenueSplit: null,
              taxCalculation: null,
            ));
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => updatedEvent);

        // Act
        final result = await controller.registerForEvent(
          event: paidEvent,
          attendee: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.event, isNotNull);
        expect(result.payment, equals(testPayment));

        verify(mockPaymentController.processEventPayment(
          event: paidEvent,
          buyer: testUser,
          quantity: 1,
        )).called(1);
        verify(mockEventService.getEventById('event_123')).called(1);
        verifyNever(mockEventService.registerForEvent(any, any));
      });

      test('should return failure for event not available', () async {
        // Arrange
        final cancelledEvent = testEvent.copyWith(status: EventStatus.cancelled);

        // Act
        final result = await controller.registerForEvent(
          event: cancelledEvent,
          attendee: testUser,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('EVENT_NOT_AVAILABLE'));
        verifyNever(mockEventService.registerForEvent(any, any));
      });

      test('should return failure for event that already started', () async {
        // Arrange
        final pastEvent = testEvent.copyWith(
          startTime: now.subtract(const Duration(hours: 1)),
        );

        // Act
        final result = await controller.registerForEvent(
          event: pastEvent,
          attendee: testUser,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('EVENT_STARTED'));
      });

      test('should return failure for insufficient capacity', () async {
        // Arrange
        final fullEvent = testEvent.copyWith(
          attendeeCount: 10,
          maxAttendees: 10,
        );

        // Act
        final result = await controller.registerForEvent(
          event: fullEvent,
          attendee: testUser,
          quantity: 1,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('INSUFFICIENT_CAPACITY'));
      });

      test('should return failure for already registered user', () async {
        // Arrange
        final registeredEvent = testEvent.copyWith(
          attendeeIds: [testUser.id],
          attendeeCount: 1,
        );

        // Act
        final result = await controller.registerForEvent(
          event: registeredEvent,
          attendee: testUser,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('ALREADY_REGISTERED'));
      });

      test('should return failure when payment processing fails', () async {
        // Arrange
        final paidEvent = testEvent.copyWith(
          price: 50.0,
          isPaid: true,
        );

        when(mockPaymentController.processEventPayment(
          event: paidEvent,
          buyer: testUser,
          quantity: 1,
        )).thenAnswer((_) async => PaymentProcessingResult.failure(
              error: 'Payment failed',
              errorCode: 'PAYMENT_FAILED',
            ));

        // Act
        final result = await controller.registerForEvent(
          event: paidEvent,
          attendee: testUser,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('PAYMENT_FAILED'));
        verify(mockPaymentController.processEventPayment(
          event: paidEvent,
          buyer: testUser,
          quantity: 1,
        )).called(1);
      });

      test('should register multiple tickets for free event', () async {
        // Arrange
        final updatedEvent = testEvent.copyWith(
          attendeeIds: List.generate(3, (i) => testUser.id),
          attendeeCount: 3,
        );

        when(mockEventService.registerForEvent(testEvent, testUser))
            .thenAnswer((_) async => Future.value());
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => updatedEvent);

        // Act
        final result = await controller.registerForEvent(
          event: testEvent,
          attendee: testUser,
          quantity: 3,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.quantity, equals(3));
        verify(mockEventService.registerForEvent(testEvent, testUser)).called(3);
      });
    });

    group('execute (WorkflowController interface)', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        final data = AttendanceData(
          event: testEvent,
          attendee: testUser,
        );
        final updatedEvent = testEvent.copyWith(
          attendeeIds: [testUser.id],
          attendeeCount: 1,
        );

        when(mockEventService.registerForEvent(testEvent, testUser))
            .thenAnswer((_) async => Future.value());
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => updatedEvent);

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isTrue);
        expect(result.event, isNotNull);
      });
    });

    group('rollback', () {
      test('should not throw when rollback is called', () async {
        // Arrange
        final result = AttendanceResult.success(
          event: testEvent,
          payment: null,
        );

        // Act & Assert
        expect(() => controller.rollback(result), returnsNormally);
        await controller.rollback(result);
      });
    });
  });
}


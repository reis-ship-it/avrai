import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai_runtime_os/controllers/event_cancellation_controller.dart';
import 'package:avrai_runtime_os/services/events/cancellation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_service.dart';
import 'package:avrai_core/models/misc/cancellation.dart';
import 'package:avrai_core/models/misc/cancellation_initiator.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/payment/refund_status.dart';
import 'package:avrai_core/models/payment/payment.dart';
import 'package:avrai_core/models/payment/payment_status.dart';
import 'package:avrai_core/models/user/unified_user.dart';

import 'event_cancellation_controller_test.mocks.dart';

@GenerateMocks([
  CancellationService,
  ExpertiseEventService,
  PaymentService,
])
void main() {
  group('EventCancellationController', () {
    late EventCancellationController controller;
    late MockCancellationService mockCancellationService;
    late MockExpertiseEventService mockEventService;
    late MockPaymentService mockPaymentService;
    final DateTime now = DateTime.now();

    setUp(() {
      mockCancellationService = MockCancellationService();
      mockEventService = MockExpertiseEventService();
      mockPaymentService = MockPaymentService();

      controller = EventCancellationController(
        cancellationService: mockCancellationService,
        eventService: mockEventService,
        paymentService: mockPaymentService,
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        final input = CancellationInput(
          eventId: 'event_123',
          userId: 'user_456',
          reason: 'Unable to attend',
          isHost: false,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty eventId', () {
        // Arrange
        final input = CancellationInput(
          eventId: '',
          userId: 'user_456',
          reason: 'Unable to attend',
          isHost: false,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['eventId'], isNotNull);
      });

      test('should return invalid result for empty userId', () {
        // Arrange
        final input = CancellationInput(
          eventId: 'event_123',
          userId: '',
          reason: 'Unable to attend',
          isHost: false,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['userId'], isNotNull);
      });

      test('should return invalid result for empty reason', () {
        // Arrange
        final input = CancellationInput(
          eventId: 'event_123',
          userId: 'user_456',
          reason: '',
          isHost: false,
        );

        // Act
        final result = controller.validate(input);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['reason'], isNotNull);
      });
    });

    group('cancelEvent', () {
      final testHost = UnifiedUser(
        id: 'host_123',
        email: 'host@test.com',
        displayName: 'Test Host',
        createdAt: now,
        updatedAt: now,
      );

      final testEvent = ExpertiseEvent(
        id: 'event_123',
        title: 'Test Event',
        description: 'A test event',
        host: testHost,
        category: 'Test',
        eventType: ExpertiseEventType.workshop,
        startTime: now.add(const Duration(days: 2)),
        endTime: now.add(const Duration(days: 2, hours: 2)),
        status: EventStatus.upcoming,
        maxAttendees: 10,
        createdAt: now,
        updatedAt: now,
      );

      test('should successfully cancel attendee ticket', () async {
        // Arrange
        final cancellation = Cancellation(
          id: 'cancellation_123',
          eventId: 'event_123',
          userId: 'user_456',
          initiator: CancellationInitiator.attendee,
          reason: 'Unable to attend',
          refundStatus: RefundStatus.completed,
          refundAmount: 45.0,
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockCancellationService.attendeeCancelTicket(
          eventId: 'event_123',
          attendeeId: 'user_456',
        )).thenAnswer((_) async => cancellation);

        // Act
        final result = await controller.cancelEvent(
          eventId: 'event_123',
          userId: 'user_456',
          reason: 'Unable to attend',
          isHost: false,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.cancellation, isNotNull);
        expect(result.refundAmount, equals(45.0));
        expect(result.refundStatus, equals(RefundStatus.completed));

        verify(mockEventService.getEventById('event_123')).called(1);
        verify(mockCancellationService.attendeeCancelTicket(
          eventId: 'event_123',
          attendeeId: 'user_456',
        )).called(1);
        verifyNever(mockEventService.updateEventStatus(any, any));
      });

      test('should successfully cancel host event and update status', () async {
        // Arrange
        final cancellation = Cancellation(
          id: 'cancellation_123',
          eventId: 'event_123',
          userId: 'host_123',
          initiator: CancellationInitiator.host,
          reason: 'Unexpected circumstances',
          refundStatus: RefundStatus.completed,
          refundAmount: 100.0,
          isFullEventCancellation: true,
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockCancellationService.hostCancelEvent(
          eventId: 'event_123',
          hostId: 'host_123',
          reason: 'Unexpected circumstances',
        )).thenAnswer((_) async => cancellation);
        when(mockEventService.updateEventStatus(
                testEvent, EventStatus.cancelled))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await controller.cancelEvent(
          eventId: 'event_123',
          userId: 'host_123',
          reason: 'Unexpected circumstances',
          isHost: true,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.cancellation, isNotNull);
        expect(result.cancellation?.isFullEventCancellation, isTrue);
        expect(result.refundAmount, equals(100.0));

        verify(mockEventService.getEventById('event_123')).called(1);
        verify(mockCancellationService.hostCancelEvent(
          eventId: 'event_123',
          hostId: 'host_123',
          reason: 'Unexpected circumstances',
        )).called(1);
        verify(mockEventService.updateEventStatus(
                testEvent, EventStatus.cancelled))
            .called(1);
      });

      test('should return failure when event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => null);

        // Act
        final result = await controller.cancelEvent(
          eventId: 'event_123',
          userId: 'user_456',
          reason: 'Unable to attend',
          isHost: false,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('EVENT_NOT_FOUND'));
        verifyNever(mockCancellationService.attendeeCancelTicket(
          eventId: anyNamed('eventId'),
          attendeeId: anyNamed('attendeeId'),
        ));
      });

      test('should return failure when host does not own event', () async {
        // Arrange
        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final result = await controller.cancelEvent(
          eventId: 'event_123',
          userId: 'different_host',
          reason: 'Unexpected circumstances',
          isHost: true,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorCode, equals('PERMISSION_DENIED'));
        verifyNever(mockCancellationService.hostCancelEvent(
          eventId: anyNamed('eventId'),
          hostId: anyNamed('hostId'),
          reason: anyNamed('reason'),
        ));
      });
    });

    group('calculateRefund', () {
      final testEvent = ExpertiseEvent(
        id: 'event_123',
        title: 'Test Event',
        description: 'A test event',
        host: UnifiedUser(
          id: 'host_123',
          email: 'host@test.com',
          displayName: 'Test Host',
          createdAt: now,
          updatedAt: now,
        ),
        category: 'Test',
        eventType: ExpertiseEventType.workshop,
        startTime: now.add(const Duration(hours: 72)), // 3 days away
        endTime: now.add(const Duration(hours: 75)),
        status: EventStatus.upcoming,
        maxAttendees: 10,
        createdAt: now,
        updatedAt: now,
      );

      test('should calculate full refund for cancellation >48 hours before',
          () async {
        // Arrange
        final payment = Payment(
          id: 'payment_123',
          userId: 'user_456',
          eventId: 'event_123',
          amount: 50.0,
          status: PaymentStatus.completed,
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser(
                'event_123', 'user_456'))
            .thenReturn(payment);

        // Act
        final calculation = await controller.calculateRefund(
          eventId: 'event_123',
          userId: 'user_456',
        );

        // Assert
        expect(calculation.refundAmount, greaterThan(0));
        expect(calculation.isFullRefund, isTrue);
        expect(calculation.hoursUntilEvent, greaterThan(48));
      });

      test('should calculate 50% refund for cancellation 24-48 hours before',
          () async {
        // Arrange
        final event24HoursAway = testEvent.copyWith(
          startTime: now.add(const Duration(hours: 36)), // 36 hours away
        );
        final payment = Payment(
          id: 'payment_123',
          userId: 'user_456',
          eventId: 'event_123',
          amount: 50.0,
          status: PaymentStatus.completed,
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => event24HoursAway);
        when(mockPaymentService.getPaymentForEventAndUser(
                'event_123', 'user_456'))
            .thenAnswer((_) => payment);

        // Act
        final calculation = await controller.calculateRefund(
          eventId: 'event_123',
          userId: 'user_456',
        );

        // Assert
        expect(calculation.refundAmount, greaterThan(0));
        expect(calculation.isFullRefund, isFalse);
        expect(calculation.hoursUntilEvent, greaterThan(24));
        expect(calculation.hoursUntilEvent, lessThanOrEqualTo(48));
      });

      test('should calculate no refund for cancellation <24 hours before',
          () async {
        // Arrange
        final event12HoursAway = testEvent.copyWith(
          startTime: now.add(const Duration(hours: 12)), // 12 hours away
        );
        final payment = Payment(
          id: 'payment_123',
          userId: 'user_456',
          eventId: 'event_123',
          amount: 50.0,
          status: PaymentStatus.completed,
          createdAt: now,
          updatedAt: now,
        );

        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => event12HoursAway);
        when(mockPaymentService.getPaymentForEventAndUser(
                'event_123', 'user_456'))
            .thenAnswer((_) => payment);

        // Act
        final calculation = await controller.calculateRefund(
          eventId: 'event_123',
          userId: 'user_456',
        );

        // Assert
        expect(calculation.refundAmount, equals(0.0));
        expect(calculation.isFullRefund, isFalse);
        expect(calculation.hoursUntilEvent, lessThanOrEqualTo(24));
      });
    });

    group('rollback', () {
      test('should restore event status on rollback for full cancellation',
          () async {
        // Arrange
        final testEvent = ExpertiseEvent(
          id: 'event_123',
          title: 'Test Event',
          description: 'A test event',
          host: UnifiedUser(
            id: 'host_123',
            email: 'host@test.com',
            displayName: 'Test Host',
            createdAt: now,
            updatedAt: now,
          ),
          category: 'Test',
          eventType: ExpertiseEventType.workshop,
          startTime: now.add(const Duration(days: 2)),
          endTime: now.add(const Duration(days: 2, hours: 2)),
          status: EventStatus.cancelled,
          maxAttendees: 10,
          createdAt: now,
          updatedAt: now,
        );

        final cancellation = Cancellation(
          id: 'cancellation_123',
          eventId: 'event_123',
          userId: 'host_123',
          initiator: CancellationInitiator.host,
          reason: 'Unexpected circumstances',
          refundStatus: RefundStatus.completed,
          isFullEventCancellation: true,
          createdAt: now,
          updatedAt: now,
        );

        final result = CancellationResult.success(
          cancellation: cancellation,
          refundAmount: 100.0,
          refundStatus: RefundStatus.completed,
        );

        when(mockEventService.getEventById('event_123'))
            .thenAnswer((_) async => testEvent);
        when(mockEventService.updateEventStatus(
                testEvent, EventStatus.upcoming))
            .thenAnswer((_) async => Future.value());

        // Act
        await controller.rollback(result);

        // Assert
        verify(mockEventService.getEventById('event_123')).called(1);
        verify(mockEventService.updateEventStatus(
                testEvent, EventStatus.upcoming))
            .called(1);
      });

      test('should not throw when rollback is called with failure result',
          () async {
        // Arrange
        final result = CancellationResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        // Act & Assert
        expect(() => controller.rollback(result), returnsNormally);
        await controller.rollback(result);
        verifyNever(mockEventService.updateEventStatus(any, any));
      });
    });
  });
}

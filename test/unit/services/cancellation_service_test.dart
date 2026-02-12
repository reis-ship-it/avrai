import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/events/cancellation_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/services/payment/refund_service.dart';
import 'package:avrai/core/services/payment/stripe_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/models/misc/cancellation.dart';
import 'package:avrai/core/models/misc/cancellation_initiator.dart';
import 'package:avrai/core/models/payment/refund_status.dart';
import 'package:avrai/core/models/payment/payment_status.dart';
import 'package:avrai/core/models/payment/refund_distribution.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

import 'cancellation_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  ExpertiseEventService,
  PaymentService,
  RefundService,
  StripeService,
])
void main() {
  group('CancellationService', () {
    late CancellationService service;
    late MockExpertiseEventService mockEventService;
    late MockPaymentService mockPaymentService;
    late MockRefundService mockRefundService;

    late ExpertiseEvent testEvent;
    late Payment testPayment;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPaymentService = MockPaymentService();
      mockRefundService = MockRefundService();

      service = CancellationService(
        eventService: mockEventService,
        paymentService: mockPaymentService,
        refundService: mockRefundService,
      );

      final host = ModelFactories.createTestUser(
        id: 'host-123',
        displayName: 'Test Host',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        host: host,
        title: 'Test Event',
        description: 'Test Description',
        category: 'Workshops',
        eventType: ExpertiseEventType.workshop,
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
        maxAttendees: 50,
        attendeeCount: 10,
        isPaid: true,
        price: 25.00,
        location: 'Test Location',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );

      testPayment = Payment(
        id: 'payment-123',
        eventId: 'event-123',
        userId: 'user-456',
        amount: 25.00,
        status: PaymentStatus.completed,
        stripePaymentIntentId: 'pi_test123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Cancellation creation tests focus on business logic (initiator type, refund status), not property assignment

    group('attendeeCancelTicket', () {
      test(
          'should create cancellation and process refund for valid cancellation, and throw exception if event not found',
          () async {
        // Test business logic: attendee cancellation with refund processing and error handling
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser(
                'event-123', 'user-456'))
            .thenAnswer((_) => testPayment);

        // Stub refund service to return a refund distribution
        when(mockRefundService.processRefund(
          paymentId: anyNamed('paymentId'),
          amount: anyNamed('amount'),
          cancellationId: anyNamed('cancellationId'),
        )).thenAnswer((invocation) async {
          return [
            RefundDistribution(
              userId: testPayment.userId,
              role: 'attendee',
              amount: invocation.namedArguments[#amount] as double,
              stripeRefundId: 're_test123',
              completedAt: DateTime.now(),
              statusMessage: 'Refund processed successfully',
            ),
          ];
        });

        // Act
        final cancellation = await service.attendeeCancelTicket(
          eventId: 'event-123',
          attendeeId: 'user-456',
        );

        // Assert
        expect(cancellation, isA<Cancellation>());
        expect(cancellation.eventId, equals('event-123'));
        expect(cancellation.initiator, equals(CancellationInitiator.attendee));
        expect(cancellation.refundStatus, equals(RefundStatus.completed));
        verify(mockEventService.getEventById('event-123')).called(1);

        // Test error handling
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.attendeeCancelTicket(
            eventId: 'event-123',
            attendeeId: 'user-456',
          ),
          throwsException,
        );
      });
    });

    group('hostCancelEvent and emergencyCancelEvent', () {
      test('should create host and emergency cancellations with batch refunds',
          () async {
        // Test business logic: host and emergency cancellation with batch refund processing
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentsForEvent('event-123'))
            .thenAnswer((_) => [testPayment]);

        // Stub batch refund processing
        when(mockRefundService.processBatchRefunds(
          payments: anyNamed('payments'),
          cancellationId: anyNamed('cancellationId'),
          fullRefund: anyNamed('fullRefund'),
        )).thenAnswer((invocation) async {
          final payments =
              invocation.namedArguments[#payments] as List<Payment>;
          return payments
              .map((payment) => RefundDistribution(
                    userId: payment.userId,
                    role: 'attendee',
                    amount: payment.amount,
                    stripeRefundId: 're_${payment.id}',
                    completedAt: DateTime.now(),
                    statusMessage: 'Refund processed successfully',
                  ))
              .toList();
        });

        // Test host cancellation
        final hostCancellation = await service.hostCancelEvent(
          eventId: 'event-123',
          hostId: 'host-123',
          reason: 'Host cancellation',
        );

        expect(hostCancellation, isA<Cancellation>());
        expect(hostCancellation.eventId, equals('event-123'));
        expect(hostCancellation.initiator, equals(CancellationInitiator.host));
        expect(hostCancellation.reason, equals('Host cancellation'));

        // Test emergency cancellation
        final emergencyCancellation = await service.emergencyCancelEvent(
          eventId: 'event-123',
          reason: 'Weather emergency',
          weatherRelated: true,
        );

        expect(emergencyCancellation, isA<Cancellation>());
        expect(emergencyCancellation.eventId, equals('event-123'));
        expect(emergencyCancellation.initiator,
            equals(CancellationInitiator.weather));
        expect(emergencyCancellation.reason, equals('Weather emergency'));
        verify(mockEventService.getEventById('event-123')).called(2);
      });
    });

    group('getCancellation', () {
      test('should return cancellation if exists, or null if not found',
          () async {
        // Test business logic: cancellation retrieval with existence checking
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser(
                'event-123', 'user-456'))
            .thenReturn(testPayment);

        // Stub refund service
        when(mockRefundService.processRefund(
          paymentId: anyNamed('paymentId'),
          amount: anyNamed('amount'),
          cancellationId: anyNamed('cancellationId'),
        )).thenAnswer((invocation) async {
          return [
            RefundDistribution(
              userId: testPayment.userId,
              role: 'attendee',
              amount: invocation.namedArguments[#amount] as double,
              stripeRefundId: 're_test123',
              completedAt: DateTime.now(),
            ),
          ];
        });

        final testCancellation = await service.attendeeCancelTicket(
          eventId: 'event-123',
          attendeeId: 'user-456',
        );

        // Act - test existing cancellation
        final cancellation = await service.getCancellation(testCancellation.id);

        // Assert
        expect(cancellation, isNotNull);
        expect(cancellation?.id, equals(testCancellation.id));

        // Test non-existent cancellation
        final notFound = await service.getCancellation('non-existent');
        expect(notFound, isNull);
      });
    });

    group('getCancellationsForEvent', () {
      test('should return all cancellations for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPaymentService.getPaymentForEventAndUser(
                'event-123', 'user-456'))
            .thenAnswer((_) => testPayment);
        when(mockPaymentService.getPaymentsForEvent('event-123'))
            .thenAnswer((_) => [testPayment]);

        // Stub refund service for attendee cancellation
        when(mockRefundService.processRefund(
          paymentId: anyNamed('paymentId'),
          amount: anyNamed('amount'),
          cancellationId: anyNamed('cancellationId'),
        )).thenAnswer((invocation) async {
          return [
            RefundDistribution(
              userId: testPayment.userId,
              role: 'attendee',
              amount: invocation.namedArguments[#amount] as double,
              stripeRefundId: 're_test123',
              completedAt: DateTime.now(),
            ),
          ];
        });

        // Stub batch refund processing for host cancellation
        when(mockRefundService.processBatchRefunds(
          payments: anyNamed('payments'),
          cancellationId: anyNamed('cancellationId'),
          fullRefund: anyNamed('fullRefund'),
        )).thenAnswer((invocation) async {
          final payments =
              invocation.namedArguments[#payments] as List<Payment>;
          return payments
              .map((payment) => RefundDistribution(
                    userId: payment.userId,
                    role: 'attendee',
                    amount: payment.amount,
                    stripeRefundId: 're_${payment.id}',
                    completedAt: DateTime.now(),
                  ))
              .toList();
        });

        await service.attendeeCancelTicket(
          eventId: 'event-123',
          attendeeId: 'user-456',
        );
        await service.hostCancelEvent(
          eventId: 'event-123',
          hostId: 'host-123',
          reason: 'Host cancellation',
        );

        // Act
        final cancellations =
            await service.getCancellationsForEvent('event-123');

        // Assert
        expect(cancellations, isNotEmpty);
        expect(cancellations.length, greaterThanOrEqualTo(2));
        expect(cancellations.every((c) => c.eventId == 'event-123'), isTrue);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

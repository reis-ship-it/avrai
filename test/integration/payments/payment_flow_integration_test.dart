import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/payment/stripe_service.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../fixtures/integration_test_fixtures.dart';
import '../../helpers/test_helpers.dart';

class MockStripeService extends Mock implements StripeService {}
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Payment Flow Integration Tests
/// 
/// Agent 3: Expertise UI & Testing (Week 4, Task 3.10)
/// 
/// Tests complete payment flow end-to-end:
/// - Paid event purchase flow
/// - Payment success scenarios
/// - Payment failure scenarios
/// - Revenue split calculation
/// 
/// **Test Scenarios:**
/// - Scenario 1: Paid Event Purchase Flow
/// - Scenario 4: Payment Failure Handling
void main() {
  group('Payment Flow Integration Tests', () {
    late PaymentService paymentService;
    late ExpertiseEventService eventService;
    late MockStripeService mockStripeService;
    late MockExpertiseEventService mockEventService;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      
      // Setup mocks
      mockStripeService = MockStripeService();
      mockEventService = MockExpertiseEventService();
      
      // Setup Stripe mock
      when(() => mockStripeService.isInitialized).thenReturn(true);
      when(() => mockStripeService.initializeStripe())
          .thenAnswer((_) async => {});
      
      // Create real event service for event creation
      eventService = ExpertiseEventService();
      
      // Create payment service with mocked Stripe
      paymentService = PaymentService(
        mockStripeService,
        mockEventService,
      );
    });
    
    tearDown(() {
      reset(mockStripeService);
      reset(mockEventService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Paid Event Purchase Flow', () {
      test('should complete payment and register user for paid event', () async {
        // Test business logic: payment processing and event registration integration
        // Arrange
        final scenario = IntegrationTestFixtures.paymentFlowScenario();
        final host = scenario['host'] as UnifiedUser;
        final attendee = scenario['attendee'] as UnifiedUser;
        
        // Create event in service (use category from scenario)
        final category = scenario['category'] as String? ?? 'Coffee';
        final event = await eventService.createEvent(
          host: host,
          title: 'Paid Test Event',
          description: 'A paid event for testing',
          category: category,
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          price: 25.0,
        );

        // Verify initial state
        expect(event.isPaid, isTrue);
        expect(event.price, isNotNull);
        expect(event.attendeeCount, equals(0));
        expect(event.canUserAttend(attendee.id), isTrue);

        // Setup event service mock to return the event
        when(() => mockEventService.getEventById(event.id))
            .thenAnswer((_) async => event);

        // Initialize payment service
        // Note: PaymentService creates payment intents internally, so no Stripe mocks needed
        await paymentService.initialize();

        // Act - Purchase ticket
        final result = await paymentService.purchaseEventTicket(
          eventId: event.id,
          userId: attendee.id,
          ticketPrice: event.price!,
          quantity: 1,
        );

        // Assert - Payment success
        expect(result.isSuccess, isTrue);
        expect(result.payment, isNotNull);
        expect(result.revenueSplit, isNotNull);

        // Assert - Revenue split
        final revenueSplit = result.revenueSplit!;
        expect(revenueSplit.totalAmount, equals(event.price!));
        expect(revenueSplit.platformFee, closeTo(event.price! * 0.10, 0.01));
        expect(revenueSplit.isValid, isTrue);
      });

      test('should calculate revenue split correctly', () {
        // Arrange
        const totalAmount = 25.00;
        const ticketsSold = 1;
        const eventId = 'test-event-123';

        // Act
        final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
          eventId: eventId,
          totalAmount: totalAmount,
          ticketsSold: ticketsSold,
        );

        // Assert
        expect(revenueSplit.totalAmount, equals(totalAmount));
        expect(revenueSplit.platformFee, closeTo(2.50, 0.01)); // 10%
        expect(revenueSplit.processingFee, closeTo(1.025, 0.01)); // ~3%
        expect(revenueSplit.hostPayout, closeTo(21.475, 0.01)); // ~87%
        expect(revenueSplit.isValid, isTrue);
      });
    });

    group('Scenario 4: Payment Failure Handling', () {
      test('should handle payment failure and not register user', () async {
        // Test business logic: payment failure does not register user for event
        // Arrange
        final scenario = IntegrationTestFixtures.paymentFlowScenario();
        final host = scenario['host'] as UnifiedUser;
        final attendee = scenario['attendee'] as UnifiedUser;
        
        // Create event in service (use category from scenario)
        final category = scenario['category'] as String? ?? 'Coffee';
        final event = await eventService.createEvent(
          host: host,
          title: 'Paid Test Event',
          description: 'A paid event for testing',
          category: category,
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          price: 25.0,
        );

        // Verify initial state
        expect(event.isPaid, isTrue);
        expect(event.attendeeCount, equals(0));
      
        // Setup event service mock to return null (simulating event not found for payment service)
        when(() => mockEventService.getEventById(event.id))
            .thenAnswer((_) async => null);

        // Initialize payment service
        await paymentService.initialize();

        // Act - Attempt payment for non-existent event (simulates failure)
        final result = await paymentService.purchaseEventTicket(
          eventId: event.id,
          userId: attendee.id,
          ticketPrice: event.price!,
          quantity: 1,
        );
      
        // Assert - Payment failure
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(result.payment, isNull);

        // Assert - Event not updated (verify with real service)
        final updatedEvent = await eventService.getEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.attendeeIds, isNot(contains(attendee.id)));
        expect(updatedEvent.attendeeCount, equals(0));
      });

      test('should handle event capacity exceeded error', () async {
        // Test business logic: payment fails when event is at capacity
        // Arrange
        final scenario = IntegrationTestFixtures.fullEventScenario();
        final host = scenario['host'] as UnifiedUser;
        final newUser = IntegrationTestHelpers.createUserWithCityExpertise();
        
        // Create event at capacity (use category from scenario or default to one host has expertise in)
        final category = scenario['category'] as String? ?? 'Coffee';
        final event = await eventService.createEvent(
          host: host,
          title: 'Full Event',
          description: 'Event at capacity',
          category: category,
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          maxAttendees: 1,
          price: 25.0,
        );
        
        // Fill event to capacity
        final firstUser = IntegrationTestHelpers.createUserWithCityExpertise();
        await eventService.registerForEvent(event, firstUser);
        final fullEvent = await eventService.getEventById(event.id);

        // Verify event is full
        expect(fullEvent, isNotNull);
        expect(fullEvent!.isFull, isTrue);
        expect(fullEvent.attendeeCount, equals(fullEvent.maxAttendees));

        // Setup event service mock to return the full event
        when(() => mockEventService.getEventById(event.id))
            .thenAnswer((_) async => fullEvent);

        // Initialize payment service
        await paymentService.initialize();

        // Act - Attempt to purchase ticket for full event
        final result = await paymentService.purchaseEventTicket(
          eventId: event.id,
          userId: newUser.id,
          ticketPrice: event.price ?? 0.0,
          quantity: 1,
        );

        // Assert - Payment should fail with capacity error
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotNull);
        // Note: Error code may vary, but should indicate capacity issue
      });
    });

    group('Payment Result Verification', () {
      test('should create successful payment result correctly', () {
        // Arrange
        final payment = IntegrationTestHelpers.createSuccessfulPayment(
          eventId: 'event-123',
          userId: 'user-456',
          amount: 25.00,
      );
      
        final revenueSplit = IntegrationTestHelpers.createTestRevenueSplit(
          eventId: 'event-123',
          totalAmount: 25.00,
          ticketsSold: 1,
        );

        // Act
        final result = IntegrationTestHelpers.createSuccessfulPaymentResult(
          payment: payment,
          revenueSplit: revenueSplit,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.payment, isNotNull);
        expect(result.revenueSplit, isNotNull);
        expect(result.errorMessage, isNull);
      });

      test('should create failed payment result correctly', () {
        // Arrange
        const errorMessage = 'Card declined';
        const errorCode = 'card_declined';

        // Act
        final result = IntegrationTestHelpers.createFailedPaymentResult(
          errorMessage: errorMessage,
          errorCode: errorCode,
      );
      
        // Assert
      expect(result.isSuccess, isFalse);
        expect(result.payment, isNull);
        expect(result.errorMessage, equals(errorMessage));
        expect(result.errorCode, equals(errorCode));
      });
    });
  });
}

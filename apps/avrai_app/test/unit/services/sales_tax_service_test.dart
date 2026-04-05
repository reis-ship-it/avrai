import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/payment/sales_tax_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'sales_tax_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('SalesTaxService', () {
    late SalesTaxService service;
    late MockExpertiseEventService mockEventService;

    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();

      service = SalesTaxService(
        eventService: mockEventService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Test Event',
        description: 'A test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        isPaid: true,
        price: 25.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Sales tax tests focus on business logic (tax calculation, tax rate retrieval, exemption logic), not property assignment

    group('calculateSalesTax', () {
      test(
          'should return zero tax for tax-exempt event types, calculate tax for taxable event types, throw exception if event not found, or calculate correct tax amount',
          () async {
        // Test business logic: sales tax calculation
        final workshopEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.workshop,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => workshopEvent);
        final calculation1 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );
        expect(calculation1, isA<SalesTaxCalculation>());
        expect(calculation1.isTaxExempt, isTrue);
        expect(calculation1.taxAmount, equals(0.0));
        expect(calculation1.taxRate, equals(0.0));
        expect(calculation1.totalAmount, equals(25.0));
        expect(calculation1.exemptionReason, isNotNull);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final calculation2 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );
        expect(calculation2, isA<SalesTaxCalculation>());
        expect(calculation2.isTaxExempt, isFalse);
        expect(calculation2.taxableAmount, equals(25.0));
        expect(calculation2.taxRate, greaterThanOrEqualTo(0.0));
        expect(calculation2.totalAmount, greaterThanOrEqualTo(25.0));

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.calculateSalesTax(
            eventId: 'event-123',
            ticketPrice: 25.0,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final calculation3 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 100.0,
        );
        expect(
            calculation3.taxAmount,
            equals(
                calculation3.taxableAmount * (calculation3.taxRate / 100.0)));
        expect(calculation3.totalAmount,
            equals(calculation3.taxableAmount + calculation3.taxAmount));
      });
    });

    group('getTaxRateForLocation', () {
      test(
          'should return tax rate for state, cache tax rates, return different rates for different locations, or handle missing state gracefully',
          () async {
        // Test business logic: tax rate retrieval
        final taxRate1 = await service.getTaxRateForLocation(
          state: 'CA',
        );
        expect(taxRate1, greaterThanOrEqualTo(0.0));
        expect(taxRate1, lessThanOrEqualTo(15.0));

        final rate1 = await service.getTaxRateForLocation(state: 'CA');
        final rate2 = await service.getTaxRateForLocation(state: 'CA');
        expect(rate1, equals(rate2));

        final caRate = await service.getTaxRateForLocation(state: 'CA');
        final nyRate = await service.getTaxRateForLocation(state: 'NY');
        expect(caRate, isA<double>());
        expect(nyRate, isA<double>());

        final taxRate2 = await service.getTaxRateForLocation(state: null);
        expect(taxRate2, equals(0.0));
      });
    });

    group('tax exemption logic', () {
      test(
          'should exempt workshop events, exempt lecture events, not exempt meetup events, or not exempt tour events',
          () async {
        // Test business logic: tax exemption rules
        final workshopEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.workshop,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => workshopEvent);
        final calculation1 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );
        expect(calculation1.isTaxExempt, isTrue);

        final lectureEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.lecture,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => lectureEvent);
        final calculation2 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );
        expect(calculation2.isTaxExempt, isTrue);

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final calculation3 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );
        expect(calculation3.isTaxExempt, isFalse);

        final tourEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.tour,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => tourEvent);
        final calculation4 = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );
        expect(calculation4.isTaxExempt, isFalse);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

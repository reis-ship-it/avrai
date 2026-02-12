import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart' hide UserRole;
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_acceptance_page.dart';

import '../../../helpers/getit_test_harness.dart';
import '../../mocks/mock_blocs.dart';

/// Partnership Acceptance Page Widget Tests
///
/// Agent 2: Partnership UI, Business UI (Week 8)
///
/// Tests the partnership acceptance page functionality.
void main() {
  group('PartnershipAcceptancePage Widget Tests', () {
    late EventPartnership testPartnership;
    late ExpertiseEvent testEvent;
    late GetItTestHarness getIt;
    late MockAuthBloc mockAuthBloc;
    late _MockPartnershipService mockPartnershipService;
    late _MockExpertiseEventService mockEventService;
    late _MockPaymentService mockPaymentService;

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      mockAuthBloc = MockAuthBloc();
      mockPartnershipService = _MockPartnershipService();
      mockEventService = _MockExpertiseEventService();
      mockPaymentService = _MockPaymentService();

      final user = UnifiedUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
      );

      final business = BusinessAccount(
        id: 'biz-1',
        name: 'Test Business',
        email: 'business@example.com',
        businessType: 'Restaurant',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testEvent = ExpertiseEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test event description',
        category: 'Food',
        eventType: ExpertiseEventType.tour,
        host: user,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'Test Location',
        maxAttendees: 20,
        price: 25.0,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testPartnership = EventPartnership(
        id: 'partnership-1',
        eventId: testEvent.id,
        userId: user.id,
        businessId: business.id,
        user: user,
        business: business,
        status: PartnershipStatus.proposed,
        vibeCompatibilityScore: 0.85,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final now = DateTime.now();
      mockAuthBloc.setState(
        Authenticated(
          user: User(
            id: 'user-1',
            email: 'user@example.com',
            name: 'Test User',
            role: UserRole.user,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );

      getIt.registerSingletonReplace<PartnershipService>(mockPartnershipService);
      getIt.registerSingletonReplace<ExpertiseEventService>(mockEventService);
      getIt.registerSingletonReplace<PaymentService>(mockPaymentService);

      when(() => mockEventService.getEventById(any()))
          .thenAnswer((_) async => testEvent);
    });

    tearDown(() {
      mockAuthBloc.close();
      getIt.unregisterIfRegistered<PartnershipService>();
      getIt.unregisterIfRegistered<ExpertiseEventService>();
      getIt.unregisterIfRegistered<PaymentService>();
    });

    // Removed: Property assignment tests
    // Partnership acceptance page tests focus on business logic (page display, accept and decline buttons, event details), not property assignment

    testWidgets(
        'should display partnership acceptance page, display accept and decline buttons, or display event details',
        (WidgetTester tester) async {
      // Test business logic: Partnership acceptance page display and functionality
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: PartnershipAcceptancePage(partnership: testPartnership),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Partnership Proposal'), findsWidgets);
      expect(find.text('Partnership Details'), findsOneWidget);
      expect(find.text('Accept Partnership'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Event Details'), findsOneWidget);
    });
  });
}

class _MockPartnershipService extends Mock implements PartnershipService {}

class _MockExpertiseEventService extends Mock implements ExpertiseEventService {}

class _MockPaymentService extends Mock implements PaymentService {}

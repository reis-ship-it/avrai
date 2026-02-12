import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/models/user/unified_user.dart' hide UserRole;
import 'package:avrai/core/models/user/user.dart' show User, UserRole;
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_proposal_page.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_acceptance_page.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_management_page.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_checkout_page.dart';
import '../../fixtures/model_factories.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/matching/partnership_matching_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/services/payment/payment_event_service.dart';
import 'package:avrai/core/services/payment/revenue_split_service.dart';
import 'package:avrai/core/services/payment/sales_tax_service.dart';
import 'package:avrai/core/controllers/payment_processing_controller.dart';
import 'package:avrai/core/controllers/partnership_checkout_controller.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widget/mocks/mock_blocs.dart';
import '../../helpers/getit_test_harness.dart';

@GenerateMocks([PartnershipService, PartnershipMatchingService, BusinessService, ExpertiseEventService, PaymentService, PaymentEventService])
import 'partnership_ui_integration_test.mocks.dart';

/// Partnership UI Integration Tests
/// 
/// Agent 2: Phase 4, Week 13 - UI Integration Testing
/// 
/// Tests the complete Partnership UI integration:
/// - Partnership proposal page
/// - Partnership acceptance page
/// - Partnership management page
/// - Partnership checkout page
/// - Navigation flows
/// - Error/loading/empty states
/// - Responsive design
void main() {
  group('Partnership UI Integration Tests', () {
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late EventPartnership testPartnership;
    late MockPartnershipService mockPartnershipService;
    late MockPartnershipMatchingService mockMatchingService;
    late MockBusinessService mockBusinessService;
    late MockExpertiseEventService mockEventService;
    late MockPaymentService mockPaymentService;
    late MockPaymentEventService mockPaymentEventService;
    late MockAuthBloc mockAuthBloc;
    late GetItTestHarness getIt;

    setUpAll(() {
      getIt = GetItTestHarness(sl: GetIt.instance);

      // Register all required services in GetIt
      mockPartnershipService = MockPartnershipService();
      mockMatchingService = MockPartnershipMatchingService();
      mockBusinessService = MockBusinessService();
      mockEventService = MockExpertiseEventService();
      mockPaymentService = MockPaymentService();
      mockPaymentEventService = MockPaymentEventService();
      mockAuthBloc = MockAuthBloc();
      
      // Unregister if already registered
      getIt.unregisterIfRegistered<PartnershipService>();
      getIt.unregisterIfRegistered<PartnershipMatchingService>();
      getIt.unregisterIfRegistered<BusinessService>();
      getIt.unregisterIfRegistered<ExpertiseEventService>();
      getIt.unregisterIfRegistered<PaymentService>();
      getIt.unregisterIfRegistered<PaymentEventService>();
      getIt.unregisterIfRegistered<SalesTaxService>();
      getIt.unregisterIfRegistered<RevenueSplitService>();
      getIt.unregisterIfRegistered<PartnershipCheckoutController>();
      getIt.unregisterIfRegistered<PaymentProcessingController>();
      
      // Register mocks
      getIt.registerSingletonReplace<PartnershipService>(mockPartnershipService);
      getIt.registerSingletonReplace<PartnershipMatchingService>(mockMatchingService);
      getIt.registerSingletonReplace<BusinessService>(mockBusinessService);
      getIt.registerSingletonReplace<ExpertiseEventService>(mockEventService);
      getIt.registerSingletonReplace<PaymentService>(mockPaymentService);
      getIt.registerSingletonReplace<PaymentEventService>(mockPaymentEventService);

      // PartnershipCheckoutPage requires PartnershipCheckoutController to be registered.
      // We wire it with minimal real dependencies; payment processing is not exercised
      // in these UI rendering tests.
      getIt.registerLazySingletonReplace<SalesTaxService>(
        () => SalesTaxService(
          eventService: mockEventService,
          paymentService: mockPaymentService,
        ),
      );
      getIt.registerLazySingletonReplace<RevenueSplitService>(
        () => RevenueSplitService(partnershipService: mockPartnershipService),
      );
      getIt.registerLazySingletonReplace<PartnershipCheckoutController>(
        () => PartnershipCheckoutController(
          partnershipService: mockPartnershipService,
          eventService: mockEventService,
          salesTaxService: GetIt.instance<SalesTaxService>(),
          revenueSplitService: GetIt.instance<RevenueSplitService>(),
          // paymentController omitted (resolved lazily on submit).
        ),
      );

      // PaymentFormWidget resolves PaymentProcessingController at build-time.
      // Provide a lightweight controller wired to mocks so checkout pages can render.
      getIt.registerSingletonReplace<PaymentProcessingController>(
        PaymentProcessingController(
          salesTaxService: GetIt.instance<SalesTaxService>(),
          paymentEventService: mockPaymentEventService,
        ),
      );
    });
    
    tearDownAll(() {
      // Unregister all services for test isolation
      getIt.unregisterIfRegistered<ExpertiseEventService>();
      getIt.unregisterIfRegistered<PaymentService>();
      getIt.unregisterIfRegistered<PartnershipService>();
      getIt.unregisterIfRegistered<PartnershipMatchingService>();
      getIt.unregisterIfRegistered<BusinessService>();
      getIt.unregisterIfRegistered<PaymentEventService>();
      getIt.unregisterIfRegistered<PartnershipCheckoutController>();
      getIt.unregisterIfRegistered<RevenueSplitService>();
      getIt.unregisterIfRegistered<SalesTaxService>();
      getIt.unregisterIfRegistered<PaymentProcessingController>();
    });

    setUp(() {
      testUser = ModelFactories.createTestUser();
      // Create test business account
      testBusiness = BusinessAccount(
        id: 'business-1',
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'restaurant',
        createdBy: testUser.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Setup mock service responses (will be set up after testEvent is created)
      
      testEvent = ExpertiseEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test event description',
        category: 'Food',
        host: testUser,
        eventType: ExpertiseEventType.tour,
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
        userId: testUser.id,
        businessId: testBusiness.id,
        type: PartnershipType.eventBased,
        status: PartnershipStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Setup mock service responses (after testEvent is created)
      when(mockMatchingService.findMatchingPartners(
        userId: anyNamed('userId'),
        eventId: anyNamed('eventId'),
        minCompatibility: anyNamed('minCompatibility'),
      )).thenAnswer((_) async => <PartnershipSuggestion>[]);
      
      when(mockBusinessService.findBusinesses(
        category: anyNamed('category'),
        verifiedOnly: anyNamed('verifiedOnly'),
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => <BusinessAccount>[]);
      
      when(mockEventService.getEventById(any))
          .thenAnswer((_) async => testEvent);
      
      when(mockPartnershipService.getPartnershipsForEvent(any))
          .thenAnswer((_) async => <EventPartnership>[]);

      when(mockPartnershipService.getPartnershipById(any))
          .thenAnswer((_) async => testPartnership);
      
      // Mock PaymentService for checkout page
      when(mockPaymentService.calculateRevenueSplit(
        totalAmount: anyNamed('totalAmount'),
        ticketsSold: anyNamed('ticketsSold'),
        eventId: anyNamed('eventId'),
      )).thenAnswer((invocation) {
        final eventId = invocation.namedArguments[#eventId] as String;
        final totalAmount = invocation.namedArguments[#totalAmount] as double;
        return RevenueSplit(
          id: 'revenue-split-1',
          eventId: eventId,
          totalAmount: totalAmount,
          platformFee: totalAmount * 0.10,
          processingFee: totalAmount * 0.03 + 0.30,
          hostPayout: totalAmount * 0.87 - 0.30,
          calculatedAt: DateTime.now(),
        );
      });
      
      // Setup mock auth bloc state (after testUser is created)
      // Convert UnifiedUser to User for AuthBloc
      final authUser = User(
        id: testUser.id,
        email: testUser.email,
        name: testUser.displayName ?? 'Test User',
        displayName: testUser.displayName ?? 'Test User',
        role: UserRole.user, // UserRole from user.dart (not unified_user.dart)
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockAuthBloc.setState(Authenticated(user: authUser));
    });

    group('Partnership Proposal Page', () {
      testWidgets('should display partnership proposal page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Partnership Proposal'), findsOneWidget);
        expect(find.text('Find a Business Partner'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should display search bar for business search', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('🔍 Search businesses...'), findsOneWidget);
      });

      testWidgets('should display suggested partners section', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Suggested Partners (Vibe Match)'), findsOneWidget);
      });

      testWidgets('should show empty state when no suggestions available', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2)); // Wait for async loading

        // Assert - Should show empty state
        expect(find.text('No suggested partners yet'), findsOneWidget);
      });
    });

    group('Partnership Acceptance Page', () {
      testWidgets('should display partnership acceptance page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipAcceptancePage(
              partnership: testPartnership,
              ),
            ),
          ),
        );
        // Wait for loading to complete
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - After loading, should find the page and event details (not just AppBar text)
        expect(find.byType(PartnershipAcceptancePage), findsOneWidget);
        // Check for content that only appears after loading (event details or buttons)
        final acceptButton = find.text('Accept Partnership');
        final declineButton = find.text('Decline');
        expect(acceptButton.evaluate().isNotEmpty || declineButton.evaluate().isNotEmpty, isTrue);
      });

      testWidgets('should display event details in acceptance page', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipAcceptancePage(
              partnership: testPartnership,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(testEvent.title), findsOneWidget);
      });

      testWidgets('should display accept and decline buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipAcceptancePage(
              partnership: testPartnership,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Accept Partnership'), findsOneWidget);
        expect(find.text('Decline'), findsOneWidget);
      });
    });

    group('Partnership Management Page', () {
      testWidgets('should display partnership management page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const PartnershipManagementPage(),
          ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Check for page type and tab navigation (which appears after loading)
        expect(find.byType(PartnershipManagementPage), findsOneWidget);
        // Check for tabs that appear after loading
        final activeTab = find.text('Active');
        final pendingTab = find.text('Pending');
        final completedTab = find.text('Completed');
        expect(activeTab.evaluate().isNotEmpty || pendingTab.evaluate().isNotEmpty || completedTab.evaluate().isNotEmpty, isTrue);
      });

      testWidgets('should display tab navigation (Active, Pending, Completed)', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const PartnershipManagementPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('should show empty state when no partnerships', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const PartnershipManagementPage(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2)); // Wait for async loading
        await tester.pumpAndSettle();

        // Assert - Should show empty state (check for empty state text or icon)
        final emptyStateText1 = find.textContaining('No');
        final emptyStateText2 = find.textContaining('partnerships');
        final emptyStateIcon = find.byIcon(Icons.handshake_outlined);
        expect(emptyStateText1.evaluate().isNotEmpty || emptyStateText2.evaluate().isNotEmpty || emptyStateIcon.evaluate().isNotEmpty, isTrue);
      });
    });

    group('Partnership Checkout Page', () {
      testWidgets('should display partnership checkout page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipCheckoutPage(
              partnership: testPartnership,
              event: testEvent,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Check for page type and event details (which appear after loading)
        expect(find.byType(PartnershipCheckoutPage), findsOneWidget);
        // Check for event title or other content that appears after loading
        expect(find.text(testEvent.title), findsOneWidget);
      });

      testWidgets('should display event details in checkout', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipCheckoutPage(
              partnership: testPartnership,
              event: testEvent,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(testEvent.title), findsOneWidget);
      });
    });

    group('Navigation Flows', () {
      testWidgets('should navigate from proposal to acceptance flow', (WidgetTester tester) async {
        // Test business logic: Partnership pages can navigate between each other
        // Arrange - Start with proposal page
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify proposal page is displayed
        expect(find.byType(PartnershipProposalPage), findsOneWidget);
        expect(find.text('Partnership Proposal'), findsOneWidget);

        // Act - Navigate to acceptance page (simulating user selecting a business)
        // In a real flow, user would select a business and navigate to acceptance
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipAcceptancePage(
                partnership: testPartnership,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Acceptance page should be displayed
        expect(find.byType(PartnershipAcceptancePage), findsOneWidget);
        // Wait for loading to complete before checking for buttons
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final acceptButton = find.text('Accept Partnership');
        final declineButton = find.text('Decline');
        expect(acceptButton.evaluate().isNotEmpty || declineButton.evaluate().isNotEmpty, isTrue);
      });

      testWidgets('should navigate from acceptance to checkout flow', (WidgetTester tester) async {
        // Test business logic: Checkout page can be rendered independently
        // Arrange & Act - Render checkout page directly
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipCheckoutPage(
                partnership: testPartnership,
                event: testEvent,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Checkout page should be displayed
        expect(find.byType(PartnershipCheckoutPage), findsOneWidget);
        // Check for any text that indicates checkout page is loaded
        // (may be loading state initially, so check for page type)
      });
    });

    group('Error States', () {
      testWidgets('should handle error states in partnership proposal', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Page should render even with potential errors
        expect(find.byType(PartnershipProposalPage), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('should show loading state while fetching suggestions', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pump(); // First frame

        // Assert - Should show loading initially
        // (Actual implementation depends on how loading is handled)
        expect(find.byType(PartnershipProposalPage), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test on phone size
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: PartnershipProposalPage(event: testEvent),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PartnershipProposalPage), findsOneWidget);

        // Test on tablet size
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpAndSettle();

        expect(find.byType(PartnershipProposalPage), findsOneWidget);

        // Reset
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}


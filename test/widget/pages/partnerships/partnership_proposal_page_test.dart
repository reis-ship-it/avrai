import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart' hide UserRole;
import 'package:avrai/core/models/user/user.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/matching/partnership_matching_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/partnerships/partnership_proposal_page.dart';

import '../../../helpers/getit_test_harness.dart';
import '../../mocks/mock_blocs.dart';

/// Partnership Proposal Page Widget Tests
///
/// Agent 2: Partnership UI, Business UI (Week 8)
///
/// Tests the partnership proposal page functionality.
void main() {
  group('PartnershipProposalPage Widget Tests', () {
    late ExpertiseEvent testEvent;
    late GetItTestHarness getIt;
    late MockAuthBloc mockAuthBloc;
    late _MockPartnershipMatchingService mockMatchingService;
    late _MockBusinessService mockBusinessService;

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      mockAuthBloc = MockAuthBloc();
      mockMatchingService = _MockPartnershipMatchingService();
      mockBusinessService = _MockBusinessService();

      final host = UnifiedUser(
        id: 'user-1',
        email: 'host@example.com',
        displayName: 'Test Host',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
      );

      testEvent = ExpertiseEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test event description',
        category: 'Food',
        eventType: ExpertiseEventType.tour,
        host: host,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'Test Location',
        maxAttendees: 20,
        price: 25.0,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final now = DateTime.now();
      mockAuthBloc.setState(
        Authenticated(
          user: User(
            id: 'user-1',
            email: 'host@example.com',
            name: 'Test Host',
            role: UserRole.user,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );

      getIt.registerSingletonReplace<PartnershipMatchingService>(mockMatchingService);
      getIt.registerSingletonReplace<BusinessService>(mockBusinessService);

      when(
        () => mockMatchingService.findMatchingPartners(
          userId: any(named: 'userId'),
          eventId: any(named: 'eventId'),
          minCompatibility: any(named: 'minCompatibility'),
        ),
      ).thenAnswer((_) async => <PartnershipSuggestion>[]);

      when(
        () => mockBusinessService.findBusinesses(
          category: any(named: 'category'),
          verifiedOnly: any(named: 'verifiedOnly'),
          maxResults: any(named: 'maxResults'),
        ),
      ).thenAnswer((_) async => []);
    });

    tearDown(() {
      mockAuthBloc.close();
      getIt.unregisterIfRegistered<PartnershipMatchingService>();
      getIt.unregisterIfRegistered<BusinessService>();
    });

    // Removed: Property assignment tests
    // Partnership proposal page tests focus on business logic (page display, search bar, suggested partners section, empty state), not property assignment

    testWidgets(
        'should display partnership proposal page, display search bar, display suggested partners section, or show empty state when no suggestions',
        (WidgetTester tester) async {
      // Test business logic: Partnership proposal page display and functionality
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: PartnershipProposalPage(event: testEvent),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Partnership Proposal'), findsOneWidget);
      expect(find.text('Find a Business Partner'), findsOneWidget);
      expect(find.text('Partner with businesses to host events together'),
          findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('🔍 Search businesses...'), findsOneWidget);
      expect(find.text('Suggested Partners (Vibe Match)'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No suggested partners yet'), findsOneWidget);
    });
  });
}

class _MockPartnershipMatchingService extends Mock
    implements PartnershipMatchingService {}

class _MockBusinessService extends Mock implements BusinessService {}
